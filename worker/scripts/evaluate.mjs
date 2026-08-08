import {readFile, stat} from "node:fs/promises";
import {extname, resolve} from "node:path";
import {randomBytes} from "node:crypto";
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
  throw new Error("Evaluation requires a manifest with at least 30 objects.");
}

const samples = [];
for (const entry of manifest) {
  const started = performance.now();
  try {
    const imagePaths = entry.images || [];
    if (imagePaths.length < 1 || imagePaths.length > 2) {
      throw new Error("Each object needs one or two images.");
    }
    const images = await Promise.all(imagePaths.map(async (path) => {
      const absolute = resolve(repositoryRoot, path);
      const file = await readFile(absolute);
      if ((await stat(absolute)).size === 0) throw new Error("Empty image.");
      return {
        imageBase64: file.toString("base64"),
        mimeType: mimeType(absolute),
      };
    }));
    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-MassLens-Client-ID": clientId,
        "X-MassLens-Request-ID": randomBytes(18).toString("base64url"),
      },
      body: JSON.stringify({images, ...(entry.context || {})}),
    });
    const payload = await response.json();
    if (!response.ok) throw new Error(payload.error?.message || response.status);
    const inputTokens = Number(response.headers.get(
      "x-masslens-input-tokens",
    ) || 0);
    const outputTokens = Number(response.headers.get(
      "x-masslens-output-tokens",
    ) || 0);
    const trueWeight = Number(entry.trueWeightGrams);
    const relativeError = Math.abs(payload.estimate_grams - trueWeight) /
      trueWeight;
    samples.push({
      id: entry.id,
      valid: true,
      categoryCorrect: normalize(payload.category) === normalize(entry.category),
      contained: trueWeight >= payload.lower_bound_grams &&
        trueWeight <= payload.upper_bound_grams,
      relativeError,
      hasDimensions: Boolean(entry.hasDimensions),
      latencyMs: performance.now() - started,
      costUsd: inputTokens * inputUsdPerMillion / 1_000_000 +
        outputTokens * outputUsdPerMillion / 1_000_000,
    });
    process.stdout.write(".");
  } catch (error) {
    samples.push({id: entry.id, valid: false, error: String(error)});
    process.stdout.write("x");
  }
}
process.stdout.write("\n");

const valid = samples.filter((item) => item.valid);
const withDimensions = valid.filter((item) => item.hasDimensions);
const photoOnly = valid.filter((item) => !item.hasDimensions);
const metrics = {
  model: process.env.MASSLENS_EVAL_MODEL || "gpt-5-nano",
  validStructuredRate: valid.length / samples.length,
  categoryAccuracy: ratio(valid, "categoryCorrect"),
  rangeContainment: ratio(valid, "contained"),
  medianErrorWithDimensions: median(
    withDimensions.map((item) => item.relativeError),
  ),
  medianErrorPhotoOnly: median(photoOnly.map((item) => item.relativeError)),
  p95LatencyMs: percentile(valid.map((item) => item.latencyMs), 0.95),
  averageCostUsd: average(valid.map((item) => item.costUsd)),
};
console.log(JSON.stringify(metrics, null, 2));

const passed = metrics.validStructuredRate === 1 &&
  metrics.categoryAccuracy >= 0.80 &&
  metrics.rangeContainment >= 0.70 &&
  (withDimensions.length === 0 || metrics.medianErrorWithDimensions <= 0.40) &&
  (photoOnly.length === 0 || metrics.medianErrorPhotoOnly <= 0.60) &&
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
