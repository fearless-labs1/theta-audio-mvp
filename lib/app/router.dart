import 'package:flutter/material.dart';
import 'package:theta_audio_mvp/features/home/pages/theta_home_page.dart';
import 'package:theta_audio_mvp/intro_screen.dart';

class AppRouter {
  static const String introRoute = '/';
  static const String homeRoute = '/home';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case introRoute:
        return MaterialPageRoute(builder: (_) => const IntroScreen());
      case homeRoute:
        return _fadeToHomeRoute();
      default:
        return MaterialPageRoute(builder: (_) => const IntroScreen());
    }
  }

  static PageRouteBuilder<dynamic> _fadeToHomeRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const ThetaHomePage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 4000),
    );
  }

  static Route<dynamic> fadeToHomeReplacement() => _fadeToHomeRoute();
}
