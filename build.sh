#!/bin/bash
set -e

APP="Steno.app"
BUNDLE="$APP/Contents"

echo "Building..."
swift build -c release 2>&1

echo "Packaging..."
rm -rf "$APP"
mkdir -p "$BUNDLE/MacOS" "$BUNDLE/Resources"

cp .build/release/steno "$BUNDLE/MacOS/steno"
cp Support/Info.plist "$BUNDLE/"

echo "Signing..."
codesign --entitlements steno.entitlements --sign - --force --deep "$APP"

echo "Done → $APP"
echo ""
echo "Next: System Settings → Privacy & Security → Accessibility → add Steno"
echo "Then double-click Steno.app to launch"
