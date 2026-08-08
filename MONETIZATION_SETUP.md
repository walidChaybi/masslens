# Ads-only production setup

MassLens has one lifetime starter scan and verified rewarded scans. Historical
billing tables stay inert for safe migration; any real old purchase balance is
preserved as ad-free `legacyScans` until used. No Play Billing dependency or
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

`/ready` fails unless the OpenAI secret, D1 binding, enforced wallet,
`gpt-5-nano`, and live rewarded unit are configured. Migration 0003 creates the
ads wallet, idempotent request/result cache, and daily metrics without deleting
old ledgers. The default AI cost ceiling is $5/day
(`MAX_DAILY_AI_COST_MICROS=5000000`); tune it in Worker variables.

## AdMob

Create/verify four Android units:

- native, used on scale, AI home, and after history result two;
- rewarded with reward amount `1`, reward item `scan`, and SSV callback
  `https://masslens-api.masslens.workers.dev/admob/reward`;
- interstitial, shown after every second completed scan only after result close;
- app-open, eligible only after four hours in background and after onboarding.

Debug builds use Google's test IDs. The release app fails fast if ads are
disabled, test IDs are enabled, or any live unit is missing. Build production:

```bash
flutter build appbundle --release \
  --dart-define=MASSLENS_API_URL=https://masslens-api.masslens.workers.dev/estimate \
  --dart-define=ADMOB_ENABLED=true \
  --dart-define=ADMOB_USE_TEST_IDS=false \
  --dart-define=ADMOB_NATIVE_AD_UNIT_ID=ca-app-pub-7681170430097585/1035038854 \
  --dart-define=ADMOB_REWARDED_AD_UNIT_ID=ca-app-pub-7681170430097585/3756662851 \
  --dart-define=ADMOB_INTERSTITIAL_AD_UNIT_ID=REPLACE_WITH_LIVE_ID \
  --dart-define=ADMOB_APP_OPEN_AD_UNIT_ID=ca-app-pub-7681170430097585/3116075891
```

Never use live ads during development. Test EEA consent and privacy choices,
reward SSV/deduplication, unavailable inventory, every placement, interstitial
cadence/cooldown, and four-hour app-open suppression on physical devices.

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
