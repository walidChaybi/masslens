const maxRequestCharacters = 9 * 1024 * 1024;
const maxImageBase64Characters = 8 * 1024 * 1024;
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
      if (error instanceof ApiError) {
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
  await enforceRateLimits(request, env, clientId);
  const data = await readRequestJson(request);
  const category = readChoice(data.category, "category", categoryChoices);
  const structure = readChoice(
    data.structure,
    "structure",
    structureChoices,
  );
  const mimeType = readChoice(
    data.mimeType || "image/jpeg",
    "mimeType",
    mimeTypeChoices,
  );
  const imageBase64 = readImageBase64(data.imageBase64);

  const estimate = await requestOpenAi(env, {
    category,
    structure,
    mimeType,
    imageBase64,
    safetyIdentifier: await hashIdentifier(clientId),
  });
  return jsonResponse(estimate);
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

async function requestOpenAi(
  env,
  {category, structure, mimeType, imageBase64, safetyIdentifier},
) {
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: env.OPENAI_MODEL || "gpt-5.6-terra",
      reasoning: {effort: env.OPENAI_REASONING_EFFORT || "medium"},
      safety_identifier: safetyIdentifier,
      store: false,
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
              text: requestPrompt(category, structure),
            },
            {
              type: "input_image",
              image_url: `data:${mimeType};base64,${imageBase64}`,
              detail: "high",
            },
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

  return extractStructuredPayload(decoded);
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

function requestPrompt(category, structure) {
  return [
    "Analyze this photo for MassLens.",
    "",
    `User-selected category: ${category}.`,
    `User-selected internal structure: ${structure}.`,
    "",
    "Estimate the primary object's weight and dimensions. If the user selected",
    "Auto, infer the category from the image. If the user selected Unknown",
    "structure, infer the most likely construction and mention uncertainty in",
    "assumptions.",
  ].join("\n");
}

async function hashIdentifier(value) {
  const input = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", input);
  return Array.from(new Uint8Array(digest), (byte) =>
    byte.toString(16).padStart(2, "0"),
  ).join("");
}

function jsonResponse(payload, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      "Cache-Control": "no-store",
      "Content-Type": "application/json; charset=utf-8",
      "X-Content-Type-Options": "nosniff",
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
2. Estimate visible dimensions in millimeters using perspective, familiar object
   proportions, and category priors. If there is no reliable scale reference,
   keep confidence lower and widen the range.
3. Estimate material and construction. Combine approximate volume with plausible
   density or known category priors. Adjust for hollow, solid, filled, porous,
   wet, folded, or packaged structure when visible or user-provided.
4. Produce a weight range that honestly reflects uncertainty. The point estimate
   must be inside the range. Low confidence usually needs at least +/-25%.
5. Never pretend a photo is a scale. Do not use results for safety-critical,
   medical, legal-trade, load-bearing, or shipping-billing decisions.

Precision priorities:
- Prefer a wider credible range over a precise-looking wrong number.
- Use the user-selected category and structure as hints, not as commands, when
  the image clearly contradicts them.
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
