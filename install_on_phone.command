#!/bin/zsh
# MassLens - build the debug app and install it on the Android phone plugged in by USB.
cd "$(dirname "$0")"
setopt pipefail
export PATH="$HOME/flutter/bin:$HOME/development/flutter/bin:$HOME/fvm/default/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter was not found on this Mac. Open Terminal and run: which flutter"
  read -k 1 "?Press any key to close..."; exit 1
fi

echo "== Connected devices =="
flutter devices
echo
echo "== Getting packages =="
flutter pub get || { read -k 1 "?Failed. Press any key to close..."; exit 1; }
echo
echo "== Building the app (this takes a few minutes) =="
flutter build apk --debug 2>&1 | tee build_log.txt || { read -k 1 "?Build failed - copy the errors above to Claude. Press any key to close..."; exit 1; }
echo
echo "== Installing on your phone =="
ADB="$(command -v adb || echo "${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb")"
if [ -x "$ADB" ]; then
  # -r keeps the app's data (history, scan balance) instead of uninstalling first.
  "$ADB" install -r build/app/outputs/flutter-apk/app-debug.apk 2>&1 | tee install_log.txt
else
  flutter install --debug 2>&1 | tee install_log.txt
fi || { read -k 1 "?Install failed - is the phone plugged in with USB debugging on? Press any key to close..."; exit 1; }
echo
echo "Done! Open MassLens on your phone."
read -k 1 "?Press any key to close..."
