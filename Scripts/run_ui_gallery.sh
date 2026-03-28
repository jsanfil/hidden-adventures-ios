#!/bin/zsh
set -euo pipefail

DEVICE_NAME="${1:-iPhone 16}"
SCREENSHOT_DIR="${UITEST_SCREENSHOT_DIR:-/tmp/hidden_adventures_ui_tests}"
RESULT_BUNDLE="${UITEST_RESULT_BUNDLE:-/tmp/HiddenAdventuresUITests.xcresult}"

xcrun simctl boot "$DEVICE_NAME" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$DEVICE_NAME" -b
xcrun simctl ui "$DEVICE_NAME" appearance light || true
xcrun simctl status_bar "$DEVICE_NAME" override \
  --time 9:41 \
  --batteryState charged \
  --batteryLevel 100 \
  --wifiBars 3 \
  --cellularMode active \
  --cellularBars 4 >/dev/null 2>&1 || true

rm -rf "$SCREENSHOT_DIR" "$RESULT_BUNDLE"
mkdir -p "$SCREENSHOT_DIR"

UITEST_SCREENSHOT_DIR="$SCREENSHOT_DIR" \
xcodebuild \
  -project HiddenAdventures.xcodeproj \
  -scheme HiddenAdventures \
  -destination "platform=iOS Simulator,name=$DEVICE_NAME" \
  -resultBundlePath "$RESULT_BUNDLE" \
  test

echo "UI test screenshots saved to: $SCREENSHOT_DIR"
echo "Result bundle saved to: $RESULT_BUNDLE"
