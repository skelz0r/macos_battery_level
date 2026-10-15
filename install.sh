#!/bin/bash
set -e

./build.sh

pkill -x BatteryTime || true
rm -rf /Applications/BatteryTime.app
cp -r BatteryTime.app /Applications/

if [ -f ~/Library/LaunchAgents/com.local.BatteryTime.plist ]; then
    launchctl unload ~/Library/LaunchAgents/com.local.BatteryTime.plist 2>/dev/null || true
    rm -f ~/Library/LaunchAgents/com.local.BatteryTime.plist
fi

open /Applications/BatteryTime.app

echo "Installed. Choose Open at Login in the panel to start it at login."
