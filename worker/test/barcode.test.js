import assert from "node:assert/strict";
import test from "node:test";

import {normalizeGtin, selectBrandedProduct} from "../src/barcode.js";
import worker from "../src/index.js";

const clientId = "barcode_client_identifier_01";
const baseEnv = {
  USDA_FDC_API_KEY: "usda-test-key",
  CLIENT_RATE_LIMITER: {limit: async () => ({success: true})},
  IP_RATE_LIMITER: {limit: async () => ({success: true})},
};

function brandedFood(overrides = {}) {
  return {
    fdcId: 2345678,
    dataType: "Branded",
    description: "CHOCOLATE HAZELNUT SPREAD",
    brandOwner: "Example Foods Inc.",
    gtinUpc: "009800800056",
    servingSize: 37,
    servingSizeUnit: "g",
    foodNutrients: [
      {nutrientId: 1008, nutrientNumber: "208", unitName: "KCAL", value: 541},
      {nutrientId: 1003, nutrientNumber: "203", unitName: "G", value: 5.41},
      {nutrientId: 1005, nutrientNumber: "205", unitName: "G", value: 59.5},
      {nutrientId: 1004, nutrientNumber: "204", unitName: "G", value: 29.7},
    ],
    ...overrides,
  };
}

function barcodeRequest(code, headers = {}) {
  return new Request(
    `https://api.example/food/barcode?code=${encodeURIComponent(code)}`,
    {headers: {"X-MassLens-Client-ID": clientId, ...headers}},
  );
}

test("normalizeGtin accepts valid GTINs and rejects bad check digits", () => {
  assert.equal(normalizeGtin("3017620422003"), "3017620422003");
  assert.equal(normalizeGtin("009800800056"), "009800800056");
  assert.equal(normalizeGtin("96385074"), "96385074");
  assert.equal(normalizeGtin("3017620422004"), null);
  assert.equal(normalizeGtin("12345"), null);
  assert.equal(normalizeGtin("abc"), null);
});

test("selectBrandedProduct matches GTIN ignoring leading zeros", () => {
  const product = selectBrandedProduct(
    {foods: [brandedFood({gtinUpc: "00009800800056"})]},
    "009800800056",
  );
  assert.equal(product.barcode, "009800800056");
  assert.equal(product.name, "Chocolate Hazelnut Spread");
  assert.equal(product.brand, "Example Foods Inc.");
  assert.equal(product.source, "usda");
  assert.equal(product.per100g.caloriesKcal, 541);
  assert.equal(product.per100g.fatGrams, 29.7);
  assert.equal(product.servingGrams, 37);
  assert.equal(product.hasPartialNutrition, false);
});

test("selectBrandedProduct skips non-matching and implausible foods", () => {
  assert.equal(
    selectBrandedProduct({foods: [brandedFood({gtinUpc: "0123"})]}, "009800800056"),
    null,
  );
  const implausible = brandedFood({
    foodNutrients: [
      {nutrientId: 1008, unitName: "KCAL", value: 4000},
    ],
  });
  assert.equal(
    selectBrandedProduct({foods: [implausible]}, "009800800056"),
    null,
  );
});

test("missing macros are reported as partial nutrition", () => {
  const product = selectBrandedProduct(
    {
      foods: [
        brandedFood({
          foodNutrients: [{nutrientId: 1008, unitName: "KCAL", value: 42}],
          servingSizeUnit: "MLT",
        }),
      ],
    },
    "009800800056",
  );
  assert.equal(product.hasPartialNutrition, true);
  assert.equal(product.per100g.proteinGrams, 0);
  assert.equal("servingGrams" in product, false);
});

test("GET /food/barcode searches USDA branded foods with only the barcode", async () => {
  const originalFetch = globalThis.fetch;
  const calls = [];
  globalThis.fetch = async (url, options) => {
    calls.push({url: String(url), body: JSON.parse(options.body)});
    return new Response(JSON.stringify({foods: [brandedFood()]}), {
      headers: {"Content-Type": "application/json"},
    });
  };
  try {
    const response = await worker.fetch(barcodeRequest("009800800056"), baseEnv);
    assert.equal(response.status, 200);
    const body = await response.json();
    assert.equal(body.status, "found");
    assert.equal(body.product.per100g.carbsGrams, 59.5);
    assert.equal(calls.length, 1);
    assert.match(calls[0].url, /api\.nal\.usda\.gov\/fdc\/v1\/foods\/search/);
    assert.deepEqual(calls[0].body, {
      query: "009800800056",
      dataType: ["Branded"],
      pageSize: 10,
    });
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("GET /food/barcode returns not_found without an error", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () =>
    new Response(JSON.stringify({foods: []}), {
      headers: {"Content-Type": "application/json"},
    });
  try {
    const response = await worker.fetch(barcodeRequest("3017620422003"), baseEnv);
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), {status: "not_found"});
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("GET /food/barcode validates input and uses separate rate-limit keys", async () => {
  const keys = [];
  const env = {
    ...baseEnv,
    CLIENT_RATE_LIMITER: {
      limit: async ({key}) => {
        keys.push(key);
        return {success: false};
      },
    },
  };
  const bad = await worker.fetch(barcodeRequest("3017620422004"), baseEnv);
  assert.equal(bad.status, 400);
  assert.equal((await bad.json()).error.code, "invalid_barcode");

  const noClient = await worker.fetch(
    new Request("https://api.example/food/barcode?code=3017620422003"),
    baseEnv,
  );
  assert.equal(noClient.status, 400);

  const limited = await worker.fetch(barcodeRequest("3017620422003"), env);
  assert.equal(limited.status, 429);
  assert.deepEqual(keys, [`barcode:${clientId}`]);
});

test("GET /food/barcode reports USDA outages as 503", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response("nope", {status: 500});
  try {
    const response = await worker.fetch(barcodeRequest("3017620422003"), baseEnv);
    assert.equal(response.status, 503);
    assert.equal((await response.json()).error.code, "nutrition_unavailable");
  } finally {
    globalThis.fetch = originalFetch;
  }
});
