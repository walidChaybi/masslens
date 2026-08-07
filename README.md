# MassLens

MassLens is an Android-first Flutter app for AI-assisted weight estimates,
camera-guided dimensions, and compatible Bluetooth scales.

## Measurement modes

- **Bluetooth scale:** reads standard BLE Weight Scale Service measurements.
- **Touch demo:** demonstrates pressure input and is never presented as a real
  weight measurement.
- **AR measurement:** uses optional Google ARCore depth, plane, or feature-point
  hit tests to trace width, height, and optional depth.
- **Photo measurement:** calibrates a photo against a payment card, €1 coin, or
  custom known reference.
- **AI estimate:** combines one or two photos, measured dimensions, and optional
  material/fill context to return a weight range and confidence level.

ARCore is optional. Devices without ARCore automatically use calibrated photo
measurement, and users may skip dimensions for a lower-confidence photo-only
estimate.

## AI engine

Production AI requests go through the Cloudflare Worker in `worker/`. The
OpenAI key stays in an encrypted Worker secret and is never bundled into the
Flutter app. Local builds use the deterministic demo repository unless cloud
mode is enabled with Dart defines.

```bash
flutter run \
  --dart-define=ESTIMATE_ENGINE=cloudflare \
  --dart-define=MASSLENS_API_URL=https://masslens-api.example.workers.dev/estimate
```

The Worker validates images and physical context, enforces scan access, calls
the OpenAI Responses API, and returns a structured estimate.

## Run

```bash
flutter pub get
flutter run
```

## Verify

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug

cd worker
npm run check
```

AR behavior must also be checked on a physical ARCore-compatible Android phone.
The emulator and Flutter widget tests cover fallback and UI behavior, but they
cannot validate real-world tracking accuracy.

## Production notes

- Keep provider keys and Google Play verification credentials server-side.
- AR and photo dimensions are estimates, not legal-trade measurements.
- Never use camera estimates for medical dosing, safety limits, load-bearing
  decisions, or regulated shipping charges.
- Follow `MONETIZATION_SETUP.md` before enabling billing enforcement or live
  advertising.
