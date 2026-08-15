# Private model evaluation

MassLens has separate frozen evaluation gates for Object mode and Food & macros
mode. Run both before a model, prompt, image-processing, USDA matching, or
nutrition-calculation release. Never commit photos, private labels, API keys, or
raw evaluation responses.

## Object gate

Copy `manifest.example.json` to the git-ignored `manifest.json`, add at least
30 labeled objects, and put photos in `private_dataset/`. Record ground-truth
mass and physical length, width, and height for every object, but never send
those labels to the Worker. At least 10 objects need a second 45–90 degree side
photo. The evaluator sends the primary image alone and then both images for
those objects, so the comparison is paired.

Run the Worker locally with a real development OpenAI key and scan enforcement
disabled, then run this from `worker/`:

```bash
npm run eval -- ../eval/manifest.json
```

The existing object evaluator remains the release authority for structured
dimensions, category identification, mass-range containment, one-view and
two-view error, latency, and AI cost. Horizontal axes are compared without
assuming which one the model named `width` or `depth`.

## Food Scale dataset

Copy `food-manifest.example.json` to the already ignored private dataset:

```bash
cp ../eval/food-manifest.example.json \
  ../eval/private_dataset/food-manifest.json
```

Build and freeze a dataset with:

- at least 30 positive food plates, each with one to six independently weighed
  visible components;
- a guided second angle for at least 10 of those plates;
- representative mixed dishes, sauces, occlusion, different plate/bowl shapes,
  lighting, cuisines, and portion sizes;
- at least one empty plate and one non-food image marked as deterministic
  expected rejections.

Weigh edible contents separately and exclude the plate, bowl, utensils, and
decorations. Treat an inseparable mixed dish as one component. For every
component, record a stable ID, an English canonical label, only genuinely
equivalent `acceptableLabels`, its true net grams, and one or more manually
audited `acceptableFdcIds`. Accept only USDA `Survey (FNDDS)`, `Foundation`,
or `SR Legacy` records; do not accept a branded match. Freeze aliases and FDC
IDs before comparing prompts so they cannot be adjusted to favor a result.

The evaluator sends only images, scan mode, container type, and optional visual
context to the Worker. Ground-truth weights, aliases, expected components, and
acceptable USDA IDs never leave the evaluator.

## Food Scale gate

Run from `worker/` against the local Worker:

```bash
npm run eval:food -- ../eval/private_dataset/food-manifest.json
```

The default endpoint is `http://127.0.0.1:8787/estimate`. Override it only for
an isolated development deployment:

```bash
MASSLENS_EVAL_URL=https://development-worker.example/estimate \
  npm run eval:food -- ../eval/private_dataset/food-manifest.json
```

The evaluator always sends `scanMode: "food_plate"` and a fresh idempotency
ID. For a positive plate, a structured response requires a meal label, overall
confidence, one to six valid items, exactly three assumptions, ordered positive
weight bounds, and at least one complete non-branded USDA nutrition match. It
also rejects any client response that leaks the model's internal `usda_query`.
An empty/non-food sample passes only with structured HTTP 422
`no_food_detected`, listed in its `acceptableErrorCodes`; rate limits, zero USDA
matches (`nutrition_not_found`), USDA outages
(`nutrition_service_unavailable`), and provider failures do not count as a
correct negative-image rejection.

Release is blocked unless all of these gates pass:

| Metric | Definition | Gate |
|---|---|---:|
| Valid structured response | Valid positive payloads plus correct expected-rejection errors, divided by all requests | 100% |
| Component identification | One-to-one canonical/accepted-label matches divided by `max(expected, returned)`, aggregated across positive requests; misses and extras both count against it | ≥80% |
| Total-weight range containment | True sum of edible component weights falls inside the sum of returned item bounds | ≥70% |
| Median total-weight error | Median relative error between true and estimated total food weight | ≤60% |
| Acceptable USDA match | Matched expected components whose returned FDC ID is in the frozen audited list, divided by all expected components | ≥85% |
| Nutrition arithmetic | Every returned nutrition record scales to its lower, estimated, and upper weights without invalid values, together with the Flutter item/edit/removal/plate aggregation tests | 100% |
| End-to-end latency | p95 across positive and expected-rejection requests | ≤20 seconds |
| Average AI cost | Successful requests using required Worker token-usage headers and the configured token prices | <$0.002 |

The one-view and two-view median total errors are printed separately for
diagnosis but are not extra gates. Rejection responses currently have no usage
headers and are excluded from the average-cost denominator; every successful
request must have positive usage headers. Set
`MASSLENS_EVAL_INPUT_USD_PER_MTOK` and
`MASSLENS_EVAL_OUTPUT_USD_PER_MTOK` to the current contracted prices when the
defaults do not apply.

Nutrition values in the Worker contract are per 100 g. The app release tests
must independently prove:

```text
effective weight = user-adjusted grams, otherwise AI estimate grams
displayed nutrient = effective weight / 100 × USDA nutrient per 100 g
```

They must also prove lower/upper calorie ranges from the original AI bounds,
recalculation after edits or removals, and partial totals when any retained
component has `nutrition: null`. The evaluator and app tests together make the
100% arithmetic gate; model quality cannot compensate for arithmetic failures.

Keep `gpt-5-nano`; do not silently switch to a more expensive model when an
evaluation fails. Iterate capture guidance, the prompt, and deterministic USDA
matching against the same frozen dataset, then retain the metrics as release
evidence.
