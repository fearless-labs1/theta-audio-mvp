import 'dart:io';

class PlatformEnv {
  const PlatformEnv._();

  static bool get isLinuxDesktop => Platform.isLinux;

  static bool get hasDisplay =>
      hasDisplayFrom(environment: Platform.environment, isLinuxDesktop: isLinuxDesktop);

  static bool hasDisplayFrom({
    required Map<String, String> environment,
    required bool isLinuxDesktop,
  }) {
    if (!isLinuxDesktop) return true;
    return (environment['DISPLAY']?.isNotEmpty ?? false) ||
        (environment['WAYLAND_DISPLAY']?.isNotEmpty ?? false);
  }

  static bool get isWSL {
    if (!isLinuxDesktop) return false;
    String? procVersion;
    try {
      procVersion = File('/proc/version').readAsStringSync();
    } catch (_) {
      procVersion = null;
    }
    return isWSLFrom(
      environment: Platform.environment,
      procVersion: procVersion,
      isLinuxDesktop: isLinuxDesktop,
    );
  }

  static bool isWSLFrom({
    required Map<String, String> environment,
    required bool isLinuxDesktop,
    String? procVersion,
  }) {
    if (!isLinuxDesktop) return false;
    if ((environment['WSL_INTEROP']?.isNotEmpty ?? false) ||
        (environment['WSL_DISTRO_NAME']?.isNotEmpty ?? false)) {
      return true;
    }
    if (procVersion == null) return false;
    final lower = procVersion.toLowerCase();
    return lower.contains('microsoft') || lower.contains('wsl');
  }
}
