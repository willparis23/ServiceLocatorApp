#!/usr/bin/env bash
# Prepares the booted iOS Simulator for running the UI test suite.
#
# Sets the simulator location to Acworth, GA and resets the app's
# location privacy permissions so the system permissions alert
# appears on first launch.

#!/usr/bin/env bash
set -e

SIM_NAME="iPhone 17 Pro"
BUNDLE_ID="com.example.ServiceLocator"
ACWORTH_LAT="34.0662"
ACWORTH_LON="-84.6769"

# Find the UDID for the named simulator
UDID=$(xcrun simctl list devices available -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
target = '$SIM_NAME'
for runtime, devices in data['devices'].items():
    for device in devices:
        if device['name'] == target and device.get('isAvailable', False):
            print(device['udid'])
            sys.exit(0)
sys.exit(1)
")

if [ -z "$UDID" ]; then
    echo "ERROR: Could not find available simulator named '$SIM_NAME'"
    xcrun simctl list devices available
    exit 1
fi

echo "Setting location for $SIM_NAME ($UDID)..."
xcrun simctl location "$UDID" set "$ACWORTH_LAT,$ACWORTH_LON"

echo "Granting location permission for $BUNDLE_ID..."
xcrun simctl privacy "$UDID" grant location "$BUNDLE_ID" || true

echo "Done."
