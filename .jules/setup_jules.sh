#!/bin/bash
set -x

# ------------------------------------------------------------------
# CONFIGURATION & LOGGING
# ------------------------------------------------------------------

log() {
  echo "[setup] $*"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

# Directory & SDK Definitions
HOME_DIR=$(cd "${HOME:-$(getent passwd "$(id -u)" | cut -d: -f6)}" && pwd)
FLUTTER_SDK=${FLUTTER_SDK:-"$HOME_DIR/flutter"}
ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT:-"$HOME_DIR/android-sdk"}
ANDROID_CMDLINE_TOOLS_VERSION=${ANDROID_CMDLINE_TOOLS_VERSION:-"11076708"}
ANDROID_PLATFORM=${ANDROID_PLATFORM:-"android-34"}
ANDROID_BUILD_TOOLS=${ANDROID_BUILD_TOOLS:-"34.0.0"}

# Repository Configuration
REPO_DIR="/app"
TARGET_BRANCH="production"

# Sudo Handling
SUDO_CMD=""
if [[ $(id -u) -ne 0 ]] && command -v sudo >/dev/null 2>&1; then
  SUDO_CMD="sudo"
fi

log "Using Flutter SDK directory: ${FLUTTER_SDK}"
log "Using Android SDK directory: ${ANDROID_SDK_ROOT}"

# ------------------------------------------------------------------
# DEPENDENCY INSTALLATION
# ------------------------------------------------------------------

log "Installing Linux build dependencies..."
$SUDO_CMD apt-get update -y
$SUDO_CMD apt-get install -y --no-install-recommends \
  curl git unzip xz-utils zip \
  clang cmake ninja-build pkg-config libgtk-3-dev libglu1-mesa \
  openjdk-17-jdk

JAVA_BIN=$(command -v javac)
JAVA_HOME=${JAVA_HOME:-"$(dirname "$(dirname "${JAVA_BIN}")")"}
export JAVA_HOME
log "JAVA_HOME set to ${JAVA_HOME}"

log "Configuring repository state in ${REPO_DIR}..."

if [[ -d "${REPO_DIR}/.git" ]]; then
  log "Git repository detected at ${REPO_DIR}. Initiating branch switch..."
  
  # Save current location
  pushd "${REPO_DIR}" >/dev/null
  
  # Ensure we have the latest metadata
  git fetch origin
  
  # Check if remote branch exists
  if git ls-remote --exit-code --heads origin "${TARGET_BRANCH}" >/dev/null 2>&1; then
    log "Checking out branch: ${TARGET_BRANCH}"
    
    # -B creates the branch if missing, or resets it if it exists
    # origin/${TARGET_BRANCH} tells git exactly where to pull from
    git checkout -B "${TARGET_BRANCH}" "origin/${TARGET_BRANCH}"
    
    log "Repository is now on ${TARGET_BRANCH}."
  else
    log "WARNING: Branch '${TARGET_BRANCH}' not found on remote. Staying on current branch."
  fi
  
  # Restore location
  popd >/dev/null
else
  log "WARNING: No git repository found at ${REPO_DIR}. Skipping branch checkout."
fi

# ------------------------------------------------------------------
# FLUTTER SDK SETUP
# ------------------------------------------------------------------

log "Ensuring Flutter SDK is present..."
if [[ ! -d "${FLUTTER_SDK}" ]]; then
  require_command git
  git clone https://github.com/flutter/flutter.git -b stable "${FLUTTER_SDK}"
else
  log "Flutter SDK already exists; skipping clone."
fi

export PATH="${FLUTTER_SDK}/bin:${PATH}"

# ------------------------------------------------------------------
# ANDROID SDK SETUP
# ------------------------------------------------------------------

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
yes | sdkmanager --licenses > /dev/null
sdkmanager --install "platform-tools" "platforms;${ANDROID_PLATFORM}" "build-tools;${ANDROID_BUILD_TOOLS}" "cmdline-tools;latest" >/dev/null

log "Configuring Flutter to use the Android SDK..."
flutter config --android-sdk "${ANDROID_SDK_ROOT}" >/dev/null
flutter precache --android --linux --web >/dev/null

# ------------------------------------------------------------------
# FINALIZATION
# ------------------------------------------------------------------

log "Setup complete. Add the following to your shell profile to persist PATH changes:"
cat <<PROFILE
export FLUTTER_SDK="${FLUTTER_SDK}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT}"
export PATH="\${FLUTTER_SDK}/bin:\${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:\${ANDROID_SDK_ROOT}/platform-tools:\${PATH}"
PROFILE
