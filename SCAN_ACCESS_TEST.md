# Two-scan rewarded access

Local implementation only; it has not been deployed or released.

- Each installation has two free AI scans shared by object and food modes. Previous starter usage counts toward the two; an existing user who used one receives one more.
- After the free scans, each completed rewarded ad adds one scan. The existing cooldown and three-credit balance cap remain.
- Failed qualifying scans are refunded. Historical purchased and earned credits remain usable.
- Lifetime access remains ad-free and has no daily scan cap. Service rate limits and the overall AI cost ceiling still apply.
- AI Scan remains the main screen, and the Bluetooth/demo scale remains in the navigation menu.

The app and Worker must both be released to change users' live experience. Verify the rewarded ad on a licensed test device before release.

Validation: 133 Flutter tests, 60 Worker tests, onboarding screenshots, and Flutter analysis passed. A live ad, purchase, and store release have not been tested here.
