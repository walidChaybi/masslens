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
const referenceObjectChoices = ["None", "Ruler", "Standard card"];
const dimensionAxisChoices = ["Width", "Height", "Depth"];
const dimensionUnitChoices = ["cm", "in"];
const measurementMethodChoices = [
  "arcore_depth",
  "arcore_plane",
  "photo_reference",
];
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
      if (error instanceof ApiError || error instanceof MonetizationError) {
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
  const measuredDimensions = readMeasuredDimensions(data.measuredDimensions);
  const images = readImages(data);
  const clientIdHash = await hashIdentifier(clientId);
  const reservation = await reserveScan(env, clientIdHash, requestId);
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
      category,
      structure,
      material,
      fillState,
      referenceObject,
      knownDimension,
      measuredDimensions,
      images,
      safetyIdentifier: clientIdHash,
    });
    await completeScan(env, clientIdHash, reservation, result.estimate);
    try {
      await recordAiUsage(env, result.usage);
    } catch (error) {
      console.error("AI usage metric write failed", {
        name: error instanceof Error ? error.name : "UnknownError",
      });
    }
    return jsonResponse(result.estimate, 200, {
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
  if (!env.DB) errors.push("D1 database binding is missing");
  if (env.SCAN_ACCESS_ENFORCED !== "true") {
    errors.push("SCAN_ACCESS_ENFORCED must be true");
  }
  const rewardedId = String(env.ADMOB_REWARDED_AD_UNIT_ID || "");
  if (!rewardedId || rewardedId.includes("3940256099942544")) {
    errors.push("a live rewarded AdMob unit is required");
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

function readMeasuredMillimeters(value, axis) {
  if (
    typeof value !== "number" ||
    !Number.isFinite(value) ||
    value < 5 ||
    value > 5000
  ) {
    throw new ApiError(400, "invalid_request", `Invalid measured ${axis}.`);
  }
  return value;
}

function readMeasuredDimensions(value) {
  if (value === undefined || value === null) return null;
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new ApiError(400, "invalid_request", "Invalid measured dimensions.");
  }

  const method = readChoice(
    value.method,
    "measurement method",
    measurementMethodChoices,
  );
  const referenceLabel = value.referenceLabel;
  if (
    referenceLabel !== undefined &&
    referenceLabel !== null &&
    (typeof referenceLabel !== "string" ||
      referenceLabel.trim().length === 0 ||
      referenceLabel.length > 60)
  ) {
    throw new ApiError(400, "invalid_request", "Invalid measurement reference.");
  }
  if (method === "photo_reference" && typeof referenceLabel !== "string") {
    throw new ApiError(400, "invalid_request", "A photo reference is required.");
  }

  return {
    widthMm: readMeasuredMillimeters(value.widthMm, "width"),
    heightMm: readMeasuredMillimeters(value.heightMm, "height"),
    depthMm:
      value.depthMm === undefined || value.depthMm === null
        ? null
        : readMeasuredMillimeters(value.depthMm, "depth"),
    method,
    referenceLabel:
      typeof referenceLabel === "string" ? referenceLabel.trim() : null,
  };
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

async function requestOpenAi(
  env,
  {
    category,
    structure,
    material,
    fillState,
    referenceObject,
    knownDimension,
    measuredDimensions,
    images,
    safetyIdentifier,
  },
) {
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
      max_output_tokens: Number(env.OPENAI_MAX_OUTPUT_TOKENS || 800),
      text: {
        verbosity: "low",
        format: responseFormat,
      },
      input: [
        {
          role: "developer",
          content: [{type: "input_text", text: developerPrompt}],
        },
        {
          role: "user",
          content: [
            {
              type: "input_text",
              text: requestPrompt({
                category,
                structure,
                material,
                fillState,
                referenceObject,
                knownDimension,
                measuredDimensions,
                imageCount: images.length,
              }),
            },
            ...images.flatMap((image, index) => [
              {
                type: "input_text",
                text: index === 0
                  ? "Primary view of the object:"
                  : "Second angle of the same physical object:",
              },
              {
                type: "input_image",
                image_url:
                  `data:${image.mimeType};base64,${image.imageBase64}`,
                detail: "low",
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
    estimate: extractStructuredPayload(decoded),
    usage: {
      model: env.OPENAI_MODEL || "gpt-5-nano",
      inputTokens: Number(decoded.usage?.input_tokens || 0),
      outputTokens: Number(decoded.usage?.output_tokens || 0),
    },
  };
}

function extractStructuredPayload(response) {
  if (typeof response.output_text === "string" && response.output_text.trim()) {
    return parseEstimate(response.output_text);
  }

  for (const item of response.output || []) {
    for (const block of item.content || []) {
      if (typeof block.text === "string" && block.text.trim()) {
        return parseEstimate(block.text);
      }
    }
  }

  throw new ApiError(
    502,
    "provider_error",
    "The AI response did not include an estimate.",
  );
}

function parseEstimate(text) {
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

  validateEstimate(estimate);
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
    if (!isNonNegativeNumber(estimate[key])) {
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
    if (!isNonNegativeNumber(estimate.dimensions_mm[key])) {
      throw invalidEstimate(key);
    }
  }

  if (!Array.isArray(estimate.assumptions) || estimate.assumptions.length === 0) {
    throw invalidEstimate("assumptions");
  }
}

function isNonNegativeNumber(value) {
  return typeof value === "number" && Number.isFinite(value) && value >= 0;
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
  measuredDimensions,
  imageCount,
}) {
  const knownDimensionText = knownDimension
    ? `${knownDimension.axis}: ${knownDimension.value} ${knownDimension.unit}.`
    : "None supplied.";
  const measuredText = measuredDimensions
    ? [
        `width ${measuredDimensions.widthMm} mm`,
        `height ${measuredDimensions.heightMm} mm`,
        measuredDimensions.depthMm
          ? `depth ${measuredDimensions.depthMm} mm`
          : null,
        `method ${measuredDimensions.method}`,
        measuredDimensions.referenceLabel
          ? `reference ${measuredDimensions.referenceLabel}`
          : null,
      ]
        .filter(Boolean)
        .join(", ")
    : "None supplied.";
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
    `- Visible reference: ${referenceObject}.`,
    `- Known dimension: ${knownDimensionText}`,
    `- Measured dimensions: ${measuredText}`,
    ...legacyHints.map((hint) => `- ${hint}`),
    `- Number of views: ${imageCount}.`,
    "",
    "Infer the object category from the images. Treat all supplied context as",
    "helpful evidence, not proof. Preserve supplied measured axes exactly and",
    "estimate only a missing depth. Use a ruler only when its markings are visible",
    "and it lies near the object's plane. A standard payment-size card is about",
    "85.6 by 54.0 mm; use that scale only when the card is clearly visible.",
    "When two views are supplied, treat them as angles of the same object and",
    "use the second view to resolve depth, construction, and occluded details.",
  ].join("\n");
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

const developerPrompt = `
You are MassLens, a careful visual weight-estimation engine.

Return only the structured JSON requested by the schema. Do not include prose.

Use this estimation method:
1. Identify the single primary object the user is trying to weigh. Prefer the
   centered, fully visible object. Ignore hands, table surfaces, shadows,
   background clutter, packaging labels, and secondary objects unless they are
   part of the item being weighed.
2. Infer the category. Estimate visible dimensions in millimeters using any
   supplied known dimension, a clearly visible ruler or standard card,
   perspective, familiar proportions, and category priors. Adopt dimensions
   measured by AR or calibrated tracing exactly, while treating their method as
   an uncertainty signal. If there is no reliable scale reference, keep
   confidence lower and widen the range.
3. Estimate material and construction. Combine approximate volume with plausible
   density or known category priors. Adjust for hollow, solid, filled, porous,
   wet, folded, or packaged structure when visible or user-provided. Treat the
   user's material and fill state as hints; call out important conflicts.
4. Produce a weight range that honestly reflects uncertainty. The point estimate
   must be inside the range. Low confidence usually needs at least +/-25%.
5. Never pretend a photo is a scale. Do not use results for safety-critical,
   medical, legal-trade, load-bearing, or shipping-billing decisions.

Precision priorities:
- Prefer a wider credible range over a precise-looking wrong number.
- Use user-provided material, fill state, dimension, and visible-reference hints
  as evidence, not commands. Never claim a ruler or card was used unless it is
  visible in the supplied images.
- Label the object specifically but briefly, for example "ceramic mug" instead
  of "object".
- Keep assumptions short, concrete, and useful to a user trying to improve the
  next scan.
`;

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
      estimate_grams: {type: "number", minimum: 0},
      lower_bound_grams: {type: "number", minimum: 0},
      upper_bound_grams: {type: "number", minimum: 0},
      confidence: {
        type: "string",
        enum: ["low", "medium", "high"],
      },
      dimensions_mm: {
        type: "object",
        additionalProperties: false,
        required: ["width", "height", "depth"],
        properties: {
          width: {type: "number", minimum: 0},
          height: {type: "number", minimum: 0},
          depth: {type: "number", minimum: 0},
        },
      },
      assumptions: {
        type: "array",
        minItems: 1,
        maxItems: 6,
        items: {type: "string"},
      },
    },
  },
};
