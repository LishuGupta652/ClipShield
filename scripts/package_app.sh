#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="ClipShield"
VERSION="${1:-${VERSION:-1.0.0}}"
BUNDLE_ID="${BUNDLE_ID:-com.yourname.clipshield}"

BUILD_DIR="$ROOT/.build/release"
DIST_DIR="$ROOT/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
INFO_PLIST_SRC="$ROOT/Resources/Info.plist"

mkdir -p "$DIST_DIR"

swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$INFO_PLIST_SRC" "$APP_DIR/Contents/Info.plist"

if [[ -d "$ROOT/Sources/ClipShieldCore/Resources" ]]; then
  rsync -a "$ROOT/Sources/ClipShieldCore/Resources/" "$APP_DIR/Contents/Resources/"
fi

if [[ -d "$ROOT/Resources" ]]; then
  rsync -a --exclude 'Info.plist' "$ROOT/Resources/" "$APP_DIR/Contents/Resources/"
fi

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName $APP_NAME" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $APP_NAME" "$APP_DIR/Contents/Info.plist"

if [[ -f "$ROOT/Resources/AppIcon.icns" ]]; then
  cp "$ROOT/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
  /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$APP_DIR/Contents/Info.plist"
fi

echo "Created: $APP_DIR"
