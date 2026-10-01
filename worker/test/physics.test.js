import assert from "node:assert/strict";
import test from "node:test";

import {
  applyArMeasurement,
  densityBounds,
  refineObjectEstimate,
} from "../src/physics.js";

const assumptions = ["Size: a", "Material: b", "Uncertainty: c"];

function estimate(overrides = {}) {
  return {
    object_label: "Phone charger",
    category: "Electronics",
    estimate_grams: 220,
    lower_bound_grams: 180,
    upper_bound_grams: 260,
    confidence: "medium",
    dimensions_mm: {width: 70, height: 60, depth: 40},
    assumptions,
    physics: {
      construction: "electronics_device",
      primary_material: "plastic",
      shape: "box",
      known_product: false,
      product_typical_grams: null,
    },
    ...overrides,
  };
}

test("responses without physics pass through unchanged apart from nothing added", () => {
  const {physics, ...legacy} = estimate();
  const {estimate: refined, trace} = refineObjectEstimate(legacy);
  assert.deepEqual(refined, legacy);
  assert.deepEqual(trace.applied, []);
});

test("physics is never sent back to the app", () => {
  const {estimate: refined} = refineObjectEstimate(estimate());
  assert.equal("physics" in refined, false);
});

test("a recognized product weight dominates the model's guess", () => {
  const {estimate: refined, trace} = refineObjectEstimate(estimate({
    physics: {
      construction: "electronics_device",
      primary_material: "plastic",
      shape: "box",
      known_product: true,
      product_typical_grams: 60,
    },
  }));
  assert.ok(trace.applied.includes("known_product"));
  assert.equal(refined.estimate_grams, 108); // 0.3 * 220 + 0.7 * 60
  assert.ok(refined.lower_bound_grams <= refined.estimate_grams);
  assert.ok(refined.upper_bound_grams >= refined.estimate_grams);
});

test("trusted AR axes replace guessed dimensions", () => {
  const {dimensions, usedAxes} = applyArMeasurement(
    {width: 70, height: 60, depth: 40},
    {
      lengthCm: 3.4,
      widthCm: 3.3,
      heightCm: 2.7,
      confidence: {length: 0.9, width: 0.8, height: 0.4},
    },
  );
  assert.equal(usedAxes, 2);
  assert.deepEqual(dimensions, {width: 34, height: 60, depth: 33});
});

test("AR size plus an impossible density pulls the weight down and lowers confidence", () => {
  const {estimate: refined, trace} = refineObjectEstimate(estimate(), {
    arMeasurement: {
      lengthCm: 3.4,
      widthCm: 3.3,
      heightCm: 2.7,
      confidence: {length: 0.9, width: 0.9, height: 0.9},
    },
  });
  assert.deepEqual(refined.dimensions_mm, {width: 34, height: 27, depth: 33});
  assert.ok(trace.applied.includes("density_lowered"));
  assert.ok(refined.estimate_grams >= 40 && refined.estimate_grams <= 90,
    `got ${refined.estimate_grams}`);
  assert.equal(refined.confidence, "low");
  assert.ok(refined.lower_bound_grams <= refined.estimate_grams * 0.75 + 0.5);
});

test("a known product that contradicts the measured size is ignored", () => {
  const {trace} = refineObjectEstimate(estimate({
    physics: {
      construction: "electronics_device",
      primary_material: "plastic",
      shape: "box",
      known_product: true,
      product_typical_grams: 2000,
    },
  }), {
    arMeasurement: {
      lengthCm: 3.4,
      widthCm: 3.3,
      heightCm: 2.7,
      confidence: {length: 0.9, width: 0.9, height: 0.9},
    },
  });
  assert.ok(trace.applied.includes("known_product_rejected"));
});

test("an implausibly light solid steel object is raised", () => {
  const {estimate: refined, trace} = refineObjectEstimate(estimate({
    object_label: "Steel dumbbell",
    estimate_grams: 50,
    lower_bound_grams: 40,
    upper_bound_grams: 60,
    dimensions_mm: {width: 200, height: 60, depth: 60},
    physics: {
      construction: "solid",
      primary_material: "steel_or_iron",
      shape: "irregular",
      known_product: false,
      product_typical_grams: null,
    },
  }));
  assert.ok(trace.applied.includes("density_raised"));
  assert.ok(refined.estimate_grams > 200);
});

test("density bounds depend on construction", () => {
  const [, hollowMax] = densityBounds("hollow_shell", "plastic");
  const [solidMin] = densityBounds("solid", "plastic");
  assert.ok(hollowMax < 1);
  assert.ok(solidMin > 0.4);
});
