#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[setup] $*"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

HOME_DIR=$(cd "${HOME:-$(getent passwd "$(id -u)" | cut -d: -f6)}" && pwd)
FLUTTER_SDK=${FLUTTER_SDK:-"$HOME_DIR/flutter"}
ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT:-"$HOME_DIR/android-sdk"}
ANDROID_CMDLINE_TOOLS_VERSION=${ANDROID_CMDLINE_TOOLS_VERSION:-"11076708"}
ANDROID_PLATFORM=${ANDROID_PLATFORM:-"android-34"}
ANDROID_BUILD_TOOLS=${ANDROID_BUILD_TOOLS:-"34.0.0"}
SKIP_ANDROID=${SKIP_ANDROID:-"0"}
FLUTTER_VERSION=${FLUTTER_VERSION:-"3.38.5"}

SUDO_CMD=""
if [[ $(id -u) -ne 0 ]] && command -v sudo >/dev/null 2>&1; then
  SUDO_CMD="sudo"
fi

log "Using Flutter SDK directory: ${FLUTTER_SDK}"
log "Using Flutter version: ${FLUTTER_VERSION}"
log "Using Android SDK directory: ${ANDROID_SDK_ROOT}"
log "SKIP_ANDROID flag set to: ${SKIP_ANDROID}"

log "Installing Linux build dependencies..."
$SUDO_CMD apt-get update -y
$SUDO_CMD apt-get install -y --no-install-recommends \
  curl git unzip xz-utils zip \
  clang cmake ninja-build pkg-config libgtk-3-dev libglu1-mesa \
  gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
  gstreamer1.0-libav gstreamer1.0-tools libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  openjdk-17-jdk

JAVA_BIN=$(command -v javac)
JAVA_HOME=${JAVA_HOME:-"$(dirname "$(dirname "${JAVA_BIN}")")"}
export JAVA_HOME
log "JAVA_HOME set to ${JAVA_HOME}"

log "Ensuring Flutter SDK is present..."
if [[ ! -d "${FLUTTER_SDK}" ]]; then
  require_command git
  git clone --depth 1 https://github.com/flutter/flutter.git -b "${FLUTTER_VERSION}" "${FLUTTER_SDK}"
else
  log "Flutter SDK already exists; skipping clone."
  if [[ -x "${FLUTTER_SDK}/bin/flutter" ]]; then
    INSTALLED_VERSION="$(${FLUTTER_SDK}/bin/flutter --version | head -n1 | awk '{print $2}')"
    if [[ "${INSTALLED_VERSION}" != "${FLUTTER_VERSION}" ]]; then
      log "Warning: Flutter SDK version (${INSTALLED_VERSION}) does not match requested version (${FLUTTER_VERSION})."
    fi
  fi
fi

export PATH="${FLUTTER_SDK}/bin:${PATH}"
export FLUTTER_SUPPRESS_ANALYTICS=true

log "Disabling Flutter analytics for non-interactive environments..."
flutter config --no-analytics >/dev/null

if [[ "${SKIP_ANDROID}" == "1" ]]; then
  log "SKIP_ANDROID=1 detected; skipping Android SDK installation."
  flutter precache --linux --web >/dev/null

  log "Setup complete. Add the following to your shell profile to persist PATH changes:"
  cat <<PROFILE
export FLUTTER_SDK="${FLUTTER_SDK}"
export PATH="\${FLUTTER_SDK}/bin:\${PATH}"
PROFILE
  exit 0
fi

log "Ensuring Android command-line tools are present..."
ANDROID_CMDLINE_DIR="${ANDROID_SDK_ROOT}/cmdline-tools/latest"
if [[ ! -d "${ANDROID_CMDLINE_DIR}" ]]; then
  mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools"
  TEMP_DIR=$(mktemp -d)
  TOOLS_ZIP="${TEMP_DIR}/cmdline-tools.zip"
  curl -fL "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip" -o "${TOOLS_ZIP}"
  unzip -q "${TOOLS_ZIP}" -d "${TEMP_DIR}"
  mv "${TEMP_DIR}/cmdline-tools" "${ANDROID_CMDLINE_DIR}"
  rm -rf "${TEMP_DIR}"
else
  log "Android command-line tools already present; skipping download."
fi

export ANDROID_SDK_ROOT
export PATH="${ANDROID_CMDLINE_DIR}/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

log "Installing Android SDK components (this may take a while)..."
LICENSE_LOG=$(mktemp)
license_exit=0
for attempt in 1 2 3; do
  set +e
  yes | sdkmanager --licenses >/dev/null 2>"${LICENSE_LOG}"
  license_exit=$?
  set -e

  if [[ ${license_exit} -eq 0 || ${license_exit} -eq 141 ]]; then
    license_exit=0
    break
  fi

  log "License acceptance attempt ${attempt} failed (exit ${license_exit}); retrying..."
  sleep 2
done

if [[ ${license_exit} -ne 0 ]]; then
  log "Failed to accept Android SDK licenses after retries (last exit: ${license_exit}). Output:"
  cat "${LICENSE_LOG}" || true
  exit ${license_exit}
fi

rm -f "${LICENSE_LOG}"

sdkmanager --install "platform-tools" "platforms;${ANDROID_PLATFORM}" "build-tools;${ANDROID_BUILD_TOOLS}" "cmdline-tools;latest" >/dev/null

log "Configuring Flutter to use the Android SDK..."
flutter config --android-sdk "${ANDROID_SDK_ROOT}" >/dev/null
flutter precache --android --linux --web >/dev/null

log "Setup complete. Add the following to your shell profile to persist PATH changes:"
cat <<PROFILE
export FLUTTER_SDK="${FLUTTER_SDK}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT}"
export PATH="\${FLUTTER_SDK}/bin:\${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:\${ANDROID_SDK_ROOT}/platform-tools:\${PATH}"
PROFILE
