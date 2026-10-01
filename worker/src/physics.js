// Deterministic post-processing for Object scans ("two-step estimation").
//
// The model describes the object (what it is, how it is built, what it is made
// of, whether it is a recognizable product). This module turns that
// description plus the dimensions into a physically plausible weight:
//   1. trusted AR measurements replace the model's guessed dimensions;
//   2. a recognized product's typical weight is blended in;
//   3. the implied effective density is checked against realistic bounds for
//      the construction/material and pulled back inside them when violated;
//   4. the range is rebuilt so it always contains the estimate and never looks
//      more precise than the confidence allows.
// The user still takes one photo and gets one answer.

export const constructionChoices = [
  "solid",
  "hollow_shell",
  "electronics_device",
  "container_empty",
  "container_filled",
  "soft_textile",
  "porous_foam",
  "flat_sheet",
  "mixed",
];

export const materialChoices = [
  "plastic",
  "aluminum",
  "steel_or_iron",
  "glass",
  "ceramic",
  "wood",
  "paper_cardboard",
  "fabric",
  "rubber_silicone",
  "food",
  "liquid",
  "stone",
  "mixed",
];

export const shapeChoices = ["box", "cylinder", "sphere", "irregular", "flat"];

// Share of the bounding box actually occupied by each outline.
const shapeFill = {
  box: 1,
  flat: 0.95,
  cylinder: 0.785,
  sphere: 0.524,
  irregular: 0.6,
};

// Effective density (g/cm³) of solid material.
const solidDensity = {
  plastic: [0.85, 1.5],
  aluminum: [2.4, 2.8],
  steel_or_iron: [6.8, 8.1],
  glass: [2.2, 2.8],
  ceramic: [1.8, 2.6],
  wood: [0.3, 1.0],
  paper_cardboard: [0.4, 1.2],
  fabric: [0.2, 1.0],
  rubber_silicone: [0.9, 1.7],
  food: [0.3, 1.3],
  liquid: [0.8, 1.4],
  stone: [2.0, 3.0],
  mixed: [0.3, 3.0],
};

// Effective density (g/cm³) of the whole occupied volume for built objects.
const constructionDensity = {
  hollow_shell: [0.03, 0.7],
  electronics_device: [0.45, 2.6],
  container_empty: [0.02, 0.6],
  container_filled: [0.5, 1.5],
  soft_textile: [0.03, 0.6],
  porous_foam: [0.01, 0.35],
  mixed: [0.05, 3.0],
};

// Plausibility checks should only catch gross errors, never fine-tune.
const BOUND_SLACK_LOW = 0.6;
const BOUND_SLACK_HIGH = 1.35;

const minimumHalfSpread = {low: 0.25, medium: 0.15, high: 0.08};

const AR_MIN_AXIS_CONFIDENCE = 0.6;

function baseDensity(construction, material) {
  return construction === "solid" || construction === "flat_sheet"
    ? solidDensity[material] ?? solidDensity.mixed
    : constructionDensity[construction] ?? constructionDensity.mixed;
}

export function densityBounds(construction, material) {
  const base = baseDensity(construction, material);
  return [base[0] * BOUND_SLACK_LOW, base[1] * BOUND_SLACK_HIGH];
}

/** Geometric middle of the realistic range: the "typical" effective density. */
export function typicalDensity(construction, material) {
  const [low, high] = baseDensity(construction, material);
  return Math.sqrt(low * high);
}

export function volumeCm3(dimensionsMm, shape) {
  const {width, height, depth} = dimensionsMm;
  return (width * height * depth) / 1000 * (shapeFill[shape] ?? shapeFill.irregular);
}

/**
 * AR axes arrive as length/width (footprint) and height. The response uses
 * width/depth for the two horizontal axes and height for the vertical one.
 */
export function applyArMeasurement(dimensionsMm, arMeasurement) {
  if (!arMeasurement) return {dimensions: dimensionsMm, usedAxes: 0};
  const confidence = arMeasurement.confidence ?? {};
  const trusted = (axis) =>
    typeof arMeasurement[`${axis}Cm`] === "number" &&
    (confidence[axis] ?? 0) >= AR_MIN_AXIS_CONFIDENCE;
  const next = {...dimensionsMm};
  let usedAxes = 0;
  if (trusted("length")) {
    next.width = round1(arMeasurement.lengthCm * 10);
    usedAxes++;
  }
  if (trusted("width")) {
    next.depth = round1(arMeasurement.widthCm * 10);
    usedAxes++;
  }
  if (trusted("height")) {
    next.height = round1(arMeasurement.heightCm * 10);
    usedAxes++;
  }
  return {dimensions: next, usedAxes};
}

export function refineObjectEstimate(estimate, {arMeasurement = null} = {}) {
  const physics = estimate.physics;
  const {physics: _omit, ...publicEstimate} = estimate;
  const trace = {applied: []};
  if (!physics || typeof physics !== "object") {
    return {estimate: publicEstimate, trace};
  }

  let confidence = publicEstimate.confidence;
  let grams = publicEstimate.estimate_grams;

  const ar = applyArMeasurement(publicEstimate.dimensions_mm, arMeasurement);
  const dimensions = ar.dimensions;
  if (ar.usedAxes > 0) trace.applied.push(`ar_axes:${ar.usedAxes}`);

  const shape = shapeChoices.includes(physics.shape) ? physics.shape : "irregular";
  const construction = constructionChoices.includes(physics.construction)
    ? physics.construction
    : "mixed";
  const material = materialChoices.includes(physics.primary_material)
    ? physics.primary_material
    : "mixed";
  const volume = volumeCm3(dimensions, shape);
  const [minDensity, maxDensity] = densityBounds(construction, material);

  // Recognized product: trust its catalogue weight when the measured size
  // does not contradict it.
  const productGrams = physics.product_typical_grams;
  if (
    physics.known_product === true &&
    typeof productGrams === "number" &&
    Number.isFinite(productGrams) &&
    productGrams > 0
  ) {
    const productDensity = volume > 0 ? productGrams / volume : 0;
    const consistent =
      ar.usedAxes === 0 ||
      (productDensity >= minDensity && productDensity <= maxDensity);
    if (consistent) {
      grams = grams * 0.3 + productGrams * 0.7;
      trace.applied.push("known_product");
    } else {
      trace.applied.push("known_product_rejected");
    }
  }

  // Density plausibility.
  if (volume > 0) {
    const density = grams / volume;
    if (density < minDensity || density > maxDensity) {
      const bound = density < minDensity ? minDensity : maxDensity;
      if (ar.usedAxes >= 2) {
        // The size is measured, so the mass is the wrong part: move to a
        // density between the violated bound and the typical one.
        const typical = typicalDensity(construction, material);
        grams = Math.sqrt(bound * typical) * volume;
      } else {
        // The size is a guess too, so only move halfway (geometrically)
        // toward the closest plausible mass.
        grams = Math.sqrt(grams * bound * volume);
      }
      confidence = "low";
      trace.applied.push(density < minDensity ? "density_raised" : "density_lowered");
    }
  }

  grams = Math.max(roundGrams(grams), 0.1);
  const spread = minimumHalfSpread[confidence] ?? minimumHalfSpread.low;
  const ratioLow = publicEstimate.lower_bound_grams / publicEstimate.estimate_grams;
  const ratioHigh = publicEstimate.upper_bound_grams / publicEstimate.estimate_grams;
  const lower = roundGrams(grams * Math.min(ratioLow, 1 - spread));
  const upper = roundGrams(grams * Math.max(ratioHigh, 1 + spread));

  trace.volumeCm3 = round1(volume);
  trace.densityBounds = [round2(minDensity), round2(maxDensity)];
  trace.impliedDensity = volume > 0 ? round2(grams / volume) : null;

  return {
    estimate: {
      ...publicEstimate,
      estimate_grams: grams,
      lower_bound_grams: Math.min(Math.max(lower, 0.05), grams),
      upper_bound_grams: Math.max(upper, grams),
      confidence,
      dimensions_mm: dimensions,
    },
    trace,
  };
}

function roundGrams(value) {
  if (value >= 100) return Math.round(value);
  if (value >= 10) return Math.round(value * 2) / 2;
  return Math.round(value * 10) / 10;
}

function round1(value) {
  return Math.round(value * 10) / 10;
}

function round2(value) {
  return Math.round(value * 100) / 100;
}
