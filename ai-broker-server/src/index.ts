import "dotenv/config";
import Fastify from "fastify";
import { appendFile, mkdir } from "node:fs/promises";
import { dirname } from "node:path";
import { z } from "zod";

type Vendor = "anthropic" | "mistral";
type Surface = "insight_bundle" | "notification_policy";

const vendorSchema = z.enum(["anthropic", "mistral"]);

const requestSchema = z.object({
  surface: z.enum(["insight_bundle", "notification_policy"]),
  profileId: z.string().min(1),
  locale: z.string().min(1),
  policyVersion: z.string().min(1),
  promptVersion: z.string().min(1),
  providerPolicy: z.object({
    preferredOrder: z.array(vendorSchema).min(1),
    allowFailover: z.boolean()
  }),
  shadowMode: z.boolean(),
  context: z.object({
    ageWeeks: z.number(),
    daysHome: z.number(),
    recentEventCount: z.number(),
    recentWalkCount: z.number(),
    recentMealCount: z.number(),
    recentPottyCount: z.number()
  }),
  payload: z.object({
    insightBundle: z
      .object({
        dailyStatus: z.object({
          baselineTitle: z.string(),
          baselineSubtitle: z.string().nullable().optional(),
          pottyUrgency: z.string(),
          isSleeping: z.boolean()
        }),
        walkSorting: z.object({
          actionable: z.array(
            z.object({
              id: z.string(),
              itemType: z.string(),
              label: z.string(),
              minutesUntil: z.number(),
              state: z.string().nullable().optional()
            })
          ),
          upcoming: z.array(
            z.object({
              id: z.string(),
              itemType: z.string(),
              label: z.string(),
              minutesUntil: z.number(),
              state: z.string().nullable().optional()
            })
          )
        }),
        trainingProgressSummary: z.string().nullable().optional(),
        socializationProgressSummary: z.string().nullable().optional()
      })
      .optional(),
    notificationPolicy: z
      .object({
        baselinePottyMinutesDelta: z.number(),
        baselineWalkMinutesDelta: z.number(),
        staleCategories: z.array(z.string())
      })
      .optional()
  })
});

type BrokerRequest = z.infer<typeof requestSchema>;

const insightDecisionSchema = z.object({
  confidence: z.number(),
  dailyStatusDecision: z
    .object({
      headline: z.string(),
      subtitle: z.string().nullable().optional(),
      confidence: z.number()
    })
    .optional()
    .nullable(),
  walkOrderingDecision: z
    .object({
      orderedIds: z.array(z.string()),
      confidence: z.number()
    })
    .optional()
    .nullable(),
  trainingProgressText: z.string().nullable().optional(),
  socializationProgressText: z.string().nullable().optional(),
  loggingRecommendations: z.array(
    z.object({
      category: z.string(),
      recommendation: z.string(),
      confidence: z.number()
    })
  )
});

const notificationDecisionSchema = z.object({
  confidence: z.number(),
  validForMinutes: z.number(),
  pottyMinutesDelta: z.number(),
  walkMinutesDelta: z.number(),
  suppressPotty: z.boolean(),
  suppressWalk: z.boolean()
});

const app = Fastify({ logger: true });

const brokerApiKey = process.env.BROKER_API_KEY;
const anthropicKey = process.env.ANTHROPIC_API_KEY;
const mistralKey = process.env.MISTRAL_API_KEY;
const anthropicModel = process.env.ANTHROPIC_MODEL ?? "claude-3-5-haiku-latest";
const mistralModel = process.env.MISTRAL_MODEL ?? "mistral-small-latest";
const port = Number(process.env.PORT ?? 8787);
const host = process.env.HOST ?? "0.0.0.0";
const logPath = process.env.AI_BROKER_LOG_PATH ?? "/var/log/ollie-ai-broker/requests.jsonl";

if (!brokerApiKey) {
  throw new Error("BROKER_API_KEY is required");
}

app.get("/health", async () => ({ ok: true, service: "ollie-ai-broker" }));

app.post("/ai/nudges/decide", async (req, reply) => {
  const requestId = crypto.randomUUID();
  const startedAt = Date.now();
  const providedKey = req.headers["x-api-key"];
  const userId = getHeaderValue(req.headers["x-user-id"]);

  if (!providedKey || providedKey !== brokerApiKey) {
    return reply.code(401).send({ error: "Unauthorized" });
  }

  const parsed = requestSchema.safeParse(req.body);
  if (!parsed.success) {
    await appendLog({
      requestId,
      userId,
      profileId: "unknown",
      surface: "unknown",
      status: "invalid_request",
      failureReason: parsed.error.message,
      latencyMs: Date.now() - startedAt
    });
    return reply.code(400).send({ error: "Invalid request", details: parsed.error.flatten() });
  }

  const payload = parsed.data;
  if (payload.surface === "insight_bundle" && !payload.payload.insightBundle) {
    return reply.code(400).send({ error: "payload.insightBundle is required" });
  }
  if (payload.surface === "notification_policy" && !payload.payload.notificationPolicy) {
    return reply.code(400).send({ error: "payload.notificationPolicy is required" });
  }

  const prompt = buildPrompt(payload);
  const order = normalizeProviderOrder(payload.providerPolicy.preferredOrder);

  let lastError: string | null = null;

  for (let i = 0; i < order.length; i++) {
    const provider = order[i];
    try {
      const attempt = await callProvider(provider, prompt);
      const jsonText = extractJSONObject(attempt.responseText);
      const modelOutput = JSON.parse(jsonText) as unknown;

      if (payload.surface === "insight_bundle") {
        insightDecisionSchema.parse(modelOutput);
      } else {
        notificationDecisionSchema.parse(modelOutput);
      }

      const cost = estimateCost(provider, attempt.inputTokens, attempt.outputTokens);
      const response = {
        providerUsed: provider,
        modelUsed: attempt.model,
        reasoningTags: buildReasoningTags(payload),
        ...(payload.surface === "insight_bundle"
          ? { insightBundleDecision: modelOutput }
          : { notificationPolicyDecision: modelOutput })
      };

      await appendLog({
        requestId,
        userId,
        profileId: payload.profileId,
        surface: payload.surface,
        status: "ok",
        failureReason: null,
        providerUsed: provider,
        modelUsed: attempt.model,
        inputTokens: cost.inputTokens,
        outputTokens: cost.outputTokens,
        estimatedCostUsd: cost.estimatedCostUsd,
        latencyMs: Date.now() - startedAt
      });

      return reply.code(200).send(response);
    } catch (error) {
      lastError = error instanceof Error ? error.message : String(error);
      const canFailover = payload.providerPolicy.allowFailover && i < order.length - 1;
      if (!canFailover) break;
    }
  }

  await appendLog({
    requestId,
    userId,
    profileId: payload.profileId,
    surface: payload.surface,
    status: "provider_failed",
    failureReason: lastError,
    latencyMs: Date.now() - startedAt
  });

  return reply.code(502).send({
    error: "All providers failed",
    detail: lastError
  });
});

app.listen({ port, host }).catch((error) => {
  app.log.error(error);
  process.exit(1);
});

function getHeaderValue(value: string | string[] | undefined): string | null {
  if (!value) return null;
  return Array.isArray(value) ? value[0] ?? null : value;
}

function normalizeProviderOrder(preferred: Vendor[]): Vendor[] {
  const baseline: Vendor[] = ["anthropic", "mistral"];
  const order = [...preferred];
  for (const provider of baseline) {
    if (!order.includes(provider)) order.push(provider);
  }
  return order;
}

function buildPrompt(payload: BrokerRequest): string {
  const instruction =
    payload.surface === "insight_bundle" ? insightInstructions() : notificationInstructions();
  return `${instruction}\n\nINPUT_JSON:\n${JSON.stringify(payload)}`;
}

function insightInstructions(): string {
  return [
    "You are a decision engine for subtle puppy app nudges.",
    "Return JSON only. No markdown.",
    "Output keys:",
    "confidence, dailyStatusDecision, walkOrderingDecision, trainingProgressText, socializationProgressText, loggingRecommendations",
    "Do not invent IDs. orderedIds must be from input.",
    "Keep text concise and non-chatty."
  ].join("\n");
}

function notificationInstructions(): string {
  return [
    "You are a notification policy tuner.",
    "Return JSON only. No markdown.",
    "Output keys:",
    "confidence, validForMinutes, pottyMinutesDelta, walkMinutesDelta, suppressPotty, suppressWalk",
    "Be conservative. Prefer tiny deltas."
  ].join("\n");
}

async function callProvider(
  provider: Vendor,
  prompt: string
): Promise<{ responseText: string; model: string; inputTokens: number; outputTokens: number }> {
  if (provider === "anthropic") {
    if (!anthropicKey) throw new Error("ANTHROPIC_API_KEY missing");
    return callAnthropic(prompt);
  }
  if (!mistralKey) throw new Error("MISTRAL_API_KEY missing");
  return callMistral(prompt);
}

async function callAnthropic(prompt: string) {
  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": anthropicKey!,
      "anthropic-version": "2023-06-01"
    },
    body: JSON.stringify({
      model: anthropicModel,
      max_tokens: 500,
      temperature: 0.2,
      messages: [{ role: "user", content: prompt }]
    })
  });
  if (!response.ok) {
    throw new Error(`Anthropic HTTP ${response.status}: ${await response.text()}`);
  }
  const raw = (await response.json()) as {
    content?: Array<{ type: string; text?: string }>;
    usage?: { input_tokens?: number; output_tokens?: number };
  };
  const responseText = raw.content?.find((chunk) => chunk.type === "text")?.text;
  if (!responseText) throw new Error("Anthropic response missing text");
  return {
    responseText,
    model: anthropicModel,
    inputTokens: raw.usage?.input_tokens ?? 0,
    outputTokens: raw.usage?.output_tokens ?? 0
  };
}

async function callMistral(prompt: string) {
  const response = await fetch("https://api.mistral.ai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${mistralKey!}`
    },
    body: JSON.stringify({
      model: mistralModel,
      temperature: 0.2,
      response_format: { type: "json_object" },
      messages: [{ role: "user", content: prompt }]
    })
  });
  if (!response.ok) {
    throw new Error(`Mistral HTTP ${response.status}: ${await response.text()}`);
  }
  const raw = (await response.json()) as {
    choices?: Array<{ message?: { content?: string } }>;
    usage?: { prompt_tokens?: number; completion_tokens?: number };
  };
  const responseText = raw.choices?.[0]?.message?.content;
  if (!responseText) throw new Error("Mistral response missing content");
  return {
    responseText,
    model: mistralModel,
    inputTokens: raw.usage?.prompt_tokens ?? 0,
    outputTokens: raw.usage?.completion_tokens ?? 0
  };
}

function extractJSONObject(text: string): string {
  const trimmed = text.trim();
  if (trimmed.startsWith("{") && trimmed.endsWith("}")) {
    return trimmed;
  }
  const start = trimmed.indexOf("{");
  const end = trimmed.lastIndexOf("}");
  if (start >= 0 && end > start) {
    return trimmed.slice(start, end + 1);
  }
  throw new Error("Provider output missing JSON object");
}

function buildReasoningTags(payload: BrokerRequest): string[] {
  const tags = [payload.surface, "schema_validated"];
  if (payload.shadowMode) tags.push("shadow_mode");
  if (payload.context.recentEventCount < 5) tags.push("low_data");
  return tags;
}

function estimateCost(provider: Vendor, inputTokens: number, outputTokens: number) {
  const pricing =
    provider === "anthropic"
      ? { inputPerM: Number(process.env.ANTHROPIC_INPUT_PER_M ?? 1.0), outputPerM: Number(process.env.ANTHROPIC_OUTPUT_PER_M ?? 5.0) }
      : { inputPerM: Number(process.env.MISTRAL_INPUT_PER_M ?? 0.4), outputPerM: Number(process.env.MISTRAL_OUTPUT_PER_M ?? 2.0) };

  const inputCost = (inputTokens / 1_000_000) * pricing.inputPerM;
  const outputCost = (outputTokens / 1_000_000) * pricing.outputPerM;
  return {
    inputTokens,
    outputTokens,
    estimatedCostUsd: Math.round((inputCost + outputCost) * 1_000_000) / 1_000_000
  };
}

async function appendLog(entry: {
  requestId: string;
  userId: string | null;
  profileId: string;
  surface: string;
  status: string;
  failureReason?: string | null;
  providerUsed?: string | null;
  modelUsed?: string | null;
  inputTokens?: number | null;
  outputTokens?: number | null;
  estimatedCostUsd?: number | null;
  latencyMs: number;
}) {
  const line = JSON.stringify({
    timestamp: new Date().toISOString(),
    ...entry
  });
  await mkdir(dirname(logPath), { recursive: true });
  await appendFile(logPath, `${line}\n`, "utf8");
}
