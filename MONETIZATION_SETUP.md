# Ads-only production setup

MassLens has three lifetime starter scans and ad-funded rewarded scans. Historical
billing tables stay inert for safe migration. The production audit found no old
purchases; migrated bonus and support balances remain as `legacyScans` until
used and stay part of the ads-only experience. No Play Billing dependency or
purchase endpoint remains.

## Worker and D1

```bash
cd worker
npm install
npx wrangler login
npx wrangler d1 migrations apply masslens-billing --remote
npx wrangler secret put OPENAI_API_KEY
npm run check
npx wrangler deploy
curl -f https://masslens-api.masslens.workers.dev/ready
```

`/ready` fails unless the OpenAI secret, D1 binding, enforced wallet, and
`gpt-5-nano` are configured. Migration 0003 creates the ads wallet, idempotent
request/result cache, and daily metrics without deleting old ledgers. Migration
0004 adds durable reward-attempt reconciliation and an audited support-credit
ledger. Migration 0005 adds the separate idempotent mobile-SDK reward ledger and
server cooldown lease; it does not create signed SSV transactions. The default
AI cost ceiling is $5/day
(`MAX_DAILY_AI_COST_MICROS=5000000`); tune it in Worker variables.

## AdMob

Create/verify four Android units:

- native, used on scale, AI home, and after history result two;
- rewarded with reward amount `1` and reward item exactly `scan`;
- interstitial, shown once during the first-open onboarding transition, at
  drawer transitions into AI Scan or Digital Scale, and after every second
  completed scan only after result close. All uses share the server-controlled
  cooldown;
- app-open, eligible only after four hours in background and after onboarding.

Production IDs:

- native: `ca-app-pub-7681170430097585/1035038854`;
- rewarded: `ca-app-pub-7681170430097585/3756662851`;
- regular interstitial: `ca-app-pub-7681170430097585/5269089498`;
- app-open: `ca-app-pub-7681170430097585/3116075891`.

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

Debug builds use Google's test IDs. The release app fails fast if ads are
disabled, test IDs are enabled, or any live unit is missing. Put the live AdMob
app ID in `android/gradle.properties` as `ADMOB_APP_ID=ca-app-pub-…~…`, then
build production:

```bash
flutter build appbundle --release \
  --dart-define=MASSLENS_API_URL=https://masslens-api.masslens.workers.dev/estimate \
  --dart-define=ADMOB_ENABLED=true \
  --dart-define=ADMOB_USE_TEST_IDS=false \
  --dart-define=ADMOB_NATIVE_AD_UNIT_ID=ca-app-pub-7681170430097585/1035038854 \
  --dart-define=ADMOB_REWARDED_AD_UNIT_ID=ca-app-pub-7681170430097585/3756662851 \
  --dart-define=ADMOB_INTERSTITIAL_AD_UNIT_ID=ca-app-pub-7681170430097585/5269089498 \
  --dart-define=ADMOB_APP_OPEN_AD_UNIT_ID=ca-app-pub-7681170430097585/3116075891
```

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

Before release, use Google's rewarded test unit and then the production rewarded
unit on a registered test device. Each completed ad must add exactly one scan;
replaying the same attempt ID must grant zero additional scans.

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
