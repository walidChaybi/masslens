import {randomBytes} from "node:crypto";
import {readFile, stat} from "node:fs/promises";
import {extname, resolve} from "node:path";
import {fileURLToPath} from "node:url";

const manifestPath = resolve(
  process.argv[2] || "../eval/private_dataset/food-manifest.json",
);
const endpoint = process.env.MASSLENS_EVAL_URL ||
  "http://127.0.0.1:8787/estimate";
const clientId = process.env.MASSLENS_EVAL_CLIENT_ID ||
  "masslens_food_evaluation_client_0001";
const inputUsdPerMillion = Number(
  process.env.MASSLENS_EVAL_INPUT_USD_PER_MTOK || 0.05,
);
const outputUsdPerMillion = Number(
  process.env.MASSLENS_EVAL_OUTPUT_USD_PER_MTOK || 0.40,
);
const repositoryRoot = fileURLToPath(new URL("../../", import.meta.url));
const allowedConfidence = new Set(["low", "medium", "high"]);
const allowedDataTypes = new Set([
  "Survey (FNDDS)",
  "Foundation",
  "SR Legacy",
]);
const nutrientKeys = [
  "calories_kcal_per_100g",
  "protein_grams_per_100g",
  "carbs_grams_per_100g",
  "fat_grams_per_100g",
];

const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
if (!Array.isArray(manifest)) {
  throw new Error("Food evaluation manifest must be an array.");
}
const foodEntries = manifest.filter(
  (entry) => entry?.expectedOutcome !== "reject",
);
const rejectionEntries = manifest.filter(
  (entry) => entry?.expectedOutcome === "reject",
);
if (foodEntries.length < 30) {
  throw new Error("Food evaluation requires at least 30 labeled plates.");
}
if (foodEntries.filter((entry) => entry.images?.length === 2).length < 10) {
  throw new Error("At least 10 plates need a guided second-angle photo.");
}
for (const negativeKind of ["empty_plate", "non_food"]) {
  if (!rejectionEntries.some((entry) => entry.negativeKind === negativeKind)) {
    throw new Error(
      "Food evaluation needs an expected rejection for " + negativeKind + ".",
    );
  }
}

const samples = [];
for (const entry of manifest) {
  validateEntry(entry);
  const loadedImages = await Promise.all(entry.images.map(loadImage));
  const variants = [
    {viewMode: "one_view", images: loadedImages.slice(0, 1)},
    ...(loadedImages.length === 2
      ? [{viewMode: "two_view", images: loadedImages}]
      : []),
  ];

  for (const variant of variants) {
    const started = performance.now();
    try {
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-MassLens-Client-ID": clientId,
          "X-MassLens-Request-ID": randomBytes(18).toString("base64url"),
        },
        body: JSON.stringify({
          ...(entry.context || {}),
          ...(entry.containerType
            ? {containerType: entry.containerType}
            : {}),
          scanMode: "food_plate",
          images: variant.images,
        }),
      });
      const payload = await response.json();
      if (entry.expectedOutcome === "reject") {
        validateExpectedRejection(response, payload, entry);
        samples.push({
          id: entry.id,
          viewMode: variant.viewMode,
          valid: true,
          expectedRejection: true,
          latencyMs: performance.now() - started,
          costUsd: optionalUsageCost(response),
        });
        process.stdout.write(".");
        continue;
      }
      if (!response.ok) {
        throw new Error(payload.error?.message || String(response.status));
      }
      validateFoodPayload(payload);

      const inputTokens = requiredUsageHeader(
        response,
        "x-masslens-input-tokens",
      );
      const outputTokens = requiredUsageHeader(
        response,
        "x-masslens-output-tokens",
      );
      const scored = scorePayload(payload, entry.expectedComponents);
      samples.push({
        id: entry.id,
        viewMode: variant.viewMode,
        valid: true,
        expectedRejection: false,
        ...scored,
        latencyMs: performance.now() - started,
        costUsd: inputTokens * inputUsdPerMillion / 1_000_000 +
          outputTokens * outputUsdPerMillion / 1_000_000,
      });
      process.stdout.write(".");
    } catch (error) {
      samples.push({
        id: entry.id,
        viewMode: variant.viewMode,
        valid: false,
        error: String(error),
      });
      process.stdout.write("x");
    }
  }
}
process.stdout.write("\n");

const valid = samples.filter((item) => item.valid);
const positive = valid.filter((item) => !item.expectedRejection);
const oneView = positive.filter((item) => item.viewMode === "one_view");
const twoView = positive.filter((item) => item.viewMode === "two_view");
const measuredCosts = valid
  .map((item) => item.costUsd)
  .filter((value) => Number.isFinite(value));
const metrics = {
  model: process.env.MASSLENS_EVAL_MODEL || "gpt-5-nano",
  plateCount: foodEntries.length,
  expectedRejectionCount: rejectionEntries.length,
  twoViewPlateCount: foodEntries.filter(
    (entry) => entry.images.length === 2,
  ).length,
  requestCount: samples.length,
  validStructuredRate: valid.length / samples.length,
  componentIdentificationAccuracy: countRatio(
    positive,
    "componentMatchCount",
    "componentDenominator",
  ),
  totalRangeContainment: ratio(positive, "contained"),
  medianTotalWeightError: median(
    positive.map((item) => item.totalWeightRelativeError),
  ),
  medianTotalWeightErrorOneView: median(
    oneView.map((item) => item.totalWeightRelativeError),
  ),
  medianTotalWeightErrorTwoView: median(
    twoView.map((item) => item.totalWeightRelativeError),
  ),
  acceptableUsdaMatchRate: countRatio(
    positive,
    "acceptableUsdaMatchCount",
    "expectedComponentCount",
  ),
  nutritionArithmeticRate: countRatio(
    positive,
    "nutritionArithmeticPassCount",
    "nutritionArithmeticCheckCount",
  ),
  p95LatencyMs: percentile(valid.map((item) => item.latencyMs), 0.95),
  costMeasuredRequestCount: measuredCosts.length,
  averageAiCostUsd: average(measuredCosts),
};
console.log(JSON.stringify(metrics, null, 2));

const failedRequests = samples.filter((item) => !item.valid);
if (failedRequests.length > 0) {
  console.error("Invalid requests (first 10):");
  for (const sample of failedRequests.slice(0, 10)) {
    console.error(
      "- " + sample.id + " [" + sample.viewMode + "]: " + sample.error,
    );
  }
}

const passed = metrics.validStructuredRate === 1 &&
  metrics.componentIdentificationAccuracy >= 0.80 &&
  metrics.totalRangeContainment >= 0.70 &&
  metrics.medianTotalWeightError <= 0.60 &&
  metrics.acceptableUsdaMatchRate >= 0.85 &&
  metrics.nutritionArithmeticRate === 1 &&
  metrics.p95LatencyMs <= 20000 &&
  metrics.costMeasuredRequestCount >= positive.length &&
  metrics.averageAiCostUsd < 0.002;
if (!passed) {
  console.error(
    "RELEASE BLOCKED: Food Scale thresholds were not met. " +
    "See eval/README.md.",
  );
  process.exitCode = 1;
} else {
  console.log("FOOD SCALE RELEASE GATE PASSED");
}

function validateEntry(entry) {
  const entryName = entry?.id || "Unknown plate";
  if (!entry || typeof entry !== "object" || Array.isArray(entry)) {
    throw new Error("Every food manifest entry must be an object.");
  }
  if (typeof entry.id !== "string" || !entry.id.trim()) {
    throw new Error("Every food manifest entry needs a stable id.");
  }
  if (!Array.isArray(entry.images) ||
      entry.images.length < 1 || entry.images.length > 2) {
    throw new Error(entryName + " needs one or two images.");
  }
  if (entry.containerType != null &&
      (typeof entry.containerType !== "string" ||
       !entry.containerType.trim())) {
    throw new Error(entryName + " has an invalid containerType.");
  }
  if (entry.context != null &&
      (typeof entry.context !== "object" ||
       Array.isArray(entry.context))) {
    throw new Error(entryName + " has an invalid context object.");
  }
  if (entry.expectedOutcome != null &&
      !["food", "reject"].includes(entry.expectedOutcome)) {
    throw new Error(entryName + " has an invalid expectedOutcome.");
  }
  if (entry.expectedOutcome === "reject") {
    if (!["empty_plate", "non_food"].includes(entry.negativeKind)) {
      throw new Error(entryName + " has an invalid negativeKind.");
    }
    if (entry.expectedComponents != null &&
        (!Array.isArray(entry.expectedComponents) ||
         entry.expectedComponents.length > 0)) {
      throw new Error(
        entryName + " must not label components for an expected rejection.",
      );
    }
    if (entry.acceptableErrorCodes != null &&
        (!Array.isArray(entry.acceptableErrorCodes) ||
         entry.acceptableErrorCodes.length < 1 ||
         entry.acceptableErrorCodes.some(
           (code) => typeof code !== "string" || !code.trim(),
         ))) {
      throw new Error(entryName + " has invalid acceptableErrorCodes.");
    }
    return;
  }
  if (!Array.isArray(entry.expectedComponents) ||
      entry.expectedComponents.length < 1 ||
      entry.expectedComponents.length > 6) {
    throw new Error(entryName + " needs one to six expected components.");
  }

  const aliases = new Set();
  for (const component of entry.expectedComponents) {
    if (!component || typeof component !== "object") {
      throw new Error(entryName + " has an invalid expected component.");
    }
    if (typeof component.id !== "string" || !component.id.trim()) {
      throw new Error(entryName + " has a component without an id.");
    }
    if (typeof component.label !== "string" || !component.label.trim()) {
      throw new Error(
        entryName + "/" + component.id + " needs an English label.",
      );
    }
    if (!Number.isFinite(component.trueWeightGrams) ||
        component.trueWeightGrams <= 0) {
      throw new Error(
        entryName + "/" + component.id + " needs a positive true weight.",
      );
    }
    if (component.acceptableLabels != null &&
        (!Array.isArray(component.acceptableLabels) ||
         component.acceptableLabels.some(
           (label) => typeof label !== "string" || !label.trim(),
         ))) {
      throw new Error(
        entryName + "/" + component.id + " has invalid acceptableLabels.",
      );
    }
    if (!Array.isArray(component.acceptableFdcIds) ||
        component.acceptableFdcIds.length < 1 ||
        component.acceptableFdcIds.some(
          (id) => !String(id).trim(),
        )) {
      throw new Error(
        entryName + "/" + component.id +
        " needs at least one audited acceptable FDC id.",
      );
    }
    for (const label of componentLabels(component)) {
      if (aliases.has(label)) {
        throw new Error(
          entryName + " reuses the component alias '" + label + "'.",
        );
      }
      aliases.add(label);
    }
  }
}

function validateExpectedRejection(response, payload, entry) {
  if (response.ok || response.status < 400 || response.status >= 500 ||
      response.status === 429) {
    throw new Error(
      "Expected a deterministic client rejection, received HTTP " +
      response.status + ".",
    );
  }
  if (!payload?.error || typeof payload.error.code !== "string" ||
      !payload.error.code.trim() ||
      typeof payload.error.message !== "string" ||
      !payload.error.message.trim()) {
    throw new Error("Expected rejection did not use the structured error shape.");
  }
  const allowed = entry.acceptableErrorCodes || ["no_food_detected"];
  if (!allowed.includes(payload.error.code)) {
    throw new Error(
      "Unexpected rejection code '" + payload.error.code + "'.",
    );
  }
}

function validateFoodPayload(payload) {
  if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
    throw new Error("Food response is not an object.");
  }
  if (typeof payload.meal_label !== "string" ||
      !payload.meal_label.trim()) {
    throw new Error("Food response has no meal_label.");
  }
  if (!allowedConfidence.has(payload.confidence)) {
    throw new Error("Food response has invalid overall confidence.");
  }
  if (!Array.isArray(payload.assumptions) ||
      payload.assumptions.length !== 3 ||
      payload.assumptions.some(
        (value) => typeof value !== "string" || !value.trim(),
      )) {
    throw new Error("Food response must have exactly three assumptions.");
  }
  if (!Array.isArray(payload.items) ||
      payload.items.length < 1 || payload.items.length > 6) {
    throw new Error("Food response must have one to six items.");
  }

  let nutritionCount = 0;
  for (const item of payload.items) {
    if (!item || typeof item !== "object" || Array.isArray(item)) {
      throw new Error("Food response contains an invalid item.");
    }
    if ("usda_query" in item) {
      throw new Error("Worker leaked an internal USDA search term.");
    }
    if (typeof item.label !== "string" || !item.label.trim()) {
      throw new Error("Food item has no label.");
    }
    if (!allowedConfidence.has(item.confidence)) {
      throw new Error("Food item has invalid confidence.");
    }
    const estimate = Number(item.estimate_grams);
    const lower = Number(item.lower_bound_grams);
    const upper = Number(item.upper_bound_grams);
    if (![estimate, lower, upper].every(
      (value) => Number.isFinite(value) && value > 0,
    ) || lower > estimate || estimate > upper) {
      throw new Error("Food item has invalid weight bounds.");
    }
    if (item.nutrition == null) continue;

    nutritionCount += 1;
    const nutrition = item.nutrition;
    if (!nutrition || typeof nutrition !== "object" ||
        Array.isArray(nutrition)) {
      throw new Error("Food item has invalid nutrition.");
    }
    if (!Number.isInteger(nutrition.fdc_id) || nutrition.fdc_id <= 0) {
      throw new Error("Nutrition has an invalid fdc_id.");
    }
    if (typeof nutrition.description !== "string" ||
        !nutrition.description.trim()) {
      throw new Error("Nutrition has no USDA description.");
    }
    if (!allowedDataTypes.has(nutrition.data_type)) {
      throw new Error(
        "Nutrition is branded or uses an unsupported USDA data type.",
      );
    }
    for (const key of nutrientKeys) {
      const value = Number(nutrition[key]);
      if (!Number.isFinite(value) || value < 0) {
        throw new Error("Nutrition has an invalid " + key + ".");
      }
    }
    if (Number(nutrition.calories_kcal_per_100g) <= 0) {
      throw new Error("Nutrition calories must be positive.");
    }
  }
  if (nutritionCount === 0) {
    throw new Error("Successful Food Scale response has no USDA match.");
  }
}

function scorePayload(payload, expectedComponents) {
  const matches = matchComponents(payload.items, expectedComponents);
  const trueTotalWeight = expectedComponents.reduce(
    (sum, component) => sum + component.trueWeightGrams,
    0,
  );
  const estimatedTotalWeight = sumItems(payload.items, "estimate_grams");
  const lowerTotalWeight = sumItems(payload.items, "lower_bound_grams");
  const upperTotalWeight = sumItems(payload.items, "upper_bound_grams");
  const nutritionItems = payload.items.filter(
    (item) => item.nutrition != null,
  );
  const arithmeticChecks = nutritionItems.map(
    (item) => verifyItemArithmetic(item),
  );
  arithmeticChecks.push(verifyPlateArithmetic(nutritionItems));

  return {
    componentMatchCount: matches.length,
    componentDenominator: Math.max(
      payload.items.length,
      expectedComponents.length,
    ),
    expectedComponentCount: expectedComponents.length,
    acceptableUsdaMatchCount: matches.filter(
      ({item, expected}) => hasAcceptableUsdaMatch(item, expected),
    ).length,
    contained: trueTotalWeight >= lowerTotalWeight &&
      trueTotalWeight <= upperTotalWeight,
    totalWeightRelativeError:
      Math.abs(estimatedTotalWeight - trueTotalWeight) / trueTotalWeight,
    nutritionArithmeticPassCount: arithmeticChecks.filter(Boolean).length,
    nutritionArithmeticCheckCount: arithmeticChecks.length,
  };
}

function matchComponents(items, expectedComponents) {
  const unmatchedItemIndexes = new Set(items.map((_, index) => index));
  const matches = [];
  for (const expected of expectedComponents) {
    const labels = new Set(componentLabels(expected));
    const itemIndex = [...unmatchedItemIndexes].find(
      (index) => labels.has(normalizeLabel(items[index].label)),
    );
    if (itemIndex == null) continue;
    unmatchedItemIndexes.delete(itemIndex);
    matches.push({item: items[itemIndex], expected});
  }
  return matches;
}

function componentLabels(component) {
  return [component.label, ...(component.acceptableLabels || [])]
    .map(normalizeLabel);
}

function normalizeLabel(value) {
  return String(value || "")
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}

function hasAcceptableUsdaMatch(item, expected) {
  if (item.nutrition == null) return false;
  const actual = String(item.nutrition.fdc_id);
  return expected.acceptableFdcIds.some((id) => String(id) === actual);
}

function verifyItemArithmetic(item) {
  const weights = [
    Number(item.lower_bound_grams),
    Number(item.estimate_grams),
    Number(item.upper_bound_grams),
  ];
  for (const key of nutrientKeys) {
    const per100 = Number(item.nutrition[key]);
    for (const weight of weights) {
      const scaled = per100 * weight / 100;
      if (!Number.isFinite(scaled) || scaled < 0) return false;
      const reconstructed = scaled * 100 / weight;
      if (!approximatelyEqual(reconstructed, per100)) return false;
    }
  }
  return true;
}

function verifyPlateArithmetic(items) {
  for (const weightKey of [
    "lower_bound_grams",
    "estimate_grams",
    "upper_bound_grams",
  ]) {
    for (const nutrientKey of nutrientKeys) {
      const total = items.reduce(
        (sum, item) => sum +
          Number(item.nutrition[nutrientKey]) *
          Number(item[weightKey]) / 100,
        0,
      );
      if (!Number.isFinite(total) || total < 0) return false;
    }
  }
  return true;
}

function approximatelyEqual(left, right) {
  return Math.abs(left - right) <=
    Number.EPSILON * Math.max(1, Math.abs(left), Math.abs(right)) * 8;
}

function requiredUsageHeader(response, name) {
  const value = Number(response.headers.get(name));
  if (!Number.isFinite(value) || value <= 0) {
    throw new Error("Missing positive " + name + " response header.");
  }
  return value;
}

function optionalUsageCost(response) {
  const input = Number(response.headers.get("x-masslens-input-tokens"));
  const output = Number(response.headers.get("x-masslens-output-tokens"));
  if (!Number.isFinite(input) || input <= 0 ||
      !Number.isFinite(output) || output <= 0) {
    return null;
  }
  return input * inputUsdPerMillion / 1_000_000 +
    output * outputUsdPerMillion / 1_000_000;
}

async function loadImage(path) {
  const absolute = resolve(repositoryRoot, path);
  const file = await readFile(absolute);
  if ((await stat(absolute)).size === 0) {
    throw new Error("Empty image: " + path);
  }
  return {
    imageBase64: file.toString("base64"),
    mimeType: mimeType(absolute),
  };
}

function mimeType(path) {
  return ({
    ".png": "image/png",
    ".webp": "image/webp",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
  })[extname(path).toLowerCase()] || "image/jpeg";
}

function sumItems(items, key) {
  return items.reduce((sum, item) => sum + Number(item[key]), 0);
}

function ratio(values, key) {
  return values.length === 0 ? 0 :
    values.filter((item) => item[key]).length / values.length;
}

function countRatio(values, numeratorKey, denominatorKey) {
  const numerator = values.reduce(
    (sum, item) => sum + item[numeratorKey],
    0,
  );
  const denominator = values.reduce(
    (sum, item) => sum + item[denominatorKey],
    0,
  );
  return denominator === 0 ? 0 : numerator / denominator;
}

function average(values) {
  return values.length === 0 ? Number.POSITIVE_INFINITY :
    values.reduce((sum, value) => sum + value, 0) / values.length;
}

function median(values) {
  return percentile(values, 0.5);
}

function percentile(values, fraction) {
  if (values.length === 0) return Number.POSITIVE_INFINITY;
  const sorted = [...values].sort((a, b) => a - b);
  return sorted[Math.ceil(fraction * sorted.length) - 1];
}
