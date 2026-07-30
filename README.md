# MassLens

MassLens is an Android-first Flutter MVP for honest, AI-assisted weight and
dimension estimation.

The current build contains a deterministic local demo engine, so the complete
capture → review → analysis → result → history flow works without API keys or
uploading photos. The estimator is isolated behind `EstimateRepository` and can
later be replaced by a secure backend implementation.

## Included

- Three-page trust-focused onboarding
- Camera and gallery image selection
- Category and object-structure review
- Animated local demo analysis
- Weight range, confidence, dimensions, and assumptions
- Private on-device image/history persistence
- Metric and imperial units
- Capture guidance, history filtering, deletion, and empty/error states

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
```

## Production seams

- Replace `DemoEstimateRepository` with a backend-backed repository.
- Keep AI provider keys and Google Play purchase verification on the server.
- Add ARCore depth/reference-object measurement as a separate guided-scan mode.
- Add explicit upload consent, retention controls, and production privacy terms
  before any photo leaves the device.
