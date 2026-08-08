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
  assert.equal(access.starterScansRemaining, 1);
  assert.equal(access.rewardedScans, 0);
  assert.equal(access.legacyScans, 0);
  assert.equal(access.remainingScans, 1);
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

test("wallet payload preserves legacy balance as ad-free access", () => {
  const access = accessPayload({
    starterUsed: 1,
    rewardedScans: 2,
    legacyScans: 7,
    scanAccessEnforced: true,
  });
  assert.equal(access.remainingScans, 9);
  assert.equal(access.adsEnabled, false);
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
  const estimate = {
    object_label: "Ceramic mug",
    category: "Household",
    estimate_grams: 360,
    lower_bound_grams: 290,
    upper_bound_grams: 450,
    confidence: "medium",
    dimensions_mm: {width: 85, height: 105, depth: 85},
    assumptions: ["No visible scale reference"],
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
          knownDimension: {axis: "Width", value: 12.5, unit: "cm"},
          measuredDimensions: {
            widthMm: 142.4,
            heightMm: 90.1,
            depthMm: 61,
            method: "arcore_depth",
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
    assert.match(seenPrompts[1], /Visible reference: Standard card/);
    assert.match(seenPrompts[1], /Width: 12\.5 cm/);
    assert.match(seenPrompts[1], /Measured dimensions: width 142\.4 mm/);
    assert.match(seenPrompts[1], /height 90\.1 mm, depth 61 mm/);
    assert.match(seenPrompts[1], /method arcore_depth/);
    assert.match(seenPrompts[1], /Preserve supplied measured axes exactly/);
    assert.match(seenPrompts[1], /Infer the object category/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("estimate endpoint rejects invalid measured dimensions", async () => {
  const response = await worker.fetch(
    new Request("https://masslens.example/estimate", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-MassLens-Client-ID": "abcdefghijklmnopqrstuvwx",
        "X-MassLens-Request-ID": "request_identifier_000003",
      },
      body: JSON.stringify({
        images: [{imageBase64: "aW1hZ2U=", mimeType: "image/jpeg"}],
        measuredDimensions: {
          widthMm: 142.4,
          heightMm: 3,
          method: "magic_camera",
        },
      }),
    }),
    env,
  );

  assert.equal(response.status, 400);
  assert.equal((await response.json()).error.code, "invalid_request");
});

test("measured dimension validation enforces shape, bounds, and methods", async () => {
  const invalidValues = [
    "not-an-object",
    {widthMm: 5001, heightMm: 90, method: "arcore_plane"},
    {widthMm: 140, heightMm: 90, method: "visual_guess"},
    {widthMm: 140, heightMm: 90, method: "photo_reference"},
  ];

  for (const measuredDimensions of invalidValues) {
    const response = await worker.fetch(
      new Request("https://masslens.example/estimate", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-MassLens-Client-ID": "abcdefghijklmnopqrstuvwx",
          "X-MassLens-Request-ID": `request_identifier_invalid_${invalidValues.indexOf(measuredDimensions)}`,
        },
        body: JSON.stringify({
          images: [{imageBase64: "aW1hZ2U=", mimeType: "image/jpeg"}],
          measuredDimensions,
        }),
      }),
      env,
    );

    assert.equal(response.status, 400);
    assert.equal((await response.json()).error.code, "invalid_request");
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
