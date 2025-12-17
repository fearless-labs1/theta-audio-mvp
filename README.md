# theta_audio_mvp_android

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Please update the Github README file with the following verbiage: # 🎧 Theta Audio MVP

**Version:** 1.0.0  
**Status:** Production Ready  


Cross-platform prayer audio application with background playback capabilities. Plays pre-recorded prayers at 10-minute intervals, even with the screen off.

[![Flutter](https://img.shields.io/badge/Flutter-3.1.0+-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Windows-lightgrey)]()
[![License](https://img.shields.io/badge/License-Proprietary-red)]()

---

## ✨ Features

- ✅ **Background Audio Playback** - Continues running with screen off
- ✅ **Automatic Intervals** - Plays prayers every 10 minutes
- ✅ **Beep Notification** - Attention signal before each prayer (Isolezelo style)
- ✅ **Lock Screen Controls** - iOS & Android media controls
- ✅ **100 Prayer Library** - Diverse, pre-recorded prayer collection
- ✅ **Random Selection** - Intelligent prayer randomization
- ✅ **Simple Interface** - Clean Start/Stop UI
- ✅ **Low Battery Usage** - Optimized for all-day operation (<5% per hour)
- ✅ **Cross-Platform** - iOS, Android, and Windows desktop support

---

## 📱 Platform Support

| Platform | Minimum Version | Status |
|----------|----------------|--------|
| **iOS** | iPhone 7+ (iOS 12+) | ✅ Production Ready |
| **Android** | Android 6.0+ (API 23+) | ✅ Production Ready |
| **Windows** | Windows 10+ (64-bit) | ✅ Production Ready |

---

## 🎙️ Audio Specifications

- **Voice Engine:** OpenAI TTS (Alloy voice @ 0.92 speed)
- **Beep Signal:** Custom attention tone (0.3-0.5 seconds)
- **Audio Format:** MP3 (high quality)
- **Playback Style:** Beep introduction → Prayer audio (seamless merge)

---

## 🚀 Quick Start

### Prerequisites

1. **Flutter SDK** 3.1.0 or higher
   ```bash
   flutter --version
   ```

2. **Platform-Specific Tools:**
   - **iOS:** Xcode 12+ (macOS only)
   - **Android:** Android Studio with SDK 23+
   - **Windows:** Visual Studio 2019+ with Desktop Development workload

3. **OpenAI API Key** (for generating prayer audio)
   - Sign up at [platform.openai.com](https://platform.openai.com)

---

## 📥 Installation

### Step 1: Clone Repository

```bash
git clone https://github.com/yourusername/theta-audio-mvp.git
cd theta-audio-mvp
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Add Audio Assets

#### Option A: Generate Prayers Automatically

```bash
# Set your OpenAI API key
export OPENAI_API_KEY='sk-your-key-here'

# Create asset directories
mkdir -p assets/audio assets/prayers

# Generate all 100 prayers
python3 generate_prayers.py
```

#### Option B: Use Pre-Generated Audio

If you have pre-generated prayer files, copy them to:
- Prayers: `assets/prayers/` (100 MP3 files)
- Beep: `assets/audio/beep.mp3`

### Step 4: Configure Platforms

#### iOS Configuration

1. Open `ios/Runner/Info.plist`
2. Add the following inside the `<dict>` tag:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

#### Android Configuration

1. Open `android/app/src/main/AndroidManifest.xml`
2. Add permissions before `<application>`:

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
```

3. Add `xmlns:tools` to `<manifest>` tag:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
```

4. Add service inside `<application>` (after `<activity>`):

```xml
<service
    android:name="com.ryanheise.audioservice.AudioService"
    android:foregroundServiceType="mediaPlayback"
    android:exported="true"
    tools:replace="android:exported">
    <intent-filter>
        <action android:name="android.media.browse.MediaBrowserService" />
    </intent-filter>
</service>
```

---

## 🏗️ Building for Release

### iOS Release Build

```bash
# Clean previous builds
flutter clean
flutter pub get

# Build iOS release
flutter build ios --release

# Open in Xcode for signing and distribution
open ios/Runner.xcworkspace
```

**In Xcode:**
1. Select `Product → Archive`
2. Once archived, click `Distribute App`
3. Choose distribution method:
   - **TestFlight:** For beta testing
   - **App Store:** For public release
   - **Ad Hoc:** For limited device distribution

### Android Release Build

```bash
# Clean previous builds
flutter clean
flutter pub get

# Build APK (for direct installation)
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

**Output locations:**
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Bundle: `build/app/outputs/bundle/release/app-release.aab`

**Signing Configuration:**

Create `android/key.properties`:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=/path/to/your/keystore.jks
```

### Windows Release Build

```bash
# Clean previous builds
flutter clean
flutter pub get

# Build Windows release
flutter build windows --release
```

**Output location:** `build/windows/x64/runner/Release/`

---

## 📦 Windows Installer with Inno Setup

### Prerequisites

1. Download and install [Inno Setup](https://jrsoftware.org/isdl.php)
2. Build Windows release (see above)

### Step 1: Create Inno Setup Script

Create `windows/installer.iss`:

```iss
#define MyAppName "Theta Audio"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Your Company Name"
#define MyAppURL "https://yourwebsite.com"
#define MyAppExeName "theta_audio_mvp.exe"

[Setup]
AppId={{YOUR-UNIQUE-APP-ID-HERE}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=..\LICENSE.txt
OutputDir=..\build\windows\installer
OutputBaseFilename=ThetaAudioSetup-v{#MyAppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
```

### Step 2: Compile Installer

**Option A: Using Inno Setup GUI**
1. Open Inno Setup Compiler
2. Open `windows/installer.iss`
3. Click `Build → Compile`

**Option B: Command Line**
```bash
# Add Inno Setup to PATH or use full path
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" windows\installer.iss
```

**Output:** `build/windows/installer/ThetaAudioSetup-v1.0.0.exe`

### Step 3: Test Installer

```bash
# Run the installer
.\build\windows\installer\ThetaAudioSetup-v1.0.0.exe
```

**Verify:**
- ✅ Installs to Program Files
- ✅ Creates Start Menu shortcuts
- ✅ Creates Desktop icon (if selected)
- ✅ App launches successfully
- ✅ Uninstaller works correctly

---

## 🧪 Testing

### Development Testing

```bash
# iOS Simulator
flutter run -d iPhone

# Android Emulator
flutter run -d emulator-5554

# Connected device
flutter devices
flutter run -d <device-id>

# Windows Desktop
flutter run -d windows
```

### Quality Gate Checklist

#### Gate #1: Background Audio ✅
- [ ] iOS: Audio plays with screen locked
- [ ] iOS: Lock screen media controls appear
- [ ] Android: Audio plays with screen off
- [ ] Android: Notification controls functional
- [ ] Windows: Audio continues when minimized

#### Gate #2: Timing Accuracy ✅
- [ ] First prayer plays immediately on Start
- [ ] Subsequent prayers play every 10 minutes (±5 sec)
- [ ] Timer survives screen lock/minimize
- [ ] Stop button halts playback instantly

#### Gate #3: Audio Quality ✅
- [ ] Beep plays before each prayer
- [ ] Prayer audio is clear (no distortion)
- [ ] No stuttering or glitches
- [ ] Volume levels consistent

#### Gate #4: User Experience ✅
- [ ] UI is clean and intuitive
- [ ] Status indicator updates correctly
- [ ] No crashes during 1-hour continuous test
- [ ] Battery usage < 5% per hour (mobile)

---

## 📁 Project Structure

```
theta_audio_mvp/
├── android/                      # Android platform files
│   └── app/src/main/
│       └── AndroidManifest.xml   # Background audio config
├── ios/                          # iOS platform files
│   └── Runner/
│       └── Info.plist            # Background audio config
├── windows/                      # Windows platform files
│   ├── runner/
│   └── installer.iss             # Inno Setup script
├── assets/
│   ├── audio/
│   │   └── beep.mp3              # Attention beep
│   └── prayers/
│       ├── 001_lords_prayer.mp3  # Prayer files
│       └── ... (100 total)
├── lib/
│   ├── main.dart                 # App entry + UI
│   ├── audio_service.dart        # Background audio engine
│   └── prayers_list.dart         # Prayer registry
├── generate_prayers.py           # Audio generation script
├── pubspec.yaml                  # Dependencies + assets
└── README.md                     # This file
```

---

## 🔧 Troubleshooting

### iOS: Audio doesn't play in background

**Solution:**
```bash
# Verify Info.plist configuration
cat ios/Runner/Info.plist | grep "UIBackgroundModes"

# Clean and rebuild
flutter clean
flutter build ios --release

# Check iOS Settings → Theta → Background App Refresh (enabled)
```

### Android: Notification doesn't show

**Solution:**
```bash
# Verify AndroidManifest.xml has all permissions
grep "FOREGROUND_SERVICE" android/app/src/main/AndroidManifest.xml

# Clean and rebuild
flutter clean
flutter build apk --release

# Check battery optimization (disable for Theta)
```

### Windows: Audio stutters or stops

**Solution:**
- Ensure no other audio applications are running
- Check Windows sound settings (not muted)
- Verify all DLL files are in the Release folder
- Run as Administrator if needed

### Build fails with "beep.mp3 not found"

**Solution:**
```bash
# Verify file exists
ls -lh assets/audio/beep.mp3

# Regenerate assets
flutter pub get
flutter clean
flutter pub get
```

---

## 📊 Performance Metrics

| Metric | iOS | Android | Windows |
|--------|-----|---------|---------|
| **Battery Usage** | <5% per hour | <5% per hour | N/A |
| **Memory Usage** | ~50MB | ~50MB | ~80MB |
| **Storage** | ~15MB | ~15MB | ~20MB |
| **CPU Usage** | Minimal | Minimal | Minimal |
| **Startup Time** | <2 seconds | <2 seconds | <1 second |

---

## 💰 Publishing Costs

| Platform | Cost | Frequency |
|----------|------|-----------|
| **Android Play Store** | R430 (~$25) | One-time |
| **iOS App Store** | R1,700 (~$99) | Annual |
| **Windows** | Free (self-hosted) | One-time |
| **OpenAI TTS** | ~$0.25 | One-time (100 prayers) |

**Total Initial Investment:** ~R2,130 (~$124)  
**Annual Recurring:** R1,700 (~$99 for iOS only)

---

## 🛠️ Development Workflow

### Local Development

```bash
# Start development
git checkout -b feature/your-feature
flutter pub get
flutter run

# Run tests
flutter test

# Format code
flutter format .

# Analyze code
flutter analyze
```

### Pre-Release Checklist

- [ ] All tests passing
- [ ] Code formatted (`flutter format`)
- [ ] No analyzer warnings (`flutter analyze`)
- [ ] All 4 quality gates verified
- [ ] Version bumped in `pubspec.yaml`
- [ ] CHANGELOG.md updated
- [ ] Release notes prepared

### Release Process

```bash
# iOS
flutter build ios --release
# → TestFlight → App Store

# Android
flutter build appbundle --release
# → Play Console → Production

# Windows
flutter build windows --release
# → Inno Setup → Self-hosted download
```

---

## 📖 Documentation

- **Build Specification:** `THETA_MVP_BUILD_SPEC_V1_0.txt`
- **Next Steps Guide:** `NEXT_STEPS_COMPLETE_GUIDE.md`
- **Audit Report:** `THETA_AUDIT_REPORT_COMPREHENSIVE.txt`
- **Platform Configs:** 
  - `ios_configuration_Info_plist_FIXED.xml`
  - `android_configuration_AndroidManifest.xml`

---

## 🤝 Contributing

This is a proprietary project. For bug reports or feature requests, please contact the development team.

---

## 📄 License

Proprietary. All rights reserved.

---

## 🙏 Acknowledgments

- **Build Methodology:** Inspired by Isolezelo AI systematic approach
- **Audio Engine:** [just_audio](https://pub.dev/packages/just_audio) by Ryan Heise
- **TTS Voice:** OpenAI Text-to-Speech (Alloy voice)
- **Quality Standard:** 9.6/10 Isolezelo certification

---

## 📞 Support

For technical support or questions:
- **Email:** support@yourcompany.com
- **Documentation:** See docs folder
- **Issues:** Contact development team

---

## 🎯 Roadmap

### Version 1.0 (Current) ✅
- Background audio playback
- 10-minute intervals
- 100 prayer library
- iOS, Android, Windows support

### Version 1.1 (Planned)
- [ ] Custom interval selection (5-60 minutes)
- [ ] Prayer category filtering
- [ ] Usage statistics dashboard
- [ ] Multiple voice options

### Version 2.0 (Future)
- [ ] User-uploaded prayers
- [ ] Prayer scheduling
- [ ] Cloud synchronization
- [ ] Multi-language support

---

**Built with ❤️ using Flutter**

**Last Updated:** December 2025