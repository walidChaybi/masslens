// Free barcode fallback for packaged foods. The app queries Open Food Facts
// directly; when a product is missing there, it asks this route, which looks
// the GTIN up in USDA FoodData Central branded foods. No AI, no scan credit.

const usdaSearchUrl = "https://api.nal.usda.gov/fdc/v1/foods/search";
const foundCacheSeconds = 7 * 24 * 60 * 60;
const notFoundCacheSeconds = 24 * 60 * 60;
const clientIdPattern = /^[A-Za-z0-9_-]{20,80}$/;

export class BarcodeError extends Error {
  constructor(status, code, message) {
    super(message);
    this.name = "BarcodeError";
    this.status = status;
    this.code = code;
  }
}

export async function handleBarcodeRoute(request, env, url) {
  if (url.pathname !== "/food/barcode") return null;
  if (request.method !== "GET") {
    throw new BarcodeError(405, "method_not_allowed", "Use GET.");
  }
  const clientId = request.headers.get("x-masslens-client-id") || "";
  if (!clientIdPattern.test(clientId)) {
    throw new BarcodeError(
      400,
      "invalid_client_id",
      "A valid client identifier is required.",
    );
  }
  const barcode = normalizeGtin(url.searchParams.get("code") || "");
  if (!barcode) {
    throw new BarcodeError(400, "invalid_barcode", "The barcode is invalid.");
  }
  if (!env.USDA_FDC_API_KEY) {
    throw new BarcodeError(
      503,
      "nutrition_service_not_configured",
      "Nutrition data is not configured.",
    );
  }
  await enforceBarcodeRateLimits(request, env, clientId);

  const result = await lookupUsdaBarcode(env, barcode);
  if (result.status === "unavailable") {
    throw new BarcodeError(
      503,
      "nutrition_unavailable",
      "Nutrition data is temporarily unavailable.",
    );
  }
  return new Response(JSON.stringify(result), {
    status: 200,
    headers: {
      "Cache-Control": "no-store",
      "Content-Type": "application/json; charset=utf-8",
      "X-Content-Type-Options": "nosniff",
    },
  });
}

async function enforceBarcodeRateLimits(request, env, clientId) {
  // Separate keys so barcode lookups never consume the AI scan budget.
  const ipAddress = request.headers.get("cf-connecting-ip") || clientId;
  const limiters = [
    env.CLIENT_RATE_LIMITER?.limit({key: `barcode:${clientId}`}),
    env.IP_RATE_LIMITER?.limit({key: `barcode:${ipAddress}`}),
  ].filter(Boolean);
  const results = await Promise.all(limiters);
  if (results.some((result) => !result?.success)) {
    throw new BarcodeError(
      429,
      "rate_limited",
      "Too many barcode lookups. Please wait a minute and try again.",
    );
  }
}

/** Returns the digits of a valid EAN-8/UPC-A/EAN-13/GTIN-14, else null. */
export function normalizeGtin(raw) {
  const digits = String(raw).replace(/[\s-]/g, "");
  if (!/^(\d{8}|\d{12,14})$/.test(digits)) return null;
  return hasValidCheckDigit(digits) ? digits : null;
}

function hasValidCheckDigit(digits) {
  const body = digits.slice(0, -1);
  let sum = 0;
  for (let index = 0; index < body.length; index += 1) {
    const digit = Number(body[body.length - 1 - index]);
    sum += index % 2 === 0 ? digit * 3 : digit;
  }
  return (10 - (sum % 10)) % 10 === Number(digits.at(-1));
}

function stripLeadingZeros(value) {
  return String(value || "").replace(/\D/g, "").replace(/^0+/, "");
}

export async function lookupUsdaBarcode(env, barcode) {
  const cache = readDefaultCache();
  const cacheRequest = new Request(
    `https://masslens-barcode-cache.invalid/v1/${barcode}`,
  );
  if (cache) {
    try {
      const cached = await cache.match(cacheRequest);
      if (cached) {
        const value = await cached.json();
        if (value?.status === "found" || value?.status === "not_found") {
          return value;
        }
      }
    } catch {
      // Cache failures fall through to a live lookup.
    }
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5000);
  let response;
  try {
    const url = new URL(usdaSearchUrl);
    url.searchParams.set("api_key", env.USDA_FDC_API_KEY);
    response = await fetch(url, {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({
        query: barcode,
        dataType: ["Branded"],
        pageSize: 10,
      }),
      signal: controller.signal,
    });
  } catch {
    return {status: "unavailable"};
  } finally {
    clearTimeout(timeout);
  }
  if (!response.ok) return {status: "unavailable"};

  let decoded;
  try {
    decoded = await response.json();
  } catch {
    return {status: "unavailable"};
  }

  const product = selectBrandedProduct(decoded, barcode);
  const result = product ? {status: "found", product} : {status: "not_found"};
  if (cache) {
    try {
      await cache.put(
        cacheRequest,
        new Response(JSON.stringify(result), {
          headers: {
            "Cache-Control": `public, max-age=${
              product ? foundCacheSeconds : notFoundCacheSeconds
            }`,
            "Content-Type": "application/json; charset=utf-8",
          },
        }),
      );
    } catch {
      // Caching is best effort.
    }
  }
  return result;
}

export function selectBrandedProduct(decoded, barcode) {
  if (!decoded || !Array.isArray(decoded.foods)) return null;
  const wanted = stripLeadingZeros(barcode);
  for (const food of decoded.foods) {
    if (
      !food ||
      food.dataType !== "Branded" ||
      stripLeadingZeros(food.gtinUpc) !== wanted ||
      typeof food.description !== "string" ||
      !food.description.trim() ||
      !Array.isArray(food.foodNutrients)
    ) {
      continue;
    }
    const calories = readNutrient(food.foodNutrients, 1008, "208", "kcal");
    if (calories === null) continue;
    const protein = readNutrient(food.foodNutrients, 1003, "203", "g");
    const carbs = readNutrient(food.foodNutrients, 1005, "205", "g");
    const fat = readNutrient(food.foodNutrients, 1004, "204", "g");
    const per100g = {
      caloriesKcal: calories,
      proteinGrams: protein ?? 0,
      carbsGrams: carbs ?? 0,
      fatGrams: fat ?? 0,
    };
    if (!isPlausible(per100g)) continue;
    const servingUnit = String(food.servingSizeUnit || "").toLowerCase();
    const servingSize = Number(food.servingSize);
    const hasServing =
      (servingUnit === "g" || servingUnit === "ml") &&
      Number.isFinite(servingSize) &&
      servingSize >= 1 &&
      servingSize <= 5000;
    const brand = [food.brandName, food.brandOwner]
      .find((value) => typeof value === "string" && value.trim());
    return {
      barcode,
      name: titleCase(food.description.trim()).slice(0, 120),
      ...(brand ? {brand: titleCase(brand.trim()).slice(0, 80)} : {}),
      source: "usda",
      per100g,
      ...(hasServing ? {servingGrams: servingSize} : {}),
      isLiquid: servingUnit === "ml",
      hasPartialNutrition: [protein, carbs, fat].some((value) => value === null),
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

function isPlausible(per100g) {
  const macros = [per100g.proteinGrams, per100g.carbsGrams, per100g.fatGrams];
  if (per100g.caloriesKcal > 950) return false;
  if (macros.some((value) => value > 100)) return false;
  if (macros.reduce((sum, value) => sum + value, 0) > 105) return false;
  return per100g.caloriesKcal > 0 || macros.some((value) => value > 0);
}

function titleCase(value) {
  // USDA branded descriptions are often ALL CAPS.
  if (value !== value.toUpperCase()) return value;
  return value.toLowerCase().replace(/(^|[\s(/-])(\p{L})/gu,
    (_, prefix, letter) => prefix + letter.toUpperCase());
}

function readDefaultCache() {
  try {
    return globalThis.caches?.default || null;
  } catch {
    return null;
  }
}
