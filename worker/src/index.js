import {
  completeScan,
  enforceDailyAiCostLimit,
  handleMonetizationRoute,
  MonetizationError,
  readRequestId,
  recordAiUsage,
  refundScan,
  reserveScan,
} from "./monetization.js";
import {
  enrichFoodEstimate,
  foodDeveloperPrompt,
  foodLocalizedTexts,
  foodRequestPrompt,
  foodResponseFormat,
  NutritionError,
  validateFoodEstimate,
} from "./food.js";
import {BarcodeError, handleBarcodeRoute} from "./barcode.js";
import {
  constructionChoices,
  materialChoices as physicsMaterialChoices,
  refineObjectEstimate,
  shapeChoices,
} from "./physics.js";

const maxRequestCharacters = 17 * 1024 * 1024;
const maxImageBase64Characters = 8 * 1024 * 1024;
const maxTotalImageBase64Characters = 15 * 1024 * 1024;
const maxImages = 2;
const clientIdPattern = /^[A-Za-z0-9_-]{20,80}$/;

const categoryChoices = [
  "Auto",
  "Food",
  "Parcel",
  "Furniture",
  "Electronics",
  "Other",
];
const structureChoices = ["Unknown", "Solid", "Hollow"];
const materialChoices = [
  "Unknown",
  "Plastic",
  "Metal",
  "Glass/Ceramic",
  "Wood",
  "Cardboard/Paper",
  "Fabric",
  "Food/Liquid",
  "Mixed",
];
const fillStateChoices = [
  "Unknown",
  "Solid",
  "Empty",
  "Partly filled",
  "Full",
];
const referenceObjectChoices = ["None", "Ruler", "Standard card", "Coin"];
const dimensionAxisChoices = [
  "Length",
  "Width",
  "Height",
  "Depth",
  "Diameter",
];
const dimensionUnitChoices = ["cm", "in"];
const responseLocaleChoices = ["en", "fr", "es"];
const scanModeChoices = ["object", "food_plate"];
const mimeTypeChoices = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
];

export default {
  async fetch(request, env) {
    try {
      return await routeRequest(request, env);
    } catch (error) {
      if (
        error instanceof ApiError ||
        error instanceof MonetizationError ||
        error instanceof NutritionError ||
        error instanceof BarcodeError
      ) {
        return errorResponse(error.status, error.code, error.message);
      }

      console.error("Unhandled worker error", {
        name: error instanceof Error ? error.name : "UnknownError",
      });
      return errorResponse(500, "internal_error", "The AI service failed.");
    }
  },
};

async function routeRequest(request, env) {
  const url = new URL(request.url);

  if (request.method === "GET" && url.pathname === "/health") {
    return jsonResponse({ok: true});
  }

  if (request.method === "GET" && url.pathname === "/ready") {
    const errors = productionConfigurationErrors(env);
    return jsonResponse(
      {ok: errors.length === 0, errors, model: env.OPENAI_MODEL || null},
      errors.length === 0 ? 200 : 503,
    );
  }

  if (
    (request.method === "GET" || request.method === "HEAD") &&
    url.pathname === "/privacy"
  ) {
    return htmlResponse(privacyPolicyHtml());
  }

  const barcodeResponse = await handleBarcodeRoute(request, env, url);
  if (barcodeResponse) return barcodeResponse;

  const monetizationResponse = await handleMonetizationRoute(
    request,
    env,
    url,
  );
  if (monetizationResponse) return monetizationResponse;

  if (request.method !== "POST" || url.pathname !== "/estimate") {
    throw new ApiError(404, "not_found", "Endpoint not found.");
  }

  if (!env.OPENAI_API_KEY) {
    throw new ApiError(
      503,
      "service_not_configured",
      "The AI service is not configured.",
    );
  }

  const clientId = readClientId(request);
  const requestId = readRequestId(request);
  await enforceRateLimits(request, env, clientId);
  const data = await readRequestJson(request);
  const scanMode = readChoice(
    data.scanMode ?? "object",
    "scanMode",
    scanModeChoices,
  );
  if (scanMode === "food_plate" && !env.USDA_FDC_API_KEY) {
    throw new ApiError(
      503,
      "nutrition_service_not_configured",
      "Nutrition data is not configured.",
    );
  }
  const responseLocale = readChoice(
    data.responseLocale ?? "en",
    "responseLocale",
    responseLocaleChoices,
  );
  // Category and structure are retained as optional legacy hints so older app
  // builds keep working while current builds provide physical context instead.
  const category = readChoice(
    data.category ?? "Auto",
    "category",
    categoryChoices,
  );
  const structure = readChoice(
    data.structure ?? "Unknown",
    "structure",
    structureChoices,
  );
  const material = readChoice(
    data.material ?? "Unknown",
    "material",
    materialChoices,
  );
  const fillState = readChoice(
    data.fillState ?? "Unknown",
    "fillState",
    fillStateChoices,
  );
  const referenceObject = readChoice(
    data.referenceObject ?? "None",
    "referenceObject",
    referenceObjectChoices,
  );
  const knownDimension = readKnownDimension(data.knownDimension);
  const arMeasuredDimension = readArMeasuredDimension(data.arMeasuredDimension);
  const arMeasurement = readArMeasurement(data.arMeasurement);
  const containerType = readOptionalText(data.containerType, "containerType");
  const images = readImages(data);
  const clientIdHash = await hashIdentifier(clientId);
  const reservation = await reserveScan(env, clientIdHash, requestId, request.headers.get("x-masslens-build") === "debug");
  if (reservation.kind === "replay") {
    try {
      return jsonResponse(JSON.parse(reservation.resultJson));
    } catch {
      throw new ApiError(
        502,
        "cached_result_invalid",
        "The saved AI result could not be recovered.",
      );
    }
  }

  try {
    await enforceDailyAiCostLimit(env);
    const result = await requestOpenAi(env, {
      scanMode,
      category,
      structure,
      material,
      fillState,
      referenceObject,
      knownDimension,
      arMeasuredDimension: scanMode !== "object" ? null : arMeasuredDimension,
      arMeasurement: scanMode !== "object" ? null : arMeasurement,
      containerType,
      images,
      responseLocale,
      safetyIdentifier: clientIdHash,
    });
    try {
      await recordAiUsage(env, result.usage);
    } catch (error) {
      console.error("AI usage metric write failed", {
        name: error instanceof Error ? error.name : "UnknownError",
      });
    }
    const estimate = scanMode === "food_plate"
      ? await enrichFoodEstimate(env, result.estimate)
      : refineObject(result.estimate, arMeasurement);
    await completeScan(env, clientIdHash, reservation, estimate, scanMode);
    return jsonResponse(estimate, 200, {
      "X-MassLens-AI-Model": result.usage.model,
      "X-MassLens-Input-Tokens": String(result.usage.inputTokens),
      "X-MassLens-Output-Tokens": String(result.usage.outputTokens),
    });
  } catch (error) {
    await refundScan(env, clientIdHash, reservation);
    throw error;
  }
}

function productionConfigurationErrors(env) {
  const errors = [];
  if (!env.OPENAI_API_KEY) errors.push("OPENAI_API_KEY is missing");
  if (!env.USDA_FDC_API_KEY) errors.push("USDA_FDC_API_KEY is missing");
  if (!env.DB) errors.push("D1 database binding is missing");
  if (env.SCAN_ACCESS_ENFORCED !== "true") {
    errors.push("SCAN_ACCESS_ENFORCED must be true");
  }
  if ((env.OPENAI_MODEL || "") !== "gpt-5-nano") {
    errors.push("OPENAI_MODEL must be gpt-5-nano for this release");
  }
  return errors;
}

function readClientId(request) {
  const clientId = request.headers.get("x-masslens-client-id") || "";
  if (!clientIdPattern.test(clientId)) {
    throw new ApiError(
      400,
      "invalid_client_id",
      "A valid client identifier is required.",
    );
  }
  return clientId;
}

async function enforceRateLimits(request, env, clientId) {
  const ipAddress = request.headers.get("cf-connecting-ip") || clientId;
  const [clientResult, ipResult] = await Promise.all([
    env.CLIENT_RATE_LIMITER.limit({key: clientId}),
    env.IP_RATE_LIMITER.limit({key: ipAddress}),
  ]);

  if (!clientResult.success || !ipResult.success) {
    throw new ApiError(
      429,
      "rate_limited",
      "Too many scans. Please wait a minute and try again.",
    );
  }
}

async function readRequestJson(request) {
  const contentType = request.headers.get("content-type") || "";
  if (!contentType.toLowerCase().startsWith("application/json")) {
    throw new ApiError(
      415,
      "unsupported_media_type",
      "Content-Type must be application/json.",
    );
  }

  const contentLength = Number(request.headers.get("content-length") || 0);
  if (Number.isFinite(contentLength) && contentLength > maxRequestCharacters) {
    throw new ApiError(413, "request_too_large", "The image is too large.");
  }

  const bodyText = await request.text();
  if (bodyText.length > maxRequestCharacters) {
    throw new ApiError(413, "request_too_large", "The image is too large.");
  }

  let data;
  try {
    data = JSON.parse(bodyText);
  } catch {
    throw new ApiError(400, "invalid_json", "Request JSON is invalid.");
  }

  if (!data || typeof data !== "object" || Array.isArray(data)) {
    throw new ApiError(400, "invalid_request", "Request must be an object.");
  }
  return data;
}

function readChoice(value, name, choices) {
  if (typeof value !== "string" || !choices.includes(value)) {
    throw new ApiError(400, "invalid_request", `Invalid ${name}.`);
  }
  return value;
}

function readOptionalText(value, name) {
  if (value === undefined || value === null || value === "") return null;
  if (
    typeof value !== "string" ||
    !value.trim() ||
    value.length > 80 ||
    /[\u0000-\u001f\u007f]/.test(value)
  ) {
    throw new ApiError(400, "invalid_request", `Invalid ${name}.`);
  }
  return value.trim();
}

function readKnownDimension(value) {
  if (value === undefined || value === null) return null;
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new ApiError(400, "invalid_request", "Invalid known dimension.");
  }

  const numericValue = value.value;
  if (
    typeof numericValue !== "number" ||
    !Number.isFinite(numericValue) ||
    numericValue <= 0 ||
    numericValue > 100000
  ) {
    throw new ApiError(400, "invalid_request", "Invalid known dimension.");
  }

  return {
    axis: readChoice(value.axis, "known dimension axis", dimensionAxisChoices),
    value: numericValue,
    unit: readChoice(value.unit, "known dimension unit", dimensionUnitChoices),
  };
}

function readArMeasuredDimension(value) {
  if (value === undefined || value === null) return null;
  if (!value || typeof value !== "object" || Array.isArray(value) ||
      typeof value.widthCm !== "number" ||
      !Number.isFinite(value.widthCm) ||
      value.widthCm < 1 || value.widthCm > 300) {
    throw new ApiError(400, "invalid_request", "Invalid AR dimension.");
  }
  return {widthCm: value.widthCm};
}

function readArMeasurement(value) {
  if (value === undefined || value === null) return null;
  const invalid = () =>
    new ApiError(400, "invalid_request", "Invalid AR measurement.");
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw invalid();
  }
  const result = {confidence: {}};
  for (const axis of ["length", "width", "height"]) {
    const size = value[`${axis}Cm`];
    if (size === undefined || size === null) continue;
    if (typeof size !== "number" || !Number.isFinite(size) ||
        size < 0.3 || size > 300) {
      throw invalid();
    }
    result[`${axis}Cm`] = size;
    const confidence = value.confidence?.[axis];
    result.confidence[axis] =
      typeof confidence === "number" && Number.isFinite(confidence)
        ? Math.min(Math.max(confidence, 0), 1)
        : 0;
  }
  if (!("lengthCm" in result) && !("widthCm" in result) &&
      !("heightCm" in result)) {
    throw invalid();
  }
  if (typeof value.distanceCm === "number" && Number.isFinite(value.distanceCm)) {
    result.distanceCm = value.distanceCm;
  }
  return result;
}

function refineObject(estimate, arMeasurement) {
  const refined = refineObjectEstimate(estimate, {arMeasurement});
  console.log("object estimate refined", {
    applied: refined.trace.applied,
    volumeCm3: refined.trace.volumeCm3,
    impliedDensity: refined.trace.impliedDensity,
    densityBounds: refined.trace.densityBounds,
    physics: estimate.physics ?? null,
    modelGrams: estimate.estimate_grams,
    finalGrams: refined.estimate.estimate_grams,
  });
  return refined.estimate;
}

function readImageBase64(value) {
  if (typeof value !== "string" || value.length === 0) {
    throw new ApiError(400, "invalid_request", "Missing image.");
  }

  const imageBase64 = value.replace(
    /^data:image\/[a-zA-Z0-9.+-]+;base64,/,
    "",
  );
  if (imageBase64.length > maxImageBase64Characters) {
    throw new ApiError(413, "request_too_large", "The image is too large.");
  }
  if (!/^[A-Za-z0-9+/=]+$/.test(imageBase64)) {
    throw new ApiError(400, "invalid_request", "Image encoding is invalid.");
  }
  return imageBase64;
}

function readImages(data) {
  if (data.images === undefined) {
    return [
      {
        imageBase64: readImageBase64(data.imageBase64),
        mimeType: readChoice(
          data.mimeType || "image/jpeg",
          "mimeType",
          mimeTypeChoices,
        ),
      },
    ];
  }

  if (
    !Array.isArray(data.images) ||
    data.images.length === 0 ||
    data.images.length > maxImages
  ) {
    throw new ApiError(
      400,
      "invalid_request",
      "Provide one or two images.",
    );
  }

  const images = data.images.map((image, index) => {
    if (!image || typeof image !== "object" || Array.isArray(image)) {
      throw new ApiError(
        400,
        "invalid_request",
        `Invalid image at position ${index + 1}.`,
      );
    }
    return {
      imageBase64: readImageBase64(image.imageBase64),
      mimeType: readChoice(
        image.mimeType || "image/jpeg",
        "mimeType",
        mimeTypeChoices,
      ),
    };
  });

  const totalCharacters = images.reduce(
    (total, image) => total + image.imageBase64.length,
    0,
  );
  if (totalCharacters > maxTotalImageBase64Characters) {
    throw new ApiError(413, "request_too_large", "The images are too large.");
  }
  return images;
}

// Small models sometimes copy packaging or engraved text (Korean on Samsung
// products, Chinese on shipping labels, ...) into the answer despite the
// language instruction. Detect those scripts so we can retry once.
const foreignScriptPattern = new RegExp(
  "[\\p{Script=Han}\\p{Script=Hangul}\\p{Script=Hiragana}" +
    "\\p{Script=Katakana}\\p{Script=Cyrillic}\\p{Script=Arabic}" +
    "\\p{Script=Hebrew}\\p{Script=Thai}\\p{Script=Devanagari}]",
  "u",
);

function estimateUsesForeignScript(estimate, scanMode) {
  const texts = scanMode === "food_plate"
    ? foodLocalizedTexts(estimate)
    : [
      estimate.object_label,
      ...(Array.isArray(estimate.assumptions) ? estimate.assumptions : []),
    ];
  return texts.some(
    (text) => typeof text === "string" && foreignScriptPattern.test(text),
  );
}

async function requestOpenAi(env, params) {
  let first;
  try {
    first = await callOpenAi(env, params);
  } catch (error) {
    if (error?.code !== "provider_zero_estimate" || params.scanMode === "food_plate") {
      throw error;
    }
    console.warn("AI returned a zero-weight object; retrying once");
    return callOpenAi(env, params, {retryForZeroWeight: true});
  }
  if (!estimateUsesForeignScript(first.estimate, params.scanMode)) return first;

  console.warn("AI estimate used a foreign script; retrying once", {
    responseLocale: params.responseLocale,
  });
  let second;
  try {
    second = await callOpenAi(env, params, {retryForLanguage: true});
  } catch {
    // The first estimate is still numerically usable; wrong-language text
    // beats a failed scan.
    return first;
  }

  return {
    estimate: estimateUsesForeignScript(second.estimate, params.scanMode)
      ? first.estimate
      : second.estimate,
    usage: {
      model: second.usage.model,
      inputTokens: first.usage.inputTokens + second.usage.inputTokens,
      outputTokens: first.usage.outputTokens + second.usage.outputTokens,
    },
  };
}

async function callOpenAi(
  env,
  {
    scanMode,
    category,
    structure,
    material,
    fillState,
    referenceObject,
    knownDimension,
    arMeasuredDimension,
    arMeasurement = null,
    containerType,
    images,
    responseLocale,
    safetyIdentifier,
  },
  {retryForLanguage = false, retryForZeroWeight = false} = {},
) {
  const language = responseLocaleInstructions[responseLocale].language;
  const localizedFields = scanMode === "food_plate"
    ? "meal_label, item labels, or the assumptions"
    : "object_label or the assumptions";
  const retryInstruction = `
IMPORTANT: A previous attempt wrote ${localizedFields} in the
wrong language by copying text visible in the photos. Write every
human-readable value strictly in ${language}, translating any product or
packaging text.`;
  const zeroWeightRetryInstruction = `
IMPORTANT: A previous attempt returned zero grams. The visible subject is a
physical object, so zero is invalid. Identify the most likely object and return
your best positive mass and positive range. If evidence is weak, use low
confidence and a wider range; never use zero as an unknown-value sentinel.`;
  const isFood = scanMode === "food_plate";
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: env.OPENAI_MODEL || "gpt-5-nano",
      reasoning: {effort: env.OPENAI_REASONING_EFFORT || "minimal"},
      safety_identifier: safetyIdentifier,
      store: false,
      max_output_tokens: Number(
        isFood
          ? env.OPENAI_FOOD_MAX_OUTPUT_TOKENS || 1600
          : env.OPENAI_MAX_OUTPUT_TOKENS || 800,
      ),
      text: {
        verbosity: "low",
        format: isFood ? foodResponseFormat : responseFormat,
      },
      input: [
        {
          role: "developer",
          content: [
            {
              type: "input_text",
              text: retryForZeroWeight
                ? developerPrompt(responseLocale) + zeroWeightRetryInstruction
                : retryForLanguage
                ? (isFood
                  ? foodDeveloperPrompt(responseLocale)
                  : developerPrompt(responseLocale)) + retryInstruction
                : isFood
                  ? foodDeveloperPrompt(responseLocale)
                  : developerPrompt(responseLocale),
            },
          ],
        },
        {
          role: "user",
          content: [
            {
              type: "input_text",
              text: isFood
                ? foodRequestPrompt({
                  containerType,
                  referenceObject,
                  knownDimension,
                  imageCount: images.length,
                })
                : requestPrompt({
                  category,
                  structure,
                  material,
                  fillState,
                  referenceObject,
                  knownDimension,
                  arMeasuredDimension,
                  arMeasurement,
                  imageCount: images.length,
                }),
            },
            ...images.flatMap((image, index) => [
              {
                type: "input_text",
                text: index === 0
                  ? isFood
                    ? "Primary view of the whole meal:"
                    : "Primary view of the object:"
                  : isFood
                    ? "Second angle of the same meal:"
                    : "Second angle of the same physical object:",
              },
              {
                type: "input_image",
                image_url:
                  `data:${image.mimeType};base64,${image.imageBase64}`,
                detail: isFood
                  ? "low"
                  : env.OPENAI_OBJECT_IMAGE_DETAIL || "high",
              },
            ]),
          ],
        },
      ],
    }),
  });

  const responseText = await response.text();
  let decoded;
  try {
    decoded = JSON.parse(responseText);
  } catch {
    console.error("OpenAI returned invalid JSON", {
      status: response.status,
      requestId: response.headers.get("x-request-id"),
    });
    throw new ApiError(
      502,
      "provider_error",
      "The AI provider returned invalid data.",
    );
  }

  if (!response.ok) {
    console.error("OpenAI request failed", {
      status: response.status,
      requestId: response.headers.get("x-request-id"),
    });
    throw new ApiError(
      response.status === 429 ? 429 : 502,
      "provider_error",
      response.status === 429
        ? "The AI service is busy. Please try again shortly."
        : "The AI provider rejected the request.",
    );
  }

  return {
    estimate: extractStructuredPayload(decoded, scanMode),
    usage: {
      model: env.OPENAI_MODEL || "gpt-5-nano",
      inputTokens: Number(decoded.usage?.input_tokens || 0),
      outputTokens: Number(decoded.usage?.output_tokens || 0),
    },
  };
}

function extractStructuredPayload(response, scanMode) {
  if (typeof response.output_text === "string" && response.output_text.trim()) {
    return parseEstimate(response.output_text, scanMode);
  }

  for (const item of response.output || []) {
    for (const block of item.content || []) {
      if (typeof block.text === "string" && block.text.trim()) {
        return parseEstimate(block.text, scanMode);
      }
    }
  }

  throw new ApiError(
    502,
    "provider_error",
    "The AI response did not include an estimate.",
  );
}

function parseEstimate(text, scanMode) {
  let estimate;
  try {
    estimate = JSON.parse(text);
  } catch {
    throw new ApiError(
      502,
      "provider_error",
      "The AI estimate could not be parsed.",
    );
  }

  if (scanMode === "food_plate") {
    validateFoodEstimate(estimate);
  } else {
    validateEstimate(estimate);
  }
  return estimate;
}

function validateEstimate(estimate) {
  if (!estimate || typeof estimate !== "object" || Array.isArray(estimate)) {
    throw invalidEstimate("object");
  }

  for (const key of ["object_label", "category", "confidence"]) {
    if (typeof estimate[key] !== "string" || !estimate[key].trim()) {
      throw invalidEstimate(key);
    }
  }

  for (const key of [
    "estimate_grams",
    "lower_bound_grams",
    "upper_bound_grams",
  ]) {
    if (!isPositiveNumber(estimate[key])) {
      if (estimate[key] === 0) {
        throw new ApiError(
          502,
          "provider_zero_estimate",
          "The AI returned an unusable zero-weight estimate.",
        );
      }
      throw invalidEstimate(key);
    }
  }

  if (
    estimate.lower_bound_grams > estimate.estimate_grams ||
    estimate.upper_bound_grams < estimate.estimate_grams
  ) {
    throw invalidEstimate("weight range");
  }

  if (
    !estimate.dimensions_mm ||
    typeof estimate.dimensions_mm !== "object" ||
    Array.isArray(estimate.dimensions_mm)
  ) {
    throw invalidEstimate("dimensions");
  }
  for (const key of ["width", "height", "depth"]) {
    if (!isPositiveNumber(estimate.dimensions_mm[key])) {
      throw invalidEstimate(key);
    }
  }

  if (
    !Array.isArray(estimate.assumptions) ||
    estimate.assumptions.length !== 3 ||
    estimate.assumptions.some(
      (assumption) => typeof assumption !== "string" || !assumption.trim(),
    )
  ) {
    throw invalidEstimate("assumptions");
  }
}

function isPositiveNumber(value) {
  return typeof value === "number" && Number.isFinite(value) && value > 0;
}

function invalidEstimate(field) {
  return new ApiError(
    502,
    "provider_error",
    `The AI estimate has an invalid ${field}.`,
  );
}

function requestPrompt({
  category,
  structure,
  material,
  fillState,
  referenceObject,
  knownDimension,
  arMeasuredDimension,
  arMeasurement = null,
  imageCount,
}) {
  const knownDimensionText = knownDimension
    ? `${knownDimension.axis}: ${knownDimension.value} ${knownDimension.unit}.`
    : "None supplied.";
  const arDimensionText = arMeasuredDimension
    ? `Approximately ${arMeasuredDimension.widthCm.toFixed(1)} cm visible width, estimated automatically from camera depth. Treat as uncertain evidence, not weight.`
    : "None available.";
  const legacyHints = [];
  if (category !== "Auto") legacyHints.push(`Legacy category hint: ${category}.`);
  if (structure !== "Unknown") {
    legacyHints.push(`Legacy structure hint: ${structure}.`);
  }

  return [
    "Analyze the supplied view or views for MassLens.",
    "",
    "User-provided physical context:",
    `- Material: ${material}.`,
    `- Fill state: ${fillState}.`,
    `- Claimed visible reference: ${referenceObject}. Confirm it in the images.`,
    `- Already-known side: ${knownDimensionText}`,
    `- AR-estimated size: ${arDimensionText}`,
    `- Camera-measured size: ${arMeasurementText(arMeasurement)}`,
    ...(arMeasurement ? [
      "The camera-measured size comes from the phone's depth tracking of the object on its supporting surface. Prefer it over visual guessing for dimensions_mm (length/width are the footprint axes, height is vertical) unless the images clearly contradict it.",
    ] : []),
    ...(arMeasuredDimension ? [
      "Use this AR width as a metric scale for the prominent object in the first image when consistent with its visible boundaries.",
      "Use the scaled geometry to inform volume and mass; depth, density and hidden construction remain inferred.",
      "In the size assumption, state whether this measured reference was used or rejected and why. Do not claim a measured weight.",
    ] : []),
    ...legacyHints.map((hint) => `- ${hint}`),
    `- Number of views: ${imageCount}.`,
    "",
    "Treat supplied context as evidence, not proof. If two views are present,",
    "use the second as a 45-90 degree side view only after confirming it shows",
    "the same physical object. Ignore a mismatched view and lower confidence.",
  ].join("\n");
}

function arMeasurementText(arMeasurement) {
  if (!arMeasurement) return "None available.";
  const parts = [];
  for (const axis of ["length", "width", "height"]) {
    const size = arMeasurement[`${axis}Cm`];
    if (typeof size !== "number") continue;
    const confidence = arMeasurement.confidence?.[axis] ?? 0;
    parts.push(`${axis} ${size.toFixed(1)} cm (confidence ${confidence.toFixed(2)})`);
  }
  return parts.length ? `${parts.join(", ")}.` : "None available.";
}

async function hashIdentifier(value) {
  const input = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", input);
  return Array.from(new Uint8Array(digest), (byte) =>
    byte.toString(16).padStart(2, "0"),
  ).join("");
}

function jsonResponse(payload, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      "Cache-Control": "no-store",
      "Content-Type": "application/json; charset=utf-8",
      "X-Content-Type-Options": "nosniff",
      ...extraHeaders,
    },
  });
}

function htmlResponse(html, status = 200) {
  return new Response(html, {
    status,
    headers: {
      "Cache-Control": "public, max-age=300",
      "Content-Type": "text/html; charset=utf-8",
      "X-Content-Type-Options": "nosniff",
    },
  });
}

function privacyPolicyHtml() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>MassLens Privacy Policy</title>
  <style>
    :root { color-scheme: light; }
    body {
      margin: 0;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      line-height: 1.55;
      color: #132238;
      background: #f6f3ec;
    }
    main {
      max-width: 720px;
      margin: 0 auto;
      padding: 32px 20px 64px;
    }
    h1 { font-size: 1.85rem; margin: 0 0 8px; }
    h2 { font-size: 1.2rem; margin: 28px 0 10px; }
    p, li { color: #2a3b52; }
    .meta { color: #687384; margin-bottom: 24px; }
  </style>
</head>
<body>
  <main>
    <h1>MassLens Privacy Policy</h1>
    <p class="meta">Last updated: September 21, 2026</p>
    <p>MassLens: Photo Estimates provides approximate AI photo estimates for objects and food plates, plus a local nutrition diary. The phone does not measure weight. Food results are approximate and are not a medical device, medical advice, or dietary advice.</p>

    <h2>Photos and AI analysis</h2>
    <p>When you start an AI scan, MassLens rotates and resizes the selected photo, re-encodes it as JPEG, and removes its embedded metadata before upload. The photo and optional second angle are sent through the MassLens Cloudflare Worker to OpenAI solely to identify visible content and estimate weight ranges. OpenAI is instructed not to retain the response (<code>store: false</code>). Photos are not sent to USDA FoodData Central and are not stored in the Worker database.</p>
    <p>The free barcode scanner reads a product barcode on your device. The app sends only that barcode number to Open Food Facts to fetch the product's label nutrition; if the product is not found there, it sends the barcode number with the app installation identifier through the MassLens Cloudflare Worker, which searches USDA FoodData Central branded foods with the barcode number only. The camera preview is decoded on your device and no image is uploaded or stored for barcode lookups, which do not use AI or scan credits. Open Food Facts receives your IP address as part of the request, like any website. Products you log are remembered on your device as Recent products and are cleared with the nutrition diary in Settings.</p>
    <p>For Food &amp; macros scans, OpenAI returns food labels, approximate weights, and generic English food-search terms. It does not supply calorie or macro values. The Worker normalizes those search terms and sends only the text queries to USDA FoodData Central. USDA does not receive photos, the app installation identifier, or saved history.</p>

    <h2>Local history and temporary service data</h2>
    <p>Results are saved only when you choose Save. Saved result data and a private image copy remain in the app's local storage on your device. You can delete one saved result from its detail screen or delete all saved history in Settings. The optional Nutrition &amp; Trends diary is also stored only on your device. Entries are never added automatically or sent to MassLens, OpenAI, or USDA. Uninstalling the app also removes its local data, subject to Android backup settings controlled by you or the device.</p>
    <p>MassLens transmits device or other IDs off the device. A random app-installation identifier—not an IMEI, serial number, or hardware MAC—is sent to the MassLens Cloudflare service to manage scan credits, rewarded-ad credits, abuse prevention, and idempotent retries. The Worker hashes that identifier before database use. A completed result JSON—not its photo—may be retained for up to 24 hours so a network retry can return the same result without charging or analyzing the photo again. Anonymous daily aggregate counts include completed Object and Food Plate scans; no user-level nutrition diary or nutrition analytics are created.</p>

    <h2>In-app purchases</h2>
    <p>MassLens offers an optional one-time Google Play purchase for unlimited scans without ads. Google processes payments. MassLens sends the product identifier, app package name, purchase token, and installation identifier to its service to verify the purchase with Google. It stores purchase tokens and hashed installation identifiers to grant, restore, or revoke access. Google Play handles refunds.</p>

    <h2>Advertising and consent</h2>
    <p>MassLens uses Google Mobile Ads (AdMob) to provide rewarded scan credits and may display other ads. Google and its advertising partners collect and share device or other IDs, including the Android advertising ID and App Set ID, plus IP address (used to estimate approximate location), diagnostics, consent choices, and ad interactions, for advertising, analytics, and fraud prevention, under their own policies. Where required, MassLens asks for consent and provides an Ad privacy choices control in Settings. You can also reset or delete the advertising ID in Android settings.</p>

    <h2>Data sharing and purpose</h2>
    <p>MassLens shares data only with service providers needed for the functions above: Cloudflare for the API, OpenAI for photo analysis, USDA FoodData Central for generic nutrition searches and barcode fallbacks, Open Food Facts for barcode lookups made directly from the app, and Google for advertising and consent. Data is not sold. Processing is limited to providing scans, calculating USDA-based results, maintaining scan credits, preventing abuse, measuring anonymous service health, and supporting ads.</p>

    <h2>Your choices</h2>
    <p>You may avoid AI processing by using only the manual nutrition diary, decline to save a result, remove saved history in Settings, change available ad privacy choices, clear the separate local nutrition diary, or uninstall the app. For access, deletion, or privacy questions that cannot be handled on-device, use the developer contact details on the MassLens Google Play listing. Include no sensitive health information or photos in your request.</p>

    <h2>Children, security, and changes</h2>
    <p>MassLens is not directed to children under the minimum age required in their country. Reasonable technical and organizational safeguards are used, but no internet transmission is completely secure. This policy may be updated when the app or its providers change; the date above will be revised.</p>
    <p>App: MassLens: Photo Estimates (package <code>com.lilai.masslens.photoestimates</code>). This policy also covers the shared photo-analysis service used by earlier MassLens versions (<code>com.lilai.aivirtual</code>).<br />
    Privacy contact: use the developer contact on the Google Play listing</p>
  </main>
</body>
</html>`;
}

function errorResponse(status, code, message) {
  return jsonResponse({error: {code, message}}, status);
}

class ApiError extends Error {
  constructor(status, code, message) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = code;
  }
}

const baseDeveloperPrompt = `
You are MassLens, a careful visual weight-estimation engine.

Return only the structured JSON requested by the schema. Do not include prose
or reveal private reasoning. The assumptions are concise evidence summaries,
not chain-of-thought.

Perform this consistency workflow internally:
1. Identify the single primary object the user is trying to weigh. Prefer the
   centered, fully visible object. Across two views, first confirm shape, color,
   markings, and construction are consistent with the same physical object.
   Ignore hands, surfaces, shadows, clutter, and unrelated packaging.
2. Infer the category and a plausible vertical height plus two horizontal
   footprint axes. Use silhouette, perspective, familiar proportions, category
   priors, an already-known side, and only scale evidence actually visible in
   the images. Return width and depth as the two horizontal axes and height as
   the vertical axis; the client presents the horizontal axes as length and
   width. A payment card is about 85.6 by 54.0 mm, but use it only when clearly
   visible and near the object's plane. Use ruler markings only when legible.
3. Infer material, effective density, and construction. Account for solid,
   hollow, empty, filled, porous, wet, folded, or packaged forms. Treat user
   material and fill selections as hints and resolve visible conflicts honestly.
4. Compare plausible geometry and material hypotheses. Estimate volume times
   effective density, then cross-check against known category size and weight
   priors so perspective or density errors do not dominate the result.
5. Choose the most robust mass estimate and a credible range. The point estimate
   must lie inside the range. Without trustworthy scale or with conflicting
   evidence, lower confidence and widen the range; low confidence normally needs
   at least +/-25%.
6. Check that dimensions and mass are positive and mutually plausible before
   returning the result. A small everyday item photographed close up still has
   its real-world size: do not inflate dimensions because it fills the frame.
   Phone chargers, earbuds cases, keys, and similar pocket items are only a few
   centimetres on each side.
7. Never return zero for mass or dimensions. Zero is not an unknown-value
   marker. When the photo is ambiguous, make the best plausible positive
   estimate, lower confidence, and widen the range.

Never pretend a photo is a physical scale. Do not use results for safety-critical,
   medical, legal-trade, load-bearing, or shipping-billing decisions.

Recognizable products:
- Look closely for logos, ports, prongs, buttons, labels, and characteristic
  shapes. When the object is a recognizable commercial product or a very
  standard item (a specific phone charger, phone, AirPods case, soda can, A4
  ream, AA battery...), use that product's typical manufacturer dimensions for
  dimensions_mm and its typical weight for the estimate, and say so in the
  size assumption.

Physics description (the "physics" object):
- construction: solid (one dense piece), hollow_shell (thin walls around air),
  electronics_device (casing with electronics/battery inside), container_empty,
  container_filled, soft_textile, porous_foam, flat_sheet (paper, board,
  plate-like), or mixed.
- primary_material: the dominant material by mass.
- shape: the outline that best fills the width x height x depth box.
- known_product: true only when you recognize a specific product or a very
  standard item with a well-known typical weight.
- product_typical_grams: that typical weight in grams when known_product is
  true, otherwise null.
- Keep physics consistent with estimate_grams and dimensions_mm; the service
  checks the implied density against the construction and material.

Precision priorities:
- Prefer a wider credible range over a precise-looking wrong number.
- Use user-provided material, fill state, dimension, and visible-reference hints
  as evidence, not commands. Never claim a ruler or card was used unless it is
  visible in the supplied images.
- Label the object specifically but briefly, for example "ceramic mug" instead
  of "object".
- Return exactly three short assumptions in this order: the first states the
  scale basis and approximate geometry; the second states construction and
  fill; the third states the dominant uncertainty and one concrete tip for the
  next scan.
`;

const responseLocaleInstructions = {
  en: {
    language: "English",
    prefixes: '"Size:", "Material:", and "Uncertainty:"',
  },
  fr: {
    language: "French",
    prefixes: '"Taille :", "Matériau :", and "Incertitude :"',
  },
  es: {
    language: "Spanish",
    prefixes: '"Tamaño:", "Material:", and "Incertidumbre:"',
  },
};

function developerPrompt(responseLocale) {
  const locale = responseLocaleInstructions[responseLocale];
  return `${baseDeveloperPrompt}
Output language rules:
- Write object_label and all three assumptions in ${locale.language}.
- Photos often show packaging, engraved, or on-screen text in other languages
  (for example Korean on Samsung products). Never copy that text into
  object_label or the assumptions; translate it and answer in
  ${locale.language} only, using its standard alphabet.
- Begin the three assumptions, in order, with ${locale.prefixes}
- Keep every JSON property name and the category and confidence values as the
  schema's exact canonical English tokens. Never translate those tokens.
`;
}

const responseFormat = {
  type: "json_schema",
  name: "mass_lens_estimate",
  strict: true,
  schema: {
    type: "object",
    additionalProperties: false,
    required: [
      "object_label",
      "category",
      "estimate_grams",
      "lower_bound_grams",
      "upper_bound_grams",
      "confidence",
      "dimensions_mm",
      "assumptions",
      "physics",
    ],
    properties: {
      object_label: {type: "string"},
      category: {
        type: "string",
        enum: [
          "Food",
          "Parcel",
          "Furniture",
          "Electronics",
          "Luggage",
          "Tool",
          "Clothing",
          "Household",
          "Other",
        ],
      },
      estimate_grams: {type: "number", exclusiveMinimum: 0},
      lower_bound_grams: {type: "number", exclusiveMinimum: 0},
      upper_bound_grams: {type: "number", exclusiveMinimum: 0},
      confidence: {
        type: "string",
        enum: ["low", "medium", "high"],
      },
      dimensions_mm: {
        type: "object",
        additionalProperties: false,
        required: ["width", "height", "depth"],
        properties: {
          width: {type: "number", exclusiveMinimum: 0},
          height: {type: "number", exclusiveMinimum: 0},
          depth: {type: "number", exclusiveMinimum: 0},
        },
      },
      assumptions: {
        type: "array",
        minItems: 3,
        maxItems: 3,
        items: {type: "string"},
      },
      physics: {
        type: "object",
        additionalProperties: false,
        required: [
          "construction",
          "primary_material",
          "shape",
          "known_product",
          "product_typical_grams",
        ],
        properties: {
          construction: {type: "string", enum: constructionChoices},
          primary_material: {type: "string", enum: physicsMaterialChoices},
          shape: {type: "string", enum: shapeChoices},
          known_product: {type: "boolean"},
          product_typical_grams: {type: ["number", "null"]},
        },
      },
    },
  },
};
