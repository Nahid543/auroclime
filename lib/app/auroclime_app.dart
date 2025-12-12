import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/weather/presentation/screens/home_screen.dart';
import '../features/weather/presentation/screens/onboarding_screen.dart';
import '../features/weather/presentation/screens/splash_screen.dart';

class AuroclimeApp extends StatelessWidget {
  const AuroclimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auroclime',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
    );
  }
}
