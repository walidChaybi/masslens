# Monetization production setup

MassLens has two lifetime starter scans, ad-funded rewarded scans, and an
optional one-time Google Play lifetime unlock (`masslens_lifetime_unlimited`,
default **$4.99**). Lifetime buyers get unlimited scans (40/day fair-use cap per
install) and no ads. Historical consumable billing tables stay inert; migrated
bonus and support balances remain as `legacyScans` until used.

## Worker and D1

```bash
cd worker
npm install
npx wrangler login
npx wrangler d1 migrations apply masslens-billing --remote
npx wrangler secret put OPENAI_API_KEY
npx wrangler secret put USDA_FDC_API_KEY
npx wrangler secret put PLAY_SERVICE_ACCOUNT_JSON
npm run check
npx wrangler deploy
curl -f https://masslens-api.masslens.workers.dev/ready
```

`/ready` fails unless the OpenAI and USDA secrets, D1 binding, enforced wallet,
and `gpt-5-nano` are configured. `USDA_FDC_API_KEY` must be a production
data.gov key, not the rate-limited public demo key. Keep it in the Worker secret
store only; never put it in Flutter assets, a `--dart-define`, source control, or
client logs. For local smoke tests only, USDA documents the public `DEMO_KEY`
(30 requests per IP per hour and 50 per day). A free personal data.gov key uses
the normal FoodData Central limit, currently 1,000 requests per hour per IP, and
is the correct choice for staging and production. See
https://fdc.nal.usda.gov/api-guide/. Migration 0003 creates the ads wallet, idempotent request/result
cache, and daily metrics without deleting old ledgers. Migration 0004 adds
durable reward-attempt reconciliation and an audited support-credit ledger.
Migration 0005 adds the separate idempotent mobile-SDK reward ledger and server
cooldown lease; it does not create signed SSV transactions. Migration 0006 adds
`lifetime_entitlements` and extends scan reservation kinds with `lifetime`. The
default AI cost ceiling is $5/day
(`MAX_DAILY_AI_COST_MICROS=5000000`); tune it in Worker variables.

Food & macros requests send photos only to the existing Worker/OpenAI analysis
path. The Worker sends USDA FoodData Central a normalized food query only—never
the image, client ID, request ID, or local history. Nutrition comes from matched
USDA records; a missing match remains weight-only and produces a partial total.
The app does not provide a diary, health goals, diagnoses, treatment, or dietary
coaching.

Empty and non-food images return 422 `no_food_detected`; a plate with zero valid
USDA matches returns 422 `nutrition_not_found`; a complete USDA outage returns
502 `nutrition_service_unavailable`. Each path refunds the reserved scan. Test
these errors as well as partial success with at least one matched component.

## AdMob

Create/verify four Android units:

- native, used on scale, AI home, and after history result two;
- rewarded with reward amount `1` and reward item exactly `scan`;
- interstitial, shown once during the first-open onboarding transition, at
  drawer transitions into AI Scan, Digital Scale, or History, after every
  second completed scan only after result close, and after every second saved
  result is read and closed. All uses share the server-controlled cooldown;
- app-open, eligible only after four hours in background and after onboarding.

Production IDs:

- native: `ca-app-pub-7681170430097585/5319406676`;
- rewarded: `ca-app-pub-7681170430097585/7055249463`;
- regular interstitial: `ca-app-pub-7681170430097585/5742167797`;
- app-open: `ca-app-pub-7681170430097585/2932171620`.

The banner (`ca-app-pub-7681170430097585/7955628865`) and rewarded
interstitial (`ca-app-pub-7681170430097585/8620483744`) are reserved. This
release never loads or requests either format, and they are not release
requirements.

The app registers a random reward-attempt ID before showing the ad. After the
Google Mobile Ads SDK reports `onUserEarnedReward`, the app sends the exact ID
to the Worker, which atomically adds one scan. The request is idempotent, so a
retry cannot add a second scan. Locally earned attempts remain retryable for 24
hours after a lost response. Both client and Worker enforce a two-minute
repeat-ad guard, and the rewarded balance is capped at three.

No AdMob server-side verification callback is configured or required for scan
credits. The former `/admob/reward` route is intentionally unavailable; mobile
SDK grants are recorded only in the separate `client_reward_grants` audit table.

Debug builds disable ads unless explicitly enabled. To test rewarded scan
credits without live ads, build with Google's test IDs:

```bash
flutter build apk --debug --dart-define=ADMOB_ENABLED=true --dart-define=ADMOB_USE_TEST_IDS=true
```

The release app fails fast if ads are
disabled, test IDs are enabled, or any live unit is missing. Put the live AdMob
app ID in `android/gradle.properties` as `ADMOB_APP_ID=ca-app-pub-…~…`, then
build production:

```bash
flutter build appbundle --release \
  --dart-define=MASSLENS_API_URL=https://masslens-api.masslens.workers.dev/estimate \
  --dart-define=MASSLENS_PRIVACY_URL=https://your-public-domain.example/privacy \
  --dart-define=ADMOB_ENABLED=true \
  --dart-define=ADMOB_USE_TEST_IDS=false \
  --dart-define=ADMOB_NATIVE_AD_UNIT_ID=ca-app-pub-7681170430097585/5319406676 \
  --dart-define=ADMOB_REWARDED_AD_UNIT_ID=ca-app-pub-7681170430097585/7055249463 \
  --dart-define=ADMOB_INTERSTITIAL_AD_UNIT_ID=ca-app-pub-7681170430097585/5742167797 \
  --dart-define=ADMOB_APP_OPEN_AD_UNIT_ID=ca-app-pub-7681170430097585/2932171620
```

Replace the example privacy URL with the final public HTTPS policy before
building. Release validation must fail when `MASSLENS_PRIVACY_URL` is missing,
not HTTPS, or still uses the example host. Use that same URL in the Google Play
listing and confirm that Settings opens it on a physical device.

For a safe physical-device onboarding check, keep Google test ads and force the
new onboarding without deleting local history:

```bash
flutter run \
  --dart-define=MASSLENS_API_URL=https://masslens-api.masslens.workers.dev/estimate \
  --dart-define=ADMOB_ENABLED=true \
  --dart-define=ADMOB_USE_TEST_IDS=true \
  --dart-define=MASSLENS_FORCE_ONBOARDING=true
```

`MASSLENS_FORCE_ONBOARDING` is ignored by release builds.

Never use live ads during development. Test EEA consent and privacy choices,
reward acknowledgement/deduplication, unavailable inventory, every placement,
interstitial cadence/cooldown, and four-hour app-open suppression on physical
devices.

`HISTORY_INTERSTITIAL_EVERY` defaults to `2`. Keep the global interstitial
cooldown at three minutes or longer: added placements create more eligible
natural breaks, not permission to show repeated full-screen ads. Help,
settings, camera capture, analysis, result reading, and app exit stay free of
interstitials.

Before release, use Google's rewarded test unit and then the production rewarded
unit on a registered test device. Each completed ad must add exactly one scan;
replaying the same attempt ID must grant zero additional scans.

## Google Play lifetime unlock

Play Console (manual):

1. Create and activate one non-consumable one-time product:
   `masslens_lifetime_unlimited`. Set the regular lifetime price you want.
   The new app has no gift wheel or discounted products. The shared backend
   retains legacy product handling only for older-package purchases/refunds.
2. Add license testers under Settings → License testing.
3. Link a Google Cloud project to Play Console, create a service account with
   **View financial data** and **Manage orders**, download JSON, and store it as
   `PLAY_SERVICE_ACCOUNT_JSON` via `wrangler secret put`.
4. Configure Real-time developer notifications (Pub/Sub) to POST void events to
   `https://masslens-api.masslens.workers.dev/billing/rtdn`.
5. Declare in-app purchases on the Play listing and update Data safety for
   purchase-token verification records.

Worker endpoints:

- `POST /billing/verify` — client sends `{productId, purchaseToken}` after Play
  purchase or restore; Worker verifies with Android Publisher API and upserts
  `lifetime_entitlements`.
- `POST /billing/rtdn` — Pub/Sub push for void/refund notifications; revokes
  lifetime access.

Worker vars (see `worker/wrangler.jsonc`):

- `PLAY_PACKAGE_NAME=com.lilai.aivirtual`
- `PLAY_LIFETIME_PRODUCT_ID=masslens_lifetime_unlimited`
- `PLAY_LIFETIME_PRODUCT_IDS=masslens_lifetime_unlimited,masslens_lifetime_off_30,…,masslens_lifetime_off_90`

Release checks on a license-tester device:

- buy lifetime → unlimited scans, ads hidden, access card shows “Unlimited scans”;
- restore on reinstall rebinds the same Google account purchase;
- refund/void via RTDN removes lifetime access and ads return for free users.

## Food Scale release compliance

Before submitting the Food & macros release:

- complete the Google Play Health declaration and select **Nutrition and Weight
  Management**;
- update the privacy policy and Data safety answers for photo processing by the
  Worker/OpenAI, normalized USDA text queries, local history, and deletion;
- show “not a medical device or dietary advice” in the Food Scale result and the
  store listing;
- verify that correcting or removing a food recalculates the displayed totals,
  while an unmatched food is clearly weight-only and the meal total says
  “partial”;
- test camera, gallery, optional second view, privacy link, consent, rewarded
  credit/refund behavior, history, and sharing on a physical Android device;
- pass both private evaluation gates in `eval/README.md` and retain the results
  with the release evidence.

## Seven-day margin check

Paid-event revenue and AI cost are stored in micro-USD. Query D1 weekly:

```sql
SELECT metric, SUM(event_count) AS events,
       SUM(value_micros) / 1000000.0 AS usd
FROM daily_metrics
WHERE day >= date('now', '-6 days')
  AND (metric IN ('ai_cost', 'scan_completed', 'scan_refunded')
       OR (metric = 'ad_revenue' AND dimension LIKE 'rewarded:%'))
GROUP BY metric;
```

Target rewarded-ad revenue per completed scan at or above 2× direct OpenAI
cost. Do not claim profitability until real fill rate, eCPM, consent rate,
latency, and the private model evaluation are measured.


## New photo-estimates package (September 2026)

The new app uses `com.lilai.masslens.photoestimates`. Keep
`PLAY_PACKAGE_NAME=com.lilai.aivirtual` for installed legacy clients and set
`PLAY_ADDITIONAL_PACKAGE_NAMES=com.lilai.masslens.photoestimates`. The new client
includes its package in purchase verification; the server validates it against
the allowlist and asks Google Play to verify that package. Recreate products and
review AdMob configuration for the new listing. See `play-store/RELAUNCH.md`.
