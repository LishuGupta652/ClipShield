#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-1.0.0}"
APP_NAME="ClipShield"

"$ROOT/scripts/package_app.sh" "$VERSION"

ZIP_PATH="$ROOT/dist/${APP_NAME}-${VERSION}.zip"
rm -f "$ZIP_PATH"

/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$ROOT/dist/$APP_NAME.app" "$ZIP_PATH"

echo "Release archive: $ZIP_PATH"
/usr/bin/shasum -a 256 "$ZIP_PATH"
