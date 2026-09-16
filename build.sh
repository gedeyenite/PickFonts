#!/bin/bash
set -e

echo "Compiling ModernFontPicker for macOS (ARM64)..."
swiftc -O -parse-as-library -target arm64-apple-macos14.0 main.swift -o ModernFontPicker -framework SwiftUI -framework AppKit

echo "Creating application bundle..."
mkdir -p "Font Picker.app/Contents/MacOS"
mkdir -p "Font Picker.app/Contents/Resources"

mv ModernFontPicker "Font Picker.app/Contents/MacOS/Font Picker"
chmod +x "Font Picker.app/Contents/MacOS/Font Picker"

if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "Font Picker.app/Contents/Resources/AppIcon.icns"
fi

cat << 'PLIST' > "Font Picker.app/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Font Picker</string>
    <key>CFBundleIdentifier</key>
    <string>net.fontpicker.modern</string>
    <key>CFBundleName</key>
    <string>Font Picker</string>
    <key>CFBundleDisplayName</key>
    <string>Font Picker</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "Build complete: Font Picker.app"
