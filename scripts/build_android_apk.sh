#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/flutter-app"
FLUTTER="$ROOT_DIR/scripts/flutter.sh"

# Reuse CrossFit Gradle home cache for faster builds
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-/workspace/crossfit/.tooling/gradle-home}"

# Load environment variables from .env if present
if [ -f "$ROOT_DIR/.env" ]; then
  export $(grep -v '^#' "$ROOT_DIR/.env" | xargs)
fi

# Configuration defaults
BASE_URL="${BASE_URL:-https://qrdoc.devbeaver.cloud/api}"
BUILD_NAME="${BUILD_NAME:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

echo "=================================================="
echo "Starting Android Release APK build..."
echo "APP_DIR: $APP_DIR"
echo "BASE_URL: $BASE_URL"
echo "BUILD_NAME: $BUILD_NAME"
echo "BUILD_NUMBER: $BUILD_NUMBER"
echo "=================================================="

mkdir -p "$GRADLE_USER_HOME"

cd "$APP_DIR"

echo "Running pub get..."
"$FLUTTER" pub get

echo "Generating Launcher Icons..."
"$FLUTTER" pub run flutter_launcher_icons

echo "Building release APK..."
"$FLUTTER" build apk \
  --release \
  --build-name="$BUILD_NAME" \
  --build-number="$BUILD_NUMBER" \
  --dart-define=BASE_URL="$BASE_URL" \
  --dart-define=WEB_VIEWER_URL="https://qrdoc.devbeaver.cloud/"

# Automatic deployment to web-viewer folder
OUTPUT_APK="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
DEPLOY_PATH="$ROOT_DIR/web-viewer/qrdoc.apk"

if [ -f "$OUTPUT_APK" ]; then
  echo "Copying built APK to Nginx web-viewer deployment folder..."
  cp "$OUTPUT_APK" "$DEPLOY_PATH"
  echo "--------------------------------------------------"
  echo "✓ Build and Deployment Successful!"
  echo "✓ Download link: http://qrdoc.devbeaver.cloud/qrdoc.apk"
  echo "--------------------------------------------------"
else
  echo "✗ Error: Built APK not found at $OUTPUT_APK"
  exit 1
fi
