#!/usr/bin/env bash
set -euo pipefail

# Point to the shared tooling SDKs in the crossfit directory to avoid downloading them again
TOOLING_DIR="/workspace/crossfit/.tooling"

export HOME="$TOOLING_DIR/home"
export XDG_CONFIG_HOME="$TOOLING_DIR/xdg-config"
export XDG_CACHE_HOME="$TOOLING_DIR/xdg-cache"
export PUB_CACHE="$TOOLING_DIR/pub-cache"
export CI="${CI:-true}"
export ANDROID_HOME="${ANDROID_HOME:-$TOOLING_DIR/android-sdk}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"

exec "$TOOLING_DIR/flutter_sdk/bin/flutter" "$@"
