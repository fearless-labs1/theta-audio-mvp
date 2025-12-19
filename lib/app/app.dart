import 'package:flutter/material.dart';
import 'package:theta_audio_mvp/app/router.dart';
import 'package:theta_audio_mvp/app/theme.dart';

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
    );
  }
}
