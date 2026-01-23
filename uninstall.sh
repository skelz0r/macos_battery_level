#!/bin/bash

launchctl unload ~/Library/LaunchAgents/com.local.BatteryTime.plist 2>/dev/null || true
rm -f ~/Library/LaunchAgents/com.local.BatteryTime.plist
rm -rf /Applications/BatteryTime.app
pkill -f BatteryTime 2>/dev/null || true

echo "Uninstalled."
