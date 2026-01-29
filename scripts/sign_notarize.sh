#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 5 ]]; then
  echo "Usage: $0 <app_path> <signing_identity> <apple_id> <team_id> <app_specific_password>"
  exit 1
fi

APP_PATH="$1"
SIGNING_IDENTITY="$2"
APPLE_ID="$3"
TEAM_ID="$4"
APP_PASSWORD="$5"

/usr/bin/codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$APP_PATH"

/usr/bin/xcrun notarytool submit "$APP_PATH" --apple-id "$APPLE_ID" --team-id "$TEAM_ID" --password "$APP_PASSWORD" --wait
/usr/bin/xcrun stapler staple "$APP_PATH"

echo "Signed and notarized: $APP_PATH"
