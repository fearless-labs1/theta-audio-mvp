import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theta_audio_mvp/app/theme.dart';

void main() {
  test('AppTheme enables Material 3 with a light color scheme', () {
    final theme = AppTheme.light();

    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, isNotNull);
  });
}
