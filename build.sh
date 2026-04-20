#!/bin/bash
set -e

APP="Steno.app"
BUNDLE="$APP/Contents"
INSTALL_DIR="$HOME/Applications"

echo "Building..."
swift build -c release 2>&1

echo "Packaging..."
rm -rf "$APP"
mkdir -p "$BUNDLE/MacOS" "$BUNDLE/Resources"

cp .build/release/steno "$BUNDLE/MacOS/steno"
cp Support/Info.plist "$BUNDLE/"

echo "Signing..."
codesign --sign "Steno Code Signing" --force --deep "$APP"

echo "Installing to ~/Applications..."
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP"
cp -r "$APP" "$INSTALL_DIR/"

LAUNCH_AGENT="$HOME/Library/LaunchAgents/net.tklr.steno.plist"
if [ ! -f "$LAUNCH_AGENT" ]; then
    cp Support/net.tklr.steno.plist "$LAUNCH_AGENT"
    launchctl load "$LAUNCH_AGENT"
    echo "Login item registered."
fi

echo "Relaunching..."
pkill -x steno 2>/dev/null; sleep 0.5
open "$INSTALL_DIR/$APP"

echo "Done → $INSTALL_DIR/$APP"
echo ""
echo "If first install: System Settings → Privacy & Security → Accessibility → add Steno"
