import 'package:flutter/material.dart';

import '../core/app_lifecycle_service.dart';
import '../core/theme/app_theme.dart';
import '../features/weather/presentation/screens/home_screen.dart';
import '../features/weather/presentation/screens/onboarding_screen.dart';
import '../features/weather/presentation/screens/splash_screen.dart';

class AuroclimeApp extends StatefulWidget {
  const AuroclimeApp({super.key});

  @override
  State<AuroclimeApp> createState() => _AuroclimeAppState();
}

class _AuroclimeAppState extends State<AuroclimeApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final initialState = WidgetsBinding.instance.lifecycleState;
    if (initialState != null) {
      AppLifecycleService.state.value = initialState;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLifecycleService.state.value = state;
  }

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
