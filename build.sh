#!/bin/bash
set -e

echo "Compiling PickFonts for macOS (ARM64)..."
swiftc -O -parse-as-library -target arm64-apple-macos14.0 main.swift -o PickFonts -framework SwiftUI -framework AppKit

echo "Creating application bundle..."
mkdir -p "PickFonts.app/Contents/MacOS"
mkdir -p "PickFonts.app/Contents/Resources"

mv PickFonts "PickFonts.app/Contents/MacOS/PickFonts"
chmod +x "PickFonts.app/Contents/MacOS/PickFonts"

if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "PickFonts.app/Contents/Resources/AppIcon.icns"
fi

APP_VERSION="${1:-2.1.0}"

cat << PLIST > "PickFonts.app/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>PickFonts</string>
    <key>CFBundleIdentifier</key>
    <string>net.pickfonts.app</string>
    <key>CFBundleName</key>
    <string>PickFonts</string>
    <key>CFBundleDisplayName</key>
    <string>PickFonts</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "Build complete: PickFonts.app"
