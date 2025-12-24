#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[setup-macos] $*"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

# Use GITHUB_WORKSPACE if available, otherwise default to HOME
# This ensures it works in both local and CI environments
WORKSPACE=${GITHUB_WORKSPACE:-"$(cd && pwd)"}
FLUTTER_SDK=${FLUTTER_SDK:-"$WORKSPACE/.flutter-sdk"}
FLUTTER_VERSION=${FLUTTER_VERSION:-"3.38.5"}

log "Using Flutter SDK directory: ${FLUTTER_SDK}"
log "Using Flutter version: ${FLUTTER_VERSION}"

log "Ensuring Flutter SDK is present..."
if [[ ! -d "${FLUTTER_SDK}" ]]; then
  require_command git
  git clone --depth 1 https://github.com/flutter/flutter.git -b "${FLUTTER_VERSION}" "${FLUTTER_SDK}"
else
  log "Flutter SDK already exists; skipping clone."
fi

export PATH="${FLUTTER_SDK}/bin:${PATH}"
export FLUTTER_SUPPRESS_ANALYTICS=true

log "Disabling Flutter analytics for non-interactive environments..."
flutter config --no-analytics >/dev/null

log "Pre-caching Flutter for iOS development..."
flutter precache --ios >/dev/null

log "Setup complete. Add the following to your shell profile to persist PATH changes:"
cat <<PROFILE
export FLUTTER_SDK="${FLUTTER_SDK}"
export PATH="\${FLUTTER_SDK}/bin:\${PATH}"
PROFILE
