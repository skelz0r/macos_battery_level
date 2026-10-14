#!/bin/bash
set -e

APP_NAME="BatteryTime"
BUILD_DIR="build"

rm -rf "$BUILD_DIR" "$APP_NAME.app"

mkdir -p "$BUILD_DIR"
mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"

cp Info.plist "$APP_NAME.app/Contents/"

swiftc -o "$APP_NAME.app/Contents/MacOS/$APP_NAME" \
    -framework Cocoa \
    -swift-version 6 \
    -warnings-as-errors \
    main.swift \
    AppDelegate.swift \
    BatteryMonitor.swift

echo "Built $APP_NAME.app"
