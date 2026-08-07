import assert from "node:assert/strict";
import test from "node:test";

import worker from "../src/index.js";
import {
  MonetizationError,
  scanPackCredits,
  validateGoogleProductPurchase,
} from "../src/monetization.js";

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

test("unknown routes return JSON 404", async () => {
  const response = await worker.fetch(
    new Request("https://masslens.example/missing"),
    env,
  );

  assert.equal(response.status, 404);
  assert.equal((await response.json()).error.code, "not_found");
});

test("access endpoint is safe before billing enforcement is enabled", async () => {
  const response = await worker.fetch(
    new Request("https://masslens.example/access", {
      headers: {"X-MassLens-Client-ID": "abcdefghijklmnopqrstuvwx"},
    }),
    {...env, BILLING_ENFORCED: "false"},
  );

  assert.equal(response.status, 200);
  const access = await response.json();
  assert.equal(access.planId, "free");
  assert.equal(access.scanLimit, 3);
  assert.equal(access.purchasedCredits, 0);
  assert.equal(access.creditDebt, 0);
  assert.equal(access.billingEnforced, false);
  assert.equal(access.adsEnabled, false);
});

test("billing cannot be enforced without D1 storage", async () => {
  const response = await worker.fetch(
    new Request("https://masslens.example/access", {
      headers: {"X-MassLens-Client-ID": "abcdefghijklmnopqrstuvwx"},
    }),
    {...env, BILLING_ENFORCED: "true"},
  );

  assert.equal(response.status, 503);
  assert.equal((await response.json()).error.code, "billing_not_configured");
});

test("billing rejects product IDs that are not owned by MassLens", async () => {
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

  assert.equal(response.status, 400);
  assert.equal((await response.json()).error.code, "invalid_product");
});

test("billing catalog contains only the 100 and 500 scan packs", () => {
  assert.deepEqual(scanPackCredits, {
    masslens_100_scans: 100,
    masslens_500_scans: 500,
  });
});

test("billing rejects retired subscription product IDs", async () => {
  const response = await worker.fetch(
    new Request("https://masslens.example/billing/verify", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-MassLens-Client-ID": "abcdefghijklmnopqrstuvwx",
      },
      body: JSON.stringify({
        productId: "masslens_100_monthly",
        purchaseToken: "abcdefghijklmnopqrstuvwxyz123456",
      }),
    }),
    env,
  );

  assert.equal(response.status, 400);
  assert.equal((await response.json()).error.code, "invalid_product");
});

test("one-time purchase validation accepts one matching unconsumed item", () => {
  const result = validateGoogleProductPurchase(
    {
      purchaseStateContext: {purchaseState: "PURCHASED"},
      productLineItem: [
        {
          productId: "masslens_100_scans",
          productOfferDetails: {
            quantity: 1,
            consumptionState: "CONSUMPTION_STATE_YET_TO_BE_CONSUMED",
          },
        },
      ],
      purchaseCompletionTime: "2026-08-05T12:00:00Z",
      obfuscatedExternalAccountId: "abcdefghijklmnopqrstuvwx",
      orderId: "GPA.1234-5678-9012-34567",
    },
    "masslens_100_scans",
  );

  assert.equal(result.purchaseTimeMs, Date.parse("2026-08-05T12:00:00Z"));
  assert.equal(result.externalAccountId, "abcdefghijklmnopqrstuvwx");
  assert.equal(result.orderId, "GPA.1234-5678-9012-34567");
});

test("one-time purchase validation rejects pending, mismatched, and bulk items", () => {
  const base = {
    purchaseStateContext: {purchaseState: "PURCHASED"},
    productLineItem: [
      {
        productId: "masslens_500_scans",
        productOfferDetails: {
          quantity: 1,
          consumptionState: "CONSUMPTION_STATE_YET_TO_BE_CONSUMED",
        },
      },
    ],
    purchaseCompletionTime: "2026-08-05T12:00:00Z",
    obfuscatedExternalAccountId: "abcdefghijklmnopqrstuvwx",
  };

  assert.throws(
    () => validateGoogleProductPurchase(
      {...base, purchaseStateContext: {purchaseState: "PENDING"}},
      "masslens_500_scans",
    ),
    (error) => error instanceof MonetizationError &&
      error.code === "purchase_pending",
  );
  assert.throws(
    () => validateGoogleProductPurchase(base, "masslens_100_scans"),
    (error) => error instanceof MonetizationError &&
      error.code === "product_mismatch",
  );
  assert.throws(
    () => validateGoogleProductPurchase(
      {
        ...base,
        productLineItem: [
          {
            ...base.productLineItem[0],
            productOfferDetails: {
              ...base.productLineItem[0].productOfferDetails,
              quantity: 2,
            },
          },
        ],
      },
      "masslens_500_scans",
    ),
    (error) => error instanceof MonetizationError &&
      error.code === "unsupported_quantity",
  );
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
    assert.equal(body.model, "gpt-5.4-mini");
    assert.equal(body.store, false);
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
    assert.ok(imageParts.every((part) => part.detail === "high"));
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
