import assert from "node:assert/strict";
import test from "node:test";

import worker from "../src/index.js";

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
    assert.match(seenPrompts[1], /Infer the object category/);
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
