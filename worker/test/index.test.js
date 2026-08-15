import assert from "node:assert/strict";
import test from "node:test";

import worker from "../src/index.js";
import {accessPayload} from "../src/monetization.js";

const env = {
  OPENAI_API_KEY: "test-key",
  CLIENT_RATE_LIMITER: {limit: async () => ({success: true})},
  IP_RATE_LIMITER: {limit: async () => ({success: true})},
};

test("health endpoint is available without secrets or input", async () => {
  const response = await worker.fetch(
    new Request("https://masslens.example/health"),
    {},
  );

  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), {ok: true});
});

test("readiness fails closed when production secrets are missing", async () => {
  const response = await worker.fetch(
    new Request("https://masslens.example/ready"),
    {},
  );
  assert.equal(response.status, 503);
  const readiness = await response.json();
  assert.equal(readiness.ok, false);
  assert.ok(readiness.errors.includes("OPENAI_API_KEY is missing"));
});

test("unknown routes return JSON 404", async () => {
  const response = await worker.fetch(
    new Request("https://masslens.example/missing"),
    env,
  );

  assert.equal(response.status, 404);
  assert.equal((await response.json()).error.code, "not_found");
});

test("access endpoint exposes the ads-only starter wallet contract", async () => {
  const response = await worker.fetch(
    new Request("https://masslens.example/access", {
      headers: {"X-MassLens-Client-ID": "abcdefghijklmnopqrstuvwx"},
    }),
    {...env, SCAN_ACCESS_ENFORCED: "false"},
  );

  assert.equal(response.status, 200);
  const access = await response.json();
  assert.equal(access.starterScansRemaining, 3);
  assert.equal(access.rewardedScans, 0);
  assert.equal(access.legacyScans, 0);
  assert.equal(access.remainingScans, 3);
  assert.equal(access.rewardBalanceCap, 3);
  assert.equal(access.scanAccessEnforced, false);
  assert.equal(access.adsEnabled, false);
  assert.equal(access.analysisModel, "gpt-5-nano");
});

test("scan access cannot be enforced without D1 storage", async () => {
  const response = await worker.fetch(
    new Request("https://masslens.example/access", {
      headers: {"X-MassLens-Client-ID": "abcdefghijklmnopqrstuvwx"},
    }),
    {...env, SCAN_ACCESS_ENFORCED: "true"},
  );

  assert.equal(response.status, 503);
  assert.equal((await response.json()).error.code, "access_not_configured");
});

test("removed billing routes return 404", async () => {
  const response = await worker.fetch(
    new Request("https://masslens.example/billing/verify", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-MassLens-Client-ID": "abcdefghijklmnopqrstuvwx",
      },
      body: JSON.stringify({
        productId: "attacker_product",
        purchaseToken: "abcdefghijklmnopqrstuvwxyz123456",
      }),
    }),
    env,
  );

  assert.equal(response.status, 404);
  assert.equal((await response.json()).error.code, "not_found");
});

test("all preserved wallet credits keep the ads-only experience enabled", () => {
  const starterAndLegacy = accessPayload({
    starterUsed: 2,
    legacyScans: 1,
    scanAccessEnforced: true,
  });
  assert.equal(starterAndLegacy.starterScansRemaining, 1);
  assert.equal(starterAndLegacy.remainingScans, 2);
  assert.equal(starterAndLegacy.adsEnabled, true);

  const legacyAndRewarded = accessPayload({
    starterUsed: 3,
    rewardedScans: 2,
    legacyScans: 1,
    scanAccessEnforced: true,
  });
  assert.equal(legacyAndRewarded.starterScansRemaining, 0);
  assert.equal(legacyAndRewarded.remainingScans, 3);
  assert.equal(legacyAndRewarded.adsEnabled, true);

  const rewardedNext = accessPayload({
    starterUsed: 3,
    rewardedScans: 2,
    scanAccessEnforced: true,
  });
  assert.equal(rewardedNext.adsEnabled, true);

  const rewardNeeded = accessPayload({
    starterUsed: 3,
    scanAccessEnforced: true,
  });
  assert.equal(rewardNeeded.remainingScans, 0);
  assert.equal(rewardNeeded.adsEnabled, true);

  const unenforced = accessPayload({
    starterUsed: 3,
    legacyScans: 1,
    scanAccessEnforced: false,
  });
  assert.equal(unenforced.adsEnabled, false);
});

test("estimate endpoint requires an installation identifier", async () => {
  const response = await worker.fetch(
    new Request("https://masslens.example/estimate", {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: "{}",
    }),
    env,
  );

  assert.equal(response.status, 400);
  assert.equal((await response.json()).error.code, "invalid_client_id");
});

test("estimate endpoint requires an idempotency identifier", async () => {
  const response = await worker.fetch(
    new Request("https://masslens.example/estimate", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-MassLens-Client-ID": "abcdefghijklmnopqrstuvwx",
      },
      body: "{}",
    }),
    env,
  );
  assert.equal(response.status, 400);
  assert.equal((await response.json()).error.code, "invalid_request_id");
});

test("one or two views are proxied without exposing the client identifier", async () => {
  const originalFetch = globalThis.fetch;
  const clientId = "abcdefghijklmnopqrstuvwx";
  const seenImageCounts = [];
  const seenPrompts = [];
  const seenDeveloperPrompts = [];
  const estimate = {
    object_label: "Ceramic mug",
    category: "Household",
    estimate_grams: 360,
    lower_bound_grams: 290,
    upper_bound_grams: 450,
    confidence: "medium",
    dimensions_mm: {width: 85, height: 105, depth: 85},
    assumptions: [
      "Size: inferred from familiar mug proportions",
      "Material: hollow ceramic with no visible contents",
      "Uncertainty: no scale reference; add a side view",
    ],
  };

  globalThis.fetch = async (url, options) => {
    assert.equal(url, "https://api.openai.com/v1/responses");
    const body = JSON.parse(options.body);
    assert.equal(body.model, "gpt-5-nano");
    assert.equal(body.store, false);
    assert.equal(body.reasoning.effort, "minimal");
    assert.equal(body.max_output_tokens, 800);
    assert.match(body.safety_identifier, /^[a-f0-9]{64}$/);
    assert.equal(body.safety_identifier.includes(clientId), false);
    const imageParts = body.input[1].content.filter(
      (part) => part.type === "input_image",
    );
    const prompt = body.input[1].content.find(
      (part) => part.type === "input_text",
    ).text;
    seenImageCounts.push(imageParts.length);
    seenPrompts.push(prompt);
    seenDeveloperPrompts.push(body.input[0].content[0].text);
    assert.ok(imageParts.every((part) => part.detail === "low"));
    return new Response(
      JSON.stringify({
        output: [{content: [{text: JSON.stringify(estimate)}]}],
      }),
      {status: 200, headers: {"Content-Type": "application/json"}},
    );
  };

  try {
    const response = await worker.fetch(
      new Request("https://masslens.example/estimate", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-MassLens-Client-ID": clientId,
          "X-MassLens-Request-ID": "request_identifier_000001",
        },
        body: JSON.stringify({
          imageBase64: "aW1hZ2U=",
          mimeType: "image/jpeg",
          category: "Auto",
          structure: "Unknown",
        }),
      }),
      env,
    );

    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), estimate);

    const twoViewResponse = await worker.fetch(
      new Request("https://masslens.example/estimate", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-MassLens-Client-ID": clientId,
          "X-MassLens-Request-ID": "request_identifier_000002",
        },
        body: JSON.stringify({
          images: [
            {imageBase64: "aW1hZ2U=", mimeType: "image/jpeg"},
            {imageBase64: "c2Vjb25k", mimeType: "image/png"},
          ],
          material: "Metal",
          fillState: "Partly filled",
          referenceObject: "Standard card",
          knownDimension: {axis: "Length", value: 12.5, unit: "cm"},
          // A legacy client field must be tolerated but ignored completely.
          measuredDimensions: {
            widthMm: 142.4,
            heightMm: 90.1,
            depthMm: 61,
            method: "removed_magic_camera",
          },
        }),
      }),
      env,
    );

    assert.equal(twoViewResponse.status, 200);
    assert.deepEqual(await twoViewResponse.json(), estimate);
    assert.deepEqual(seenImageCounts, [1, 2]);
    assert.match(seenPrompts[1], /Material: Metal/);
    assert.match(seenPrompts[1], /Fill state: Partly filled/);
    assert.match(seenPrompts[1], /Claimed visible reference: Standard card/);
    assert.match(seenPrompts[1], /Already-known side: Length: 12\.5 cm/);
    assert.doesNotMatch(
      seenPrompts[1],
      /142\.4|90\.1|removed_magic_camera/i,
    );
    assert.match(seenPrompts[1], /45-90 degree side view/);
    assert.match(seenDeveloperPrompts[1], /volume times/);
    assert.match(
      seenDeveloperPrompts[1],
      /Return exactly three short assumptions/,
    );
    assert.doesNotMatch(
      seenDeveloperPrompts[1],
      /\bARCore\b|calibrated tracing/i,
    );
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("a wrong-language estimate is retried once with a corrective prompt", async () => {
  const originalFetch = globalThis.fetch;
  const koreanEstimate = {
    object_label: "에어팟 무선 이어폰",
    category: "Electronics",
    estimate_grams: 50,
    lower_bound_grams: 40,
    upper_bound_grams: 65,
    confidence: "medium",
    dimensions_mm: {width: 50, height: 28, depth: 50},
    assumptions: [
      "Size: 케이스 크기 기준",
      "Material: 플라스틱",
      "Uncertainty: 스케일 없음",
    ],
  };
  const frenchEstimate = {
    ...koreanEstimate,
    object_label: "Écouteurs sans fil avec boîtier",
    assumptions: [
      "Taille : déduite du boîtier standard",
      "Matériau : plastique creux",
      "Incertitude : aucune référence d'échelle",
    ],
  };

  const seenDeveloperPrompts = [];
  globalThis.fetch = async (url, options) => {
    const body = JSON.parse(options.body);
    seenDeveloperPrompts.push(body.input[0].content[0].text);
    const estimate =
      seenDeveloperPrompts.length === 1 ? koreanEstimate : frenchEstimate;
    return new Response(
      JSON.stringify({
        output: [{content: [{text: JSON.stringify(estimate)}]}],
      }),
      {status: 200, headers: {"Content-Type": "application/json"}},
    );
  };

  try {
    const response = await worker.fetch(
      new Request("https://masslens.example/estimate", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-MassLens-Client-ID": "abcdefghijklmnopqrstuvwx",
          "X-MassLens-Request-ID": "request_identifier_ko_001",
        },
        body: JSON.stringify({
          imageBase64: "aW1hZ2U=",
          mimeType: "image/jpeg",
          responseLocale: "fr",
        }),
      }),
      env,
    );

    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), frenchEstimate);
    assert.equal(seenDeveloperPrompts.length, 2);
    assert.doesNotMatch(seenDeveloperPrompts[0], /previous attempt/);
    assert.match(seenDeveloperPrompts[1], /previous attempt.*wrong language/s);
    assert.match(seenDeveloperPrompts[1], /strictly in French/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("AI estimates require positive dimensions and three evidence summaries", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response(
    JSON.stringify({
      output: [{
        content: [{
          text: JSON.stringify({
            object_label: "Unknown object",
            category: "Other",
            estimate_grams: 100,
            lower_bound_grams: 50,
            upper_bound_grams: 150,
            confidence: "low",
            dimensions_mm: {width: 0, height: 10, depth: 10},
            assumptions: ["Size: no scale reference"],
          }),
        }],
      }],
    }),
    {status: 200, headers: {"Content-Type": "application/json"}},
  );

  try {
    const response = await worker.fetch(
      new Request("https://masslens.example/estimate", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-MassLens-Client-ID": "abcdefghijklmnopqrstuvwx",
          "X-MassLens-Request-ID": "request_identifier_invalid_ai_output",
        },
        body: JSON.stringify({
          images: [{imageBase64: "aW1hZ2U=", mimeType: "image/jpeg"}],
        }),
      }),
      env,
    );

    assert.equal(response.status, 502);
    assert.equal((await response.json()).error.code, "provider_error");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("estimate endpoint rejects an invalid known dimension", async () => {
  const response = await worker.fetch(
    new Request("https://masslens.example/estimate", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-MassLens-Client-ID": "abcdefghijklmnopqrstuvwx",
        "X-MassLens-Request-ID": "request_identifier_000004",
      },
      body: JSON.stringify({
        images: [{imageBase64: "aW1hZ2U=", mimeType: "image/jpeg"}],
        knownDimension: {axis: "Width", value: 0, unit: "cm"},
      }),
    }),
    env,
  );

  assert.equal(response.status, 400);
  assert.equal((await response.json()).error.code, "invalid_request");
});

test("estimate endpoint rejects more than two views", async () => {
  const response = await worker.fetch(
    new Request("https://masslens.example/estimate", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-MassLens-Client-ID": "abcdefghijklmnopqrstuvwx",
        "X-MassLens-Request-ID": "request_identifier_000005",
      },
      body: JSON.stringify({
        images: [
          {imageBase64: "aW1hZ2U=", mimeType: "image/jpeg"},
          {imageBase64: "c2Vjb25k", mimeType: "image/jpeg"},
          {imageBase64: "dGhpcmQ=", mimeType: "image/jpeg"},
        ],
        category: "Auto",
        structure: "Unknown",
      }),
    }),
    env,
  );

  assert.equal(response.status, 400);
  assert.equal((await response.json()).error.code, "invalid_request");
});
