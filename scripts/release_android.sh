#!/usr/bin/env bash
set -euo pipefail

EXPECTED_FLUTTER_VERSION="3.38.5"
SIGNING_VARS=(ANDROID_KEYSTORE_PATH ANDROID_KEYSTORE_PASSWORD ANDROID_KEY_ALIAS ANDROID_KEY_PASSWORD)

log() {
  echo "[release] $*"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

check_flutter_version() {
  local version
  version=$(flutter --version | head -n1 | awk '{print $2}')
  if [[ "$version" != "$EXPECTED_FLUTTER_VERSION" ]]; then
    log "Flutter version mismatch. Expected $EXPECTED_FLUTTER_VERSION, found $version"
    exit 1
  fi
}

ensure_signing_env() {
  local missing=()
  for var in "${SIGNING_VARS[@]}"; do
    if [[ -z "${!var:-}" ]]; then
      missing+=("$var")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    log "Missing signing environment variables: ${missing[*]}"
    exit 1
  fi
}

maybe_run_build_runner() {
  if grep -q "build_runner" pubspec.yaml; then
    log "Running build_runner to refresh generated files..."
    flutter pub run build_runner build --delete-conflicting-outputs
  else
    log "build_runner not detected; skipping code generation."
  fi
}

main() {
  require_command flutter
  check_flutter_version

  log "Cleaning previous outputs..."
  flutter clean

  log "Fetching dependencies..."
  flutter pub get

  log "Running static analysis..."
  flutter analyze

  log "Running tests..."
  flutter test

  maybe_run_build_runner

  ensure_signing_env

  log "Building release app bundle..."
  flutter build appbundle --release

  local bundle_path="build/app/outputs/bundle/release/app-release.aab"
  if [[ -f "$bundle_path" ]]; then
    log "Build complete: $bundle_path"
    log "SHA256: $(sha256sum "$bundle_path" | awk '{print $1}')"
  else
    log "Failed to locate bundle at $bundle_path"
    exit 1
  fi
}

main "$@"
