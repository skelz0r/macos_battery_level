#!/bin/bash
set -e

./build.sh

pkill -x BatteryTime || true
rm -rf /Applications/BatteryTime.app
cp -r BatteryTime.app /Applications/

mkdir -p ~/Library/LaunchAgents

cat > ~/Library/LaunchAgents/com.local.BatteryTime.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.local.BatteryTime</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/BatteryTime.app/Contents/MacOS/BatteryTime</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

launchctl unload ~/Library/LaunchAgents/com.local.BatteryTime.plist 2>/dev/null || true
launchctl load ~/Library/LaunchAgents/com.local.BatteryTime.plist

echo "Installed. BatteryTime will start at login."
