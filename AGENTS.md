# Agent Instructions

## Repository Practices
- Keep environment provisioning guidance in this repository. Prefer updating `scripts/setup_flutter_android.sh` for Flutter/Android toolchain setup rather than scattering one-off commands.
- Document setup steps for contributors in `README.md` or within `scripts/` comments when changing tooling.
- Avoid checking large binaries or installer archives into the repository; rely on scripted downloads instead.
- Keep this `AGENTS.md` as the canonical reference for the `main` (release/website) branch and ensure it stays at parity or stricter than `production`.

## Flutter Project Expectations
- Framework: Flutter 3.38.5 (stable). Favor Material 3 components and `const` constructors where possible.
- Architecture: Feature-first structure under `lib/features/` with shared utilities in `lib/core/`, aligning with Clean Architecture principles.
- State management: Use the project’s chosen state solution consistently; avoid adding new packages without prior agreement or listing them in `pubspec.yaml`.
- Ensure new UI elements meet accessibility expectations (labels for controls, sufficient contrast) when working with Flutter screens.

## Workflow Requirements
- Run `flutter analyze` before finalizing changes to keep the build clean.
- Run `flutter test` locally and resolve failures before committing.
- After modifying model classes that rely on code generation, run `flutter pub run build_runner build --delete-conflicting-outputs`.
- For every new logic class (e.g., blocs, controllers, services, use cases), add corresponding unit tests in `test/` mirroring the `lib/` structure.
- Do not submit changes with analyzer warnings or test failures; fix them or document blocking issues in the PR description.
