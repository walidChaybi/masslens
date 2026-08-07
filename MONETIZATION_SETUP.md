# MassLens monetization setup

MassLens uses direct Google Play Billing for two repurchasable, one-time scan
packs. There are no subscriptions, renewals, or recurring charges. The Worker
verifies each purchase, grants credits exactly once in D1, and consumes the
Google Play transaction so the same pack can be bought again. RevenueCat is not
used.

Production remains deliberately safe until setup is complete:

- `BILLING_ENFORCED` is `false`, so the live scanner is not quota-blocked.
- `ADMOB_ENABLED` defaults to `false`.
- the real AdMob App ID is configured, but ad requests still use Google's
  official test IDs by default.
- no Google or OpenAI private key is stored in the Flutter application.
- purchased credits are currently tied to the app installation; do not enable
  live paid packs until durable user accounts are added or that limitation is
  explicitly accepted and disclosed.

## 1. Create the Play one-time products

In the existing Play Console listing for `com.lilai.aivirtual`, open
**Monetize with Play → Products → One-time products** and create these exact,
immutable product IDs:

| Product ID | Display name | Credits | Proposed launch price |
| --- | --- | ---: | ---: |
| `masslens_100_scans` | MassLens Basic — 100 scans | 100 | $4.99 / €5.99 |
| `masslens_500_scans` | MassLens Max — 500 scans | 500 | $19.99 / €23.99 |

For each product, create one purchase option with ID `standard`:

- purchase type: **Buy**;
- product classification: **Service**;
- quantity and multi-purchase limits: **off**;
- regional availability and price: configured, then **Activate**;
- backwards compatibility: enabled for the standard Buy option if Play shows
  the setting.

The app reads localized prices directly from Google Play. The Max pack is about
20% cheaper per scan than buying five Basic packs. Purchased scans do not reset
or expire.

Use `testers-community@googlegroups.com` for the closed test track. For
**Settings → License testing**, use only private, controlled Google accounts.
Adding the community group there would let every group member make no-charge
license-test purchases.

## 2. Give the Worker Play verification access

1. In Google Cloud, enable **Google Play Android Developer API**.
2. Create a dedicated service account, for example
   `masslens-play-verifier`.
3. Add its email as a Play Console user for the MassLens app.
4. Grant **View financial data, orders, and cancellation survey responses**
   and **Manage orders and subscriptions**. Google uses the latter permission
   name for purchase-management APIs even though MassLens has no subscription.
5. Create and download its JSON key. Do not add that JSON file to this repo.
6. Store the entire JSON as one encrypted Worker secret:

```bash
cd worker
npx wrangler secret put GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
```

The Worker checks Google Play's `ProductPurchaseV2` state, product ID, quantity,
purchase token, and obfuscated MassLens owner. It atomically grants the server
allowlisted 100 or 500 credits, then consumes the Play transaction. Duplicate
callbacks and concurrent retries cannot grant the same token twice.

## 3. Apply the D1 credit-ledger migration

The D1 database is already configured in `worker/wrangler.jsonc`. Refresh
Wrangler login first if D1 returns authentication code `10000`:

```bash
cd worker
npx wrangler login
```

Apply all checked-in migrations and verify the Worker:

```bash
npx wrangler d1 migrations apply masslens-billing --remote
npm run check
```

Migration `0002_consumable_credits.sql` adds the persistent credit wallet,
purchase-token ledger, idempotent grant trigger, and void/refund debt handling.
The old subscription table from migration `0001` is intentionally preserved so
deployed data is not destructively removed.

Keep `BILLING_ENFORCED` set to `false` during license testing. Once both products
verify, consume successfully, can be repurchased, and return the correct wallet
balance from `/access`, change it to `true` and deploy again.

## 4. Configure refunds and purchase notifications

Before production, enable Google Play Real-time Developer Notifications for
one-time products and route authenticated Pub/Sub pushes to a secure Worker
endpoint. Handle `ONE_TIME_PRODUCT_CANCELED` and voided-purchase notifications,
then reconcile periodically with the Voided Purchases API. The D1 schema can
record a void and subtract the full grant, including a negative balance when
refunded credits were already used.

This notification endpoint and authenticated account recovery remain release
blockers; `BILLING_ENFORCED` must stay off until they are complete.

## 5. Create AdMob units

MassLens uses only these launch formats:

- Native: `ca-app-pub-7681170430097585/1035038854`;
- Rewarded, reward amount `1`, reward item `scan`:
  `ca-app-pub-7681170430097585/3756662851`.

Interstitial, Banner, App Open, and Rewarded Interstitial are disabled.

For the Rewarded unit, enable server-side verification and set:

```text
https://masslens-api.masslens.workers.dev/admob/reward
```

The Worker verifies Google's signature, timestamp, ad unit, transaction ID, and
installation ID. Duplicate reward callbacks cannot add multiple scans.

The non-secret AdMob App ID is in `android/gradle.properties`:

```properties
ADMOB_APP_ID=ca-app-pub-7681170430097585~3976154706
```

## 6. Build a real-ads test release

MassLens will update the existing `com.lilai.aivirtual` / VirtuAI Play listing.
Before building the upload AAB, change the build number in `pubspec.yaml` from
the current `+2` to a number strictly greater than the listing's highest
existing version code. The exact existing number still needs to be copied from
Play Console.

Keep Google's test IDs enabled until ad layouts and consent are verified:

```bash
flutter run \
  --dart-define=ESTIMATE_ENGINE=cloudflare \
  --dart-define=MASSLENS_API_URL=https://masslens-api.masslens.workers.dev/estimate \
  --dart-define=ADMOB_ENABLED=true
```

For the eventual production build, explicitly disable test IDs:

```bash
flutter build appbundle --release \
  --dart-define=ESTIMATE_ENGINE=cloudflare \
  --dart-define=MASSLENS_API_URL=https://masslens-api.masslens.workers.dev/estimate \
  --dart-define=ADMOB_ENABLED=true \
  --dart-define=ADMOB_USE_TEST_IDS=false \
  --dart-define=ADMOB_NATIVE_AD_UNIT_ID=ca-app-pub-7681170430097585/1035038854 \
  --dart-define=ADMOB_REWARDED_AD_UNIT_ID=ca-app-pub-7681170430097585/3756662851
```

Never publish a release with Google's test ad IDs. Ads are disabled while the
user has purchased credits and can resume when that paid balance reaches zero.

## 7. Final test matrix

- New installation receives the free scan allowance.
- After free and bonus scans are exhausted, a scan opens the pack sheet.
- Rewarded ad adds exactly one scan, including after a duplicate callback.
- Basic grants exactly 100 credits; Max grants exactly 500.
- Buying Basic twice yields 200 credits; Basic plus Max yields 600.
- Submitting the same token twice grants once; another installation cannot
  claim it.
- Pending, canceled, mismatched, multi-quantity, and consumed unknown purchases
  grant nothing.
- Kill the app before verification, after the D1 grant, and before consumption;
  each retry recovers without credit loss or duplication.
- Each product is purchasable again after Google confirms consumption.
- Free scans are spent first, then rewarded scans, then purchased credits.
- Purchased credits do not reset when the free allowance resets.
- Refund and chargeback notifications void the grant exactly once.
- Test EEA consent and **Ad privacy choices** in Settings.
- Confirm no customer-facing UI contains renewal, subscription, or `/mo` copy.
