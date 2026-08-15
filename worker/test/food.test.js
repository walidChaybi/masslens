import assert from "node:assert/strict";
import {readFileSync} from "node:fs";
import {DatabaseSync} from "node:sqlite";
import test from "node:test";

import worker from "../src/index.js";

const migrations = [
  "../migrations/0001_monetization.sql",
  "../migrations/0002_consumable_credits.sql",
  "../migrations/0003_ads_only_access.sql",
].map((url) => readFileSync(new URL(url, import.meta.url), "utf8"));

const clientId = "food_client_identifier_0001";
const baseEnv = {
  OPENAI_API_KEY: "openai-test-key",
  USDA_FDC_API_KEY: "usda-test-key",
  CLIENT_RATE_LIMITER: {limit: async () => ({success: true})},
  IP_RATE_LIMITER: {limit: async () => ({success: true})},
};

test("food mode uses a separate strict schema and enriches concurrent items", async () => {
  const originalFetch = globalThis.fetch;
  const raw = foodEstimate();
  const usdaBodies = [];
  let activeUsdaCalls = 0;
  let maxActiveUsdaCalls = 0;

  globalThis.fetch = async (url, options) => {
    if (String(url) === "https://api.openai.com/v1/responses") {
      const body = JSON.parse(options.body);
      assert.equal(body.model, "gpt-5-nano");
      assert.equal(body.max_output_tokens, 1600);
      assert.equal(body.text.format.name, "mass_lens_food_plate_estimate");
      assert.equal(body.text.format.strict, true);
      assert.equal(body.text.format.schema.properties.items.minItems, 1);
      assert.equal(body.text.format.schema.properties.items.maxItems, 6);
      assert.equal(
        body.text.format.schema.properties.items.items.additionalProperties,
        false,
      );
      assert.match(body.input[0].content[0].text, /Never return calories/);
      assert.match(body.input[0].content[0].text, /usda_query.*English/s);
      assert.match(body.input[0].content[0].text, /Exclude the plate/);
      assert.match(body.input[1].content[0].text, /Container type: Bowl/);
      assert.match(body.input[1].content[0].text, /Diameter: 18 cm/);
      assert.match(body.input[1].content[0].text, /same meal/);
      return providerResponse(raw, {input_tokens: 320, output_tokens: 140});
    }

    const parsedUrl = new URL(url);
    assert.equal(parsedUrl.origin, "https://api.nal.usda.gov");
    assert.equal(parsedUrl.searchParams.get("api_key"), "usda-test-key");
    assert.equal(options.method, "POST");
    assert.ok(options.signal instanceof AbortSignal);
    const body = JSON.parse(options.body);
    usdaBodies.push(body);
    assert.deepEqual(body.dataType, [
      "Survey (FNDDS)",
      "Foundation",
      "SR Legacy",
    ]);
    assert.equal(body.pageSize, 10);
    activeUsdaCalls += 1;
    maxActiveUsdaCalls = Math.max(maxActiveUsdaCalls, activeUsdaCalls);
    await new Promise((resolve) => setTimeout(resolve, 5));
    activeUsdaCalls -= 1;
    return usdaResponse(body.query.includes("chicken")
      ? usdaFood({
        fdcId: 171077,
        description: "Chicken breast, roasted",
        dataType: "Foundation",
        calories: 165,
        protein: 31.02,
        carbs: 0,
        fat: 3.57,
      })
      : usdaFood({
        fdcId: 168878,
        description: "Rice, white, cooked",
        dataType: "Survey (FNDDS)",
        calories: 130,
        protein: 2.69,
        carbs: 28.17,
        fat: 0.28,
      }));
  };

  try {
    const response = await worker.fetch(
      foodRequest("food_request_complete_0001", {
        containerType: "Bowl",
        referenceObject: "Coin",
        knownDimension: {axis: "Diameter", value: 18, unit: "cm"},
      }),
      baseEnv,
    );

    assert.equal(response.status, 200);
    const result = await response.json();
    assert.equal(result.meal_label, "Chicken and rice bowl");
    assert.equal(result.items.length, 2);
    assert.equal(result.items[0].nutrition.fdc_id, 171077);
    assert.equal(result.items[0].nutrition.calories_kcal_per_100g, 165);
    assert.equal(result.items[0].nutrition.protein_grams_per_100g, 31.02);
    assert.equal(result.items[1].nutrition.carbs_grams_per_100g, 28.17);
    assert.equal("usda_query" in result.items[0], false);
    assert.deepEqual(
      usdaBodies.map((body) => body.query).sort(),
      ["chicken breast roasted", "white rice cooked"],
    );
    assert.ok(usdaBodies.every((body) =>
      !JSON.stringify(body).includes("aW1hZ2U=") &&
      !JSON.stringify(body).includes(clientId)
    ));
    assert.ok(maxActiveUsdaCalls >= 2);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("partial USDA matches succeed and leave unmatched items weight-only", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url, options) => {
    if (String(url).includes("api.openai.com")) {
      return providerResponse(foodEstimate());
    }
    const query = JSON.parse(options.body).query;
    return query.includes("chicken")
      ? usdaResponse(usdaFood({
        fdcId: 171077,
        description: "Chicken breast, roasted",
        dataType: "SR Legacy",
        calories: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
      }))
      : usdaResponse();
  };

  try {
    const response = await worker.fetch(
      foodRequest("food_request_partial_0001"),
      baseEnv,
    );
    assert.equal(response.status, 200);
    const result = await response.json();
    assert.ok(result.items[0].nutrition);
    assert.equal(result.items[1].nutrition, null);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("branded and nutritionally incomplete USDA candidates are excluded", async () => {
  const originalFetch = globalThis.fetch;
  const oneItem = foodEstimate({items: [foodEstimate().items[0]]});
  globalThis.fetch = async (url) => {
    if (String(url).includes("api.openai.com")) return providerResponse(oneItem);
    const branded = usdaFood({
      fdcId: 1,
      description: "Brand chicken",
      dataType: "Branded",
      calories: 100,
      protein: 20,
      carbs: 1,
      fat: 2,
    });
    const incomplete = {
      ...usdaFood({
        fdcId: 2,
        description: "Incomplete chicken",
        dataType: "Foundation",
        calories: 100,
        protein: 20,
        carbs: 1,
        fat: 2,
      }),
      foodNutrients: nutrientRows({
        calories: 100,
        protein: 20,
        carbs: 1,
        fat: 2,
      }).filter((nutrient) => nutrient.nutrientId !== 1004),
    };
    const generic = usdaFood({
      fdcId: 3,
      description: "Chicken, roasted",
      dataType: "Foundation",
      calories: 160,
      protein: 30,
      carbs: 0,
      fat: 3,
    });
    return new Response(JSON.stringify({foods: [branded, incomplete, generic]}), {
      status: 200,
      headers: {"Content-Type": "application/json"},
    });
  };

  try {
    const response = await worker.fetch(
      foodRequest("food_request_generic_0001"),
      baseEnv,
    );
    assert.equal(response.status, 200);
    assert.equal((await response.json()).items[0].nutrition.fdc_id, 3);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("zero USDA matches fail without returning AI-generated nutrition", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url) => String(url).includes("api.openai.com")
    ? providerResponse(foodEstimate({items: [foodEstimate().items[0]]}))
    : usdaResponse();

  try {
    const response = await worker.fetch(
      foodRequest("food_request_no_match_0001"),
      baseEnv,
    );
    assert.equal(response.status, 422);
    assert.equal((await response.json()).error.code, "nutrition_not_found");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("empty plates and non-food photos reject before any USDA request", async () => {
  const sqlite = createDatabase();
  const originalFetch = globalThis.fetch;
  let usdaCalls = 0;
  const env = {
    ...baseEnv,
    DB: d1Adapter(sqlite),
    SCAN_ACCESS_ENFORCED: "true",
  };
  const noFood = foodEstimate({
    meal_label: "No food detected",
    confidence: "low",
    items: [{
      label: "No food detected",
      usda_query: "__NO_FOOD__",
      estimate_grams: 0,
      lower_bound_grams: 0,
      upper_bound_grams: 0,
      confidence: "low",
    }],
  });
  globalThis.fetch = async (url) => {
    if (String(url).includes("api.openai.com")) return providerResponse(noFood);
    usdaCalls += 1;
    return usdaResponse();
  };

  try {
    const response = await worker.fetch(
      foodRequest("food_request_empty_plate_01"),
      env,
    );
    assert.equal(response.status, 422);
    assert.equal((await response.json()).error.code, "no_food_detected");
    assert.equal(usdaCalls, 0);
    assert.equal(
      sqlite.prepare("SELECT starter_used FROM ad_scan_wallets").get()
        .starter_used,
      0,
    );
    assert.equal(
      sqlite.prepare(
        "SELECT state FROM scan_requests WHERE request_id = ?",
      ).get("food_request_empty_plate_01").state,
      "refunded",
    );
  } finally {
    globalThis.fetch = originalFetch;
    sqlite.close();
  }
});

test("a complete USDA outage fails and refunds the reserved scan", async () => {
  const sqlite = createDatabase();
  const originalFetch = globalThis.fetch;
  const env = {
    ...baseEnv,
    DB: d1Adapter(sqlite),
    SCAN_ACCESS_ENFORCED: "true",
  };
  globalThis.fetch = async (url) => {
    if (String(url).includes("api.openai.com")) {
      return providerResponse(foodEstimate({items: [foodEstimate().items[0]]}));
    }
    throw new TypeError("network unavailable");
  };

  try {
    const response = await worker.fetch(
      foodRequest("food_request_outage_00001"),
      env,
    );
    assert.equal(response.status, 502);
    assert.equal(
      (await response.json()).error.code,
      "nutrition_service_unavailable",
    );
    assert.equal(
      sqlite.prepare("SELECT starter_used FROM ad_scan_wallets").get()
        .starter_used,
      0,
    );
    assert.equal(
      sqlite.prepare(
        "SELECT state FROM scan_requests WHERE request_id = ?",
      ).get("food_request_outage_00001").state,
      "refunded",
    );
  } finally {
    globalThis.fetch = originalFetch;
    sqlite.close();
  }
});

test("USDA calls are aborted at the configured bounded timeout", async () => {
  const originalFetch = globalThis.fetch;
  const oneItem = foodEstimate({items: [foodEstimate().items[0]]});
  let observedAbort = false;
  globalThis.fetch = async (url, options) => {
    if (String(url).includes("api.openai.com")) return providerResponse(oneItem);
    return new Promise((_resolve, reject) => {
      options.signal.addEventListener("abort", () => {
        observedAbort = true;
        reject(options.signal.reason);
      }, {once: true});
    });
  };

  try {
    const started = performance.now();
    const response = await worker.fetch(
      foodRequest("food_request_timeout_0001"),
      {...baseEnv, USDA_TIMEOUT_MS: "250"},
    );
    assert.equal(response.status, 502);
    assert.equal(
      (await response.json()).error.code,
      "nutrition_service_unavailable",
    );
    assert.equal(observedAbort, true);
    assert.ok(performance.now() - started < 1000);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("food labels and assumptions follow the selected response locale", async () => {
  const originalFetch = globalThis.fetch;
  const french = foodEstimate({
    meal_label: "Bol de poulet et de riz",
    items: [{
      ...foodEstimate().items[0],
      label: "Blanc de poulet rôti",
    }],
    assumptions: [
      "Portion : estimée selon la géométrie du bol",
      "Préparation : le poulet semble rôti",
      "Incertitude : la profondeur est partiellement masquée",
    ],
  });
  globalThis.fetch = async (url, options) => {
    if (String(url).includes("api.openai.com")) {
      const body = JSON.parse(options.body);
      assert.match(body.input[0].content[0].text, /in\s+French only/);
      assert.match(body.input[0].content[0].text, /usda_query.*English/s);
      return providerResponse(french);
    }
    return usdaResponse(usdaFood({
      fdcId: 171077,
      description: "Chicken breast, roasted",
      dataType: "Foundation",
      calories: 165,
      protein: 31,
      carbs: 0,
      fat: 3.6,
    }));
  };

  try {
    const response = await worker.fetch(
      foodRequest("food_request_french_0001", {responseLocale: "fr"}),
      baseEnv,
    );
    assert.equal(response.status, 200);
    const payload = await response.json();
    assert.equal(payload.meal_label, "Bol de poulet et de riz");
    assert.equal(payload.items[0].label, "Blanc de poulet rôti");
    assert.equal(payload.assumptions.length, 3);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("an idempotent food retry replays enrichment and records the mode once", async () => {
  const sqlite = createDatabase();
  const originalFetch = globalThis.fetch;
  let openAiCalls = 0;
  let usdaCalls = 0;
  const env = {
    ...baseEnv,
    DB: d1Adapter(sqlite),
    SCAN_ACCESS_ENFORCED: "true",
  };
  const oneItem = foodEstimate({items: [foodEstimate().items[0]]});
  globalThis.fetch = async (url) => {
    if (String(url).includes("api.openai.com")) {
      openAiCalls += 1;
      return providerResponse(oneItem);
    }
    usdaCalls += 1;
    return usdaResponse(usdaFood({
      fdcId: 171077,
      description: "Chicken breast, roasted",
      dataType: "Foundation",
      calories: 165,
      protein: 31,
      carbs: 0,
      fat: 3.6,
    }));
  };

  try {
    const requestId = "food_request_idempotent_01";
    const first = await worker.fetch(foodRequest(requestId), env);
    const firstPayload = await first.json();
    assert.equal(first.status, 200);

    const replay = await worker.fetch(
      foodRequest(requestId, {responseLocale: "fr"}),
      env,
    );
    assert.equal(replay.status, 200);
    assert.deepEqual(await replay.json(), firstPayload);
    assert.equal(openAiCalls, 1);
    assert.equal(usdaCalls, 1);
    assert.equal("usda_query" in firstPayload.items[0], false);
    assert.equal(
      sqlite.prepare(
        `SELECT event_count FROM daily_metrics
          WHERE metric = 'scan_completed_mode' AND dimension = 'food_plate'`,
      ).get().event_count,
      1,
    );
  } finally {
    globalThis.fetch = originalFetch;
    sqlite.close();
  }
});

test("USDA lookups use a seven-day Cache API entry", async () => {
  const originalFetch = globalThis.fetch;
  const originalCachesDescriptor = Object.getOwnPropertyDescriptor(
    globalThis,
    "caches",
  );
  const entries = new Map();
  let usdaCalls = 0;
  let writtenCacheControl;
  Object.defineProperty(globalThis, "caches", {
    configurable: true,
    value: {
      default: {
        async match(request) {
          return entries.get(request.url)?.clone();
        },
        async put(request, response) {
          writtenCacheControl = response.headers.get("Cache-Control");
          entries.set(request.url, response.clone());
        },
      },
    },
  });
  const oneItem = foodEstimate({items: [foodEstimate().items[0]]});
  globalThis.fetch = async (url) => {
    if (String(url).includes("api.openai.com")) return providerResponse(oneItem);
    usdaCalls += 1;
    return usdaResponse(usdaFood({
      fdcId: 171077,
      description: "Chicken breast, roasted",
      dataType: "Foundation",
      calories: 165,
      protein: 31,
      carbs: 0,
      fat: 3.6,
    }));
  };

  try {
    const first = await worker.fetch(
      foodRequest("food_request_cache_000001"),
      baseEnv,
    );
    const second = await worker.fetch(
      foodRequest("food_request_cache_000002"),
      baseEnv,
    );
    assert.equal(first.status, 200);
    assert.equal(second.status, 200);
    assert.equal(usdaCalls, 1);
    assert.equal(writtenCacheControl, "public, max-age=604800");
  } finally {
    globalThis.fetch = originalFetch;
    if (originalCachesDescriptor) {
      Object.defineProperty(globalThis, "caches", originalCachesDescriptor);
    } else {
      delete globalThis.caches;
    }
  }
});

test("food schema validation stops invalid AI output before USDA", async () => {
  const originalFetch = globalThis.fetch;
  let usdaCalls = 0;
  const invalid = foodEstimate({
    items: [{...foodEstimate().items[0], unexpected_nutrients: true}],
  });
  globalThis.fetch = async (url) => {
    if (String(url).includes("api.openai.com")) return providerResponse(invalid);
    usdaCalls += 1;
    return usdaResponse();
  };

  try {
    const response = await worker.fetch(
      foodRequest("food_request_bad_schema_01"),
      baseEnv,
    );
    assert.equal(response.status, 502);
    assert.equal((await response.json()).error.code, "provider_error");
    assert.equal(usdaCalls, 0);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("food mode validates its request before wallet or provider work", async () => {
  const originalFetch = globalThis.fetch;
  let providerCalls = 0;
  let databaseCalls = 0;
  globalThis.fetch = async () => {
    providerCalls += 1;
    throw new Error("provider must not be reached");
  };
  const guardedEnv = {
    ...baseEnv,
    SCAN_ACCESS_ENFORCED: "true",
    DB: {
      prepare() {
        databaseCalls += 1;
        throw new Error("wallet must not be reached");
      },
    },
  };

  try {
    const invalidMode = await worker.fetch(
      foodRequest("food_request_invalid_mode_1", {scanMode: "meal"}),
      guardedEnv,
    );
    assert.equal(invalidMode.status, 400);
    assert.equal((await invalidMode.json()).error.code, "invalid_request");

    const invalidContainer = await worker.fetch(
      foodRequest("food_request_invalid_container", {containerType: "\n"}),
      guardedEnv,
    );
    assert.equal(invalidContainer.status, 400);
    assert.equal((await invalidContainer.json()).error.code, "invalid_request");
    assert.equal(databaseCalls, 0);
    assert.equal(providerCalls, 0);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("food mode requires its server-side USDA secret but object mode does not", async () => {
  const originalFetch = globalThis.fetch;
  let providerCalls = 0;
  globalThis.fetch = async () => {
    providerCalls += 1;
    return providerResponse(foodEstimate());
  };

  try {
    const response = await worker.fetch(
      foodRequest("food_request_missing_key_01"),
      {...baseEnv, USDA_FDC_API_KEY: undefined},
    );
    assert.equal(response.status, 503);
    assert.equal(
      (await response.json()).error.code,
      "nutrition_service_not_configured",
    );
    assert.equal(providerCalls, 0);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

function foodEstimate(overrides = {}) {
  return {
    meal_label: "Chicken and rice bowl",
    confidence: "medium",
    items: [
      {
        label: "Roasted chicken breast",
        usda_query: "Chicken breast roasted",
        estimate_grams: 150,
        lower_bound_grams: 120,
        upper_bound_grams: 190,
        confidence: "medium",
      },
      {
        label: "Cooked white rice",
        usda_query: "White rice cooked",
        estimate_grams: 210,
        lower_bound_grams: 170,
        upper_bound_grams: 270,
        confidence: "medium",
      },
    ],
    assumptions: [
      "Portion: estimated from the visible bowl geometry",
      "Preparation: chicken appears roasted and rice cooked",
      "Uncertainty: food depth is partly hidden by the bowl",
    ],
    ...overrides,
  };
}

function foodRequest(requestId, overrides = {}) {
  return new Request("https://masslens.example/estimate", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-MassLens-Client-ID": clientId,
      "X-MassLens-Request-ID": requestId,
    },
    body: JSON.stringify({
      scanMode: "food_plate",
      images: [{imageBase64: "aW1hZ2U=", mimeType: "image/jpeg"}],
      ...overrides,
    }),
  });
}

function providerResponse(payload, usage) {
  return new Response(
    JSON.stringify({
      output: [{content: [{text: JSON.stringify(payload)}]}],
      usage,
    }),
    {status: 200, headers: {"Content-Type": "application/json"}},
  );
}

function usdaResponse(...foods) {
  return new Response(JSON.stringify({foods}), {
    status: 200,
    headers: {"Content-Type": "application/json"},
  });
}

function usdaFood({
  fdcId,
  description,
  dataType,
  calories,
  protein,
  carbs,
  fat,
}) {
  return {
    fdcId,
    description,
    dataType,
    foodNutrients: nutrientRows({calories, protein, carbs, fat}),
  };
}

function nutrientRows({calories, protein, carbs, fat}) {
  return [
    nutrient(1008, "208", "KCAL", calories),
    nutrient(1003, "203", "G", protein),
    nutrient(1005, "205", "G", carbs),
    nutrient(1004, "204", "G", fat),
  ];
}

function nutrient(nutrientId, nutrientNumber, unitName, value) {
  return {nutrientId, nutrientNumber, unitName, value};
}

function createDatabase() {
  const sqlite = new DatabaseSync(":memory:");
  for (const migration of migrations) sqlite.exec(migration);
  return sqlite;
}

function d1Adapter(sqlite) {
  return {
    prepare(sql) {
      let bindings = [];
      return {
        bind(...values) {
          bindings = values;
          return this;
        },
        run() {
          const result = sqlite.prepare(sql).run(...bindings);
          return {meta: {changes: Number(result.changes)}};
        },
        first() {
          return sqlite.prepare(sql).get(...bindings);
        },
      };
    },
  };
}
