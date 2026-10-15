#!/bin/bash
set -e

APP_NAME="BatteryTime"
VERSION="${VERSION:-0.0.0}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"

rm -rf "$APP_NAME.app"

swift build -c release --product "$APP_NAME"
BIN_DIR="$(swift build -c release --show-bin-path)"

mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"

cp Info.plist "$APP_NAME.app/Contents/"
plutil -insert CFBundleShortVersionString -string "$VERSION" "$APP_NAME.app/Contents/Info.plist"
plutil -insert CFBundleVersion -string "$VERSION" "$APP_NAME.app/Contents/Info.plist"
cp "$BIN_DIR/$APP_NAME" "$APP_NAME.app/Contents/MacOS/$APP_NAME"

if [ "$SIGN_IDENTITY" = "-" ]; then
    codesign --force --sign - "$APP_NAME.app"
else
    codesign --force --sign "$SIGN_IDENTITY" --options runtime --timestamp "$APP_NAME.app"
fi

echo "Built $APP_NAME.app $VERSION"
