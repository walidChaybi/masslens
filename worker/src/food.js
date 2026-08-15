const allowedUsdaDataTypes = new Set([
  "Survey (FNDDS)",
  "Foundation",
  "SR Legacy",
]);
const confidenceChoices = new Set(["low", "medium", "high"]);
const foodEstimateKeys = new Set([
  "meal_label",
  "confidence",
  "items",
  "assumptions",
]);
const foodItemKeys = new Set([
  "label",
  "usda_query",
  "estimate_grams",
  "lower_bound_grams",
  "upper_bound_grams",
  "confidence",
]);
const nutritionCacheSeconds = 7 * 24 * 60 * 60;
const usdaSearchUrl = "https://api.nal.usda.gov/fdc/v1/foods/search";
const noFoodQuerySentinel = "__NO_FOOD__";

export const foodResponseFormat = {
  type: "json_schema",
  name: "mass_lens_food_plate_estimate",
  strict: true,
  schema: {
    type: "object",
    additionalProperties: false,
    required: ["meal_label", "confidence", "items", "assumptions"],
    properties: {
      meal_label: {type: "string"},
      confidence: {
        type: "string",
        enum: ["low", "medium", "high"],
      },
      items: {
        type: "array",
        minItems: 1,
        maxItems: 6,
        items: {
          type: "object",
          additionalProperties: false,
          required: [
            "label",
            "usda_query",
            "estimate_grams",
            "lower_bound_grams",
            "upper_bound_grams",
            "confidence",
          ],
          properties: {
            label: {type: "string"},
            usda_query: {type: "string"},
            estimate_grams: {type: "number", minimum: 0},
            lower_bound_grams: {type: "number", minimum: 0},
            upper_bound_grams: {type: "number", minimum: 0},
            confidence: {
              type: "string",
              enum: ["low", "medium", "high"],
            },
          },
        },
      },
      assumptions: {
        type: "array",
        minItems: 3,
        maxItems: 3,
        items: {type: "string"},
      },
    },
  },
};

const foodPromptBase = `
You are MassLens Food Scale, a careful visual food-portion estimation engine.

Return only the structured JSON requested by the schema. Do not include prose
or reveal private reasoning. The assumptions are concise evidence summaries,
not chain-of-thought. Never return calories or nutrient values: the server gets
those values from USDA FoodData Central after your visual analysis.

Analyze one whole plate, bowl, or food container:
1. Identify between one and six visible edible components. Exclude the plate,
   bowl, container, cutlery, napkins, hands, shadows, garnishes that are clearly
   decorative, and background objects.
2. Keep separable foods as separate items. Treat a mixed preparation that
   cannot be visually separated (for example lasagna, curry, or stew) as one
   dish rather than inventing hidden ingredient amounts.
3. Estimate the net edible weight of each item. The point estimate must lie
   inside a credible lower/upper range. Use container geometry, visible depth,
   familiar serving sizes, a supplied dimension, and only reference objects
   actually visible in the images.
4. Give each item an English usda_query describing the closest generic prepared
   food, including cooking method when visible (for example "chicken breast
   roasted" or "white rice cooked"). Do not name a brand and do not include an
   amount, serving size, unit, or nutrient value in usda_query.
5. If no edible food is visible (including an empty plate or a photo of only
   non-food objects), return exactly one server-only sentinel item: translate
   "No food detected" for its label, set usda_query to "${noFoodQuerySentinel}",
   set all three gram values to 0, and set item and overall confidence to low.
   Never use this sentinel when any edible food portion is visible.
6. Choose overall confidence from the combined item evidence. With occlusion,
   unknown depth, a mixed dish, or no trustworthy scale reference, lower
   confidence and widen the affected ranges.
7. Check that every weight is non-negative, every point estimate lies inside
   its range, and exactly three concise assumptions are returned.

Never pretend a photo is a physical scale. Results are approximate and are not
medical advice, dietary advice, or suitable for allergy or safety decisions.
`;

const foodLocaleInstructions = {
  en: {
    language: "English",
    prefixes: '"Portion:", "Preparation:", and "Uncertainty:"',
  },
  fr: {
    language: "French",
    prefixes: '"Portion :", "Préparation :", and "Incertitude :"',
  },
  es: {
    language: "Spanish",
    prefixes: '"Porción:", "Preparación:", and "Incertidumbre:"',
  },
};

export function foodDeveloperPrompt(responseLocale) {
  const locale = foodLocaleInstructions[responseLocale];
  return `${foodPromptBase}
Output language rules:
- Write meal_label, every item label, and all three assumptions in
  ${locale.language} only, translating text visible in the photos.
- Begin the three assumptions, in order, with ${locale.prefixes}
- Write every usda_query in concise English regardless of the output locale.
- Keep every JSON property name and confidence value as the schema's exact
  canonical English token. Never translate those tokens.
`;
}

export function foodRequestPrompt({
  containerType,
  referenceObject,
  knownDimension,
  imageCount,
}) {
  const knownDimensionText = knownDimension
    ? `${knownDimension.axis}: ${knownDimension.value} ${knownDimension.unit}.`
    : "None supplied.";
  return [
    "Analyze the supplied meal view or views for MassLens Food Scale.",
    "",
    "User-provided portion context:",
    `- Container type: ${containerType || "Not supplied"}.`,
    `- Claimed visible reference: ${referenceObject}. Confirm it in the images.`,
    `- Known container/reference dimension: ${knownDimensionText}`,
    `- Number of views: ${imageCount}.`,
    "",
    "Treat supplied context as evidence, not proof. If two views are present,",
    "confirm they show the same meal and use the second angle to estimate food",
    "depth. Ignore a mismatched view and lower confidence.",
  ].join("\n");
}

export function validateFoodEstimate(estimate) {
  requirePlainObject(estimate, "food estimate");
  requireExactKeys(estimate, foodEstimateKeys, "food estimate");
  requireText(estimate.meal_label, "meal_label");
  requireConfidence(estimate.confidence, "confidence");

  if (
    !Array.isArray(estimate.items) ||
    estimate.items.length < 1 ||
    estimate.items.length > 6
  ) {
    throw invalidFoodEstimate("items");
  }
  for (const [index, item] of estimate.items.entries()) {
    requirePlainObject(item, `item ${index + 1}`);
    requireExactKeys(item, foodItemKeys, `item ${index + 1}`);
    requireText(item.label, `item ${index + 1} label`);
    requireText(item.usda_query, `item ${index + 1} usda_query`, 160);
    requireConfidence(item.confidence, `item ${index + 1} confidence`);
    for (const key of [
      "estimate_grams",
      "lower_bound_grams",
      "upper_bound_grams",
    ]) {
      if (!isNonNegativeNumber(item[key])) {
        throw invalidFoodEstimate(`item ${index + 1} ${key}`);
      }
    }
    if (
      item.lower_bound_grams > item.estimate_grams ||
      item.upper_bound_grams < item.estimate_grams
    ) {
      throw invalidFoodEstimate(`item ${index + 1} weight range`);
    }
  }

  const sentinelItems = estimate.items.filter(
    (item) => item.usda_query === noFoodQuerySentinel,
  );
  if (
    sentinelItems.length > 0 &&
    (
      estimate.items.length !== 1 ||
      estimate.confidence !== "low" ||
      sentinelItems[0].confidence !== "low" ||
      sentinelItems[0].estimate_grams !== 0 ||
      sentinelItems[0].lower_bound_grams !== 0 ||
      sentinelItems[0].upper_bound_grams !== 0
    )
  ) {
    throw invalidFoodEstimate("no-food sentinel");
  }

  if (
    !Array.isArray(estimate.assumptions) ||
    estimate.assumptions.length !== 3 ||
    estimate.assumptions.some(
      (assumption) => typeof assumption !== "string" || !assumption.trim(),
    )
  ) {
    throw invalidFoodEstimate("assumptions");
  }
}

export function foodLocalizedTexts(estimate) {
  return [
    estimate?.meal_label,
    ...(Array.isArray(estimate?.items)
      ? estimate.items.flatMap((item) => [item?.label, item?.usda_query])
      : []),
    ...(Array.isArray(estimate?.assumptions) ? estimate.assumptions : []),
  ];
}

export async function enrichFoodEstimate(env, estimate) {
  if (estimate.items[0]?.usda_query === noFoodQuerySentinel) {
    throw new NutritionError(
      422,
      "no_food_detected",
      "No food was detected in the supplied photo.",
    );
  }
  const lookups = await Promise.all(
    estimate.items.map((item) => lookupNutrition(env, item.usda_query)),
  );
  const matchedCount = lookups.filter(
    (lookup) => lookup.status === "matched",
  ).length;
  const unavailableCount = lookups.filter(
    (lookup) => lookup.status === "unavailable",
  ).length;

  if (matchedCount === 0) {
    if (unavailableCount === lookups.length) {
      throw new NutritionError(
        502,
        "nutrition_service_unavailable",
        "Nutrition data is temporarily unavailable. Please try again.",
      );
    }
    throw new NutritionError(
      422,
      "nutrition_not_found",
      "Nutrition data could not be matched for this meal.",
    );
  }

  return {
    meal_label: estimate.meal_label,
    confidence: estimate.confidence,
    items: estimate.items.map((item, index) => ({
      label: item.label,
      estimate_grams: item.estimate_grams,
      lower_bound_grams: item.lower_bound_grams,
      upper_bound_grams: item.upper_bound_grams,
      confidence: item.confidence,
      nutrition: lookups[index].nutrition,
    })),
    assumptions: [...estimate.assumptions],
  };
}

async function lookupNutrition(env, query) {
  const normalizedQuery = normalizeUsdaQuery(query);
  const cache = readDefaultCache();
  const cacheRequest = new Request(
    `https://masslens-usda-cache.invalid/v1/${encodeURIComponent(normalizedQuery)}`,
  );

  if (cache) {
    try {
      const cached = await cache.match(cacheRequest);
      if (cached) {
        const value = await cached.json();
        if (isCachedLookup(value)) return value;
      }
    } catch (error) {
      logCacheFailure("read", error);
    }
  }

  const controller = new AbortController();
  const timeout = setTimeout(
    () => controller.abort(),
    readTimeoutMs(env.USDA_TIMEOUT_MS),
  );
  let response;
  try {
    const url = new URL(usdaSearchUrl);
    url.searchParams.set("api_key", env.USDA_FDC_API_KEY);
    response = await fetch(url, {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({
        query: normalizedQuery,
        dataType: [...allowedUsdaDataTypes],
        pageSize: 10,
      }),
      signal: controller.signal,
    });
  } catch (error) {
    console.error("USDA FoodData Central request failed", {
      name: error instanceof Error ? error.name : "UnknownError",
    });
    return {status: "unavailable", nutrition: null};
  } finally {
    clearTimeout(timeout);
  }

  if (!response.ok) {
    console.error("USDA FoodData Central rejected a request", {
      status: response.status,
    });
    return {status: "unavailable", nutrition: null};
  }

  let decoded;
  try {
    decoded = await response.json();
  } catch {
    console.error("USDA FoodData Central returned invalid JSON");
    return {status: "unavailable", nutrition: null};
  }

  const nutrition = selectNutrition(decoded);
  const result = nutrition
    ? {status: "matched", nutrition}
    : {status: "not_found", nutrition: null};
  if (cache) {
    try {
      await cache.put(
        cacheRequest,
        new Response(JSON.stringify(result), {
          headers: {
            "Cache-Control": `public, max-age=${nutritionCacheSeconds}`,
            "Content-Type": "application/json; charset=utf-8",
          },
        }),
      );
    } catch (error) {
      logCacheFailure("write", error);
    }
  }
  return result;
}

function selectNutrition(decoded) {
  if (!decoded || !Array.isArray(decoded.foods)) return null;
  for (const food of decoded.foods) {
    if (
      !food ||
      !allowedUsdaDataTypes.has(food.dataType) ||
      !Number.isInteger(Number(food.fdcId)) ||
      Number(food.fdcId) <= 0 ||
      typeof food.description !== "string" ||
      !food.description.trim() ||
      !Array.isArray(food.foodNutrients)
    ) {
      continue;
    }
    const calories = readNutrient(food.foodNutrients, 1008, "208", "kcal");
    const protein = readNutrient(food.foodNutrients, 1003, "203", "g");
    const carbs = readNutrient(food.foodNutrients, 1005, "205", "g");
    const fat = readNutrient(food.foodNutrients, 1004, "204", "g");
    if ([calories, protein, carbs, fat].some((value) => value === null)) {
      continue;
    }
    return {
      fdc_id: Number(food.fdcId),
      description: food.description.trim(),
      data_type: food.dataType,
      calories_kcal_per_100g: calories,
      protein_grams_per_100g: protein,
      carbs_grams_per_100g: carbs,
      fat_grams_per_100g: fat,
    };
  }
  return null;
}

function readNutrient(nutrients, nutrientId, nutrientNumber, expectedUnit) {
  const nutrient = nutrients.find((candidate) =>
    Number(candidate?.nutrientId) === nutrientId ||
    String(candidate?.nutrientNumber || "") === nutrientNumber
  );
  if (!nutrient) return null;
  const unit = String(nutrient.unitName || "").toLowerCase();
  if (unit !== expectedUnit.toLowerCase()) return null;
  const value = Number(nutrient.value);
  return Number.isFinite(value) && value >= 0 ? value : null;
}

function normalizeUsdaQuery(value) {
  return value.trim().replace(/\s+/g, " ").toLowerCase().slice(0, 160);
}

function readDefaultCache() {
  try {
    return globalThis.caches?.default || null;
  } catch {
    return null;
  }
}

function readTimeoutMs(value) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) return 4000;
  return Math.min(10000, Math.max(250, Math.round(parsed)));
}

function isCachedLookup(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) return false;
  if (value.status === "not_found" && value.nutrition === null) return true;
  return value.status === "matched" && isNutrition(value.nutrition);
}

function isNutrition(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) return false;
  return Number.isInteger(value.fdc_id) &&
    value.fdc_id > 0 &&
    typeof value.description === "string" &&
    allowedUsdaDataTypes.has(value.data_type) &&
    [
      value.calories_kcal_per_100g,
      value.protein_grams_per_100g,
      value.carbs_grams_per_100g,
      value.fat_grams_per_100g,
    ].every(isNonNegativeNumber);
}

function requirePlainObject(value, field) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw invalidFoodEstimate(field);
  }
}

function requireExactKeys(value, expectedKeys, field) {
  const keys = Object.keys(value);
  if (
    keys.length !== expectedKeys.size ||
    keys.some((key) => !expectedKeys.has(key))
  ) {
    throw invalidFoodEstimate(`${field} properties`);
  }
}

function requireText(value, field, maxLength = 200) {
  if (
    typeof value !== "string" ||
    !value.trim() ||
    value.length > maxLength ||
    /[\u0000-\u001f\u007f]/.test(value)
  ) {
    throw invalidFoodEstimate(field);
  }
}

function requireConfidence(value, field) {
  if (!confidenceChoices.has(value)) throw invalidFoodEstimate(field);
}

function isNonNegativeNumber(value) {
  return typeof value === "number" && Number.isFinite(value) && value >= 0;
}

function invalidFoodEstimate(field) {
  return new NutritionError(
    502,
    "provider_error",
    `The AI food estimate has an invalid ${field}.`,
  );
}

function logCacheFailure(operation, error) {
  console.error("USDA nutrition cache failed", {
    operation,
    name: error instanceof Error ? error.name : "UnknownError",
  });
}

export class NutritionError extends Error {
  constructor(status, code, message) {
    super(message);
    this.name = "NutritionError";
    this.status = status;
    this.code = code;
  }
}
