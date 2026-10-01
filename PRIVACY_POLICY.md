# MassLens Privacy Policy

Last updated: September 21, 2026

> Release template: replace the bracketed contact details, review it with the
> app owner, and publish it at the HTTPS URL supplied through
> `MASSLENS_PRIVACY_URL` before releasing the food-estimate feature.

MassLens provides approximate AI photo estimates for objects and food plates. Food results are
approximate and are not a medical device, medical advice, or dietary advice.

## Photos and AI analysis

When you start an AI scan, MassLens rotates and resizes the selected photo,
re-encodes it as JPEG, and removes its embedded metadata before upload. The
photo and optional second angle are sent through the MassLens Cloudflare Worker
to OpenAI solely to identify visible content and estimate weight ranges. OpenAI
is instructed not to retain the response (`store: false`). Photos are not sent
to USDA FoodData Central and are not stored in the Worker database.

For Food & macros scans, OpenAI returns food labels, approximate weights, and
generic English food-search terms. It does not supply calorie or macro values.
The Worker normalizes those search terms and sends only the text queries to USDA
FoodData Central. USDA does not receive photos, the app installation identifier,
or saved history.

## Barcode lookups

The free barcode scanner decodes a product barcode from the camera preview on
your device; no image is uploaded or stored. The app sends only the barcode
number to Open Food Facts to fetch the product's label nutrition. If the
product is not found there, the app sends the barcode number with the app
installation identifier to the MassLens Cloudflare Worker, which searches USDA
FoodData Central branded foods using the barcode number only. Barcode lookups
do not use AI or scan credits. Like any website, Open Food Facts receives your
IP address with the request. Products you log are remembered on your device as
"Recent products" and are cleared with the nutrition diary in Settings.

## Local history and temporary service data

Results are saved only when you choose Save. Saved result data and a private
image copy remain in the app's local storage on your device. You can delete one
saved result from its detail screen or delete all saved history in Settings.
The optional Nutrition & Trends diary is also stored only on your device. It
contains entries you add manually or explicitly copy from a saved food-estimate
result; entries are never added automatically or sent to MassLens, OpenAI, or
USDA. Nutrition entries can be edited, deleted individually, or cleared
separately in Settings without deleting saved scans.
Uninstalling the app also removes its local data, subject to Android backup
settings controlled by you or the device.

MassLens transmits device or other IDs off the device. A random
app-installation identifier—not an IMEI, serial number, or hardware MAC—is sent
to the MassLens Cloudflare service to manage scan credits, rewarded-ad credits,
lifetime purchase verification, abuse prevention, and idempotent retries. The Worker
hashes that identifier before database use and may store Google Play purchase
tokens needed to grant or revoke lifetime access. A completed result JSON—not its
photo—may be retained for up to 24 hours so a network retry can return the same
result without charging or analyzing the photo again. Anonymous daily aggregate
counts include completed Object and Food Plate scans; no user-level nutrition
diary or nutrition analytics are created.

## In-app purchases

MassLens offers an optional one-time Google Play product that unlocks unlimited
scans and removes ads for the purchasing Google account on supported devices.
Google Play processes the payment. MassLens verifies the purchase token with
Google and stores a hashed installation identifier plus the purchase token to
grant, restore, or revoke access. Refunds and voids are handled through Google
Play and remove lifetime access when notified.

## Advertising and consent

MassLens uses Google Mobile Ads (AdMob) for free users to provide rewarded scan
credits and may display other ads. Lifetime purchasers do not see ads. Google
and its advertising partners collect and share device or other IDs, including
the Android advertising ID and App Set ID, plus IP address (used to estimate
approximate location), diagnostics, consent choices, and ad interactions, for
advertising, analytics, and fraud prevention, under their own policies. Where
required, MassLens asks for consent and provides an Ad privacy choices control
in Settings. You can also reset or delete the advertising ID in Android settings.

## Data sharing and purpose

MassLens shares data only with service providers needed for the functions above:
Cloudflare for the API, OpenAI for photo analysis, USDA FoodData Central for
generic nutrition searches and barcode fallbacks, Open Food Facts for barcode
lookups made directly from the app, and Google for advertising and consent. Data is not
sold. Processing is limited to providing scans, calculating USDA-based results,
maintaining scan credits, preventing abuse, measuring anonymous service health,
and supporting ads.

## Your choices

You may avoid AI processing by using only the manual nutrition diary,
decline to save a result, remove saved history in Settings, change available ad
privacy choices, clear the separate local nutrition diary, or uninstall the
app. For access, deletion, or privacy questions that cannot be handled
on-device, contact [PRIVACY CONTACT EMAIL]. Include no sensitive health
information or photos in your request.

## Children, security, and changes

MassLens is not directed to children under the minimum age required in their
country. Reasonable technical and organizational safeguards are used, but no
internet transmission is completely secure. This policy may be updated when the
app or its providers change; the date above will be revised.

App owner: [LEGAL NAME / COMPANY]\
Privacy contact: [PRIVACY CONTACT EMAIL]\
Country: [COUNTRY]
