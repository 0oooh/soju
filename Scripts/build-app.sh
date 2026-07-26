#!/bin/bash
# Build the release Soju.app bundle into build/.
# Usage: Scripts/build-app.sh [--single-arch]
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$(cat VERSION)"

if [[ "${1:-}" == "--single-arch" ]]; then
    swift build -c release
    BIN=".build/release/Soju"
else
    swift build -c release --arch arm64 --arch x86_64
    # Universal product path differs across toolchain versions.
    for candidate in .build/out/Products/Release/Soju .build/apple/Products/Release/Soju; do
        [[ -f "$candidate" ]] && BIN="$candidate" && break
    done
fi

APP="build/Soju.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/Soju"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Soju</string>
    <key>CFBundleDisplayName</key><string>Soju</string>
    <key>CFBundleIdentifier</key><string>io.github.0oooh.Soju</string>
    <key>CFBundleExecutable</key><string>Soju</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key><string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSHumanReadableCopyright</key><string>MIT License</string>
    <key>NSMicrophoneUsageDescription</key><string>Windows programs run by Soju need this to use your microphone.</string>
    <key>NSCameraUsageDescription</key><string>Windows programs run by Soju need this to use your camera.</string>
</dict>
</plist>
PLIST

codesign --force --deep -s - "$APP"
echo "Built $APP (version $VERSION)"
