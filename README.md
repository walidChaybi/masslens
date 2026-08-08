# MassLens

MassLens is an Android-first Flutter app with three honest modes:

- a compatible Bluetooth scale for physical readings;
- a touch **simulator** explicitly labeled as not a measurement;
- real photo analysis through the Cloudflare Worker and OpenAI Responses API.

There is no AI demo, offline fallback result, subscription, or scan pack. A new
installation receives three lifetime starter scans. After that, one AdMob rewarded
ad earns one scan after server-side verification. Provider failures refund the
reserved scan; the app never fabricates a result.

## AI and privacy

The app rejects corrupt/undersized photos and warns about darkness or blur.
Before upload it rotates and resizes each image to at most 1024 px, re-encodes
it as JPEG, and strips metadata. The Worker uses `gpt-5-nano`, minimal reasoning,
low-detail image input, structured JSON, bounded output, `store: false`, and a
hashed safety identifier. Completed JSON (never photos) is replayable for 24
hours under an idempotent request ID.

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
```

Camera, ARCore, BLE, consent, and AdMob test units still require physical-device
verification. Model release requires the private 30+ object gate documented in
`eval/README.md`. Profit is not guaranteed; compare real seven-day paid-event
revenue with direct AI cost before changing cadence.

See `MONETIZATION_SETUP.md` for Worker, D1, SSV, ad IDs, release validation, and
unit-economics operations.
