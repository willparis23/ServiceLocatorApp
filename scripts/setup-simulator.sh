#!/usr/bin/env bash
# Prepares the booted iOS Simulator for running the UI test suite.
#
# Sets the simulator location to Acworth, GA and resets the app's
# location privacy permissions so the system permissions alert
# appears on first launch.

set -e

BUNDLE_ID="com.example.ServiceLocator"
ACWORTH_LAT="34.0662"
ACWORTH_LON="-84.6769"

echo "Setting simulator location to Acworth, GA ($ACWORTH_LAT, $ACWORTH_LON)..."
xcrun simctl location booted set "$ACWORTH_LAT,$ACWORTH_LON"

echo "Resetting location privacy for $BUNDLE_ID..."
xcrun simctl privacy booted reset location "$BUNDLE_ID" || true

echo "Done. Ready to run tests."
