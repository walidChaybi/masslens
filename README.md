# MassLens

MassLens is an Android-first Flutter app with three honest tools:

- a compatible Bluetooth scale for physical readings;
- a touch **simulator** explicitly labeled as not a measurement;
- real photo analysis through the Cloudflare Worker and OpenAI Responses API,
  with separate Object and Food & macros scan modes.

Object mode returns an approximate weight range, visual dimensions, and its
assumptions. Food & macros mode identifies one to six visible plate components,
estimates each component's weight range, and attaches approximate calories,
protein, carbohydrates, and fat from USDA FoodData Central. Users can remove a
false detection or correct a portion weight before saving the scan. Nutrition
results are informational estimates, not medical advice or dietary coaching.

There is no AI demo, offline fallback result, subscription, or scan pack. A new
installation receives three lifetime starter scans. After that, one AdMob rewarded
ad earns one scan after the SDK reports the completed reward. Provider failures refund the
reserved scan; the app never fabricates a result.

## AI and privacy

The app rejects corrupt/undersized photos and warns about darkness or blur.
Before upload it rotates and resizes each image to at most 1024 px, re-encodes
it as JPEG, and strips metadata. The Worker uses `gpt-5-nano`, minimal reasoning,
low-detail image input, structured JSON, bounded output, `store: false`, and a
hashed safety identifier. In Food & macros mode, the model supplies food labels,
weight ranges, and USDA-friendly search terms but never invents nutrient values.
The Worker sends only normalized food queries to USDA FoodData Central—never
photos, installation identifiers, or history. Components without a suitable
USDA match remain weight-only and totals are labeled partial. Completed JSON
(never photos) is replayable for 24 hours under an idempotent request ID.
At least one component must have a nutrition match; empty/non-food photos, zero
matches, and a complete USDA outage fail honestly and refund the reserved scan.

## Develop and verify

```bash
flutter pub get
flutter run --dart-define=ADMOB_ENABLED=true
flutter analyze
flutter test
flutter build apk --debug

cd worker
npm install
npm run check
npm run eval:food -- ../eval/private_dataset/food-manifest.json
```

Camera, BLE, consent, and AdMob test units still require physical-device
verification. Model release requires both the private 30+ object gate and the
private 30+ food-plate gate documented in `eval/README.md`. Profit is not
guaranteed; compare real seven-day paid-event revenue with direct AI cost before
changing cadence.

Production Worker setup requires `OPENAI_API_KEY` and `USDA_FDC_API_KEY` as
Cloudflare secrets. Release app builds also require an HTTPS privacy-policy URL
through `--dart-define=MASSLENS_PRIVACY_URL=...`. Before publishing, complete
Google Play's Health declaration with **Nutrition and Weight Management**, link
the same privacy policy in the listing and app, and verify the Food Scale
disclaimer and deletion flow.

`PRIVACY_POLICY.md` is the release-ready policy template. Replace its bracketed
owner/contact fields, publish it over HTTPS, and use that public URL for the
release define and Play listing.

See `MONETIZATION_SETUP.md` for Worker, D1, ad IDs, release validation, and
unit-economics operations.
