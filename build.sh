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
codesign --sign - --force --deep "$APP"

echo "Installing to ~/Applications..."
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP"
cp -r "$APP" "$INSTALL_DIR/"

echo "Done → $INSTALL_DIR/$APP"
echo ""
echo "If first install: System Settings → Privacy & Security → Accessibility → add Steno"
open "$INSTALL_DIR/$APP"
