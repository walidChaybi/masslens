#!/bin/zsh
# MassLens: Photo Estimates - build the signed Play Store bundle (.aab).
set -euo pipefail
cd "$(dirname "$0")"
export PATH="$HOME/flutter/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //; s/+.*//')

# Run flutter analyze and flutter test before publishing.
: > release_log.txt
echo "== Building release bundle $VERSION ==" | tee -a release_log.txt
setopt pipefail
flutter build appbundle --release \
  --dart-define=MASSLENS_API_URL=https://masslens-api.masslens.workers.dev/estimate \
  --dart-define=MASSLENS_PRIVACY_URL=https://masslens-api.masslens.workers.dev/privacy \
  --dart-define=ADMOB_ENABLED=true \
  --dart-define=ADMOB_USE_TEST_IDS=false \
  --dart-define=ADMOB_NATIVE_AD_UNIT_ID=ca-app-pub-7681170430097585/5319406676 \
  --dart-define=ADMOB_REWARDED_AD_UNIT_ID=ca-app-pub-7681170430097585/7055249463 \
  --dart-define=ADMOB_INTERSTITIAL_AD_UNIT_ID=ca-app-pub-7681170430097585/5742167797 \
  --dart-define=ADMOB_APP_OPEN_AD_UNIT_ID=ca-app-pub-7681170430097585/2932171620 \
  2>&1 | tee -a release_log.txt
# Only copy after Flutter exits successfully; never accept a stale bundle.
cp build/app/outputs/bundle/release/app-release.aab "MassLens-Photo-Estimates-$VERSION-play-signed.aab"
echo "RELEASE OK: MassLens-Photo-Estimates-$VERSION-play-signed.aab" | tee -a release_log.txt
