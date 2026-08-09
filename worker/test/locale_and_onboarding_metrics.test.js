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

const clientId = "locale_client_identifier_01";
const baseEnv = {
  OPENAI_API_KEY: "test-key",
  CLIENT_RATE_LIMITER: {limit: async () => ({success: true})},
  IP_RATE_LIMITER: {limit: async () => ({success: true})},
};

const localizedEstimates = {
  en: estimate({
    objectLabel: "Ceramic mug",
    assumptions: [
      "Size: estimated from familiar mug proportions",
      "Material: hollow ceramic and apparently empty",
      "Uncertainty: no scale reference; add a side view",
    ],
  }),
  fr: estimate({
    objectLabel: "Tasse en céramique",
    assumptions: [
      "Taille : estimée selon les proportions d'une tasse",
      "Matériau : céramique creuse et apparemment vide",
      "Incertitude : aucune référence; ajoutez une vue latérale",
    ],
  }),
  es: estimate({
    objectLabel: "Taza de cerámica",
    assumptions: [
      "Tamaño: estimado por las proporciones habituales de una taza",
      "Material: cerámica hueca y aparentemente vacía",
      "Incertidumbre: sin referencia; añade una vista lateral",
    ],
  }),
};

test("estimate output locale defaults to English and supports French and Spanish", async () => {
  const originalFetch = globalThis.fetch;
  const providerBodies = [];
  globalThis.fetch = async (_url, options) => {
    const body = JSON.parse(options.body);
    providerBodies.push(body);
    const locale = providerBodies.length === 1
      ? "en"
      : providerBodies.length === 2
        ? "fr"
        : "es";
    return providerResponse(localizedEstimates[locale]);
  };

  try {
    const english = await worker.fetch(
      estimateRequest("locale_request_identifier_en"),
      baseEnv,
    );
    const french = await worker.fetch(
      estimateRequest("locale_request_identifier_fr", "fr"),
      baseEnv,
    );
    const spanish = await worker.fetch(
      estimateRequest("locale_request_identifier_es", "es"),
      baseEnv,
    );

    assert.equal(english.status, 200);
    assert.equal(french.status, 200);
    assert.equal(spanish.status, 200);
    assert.deepEqual(await english.json(), localizedEstimates.en);
    assert.deepEqual(await french.json(), localizedEstimates.fr);
    assert.deepEqual(await spanish.json(), localizedEstimates.es);

    const developerPrompts = providerBodies.map(
      (body) => body.input[0].content[0].text,
    );
    assert.match(developerPrompts[0], /all three assumptions in English/);
    assert.match(developerPrompts[0], /"Size:".*"Material:".*"Uncertainty:"/);
    assert.match(developerPrompts[1], /all three assumptions in French/);
    assert.match(developerPrompts[1], /"Taille :".*"Matériau :".*"Incertitude :"/);
    assert.match(developerPrompts[2], /all three assumptions in Spanish/);
    assert.match(developerPrompts[2], /"Tamaño:".*"Material:".*"Incertidumbre:"/);
    for (const prompt of developerPrompts) {
      assert.match(
        prompt,
        /category and confidence values as the\s+schema's exact canonical English tokens/,
      );
      assert.match(prompt, /Return exactly three short assumptions/);
    }

    const format = providerBodies[2].text.format;
    assert.deepEqual(format.schema.properties.confidence.enum, [
      "low",
      "medium",
      "high",
    ]);
    assert.ok(format.schema.properties.category.enum.includes("Household"));
    assert.equal(format.schema.properties.object_label.type, "string");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("an invalid response locale is rejected before wallet reservation or AI spend", async () => {
  const originalFetch = globalThis.fetch;
  let providerCalls = 0;
  let databaseCalls = 0;
  globalThis.fetch = async () => {
    providerCalls += 1;
    return providerResponse(localizedEstimates.en);
  };

  try {
    const response = await worker.fetch(
      estimateRequest("locale_request_identifier_invalid", "de"),
      {
        ...baseEnv,
        SCAN_ACCESS_ENFORCED: "true",
        DB: {
          prepare() {
            databaseCalls += 1;
            throw new Error("The wallet must not be reached");
          },
        },
      },
    );

    assert.equal(response.status, 400);
    const error = await response.json();
    assert.equal(error.error.code, "invalid_request");
    assert.equal(error.error.message, "Invalid responseLocale.");
    assert.equal(databaseCalls, 0);
    assert.equal(providerCalls, 0);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("an idempotent retry replays the original result language", async () => {
  const sqlite = createDatabase();
  const originalFetch = globalThis.fetch;
  let providerCalls = 0;
  globalThis.fetch = async () => {
    providerCalls += 1;
    return providerResponse(localizedEstimates.en, {
      input_tokens: 200,
      output_tokens: 80,
    });
  };
  const requestId = "locale_idempotent_request_01";
  const env = {
    ...baseEnv,
    DB: d1Adapter(sqlite),
    SCAN_ACCESS_ENFORCED: "true",
  };

  try {
    const original = await worker.fetch(
      estimateRequest(requestId, "en"),
      env,
    );
    assert.equal(original.status, 200);
    assert.deepEqual(await original.json(), localizedEstimates.en);

    const replay = await worker.fetch(
      estimateRequest(requestId, "es"),
      env,
    );
    assert.equal(replay.status, 200);
    assert.deepEqual(await replay.json(), localizedEstimates.en);
    assert.equal(providerCalls, 1);
    assert.equal(
      sqlite.prepare(
        "SELECT starter_used FROM ad_scan_wallets LIMIT 1",
      ).get().starter_used,
      1,
    );
  } finally {
    globalThis.fetch = originalFetch;
    sqlite.close();
  }
});

test("onboarding and drawer interstitial paid events are accepted", async () => {
  const sqlite = createDatabase();
  try {
    for (const placement of [
      "onboarding_interstitial",
      "drawer_ai_scan_interstitial",
      "drawer_digital_scale_interstitial",
    ]) {
      const response = await worker.fetch(
        new Request("https://masslens.example/metrics/ad-revenue", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-MassLens-Client-ID": clientId,
          },
          body: JSON.stringify({
            placement,
            currencyCode: "eur",
            precision: "precise",
            valueMicros: 2468,
          }),
        }),
        {DB: d1Adapter(sqlite)},
      );

      assert.equal(response.status, 204);
      const metric = sqlite.prepare(
        `SELECT event_count, value_micros FROM daily_metrics
          WHERE metric = 'ad_revenue' AND dimension = ?`,
      ).get(`${placement}:EUR:precise`);
      assert.equal(metric.event_count, 1);
      assert.equal(metric.value_micros, 2468);
    }
  } finally {
    sqlite.close();
  }
});

function estimate({objectLabel, assumptions}) {
  return {
    object_label: objectLabel,
    category: "Household",
    estimate_grams: 360,
    lower_bound_grams: 290,
    upper_bound_grams: 450,
    confidence: "medium",
    dimensions_mm: {width: 85, height: 105, depth: 85},
    assumptions,
  };
}

function estimateRequest(requestId, responseLocale) {
  const body = {
    images: [{imageBase64: "aW1hZ2U=", mimeType: "image/jpeg"}],
    material: "Glass/Ceramic",
    fillState: "Empty",
  };
  if (responseLocale !== undefined) body.responseLocale = responseLocale;
  return new Request("https://masslens.example/estimate", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-MassLens-Client-ID": clientId,
      "X-MassLens-Request-ID": requestId,
    },
    body: JSON.stringify(body),
  });
}

function providerResponse(estimatePayload, usage) {
  return new Response(
    JSON.stringify({
      output: [{content: [{text: JSON.stringify(estimatePayload)}]}],
      usage,
    }),
    {status: 200, headers: {"Content-Type": "application/json"}},
  );
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
