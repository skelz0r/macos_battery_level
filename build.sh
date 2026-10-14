#!/bin/bash
set -e

APP_NAME="BatteryTime"

rm -rf "$APP_NAME.app"

swift build -c release --product "$APP_NAME"
BIN_DIR="$(swift build -c release --show-bin-path)"

mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"

cp Info.plist "$APP_NAME.app/Contents/"
cp "$BIN_DIR/$APP_NAME" "$APP_NAME.app/Contents/MacOS/$APP_NAME"

echo "Built $APP_NAME.app"
