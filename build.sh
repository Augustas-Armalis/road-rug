#!/bin/bash
# Builds build/Road Rug.app (universal: Apple Silicon + Intel) with just the Xcode Command Line Tools.
#   ./build.sh            build the app
#   ./build.sh --zip      also package dist/RoadRug.zip for a release
set -euo pipefail
cd "$(dirname "$0")"

APP="build/Road Rug.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" build/obj
cp Info.plist "$APP/Contents/Info.plist"
cp Resources/rug.png Resources/AppIcon.icns "$APP/Contents/Resources/"

for arch in arm64 x86_64; do
  swiftc -O -wmo -swift-version 5 -target "$arch-apple-macos14.0" \
    Sources/*.swift \
    -o "build/obj/RoadRug-$arch" \
    -framework Cocoa -framework Metal -framework MetalKit -framework QuartzCore
done
lipo -create build/obj/RoadRug-arm64 build/obj/RoadRug-x86_64 -output "$APP/Contents/MacOS/RoadRug"

codesign --force --sign - "$APP" >/dev/null
echo "Built $APP"

if [ "${1:-}" = "--zip" ]; then
  mkdir -p dist
  rm -f dist/RoadRug.zip
  ditto -c -k --keepParent "$APP" dist/RoadRug.zip
  echo "Packaged dist/RoadRug.zip ($(du -h dist/RoadRug.zip | cut -f1))"
fi
