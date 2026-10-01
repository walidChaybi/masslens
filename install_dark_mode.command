#!/bin/zsh
# MassLens - check the dark-mode work, then build and install the debug app on
# the Android phone plugged in by USB.
#
# Analysis runs before the build: a compile error shows up in seconds instead of
# after a five-minute APK build. Everything is logged to install_darkmode_log.txt.
cd "$(dirname "$0")"
setopt pipefail
export PATH="$HOME/flutter/bin:$HOME/development/flutter/bin:$HOME/fvm/default/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
LOG=install_darkmode_log.txt
: > "$LOG"

say() { print -r -- "$@" | tee -a "$LOG"; }
stop() { say ""; say "$1"; read -k 1 "?Press any key to close..."; exit 1; }

command -v flutter >/dev/null 2>&1 || \
  stop "Flutter was not found. Open Terminal and run: which flutter"

say "== Connected devices =="
flutter devices 2>&1 | tee -a "$LOG"

say ""
say "== Formatting, packages, localizations =="
dart format lib test 2>&1 | tail -3 | tee -a "$LOG"
flutter pub get 2>&1 | tail -4 | tee -a "$LOG"
flutter gen-l10n 2>&1 | tee -a "$LOG" || stop "gen-l10n failed. Send Claude the log."

say ""
say "== Analyzing =="
flutter analyze 2>&1 | tee -a "$LOG"
# Only real errors block the build; pre-existing lint hints do not.
if grep -q "error •" "$LOG"; then
  stop "ANALYZE FOUND ERRORS - nothing was built. Tell Claude and it will read the log."
fi
say "No compile errors."

say ""
say "== Building the debug app (a few minutes) =="
flutter build apk --debug \
  --dart-define=MASSLENS_API_URL=https://masslens-api.masslens.workers.dev/estimate \
  --dart-define=MASSLENS_PRIVACY_URL=https://masslens-api.masslens.workers.dev/privacy \
  2>&1 | tee -a "$LOG" || stop "BUILD FAILED - tell Claude and it will read the log."

say ""
say "== Installing on your phone =="
ADB="$(command -v adb || print -r -- "${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb")"
if [ -x "$ADB" ]; then
  # -r keeps your saved history and scan balance.
  "$ADB" install -r build/app/outputs/flutter-apk/app-debug.apk 2>&1 | tee -a "$LOG" \
    || stop "INSTALL FAILED - is the phone plugged in with USB debugging on?"
else
  flutter install --debug 2>&1 | tee -a "$LOG" \
    || stop "INSTALL FAILED - is the phone plugged in with USB debugging on?"
fi

say ""
say "DONE - open MassLens, then Settings > Appearance and pick Dark."
read -k 1 "?Press any key to close..."
