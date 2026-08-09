import {randomBytes} from "node:crypto";
import {readFile, stat} from "node:fs/promises";
import {extname, resolve} from "node:path";
import {fileURLToPath} from "node:url";

const manifestPath = resolve(process.argv[2] || "../eval/manifest.json");
const endpoint = process.env.MASSLENS_EVAL_URL ||
  "http://127.0.0.1:8787/estimate";
const clientId = process.env.MASSLENS_EVAL_CLIENT_ID ||
  "masslens_evaluation_client_0001";
const inputUsdPerMillion = Number(
  process.env.MASSLENS_EVAL_INPUT_USD_PER_MTOK || 0.05,
);
const outputUsdPerMillion = Number(
  process.env.MASSLENS_EVAL_OUTPUT_USD_PER_MTOK || 0.40,
);
const repositoryRoot = fileURLToPath(new URL("../../", import.meta.url));
const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
if (!Array.isArray(manifest) || manifest.length < 30) {
  throw new Error("Evaluation requires at least 30 labeled objects.");
}
if (manifest.filter((entry) => entry.images?.length === 2).length < 10) {
  throw new Error("At least 10 objects need a guided side-view photo.");
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
        body: JSON.stringify({images: variant.images, ...(entry.context || {})}),
      });
      const payload = await response.json();
      if (!response.ok) {
        throw new Error(payload.error?.message || String(response.status));
      }
      const inputTokens = Number(
        response.headers.get("x-masslens-input-tokens") || 0,
      );
      const outputTokens = Number(
        response.headers.get("x-masslens-output-tokens") || 0,
      );
      const trueWeight = Number(entry.trueWeightGrams);
      samples.push({
        id: entry.id,
        viewMode: variant.viewMode,
        valid: true,
        categoryCorrect:
          normalize(payload.category) === normalize(entry.category),
        contained: trueWeight >= payload.lower_bound_grams &&
          trueWeight <= payload.upper_bound_grams,
        massRelativeError:
          Math.abs(payload.estimate_grams - trueWeight) / trueWeight,
        dimensionRelativeError: dimensionError(
          payload.dimensions_mm,
          entry.trueDimensionsMm,
        ),
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
const oneView = valid.filter((item) => item.viewMode === "one_view");
const twoView = valid.filter((item) => item.viewMode === "two_view");
const pairedIds = new Set(twoView.map((item) => item.id));
const pairedOneView = oneView.filter((item) => pairedIds.has(item.id));
const metrics = {
  model: process.env.MASSLENS_EVAL_MODEL || "gpt-5-nano",
  objectCount: manifest.length,
  requestCount: samples.length,
  validStructuredRate: valid.length / samples.length,
  categoryAccuracy: ratio(valid, "categoryCorrect"),
  rangeContainment: ratio(valid, "contained"),
  medianMassErrorOneView: median(
    oneView.map((item) => item.massRelativeError),
  ),
  medianMassErrorTwoView: median(
    twoView.map((item) => item.massRelativeError),
  ),
  pairedMedianMassErrorOneView: median(
    pairedOneView.map((item) => item.massRelativeError),
  ),
  medianDimensionErrorOneView: median(
    oneView.map((item) => item.dimensionRelativeError),
  ),
  medianDimensionErrorTwoView: median(
    twoView.map((item) => item.dimensionRelativeError),
  ),
  p95LatencyMs: percentile(valid.map((item) => item.latencyMs), 0.95),
  averageCostUsd: average(valid.map((item) => item.costUsd)),
};
console.log(JSON.stringify(metrics, null, 2));

const passed = metrics.validStructuredRate === 1 &&
  metrics.categoryAccuracy >= 0.80 &&
  metrics.rangeContainment >= 0.70 &&
  metrics.medianMassErrorOneView <= 0.60 &&
  metrics.medianMassErrorTwoView <= 0.60 &&
  metrics.medianMassErrorTwoView <= metrics.pairedMedianMassErrorOneView &&
  metrics.medianDimensionErrorOneView <= 0.60 &&
  metrics.medianDimensionErrorTwoView <= 0.40 &&
  metrics.p95LatencyMs <= 15000 &&
  metrics.averageCostUsd < 0.001;
if (!passed) {
  console.error(
    "RELEASE BLOCKED: evaluation thresholds were not met. See eval/README.md.",
  );
  process.exitCode = 1;
} else {
  console.log("RELEASE GATE PASSED");
}

function validateEntry(entry) {
  if (!entry || typeof entry !== "object") {
    throw new Error("Every manifest entry must be an object.");
  }
  if (!Array.isArray(entry.images) ||
      entry.images.length < 1 || entry.images.length > 2) {
    throw new Error(`${entry.id || "Unknown object"} needs one or two images.`);
  }
  if (!Number.isFinite(entry.trueWeightGrams) || entry.trueWeightGrams <= 0) {
    throw new Error(`${entry.id || "Unknown object"} needs a positive mass.`);
  }
  const dimensions = entry.trueDimensionsMm;
  for (const axis of ["length", "width", "height"]) {
    if (!Number.isFinite(dimensions?.[axis]) || dimensions[axis] <= 0) {
      throw new Error(`${entry.id || "Unknown object"} needs ${axis}.`);
    }
  }
}

async function loadImage(path) {
  const absolute = resolve(repositoryRoot, path);
  const file = await readFile(absolute);
  if ((await stat(absolute)).size === 0) throw new Error("Empty image.");
  return {
    imageBase64: file.toString("base64"),
    mimeType: mimeType(absolute),
  };
}

function dimensionError(predicted, actual) {
  const predictedHorizontal = [Number(predicted.width), Number(predicted.depth)]
    .sort((a, b) => b - a);
  const actualHorizontal = [Number(actual.length), Number(actual.width)]
    .sort((a, b) => b - a);
  const pairs = [
    [predictedHorizontal[0], actualHorizontal[0]],
    [predictedHorizontal[1], actualHorizontal[1]],
    [Number(predicted.height), Number(actual.height)],
  ];
  if (pairs.some(([predictedValue]) =>
    !Number.isFinite(predictedValue) || predictedValue <= 0)) {
    throw new Error("AI returned invalid dimensions.");
  }
  return average(pairs.map(([predictedValue, actualValue]) =>
    Math.abs(predictedValue - actualValue) / actualValue));
}

function mimeType(path) {
  return ({
    ".png": "image/png",
    ".webp": "image/webp",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
  })[extname(path).toLowerCase()] || "image/jpeg";
}

function normalize(value) {
  return String(value || "").trim().toLowerCase();
}

function ratio(values, key) {
  return values.length === 0 ? 0 :
    values.filter((item) => item[key]).length / values.length;
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
