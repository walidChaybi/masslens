# MassLens monetization setup

The app code is complete for direct Google Play Billing, server-side purchase
verification, scan quotas, AdMob consent, native/interstitial ads, and verified
rewarded-ad credits. RevenueCat is not used.

Production remains deliberately safe until setup is complete:

- `BILLING_ENFORCED` is `false`, so the live scanner is not quota-blocked.
- `ADMOB_ENABLED` defaults to `false`.
- the Android manifest uses Google's official test AdMob App ID by default.
- no Google or OpenAI private key is stored in the Flutter application.

## 1. Create the Play subscriptions

In the MassLens Play Console app (`com.lilai.aivirtual`), open **Monetize with
Play → Products → Subscriptions** and create these exact product IDs:

| Product ID | Display name | Monthly allowance |
| --- | --- | ---: |
| `masslens_50_monthly` | MassLens Basic | 50 scans |
| `masslens_100_monthly` | MassLens Plus | 100 scans |
| `masslens_max_monthly` | MassLens Max | 300 scans |

Create and activate one auto-renewing monthly base plan for each product. Set
prices in Play Console; the app reads localized prices directly from Google
Play. Add your tester Gmail account under **Settings → License testing**.

The app supports restoration and switching between active plans. Play handles
the checkout, renewal, cancellation, regional tax, and payment method UI.

## 2. Give the Worker Play verification access

1. In Google Cloud, enable **Google Play Android Developer API**.
2. Create a dedicated service account, for example
   `masslens-play-verifier`.
3. Add its email as a Play Console user for the MassLens app.
4. Grant the minimum purchase API permission: **View financial data, orders,
   and cancellation survey responses**. Add **Manage orders and subscriptions**
   only if the console requires it for acknowledgement in your account.
5. Create and download its JSON key. Do not add that JSON file to this repo.
6. Store the entire JSON as one encrypted Worker secret:

```bash
cd worker
npx wrangler secret put GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
```

The Worker verifies the package, product ID, purchase token, subscription state,
expiry, and ownership before granting scans. It also acknowledges verified
purchases and refreshes stored subscriptions against Google at least every six
hours of active use.

## 3. Create and migrate Cloudflare D1

Refresh Wrangler login first if D1 returns authentication code `10000`:

```bash
cd worker
npx wrangler login
```

Create the database:

```bash
npx wrangler d1 create masslens-billing
```

Copy Wrangler's returned `database_id` into `worker/wrangler.jsonc`:

```jsonc
"d1_databases": [
  {
    "binding": "DB",
    "database_name": "masslens-billing",
    "database_id": "PASTE-DATABASE-ID"
  }
]
```

Apply the checked-in schema and deploy:

```bash
npx wrangler d1 migrations apply masslens-billing --remote
npm run check
npm run deploy
```

Keep `BILLING_ENFORCED` set to `false` during the first Play test. Once a test
purchase verifies and `/access` returns the paid plan, change it to `true` in
`worker/wrangler.jsonc` and deploy again.

## 4. Create AdMob units

Add MassLens to AdMob using Android package `com.lilai.aivirtual`. Create:

- one Native ad unit for the home screen;
- one Interstitial ad unit, shown only after every third completed free scan;
- one Rewarded ad unit with reward amount `1` and reward item `scan`.

For the rewarded unit, enable server-side verification and set the callback URL
to:

```text
https://masslens-api.masslens.workers.dev/admob/reward
```

The Worker verifies Google's ECDSA signature, timestamp, ad unit, transaction
ID, and installation ID. A database uniqueness constraint prevents callback
replays from granting duplicate scans.

When AdMob's setup screen tests the callback, provide a sample user ID matching
the app format, for example `masslensRewardTestClient01`.

Put the rewarded unit's full ID in `worker/wrangler.jsonc` as
`ADMOB_REWARDED_AD_UNIT_ID` before deploying. Put the non-secret AdMob App ID in
`android/gradle.properties`:

```properties
ADMOB_APP_ID=ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy
```

## 5. Build a real-ads test release

Keep test IDs enabled until the layouts and consent flow are verified. The
default build uses Google's test IDs and cannot generate revenue:

```bash
flutter run \
  --dart-define=ESTIMATE_ENGINE=cloudflare \
  --dart-define=MASSLENS_API_URL=https://masslens-api.masslens.workers.dev/estimate \
  --dart-define=ADMOB_ENABLED=true
```

For a production build, provide all three real ad unit IDs and explicitly turn
off test IDs:

```bash
flutter build appbundle --release \
  --dart-define=ESTIMATE_ENGINE=cloudflare \
  --dart-define=MASSLENS_API_URL=https://masslens-api.masslens.workers.dev/estimate \
  --dart-define=ADMOB_ENABLED=true \
  --dart-define=ADMOB_USE_TEST_IDS=false \
  --dart-define=ADMOB_NATIVE_AD_UNIT_ID=ca-app-pub-.../... \
  --dart-define=ADMOB_INTERSTITIAL_AD_UNIT_ID=ca-app-pub-.../... \
  --dart-define=ADMOB_REWARDED_AD_UNIT_ID=ca-app-pub-.../...
```

Never publish a release with Google's test ad IDs. Paid users receive no ads;
free users see ads only after UMP says ads can legally be requested.

## 6. Final test matrix

- New free user receives three monthly scans.
- Fourth scan opens the paywall.
- Rewarded ad adds exactly one scan, including after a duplicate callback.
- Purchase each plan with a Play license tester and verify 50/100/300 allowance.
- Restore the subscription after reinstalling with the same Play account.
- Upgrade and downgrade between plans.
- Cancel in Play and confirm access remains until the paid period ends.
- Confirm paid users never load native, interstitial, or rewarded ads.
- Test EEA consent and the **Ad privacy choices** row in Settings.
