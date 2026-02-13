import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:theta_audio_mvp/app/router.dart';
import 'package:theta_audio_mvp/app/theme.dart';
import 'package:theta_audio_mvp/core/widgets/window_controls_overlay.dart';

class ThetaApp extends StatelessWidget {
  const ThetaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Theta Audio MVP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.introRoute,
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (defaultTargetPlatform != TargetPlatform.windows) {
          return content;
        }
        return Stack(
          children: [
            content,
            const WindowControlsOverlay(),
          ],
        );
      },
    );
  }
}
