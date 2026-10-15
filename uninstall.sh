#!/bin/bash

launchctl unload ~/Library/LaunchAgents/com.local.BatteryTime.plist 2>/dev/null || true
rm -f ~/Library/LaunchAgents/com.local.BatteryTime.plist
pkill -x BatteryTime 2>/dev/null || true
rm -rf /Applications/BatteryTime.app

echo "Uninstalled."
