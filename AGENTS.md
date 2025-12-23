# Agent Instructions

## Repository Practices
- Keep environment provisioning guidance in this repository. Prefer updating `scripts/setup_flutter_android.sh` for Flutter/Android toolchain setup rather than scattering one-off commands.
- Document setup steps for contributors in `README.md` or within `scripts/` comments when changing tooling.
- Avoid checking large binaries or installer archives into the repository; rely on scripted downloads instead.

## Flutter Project Expectations
- Framework: Flutter 3.38.5 (stable). Favor Material 3 components and `const` constructors where possible.
- Architecture: Feature-first structure under `lib/features/` with shared utilities in `lib/core/`, aligning with Clean Architecture principles.
- State management: Use the project’s chosen state solution consistently; avoid adding new packages without prior agreement or listing them in `pubspec.yaml`.

## Workflow Requirements
- Run `flutter analyze` before finalizing changes to keep the build clean.
- After modifying model classes that rely on code generation, run `flutter pub run build_runner build --delete-conflicting-outputs`.
- For every new logic class (e.g., blocs, controllers, services, use cases), add corresponding unit tests in `test/` mirroring the `lib/` structure.
