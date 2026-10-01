#!/bin/zsh
# MassLens - verify the free barcode scanner feature.
# Runs pub get, l10n generation, analyze, all Flutter tests, Worker tests and a
# debug APK build. Full output goes to barcode_verify_log.txt.
cd "$(dirname "$0")"
export PATH="$HOME/flutter/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
LOG=barcode_verify_log.txt
: > $LOG
step() {
  local name=$1; shift
  echo "== $name" | tee -a $LOG
  "$@" >> $LOG 2>&1
  local code=$?
  echo "== $name exit $code" | tee -a $LOG
  return $code
}
step "pub get" flutter pub get
step "gen-l10n" flutter gen-l10n
step "format new files" dart format lib/features/barcode test/barcode_test.dart \
  lib/features/nutrition/presentation/nutrition_screen.dart \
  lib/features/nutrition/presentation/nutrition_scan_cta.dart
step "analyze" flutter analyze
step "golden refresh" flutter test --dart-define=ADMOB_ENABLED=false --update-goldens test/onboarding_golden_test.dart
step "flutter tests" flutter test --dart-define=ADMOB_ENABLED=false
step "worker tests" zsh -c "cd worker && npm run check"
step "debug apk" flutter build apk --debug
echo "VERIFY FINISHED" | tee -a $LOG
grep "exit" $LOG
read -k 1 "?Press any key to close..."
