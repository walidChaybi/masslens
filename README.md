# MassLens

MassLens is an Android-first Flutter MVP for honest, AI-assisted weight and
dimension estimation.

The current build contains a deterministic local demo engine, so the complete
capture → review → analysis → result → history flow works without API keys or
uploading photos. The estimator is isolated behind `EstimateRepository` and can
switch to the secure Cloudflare Worker without changing the UI flow.

## AI engine

Production AI requests go through a small Cloudflare Worker. The OpenAI key is
stored as an encrypted Worker secret and is never included in the Flutter app.
The Worker validates requests, limits scans per installation and network, calls
the OpenAI Responses API, and returns only the structured estimate.

The app remains in local demo mode unless cloud mode is enabled at build/run
time.

### Cloudflare setup

1. Create a free Cloudflare account.
2. Install the Worker dependencies and sign in:

```bash
cd worker
npm install
npx wrangler login
```

3. Deploy the Worker once. Wrangler prints its `workers.dev` URL:

```bash
npm run deploy
```

4. Store the OpenAI key. Paste it only into Wrangler's interactive prompt:

```bash
npx wrangler secret put OPENAI_API_KEY
```

5. Verify the deployed health endpoint, replacing the example URL with the URL
   from step 3:

```bash
curl https://masslens-api.YOUR-SUBDOMAIN.workers.dev/health
```

6. Run the Flutter app with the Worker estimate endpoint:

```bash
cd ..
flutter run \
  --dart-define=ESTIMATE_ENGINE=cloudflare \
  --dart-define=MASSLENS_API_URL=https://masslens-api.YOUR-SUBDOMAIN.workers.dev/estimate
```

The Worker uses `gpt-5.4-mini` with medium reasoning by default. Change the
non-secret values in `worker/wrangler.jsonc` and redeploy if evaluation shows a
different model or effort is a better cost/quality fit.

Check the Worker before deployment with:

```bash
cd worker
npm run check
```

## Included

- Three-page trust-focused onboarding
- Camera and gallery image selection with an optional second angle
- Category and object-structure review
- Animated scan-line analysis with clear progress feedback
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

- Keep AI provider keys and Google Play purchase verification in server-side
  secrets only.
- Add real user authentication and account quotas before paid or large-scale
  public access; installation and network rate limits are the MVP abuse guard.
- Add ARCore depth/reference-object measurement as a separate guided-scan mode.
- Add explicit upload consent, retention controls, and production privacy terms
  before any photo leaves the device.
