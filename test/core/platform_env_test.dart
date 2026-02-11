import 'package:flutter_test/flutter_test.dart';
import 'package:theta_audio_mvp/core/platform_env.dart';

void main() {
  group('PlatformEnv.isWSLFrom', () {
    test('returns false when not linux desktop', () {
      expect(
        PlatformEnv.isWSLFrom(
          environment: const {},
          procVersion: 'Linux version x microsoft',
          isLinuxDesktop: false,
        ),
        isFalse,
      );
    });

    test('returns true when WSL env var is present', () {
      expect(
        PlatformEnv.isWSLFrom(
          environment: const {'WSL_INTEROP': '/run/WSL/1'},
          procVersion: null,
          isLinuxDesktop: true,
        ),
        isTrue,
      );
    });

    test('returns true when proc version contains microsoft', () {
      expect(
        PlatformEnv.isWSLFrom(
          environment: const {},
          procVersion: 'Linux version 5.10.16.3-microsoft-standard-WSL2',
          isLinuxDesktop: true,
        ),
        isTrue,
      );
    });

    test('returns false when no WSL signals are present', () {
      expect(
        PlatformEnv.isWSLFrom(
          environment: const {},
          procVersion: 'Linux version 6.8.0-generic Ubuntu',
          isLinuxDesktop: true,
        ),
        isFalse,
      );
    });
  });

  group('PlatformEnv.hasDisplayFrom', () {
    test('returns true when display is present', () {
      expect(
        PlatformEnv.hasDisplayFrom(
          environment: const {'DISPLAY': ':0'},
          isLinuxDesktop: true,
        ),
        isTrue,
      );
    });

    test('returns true when wayland display is present', () {
      expect(
        PlatformEnv.hasDisplayFrom(
          environment: const {'WAYLAND_DISPLAY': 'wayland-0'},
          isLinuxDesktop: true,
        ),
        isTrue,
      );
    });

    test('returns false when linux has no display env', () {
      expect(
        PlatformEnv.hasDisplayFrom(
          environment: const {},
          isLinuxDesktop: true,
        ),
        isFalse,
      );
    });
  });
}
