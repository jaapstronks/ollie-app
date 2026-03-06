/**
 * Tests for LLM output normalization layer.
 * Run with: npx tsx --test src/normalize.test.ts
 */
import { describe, it } from "node:test";
import assert from "node:assert/strict";

// Re-export the functions we want to test (normally these would be in a separate module)
// For now, we duplicate the logic here for testing

function normalizeJSONText(text: string): string {
  let normalized = text;
  normalized = normalized.replace(/\/\/[^\n]*\n/g, "\n");
  normalized = normalized.replace(/\/\*[\s\S]*?\*\//g, "");
  normalized = normalized.replace(/'([^'\\]*(\\.[^'\\]*)*)'/g, '"$1"');
  normalized = normalized.replace(/([{,]\s*)([a-zA-Z_][a-zA-Z0-9_]*)(\s*:)/g, '$1"$2"$3');
  normalized = normalized.replace(/,(\s*[}\]])/g, "$1");
  normalized = normalized.replace(/:\s*NaN\b/g, ": null");
  normalized = normalized.replace(/:\s*Infinity\b/g, ": null");
  normalized = normalized.replace(/:\s*-Infinity\b/g, ": null");
  normalized = normalized.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F]/g, "");
  return normalized;
}

function normalizeNotificationDecision(raw: unknown): unknown {
  if (!raw || typeof raw !== "object") return raw;
  const obj = raw as Record<string, unknown>;

  const numberFields = ["confidence", "validForMinutes", "pottyMinutesDelta", "walkMinutesDelta"];
  for (const field of numberFields) {
    if (typeof obj[field] === "string") {
      obj[field] = parseFloat(obj[field] as string) || 0;
    }
    if (obj[field] === undefined || obj[field] === null) {
      if (field === "confidence") obj[field] = 0;
      else if (field === "validForMinutes") obj[field] = 60;
      else obj[field] = 0;
    }
  }

  const boolFields = ["suppressPotty", "suppressWalk"];
  for (const field of boolFields) {
    if (typeof obj[field] === "string") {
      obj[field] = obj[field] === "true" || obj[field] === "1";
    }
    if (obj[field] === undefined || obj[field] === null) {
      obj[field] = false;
    }
  }

  return obj;
}

describe("normalizeJSONText", () => {
  it("removes trailing commas", () => {
    const input = '{"a": 1, "b": 2,}';
    const result = normalizeJSONText(input);
    assert.equal(result, '{"a": 1, "b": 2}');
  });

  it("removes trailing commas in arrays", () => {
    const input = '{"arr": [1, 2, 3,]}';
    const result = normalizeJSONText(input);
    assert.equal(result, '{"arr": [1, 2, 3]}');
  });

  it("converts single quotes to double quotes", () => {
    const input = "{'name': 'test'}";
    const result = normalizeJSONText(input);
    assert.equal(result, '{"name": "test"}');
  });

  it("quotes unquoted keys", () => {
    const input = '{foo: "bar", baz: 123}';
    const result = normalizeJSONText(input);
    assert.equal(result, '{"foo": "bar", "baz": 123}');
  });

  it("removes single-line comments", () => {
    const input = '{\n"a": 1, // this is a comment\n"b": 2\n}';
    const result = normalizeJSONText(input);
    assert.ok(!result.includes("comment"));
  });

  it("removes multi-line comments", () => {
    const input = '{"a": 1, /* comment */ "b": 2}';
    const result = normalizeJSONText(input);
    assert.equal(result, '{"a": 1,  "b": 2}');
  });

  it("replaces NaN with null", () => {
    const input = '{"value": NaN}';
    const result = normalizeJSONText(input);
    assert.equal(result, '{"value": null}');
  });

  it("replaces Infinity with null", () => {
    const input = '{"value": Infinity}';
    const result = normalizeJSONText(input);
    assert.equal(result, '{"value": null}');
  });

  it("replaces -Infinity with null", () => {
    const input = '{"value": -Infinity}';
    const result = normalizeJSONText(input);
    assert.equal(result, '{"value": null}');
  });

  it("handles valid JSON unchanged", () => {
    const input = '{"confidence": 0.85, "validForMinutes": 60}';
    const result = normalizeJSONText(input);
    assert.equal(result, input);
  });
});

describe("normalizeNotificationDecision", () => {
  it("converts string numbers to numbers", () => {
    const input = { confidence: "0.85", validForMinutes: "60", pottyMinutesDelta: "5", walkMinutesDelta: "-10" };
    const result = normalizeNotificationDecision(input) as Record<string, unknown>;
    assert.equal(result.confidence, 0.85);
    assert.equal(result.validForMinutes, 60);
    assert.equal(result.pottyMinutesDelta, 5);
    assert.equal(result.walkMinutesDelta, -10);
  });

  it("converts string booleans to booleans", () => {
    const input = {
      confidence: 0.8,
      validForMinutes: 60,
      pottyMinutesDelta: 0,
      walkMinutesDelta: 0,
      suppressPotty: "true",
      suppressWalk: "false"
    };
    const result = normalizeNotificationDecision(input) as Record<string, unknown>;
    assert.equal(result.suppressPotty, true);
    assert.equal(result.suppressWalk, false);
  });

  it("provides defaults for missing fields", () => {
    const input = {};
    const result = normalizeNotificationDecision(input) as Record<string, unknown>;
    assert.equal(result.confidence, 0);
    assert.equal(result.validForMinutes, 60);
    assert.equal(result.pottyMinutesDelta, 0);
    assert.equal(result.walkMinutesDelta, 0);
    assert.equal(result.suppressPotty, false);
    assert.equal(result.suppressWalk, false);
  });

  it("handles null values", () => {
    const input = { confidence: null, validForMinutes: null, suppressPotty: null };
    const result = normalizeNotificationDecision(input) as Record<string, unknown>;
    assert.equal(result.confidence, 0);
    assert.equal(result.validForMinutes, 60);
    assert.equal(result.suppressPotty, false);
  });

  it("preserves valid values", () => {
    const input = {
      confidence: 0.9,
      validForMinutes: 120,
      pottyMinutesDelta: 10,
      walkMinutesDelta: -5,
      suppressPotty: true,
      suppressWalk: false
    };
    const result = normalizeNotificationDecision(input) as Record<string, unknown>;
    assert.equal(result.confidence, 0.9);
    assert.equal(result.validForMinutes, 120);
    assert.equal(result.pottyMinutesDelta, 10);
    assert.equal(result.walkMinutesDelta, -5);
    assert.equal(result.suppressPotty, true);
    assert.equal(result.suppressWalk, false);
  });
});

describe("end-to-end normalization", () => {
  it("handles typical LLM malformed output", () => {
    // Typical issues: trailing comma, string numbers
    const llmOutput = `{
      confidence: '0.85',
      validForMinutes: 60,
      pottyMinutesDelta: '5',
      walkMinutesDelta: -10,
      suppressPotty: false,
      suppressWalk: false,
    }`;

    const normalizedText = normalizeJSONText(llmOutput);
    const parsed = JSON.parse(normalizedText);
    const result = normalizeNotificationDecision(parsed) as Record<string, unknown>;

    assert.equal(result.confidence, 0.85);
    assert.equal(result.validForMinutes, 60);
    assert.equal(result.pottyMinutesDelta, 5);
    assert.equal(result.walkMinutesDelta, -10);
    assert.equal(result.suppressPotty, false);
    assert.equal(result.suppressWalk, false);
  });
});
