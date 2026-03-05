/**
 * Ollie AI Broker Worker
 *
 * Vendor-agnostic relay and policy layer for AI nudges.
 * Routes to Anthropic/Mistral with failover, validates schema,
 * and logs token/cost analytics to D1.
 */

type Surface = "insight_bundle" | "notification_policy";
type Vendor = "anthropic" | "mistral";

interface Env {
  DB: D1Database;
  BROKER_API_KEY: string;
  ANTHROPIC_API_KEY?: string;
  MISTRAL_API_KEY?: string;
  ANTHROPIC_MODEL?: string;
  MISTRAL_MODEL?: string;
}

interface ProviderPolicy {
  preferredOrder: Vendor[];
  allowFailover: boolean;
}

interface BrokerRequest {
  surface: Surface;
  profileId: string;
  locale: string;
  policyVersion: string;
  promptVersion: string;
  providerPolicy: ProviderPolicy;
  shadowMode: boolean;
  context: {
    ageWeeks: number;
    daysHome: number;
    recentEventCount: number;
    recentWalkCount: number;
    recentMealCount: number;
    recentPottyCount: number;
  };
  payload: {
    insightBundle?: {
      dailyStatus: {
        baselineTitle: string;
        baselineSubtitle?: string | null;
        pottyUrgency: string;
        isSleeping: boolean;
      };
      walkSorting: {
        actionable: WalkItem[];
        upcoming: WalkItem[];
      };
      trainingProgressSummary?: string | null;
      socializationProgressSummary?: string | null;
    };
    notificationPolicy?: {
      baselinePottyMinutesDelta: number;
      baselineWalkMinutesDelta: number;
      staleCategories: string[];
    };
  };
}

interface WalkItem {
  id: string;
  itemType: string;
  label: string;
  minutesUntil: number;
  state?: string | null;
}

interface BrokerResponse {
  providerUsed: string | null;
  modelUsed: string | null;
  reasoningTags: string[];
  insightBundleDecision?: InsightBundleDecision;
  notificationPolicyDecision?: NotificationPolicyDecision;
}

interface InsightBundleDecision {
  confidence: number;
  dailyStatusDecision?: {
    headline: string;
    subtitle?: string | null;
    confidence: number;
  };
  walkOrderingDecision?: {
    orderedIds: string[];
    confidence: number;
  };
  trainingProgressText?: string | null;
  socializationProgressText?: string | null;
  loggingRecommendations: Array<{
    category: string;
    recommendation: string;
    confidence: number;
  }>;
}

interface NotificationPolicyDecision {
  confidence: number;
  validForMinutes: number;
  pottyMinutesDelta: number;
  walkMinutesDelta: number;
  suppressPotty: boolean;
  suppressWalk: boolean;
}

interface ProviderAttemptResult {
  responseText: string;
  model: string;
  inputTokens: number;
  outputTokens: number;
}

interface UsageCost {
  inputTokens: number;
  outputTokens: number;
  estimatedCostUsd: number;
}

const PRICING_PER_MILLION: Record<Vendor, { input: number; output: number }> = {
  anthropic: { input: 1.0, output: 5.0 }, // Tune with your chosen model pricing.
  mistral: { input: 0.4, output: 2.0 } // Tune with your chosen model pricing.
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, X-API-Key, X-User-Id"
    };

    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    if (url.pathname === "/health" && request.method === "GET") {
      return json({ ok: true, service: "ollie-ai-broker" }, 200, corsHeaders);
    }

    if (url.pathname !== "/ai/nudges/decide" || request.method !== "POST") {
      return json({ error: "Not found" }, 404, corsHeaders);
    }

    const providedApiKey = request.headers.get("X-API-Key");
    if (!providedApiKey || providedApiKey !== env.BROKER_API_KEY) {
      return json({ error: "Unauthorized" }, 401, corsHeaders);
    }

    const requestId = crypto.randomUUID();
    const userId = request.headers.get("X-User-Id");
    const startedAt = Date.now();

    let payload: BrokerRequest;
    try {
      payload = (await request.json()) as BrokerRequest;
    } catch {
      return json({ error: "Invalid JSON" }, 400, corsHeaders);
    }

    const validationError = validateRequest(payload);
    if (validationError) {
      await logRequest(env, {
        requestId,
        userId,
        profileId: payload.profileId ?? "unknown",
        surface: payload.surface ?? "unknown",
        status: "invalid_request",
        failureReason: validationError,
        latencyMs: Date.now() - startedAt,
        inputTokens: null,
        outputTokens: null,
        estimatedCostUsd: null,
        providerUsed: null,
        modelUsed: null,
        shadowMode: payload.shadowMode === true
      });
      return json({ error: validationError }, 400, corsHeaders);
    }

    const providerOrder = normalizeProviderOrder(payload.providerPolicy);
    const allowFailover = payload.providerPolicy.allowFailover !== false;
    const prompt = buildPrompt(payload);

    let lastError: string | null = null;

    for (let i = 0; i < providerOrder.length; i++) {
      const vendor = providerOrder[i];

      try {
        const attempt = await callProvider(vendor, prompt, env);
        const parsed = parseModelResponse(payload.surface, attempt.responseText);
        const validation = validateDecision(payload.surface, parsed);
        if (validation) {
          throw new Error(`Schema validation failed: ${validation}`);
        }

        const cost = estimateCost(vendor, attempt.inputTokens, attempt.outputTokens);
        const response: BrokerResponse = {
          providerUsed: vendor,
          modelUsed: attempt.model,
          reasoningTags: inferReasoningTags(payload),
          ...(payload.surface === "insight_bundle"
            ? { insightBundleDecision: parsed as InsightBundleDecision }
            : { notificationPolicyDecision: parsed as NotificationPolicyDecision })
        };

        await logRequest(env, {
          requestId,
          userId,
          profileId: payload.profileId,
          surface: payload.surface,
          status: "ok",
          failureReason: null,
          latencyMs: Date.now() - startedAt,
          inputTokens: cost.inputTokens,
          outputTokens: cost.outputTokens,
          estimatedCostUsd: cost.estimatedCostUsd,
          providerUsed: vendor,
          modelUsed: attempt.model,
          shadowMode: payload.shadowMode
        });

        return json(response, 200, corsHeaders);
      } catch (error) {
        const message = error instanceof Error ? error.message : "Unknown provider error";
        lastError = `${vendor}: ${message}`;
        const shouldRetry = allowFailover && i < providerOrder.length - 1;
        if (!shouldRetry) {
          break;
        }
      }
    }

    await logRequest(env, {
      requestId,
      userId,
      profileId: payload.profileId,
      surface: payload.surface,
      status: "provider_failed",
      failureReason: lastError,
      latencyMs: Date.now() - startedAt,
      inputTokens: null,
      outputTokens: null,
      estimatedCostUsd: null,
      providerUsed: null,
      modelUsed: null,
      shadowMode: payload.shadowMode
    });

    return json({ error: "All providers failed", detail: lastError }, 502, corsHeaders);
  }
};

function json(body: unknown, status: number, extraHeaders?: Record<string, string>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...(extraHeaders ?? {})
    }
  });
}

function validateRequest(payload: BrokerRequest): string | null {
  if (!payload || typeof payload !== "object") return "Payload is required";
  if (!["insight_bundle", "notification_policy"].includes(payload.surface)) return "Invalid surface";
  if (!payload.profileId || typeof payload.profileId !== "string") return "profileId is required";
  if (!payload.providerPolicy || !Array.isArray(payload.providerPolicy.preferredOrder)) {
    return "providerPolicy.preferredOrder is required";
  }
  if (payload.surface === "insight_bundle" && !payload.payload?.insightBundle) {
    return "payload.insightBundle is required";
  }
  if (payload.surface === "notification_policy" && !payload.payload?.notificationPolicy) {
    return "payload.notificationPolicy is required";
  }
  return null;
}

function normalizeProviderOrder(policy: ProviderPolicy): Vendor[] {
  const defaults: Vendor[] = ["anthropic", "mistral"];
  const preferred = policy.preferredOrder.filter((p): p is Vendor => p === "anthropic" || p === "mistral");
  if (preferred.length === 0) return defaults;
  const merged = [...preferred];
  for (const d of defaults) {
    if (!merged.includes(d)) merged.push(d);
  }
  return merged;
}

function buildPrompt(payload: BrokerRequest): string {
  const instructions = payload.surface === "insight_bundle"
    ? insightBundleInstructions()
    : notificationPolicyInstructions();
  return `${instructions}\n\nINPUT_JSON:\n${JSON.stringify(payload)}`;
}

function insightBundleInstructions(): string {
  return [
    "You are an AI policy assistant for a puppy tracking app.",
    "Return JSON only. No markdown.",
    "Generate output strictly matching this shape:",
    "{",
    '  "confidence": number 0..1,',
    '  "dailyStatusDecision": { "headline": string, "subtitle": string|null, "confidence": number } | null,',
    '  "walkOrderingDecision": { "orderedIds": string[], "confidence": number } | null,',
    '  "trainingProgressText": string|null,',
    '  "socializationProgressText": string|null,',
    '  "loggingRecommendations": [',
    '    { "category": "potty|walk|meal|training|socialization", "recommendation": string, "confidence": number }',
    "  ]",
    "}",
    "Do not invent IDs. orderedIds must come only from input walk item IDs.",
    "Keep copy subtle and concise."
  ].join("\n");
}

function notificationPolicyInstructions(): string {
  return [
    "You are an AI policy assistant for reminder tuning.",
    "Return JSON only. No markdown.",
    "Generate output strictly matching this shape:",
    "{",
    '  "confidence": number 0..1,',
    '  "validForMinutes": integer 60..480,',
    '  "pottyMinutesDelta": integer -30..30,',
    '  "walkMinutesDelta": integer -30..30,',
    '  "suppressPotty": boolean,',
    '  "suppressWalk": boolean',
    "}",
    "Be conservative. Avoid suppression unless confidence is high."
  ].join("\n");
}

async function callProvider(vendor: Vendor, prompt: string, env: Env): Promise<ProviderAttemptResult> {
  if (vendor === "anthropic") {
    return callAnthropic(prompt, env);
  }
  return callMistral(prompt, env);
}

async function callAnthropic(prompt: string, env: Env): Promise<ProviderAttemptResult> {
  if (!env.ANTHROPIC_API_KEY) {
    throw new Error("ANTHROPIC_API_KEY missing");
  }
  const model = env.ANTHROPIC_MODEL ?? "claude-3-5-haiku-latest";

  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": env.ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01"
    },
    body: JSON.stringify({
      model,
      max_tokens: 500,
      temperature: 0.2,
      messages: [{ role: "user", content: prompt }]
    })
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Anthropic HTTP ${response.status}: ${text}`);
  }

  const raw = (await response.json()) as {
    content?: Array<{ type: string; text?: string }>;
    usage?: { input_tokens?: number; output_tokens?: number };
  };

  const contentText = raw.content?.find((c) => c.type === "text")?.text;
  if (!contentText) throw new Error("Anthropic response missing text");

  return {
    responseText: contentText,
    model,
    inputTokens: raw.usage?.input_tokens ?? 0,
    outputTokens: raw.usage?.output_tokens ?? 0
  };
}

async function callMistral(prompt: string, env: Env): Promise<ProviderAttemptResult> {
  if (!env.MISTRAL_API_KEY) {
    throw new Error("MISTRAL_API_KEY missing");
  }
  const model = env.MISTRAL_MODEL ?? "mistral-small-latest";

  const response = await fetch("https://api.mistral.ai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${env.MISTRAL_API_KEY}`
    },
    body: JSON.stringify({
      model,
      temperature: 0.2,
      messages: [{ role: "user", content: prompt }],
      response_format: { type: "json_object" }
    })
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Mistral HTTP ${response.status}: ${text}`);
  }

  const raw = (await response.json()) as {
    choices?: Array<{ message?: { content?: string } }>;
    usage?: { prompt_tokens?: number; completion_tokens?: number };
  };

  const contentText = raw.choices?.[0]?.message?.content;
  if (!contentText) throw new Error("Mistral response missing content");

  return {
    responseText: contentText,
    model,
    inputTokens: raw.usage?.prompt_tokens ?? 0,
    outputTokens: raw.usage?.completion_tokens ?? 0
  };
}

function parseModelResponse(surface: Surface, text: string): InsightBundleDecision | NotificationPolicyDecision {
  const objectText = extractJSONObject(text);
  const parsed = JSON.parse(objectText) as unknown;
  if (surface === "insight_bundle") {
    return parsed as InsightBundleDecision;
  }
  return parsed as NotificationPolicyDecision;
}

function extractJSONObject(text: string): string {
  const trimmed = text.trim();
  if (trimmed.startsWith("{") && trimmed.endsWith("}")) {
    return trimmed;
  }
  const first = trimmed.indexOf("{");
  const last = trimmed.lastIndexOf("}");
  if (first >= 0 && last > first) {
    return trimmed.slice(first, last + 1);
  }
  throw new Error("Model output did not include JSON object");
}

function validateDecision(surface: Surface, decision: unknown): string | null {
  if (!decision || typeof decision !== "object") return "Decision must be an object";

  if (surface === "insight_bundle") {
    const d = decision as InsightBundleDecision;
    if (typeof d.confidence !== "number") return "insightBundle.confidence required";
    if (!Array.isArray(d.loggingRecommendations)) return "loggingRecommendations must be array";
    return null;
  }

  const d = decision as NotificationPolicyDecision;
  if (typeof d.confidence !== "number") return "notificationPolicy.confidence required";
  if (typeof d.validForMinutes !== "number") return "notificationPolicy.validForMinutes required";
  if (typeof d.pottyMinutesDelta !== "number") return "notificationPolicy.pottyMinutesDelta required";
  if (typeof d.walkMinutesDelta !== "number") return "notificationPolicy.walkMinutesDelta required";
  if (typeof d.suppressPotty !== "boolean") return "notificationPolicy.suppressPotty required";
  if (typeof d.suppressWalk !== "boolean") return "notificationPolicy.suppressWalk required";
  return null;
}

function inferReasoningTags(payload: BrokerRequest): string[] {
  const tags = ["schema_validated", payload.surface];
  if (payload.shadowMode) tags.push("shadow_mode");
  if (payload.context.recentEventCount < 5) tags.push("low_data");
  return tags;
}

function estimateCost(vendor: Vendor, inputTokens: number, outputTokens: number): UsageCost {
  const pricing = PRICING_PER_MILLION[vendor];
  const inputCost = (inputTokens / 1_000_000) * pricing.input;
  const outputCost = (outputTokens / 1_000_000) * pricing.output;
  return {
    inputTokens,
    outputTokens,
    estimatedCostUsd: roundUsd(inputCost + outputCost)
  };
}

function roundUsd(value: number): number {
  return Math.round(value * 1_000_000) / 1_000_000;
}

async function logRequest(
  env: Env,
  row: {
    requestId: string;
    userId: string | null;
    profileId: string;
    surface: string;
    status: string;
    failureReason: string | null;
    latencyMs: number;
    inputTokens: number | null;
    outputTokens: number | null;
    estimatedCostUsd: number | null;
    providerUsed: string | null;
    modelUsed: string | null;
    shadowMode: boolean;
  }
): Promise<void> {
  if (!env.DB) return;
  try {
    await env.DB.prepare(
      `INSERT INTO ai_requests (
        request_id, user_id, profile_id, surface, provider_used, model_used, status,
        failure_reason, latency_ms, input_tokens, output_tokens, estimated_cost_usd, shadow_mode
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    ).bind(
      row.requestId,
      row.userId,
      row.profileId,
      row.surface,
      row.providerUsed,
      row.modelUsed,
      row.status,
      row.failureReason,
      row.latencyMs,
      row.inputTokens,
      row.outputTokens,
      row.estimatedCostUsd,
      row.shadowMode ? 1 : 0
    ).run();
  } catch {
    // Logging failure should not fail the request.
  }
}
