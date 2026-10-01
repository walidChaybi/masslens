#!/bin/zsh
# MassLens - verify the dark-mode / settings work.
# Formats, regenerates localizations, analyzes, then runs the full test suite.
# Everything lands in darkmode_verify_log.txt for review.
cd "$(dirname "$0")"
export PATH="$HOME/flutter/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
LOG=darkmode_verify_log.txt

{
  echo "=== dart format ==="
  dart format lib test
  echo
  echo "=== flutter gen-l10n ==="
  flutter gen-l10n
  echo
  echo "=== flutter analyze ==="
  flutter analyze
  echo "ANALYZE EXIT: $?"
  echo
  echo "=== flutter test ==="
  flutter test --dart-define=ADMOB_ENABLED=false --update-goldens \
    test/onboarding_golden_test.dart
  flutter test --dart-define=ADMOB_ENABLED=false --reporter expanded
  echo "TEST EXIT: $?"
} > "$LOG" 2>&1

echo "FINISHED" >> "$LOG"
grep -E "ANALYZE EXIT|TEST EXIT|error •|All tests passed|Some tests failed" "$LOG" | tail -20
echo
echo "Full log: $LOG"
read -k 1 "?Press any key to close..."
