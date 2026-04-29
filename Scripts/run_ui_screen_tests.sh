#!/bin/zsh
set -euo pipefail

DEVICE_NAME="${1:-iPhone 16}"
ONLY_TESTING="${2:-${UITEST_ONLY_TESTING:-}}"
SCREENSHOT_DIR="${UITEST_SCREENSHOT_DIR:-/tmp/hidden_adventures_ui_tests}"
RESULT_BUNDLE="${UITEST_RESULT_BUNDLE:-/tmp/HiddenAdventuresUITests.xcresult}"
DERIVED_DATA_DIR="${UITEST_DERIVED_DATA_DIR:-/tmp/HiddenAdventuresUITestsDerivedData}"
SCHEME="${UITEST_SCHEME:-HiddenAdventures-LocalAutomation}"
TEST_PLAN="${UITEST_TEST_PLAN:-LocalDev}"
DESTINATION="${UITEST_DESTINATION:-platform=iOS Simulator,name=$DEVICE_NAME}"

if [[ "${UITEST_SKIP_SIMCTL_PREP:-0}" != "1" ]]; then
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
fi

if [[ -n "$DERIVED_DATA_DIR" ]]; then
  rm -rf "$DERIVED_DATA_DIR"
fi

rm -rf "$SCREENSHOT_DIR" "$RESULT_BUNDLE"
mkdir -p "$SCREENSHOT_DIR"

TEST_ARGS=(
  -project HiddenAdventures.xcodeproj
  -scheme "$SCHEME"
  -destination "$DESTINATION"
  -testPlan "$TEST_PLAN"
  -resultBundlePath "$RESULT_BUNDLE"
)

if [[ -n "$DERIVED_DATA_DIR" ]]; then
  TEST_ARGS+=(-derivedDataPath "$DERIVED_DATA_DIR")
fi

if [[ -n "$ONLY_TESTING" ]]; then
  TEST_ARGS+=(-only-testing:"$ONLY_TESTING")
fi

UITEST_SCREENSHOT_DIR="$SCREENSHOT_DIR" \
xcodebuild "${TEST_ARGS[@]}" test

echo "UI test screenshots saved to: $SCREENSHOT_DIR"
echo "Result bundle saved to: $RESULT_BUNDLE"
echo "Derived data used: $DERIVED_DATA_DIR"
echo "Scheme used: $SCHEME"
echo "Test plan used: $TEST_PLAN"
echo "Destination used: $DESTINATION"
echo "Simulator prep skipped: ${UITEST_SKIP_SIMCTL_PREP:-0}"
if [[ -n "$ONLY_TESTING" ]]; then
  echo "Only testing: $ONLY_TESTING"
fi
