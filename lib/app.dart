import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planora/core/theme/app_theme.dart';
import 'package:planora/core/theme/theme_notifier.dart';
import 'package:planora/features/auth/presentation/screens/login_screen.dart';
import 'package:planora/features/auth/presentation/screens/signup_screen.dart';
import 'package:planora/features/auth/presentation/screens/splash_screen.dart';
import 'package:planora/features/home/presentation/screens/home_screen.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Planora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/home': (_) => const HomeScreen(),
      },
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeInOut,
    );
  }
}
