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
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(), // Temporary screen for testing

      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        // '/profile': (context) => const ProfileScreen(),
      },

      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeInOut,
    );
  }
}

class TemporaryHomeScreen extends ConsumerWidget {
  const TemporaryHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FocusFlow'),
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Welcome to FocusFlow',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Plan, track, and improve your daily life',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Theme Mode Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Current Theme',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Chip(
                        avatar: Icon(_getThemeIcon(themeMode), size: 18),
                        label: Text(_getThemeText(themeMode)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Theme Selector Buttons
              Wrap(
                spacing: 12,
                children: [
                  _ThemeButton(
                    icon: Icons.light_mode,
                    label: 'Light',
                    isSelected: themeMode == ThemeMode.light,
                    onPressed: () {
                      ref.read(themeModeProvider.notifier).setLightMode();
                    },
                  ),
                  _ThemeButton(
                    icon: Icons.dark_mode,
                    label: 'Dark',
                    isSelected: themeMode == ThemeMode.dark,
                    onPressed: () {
                      ref.read(themeModeProvider.notifier).setDarkMode();
                    },
                  ),
                  _ThemeButton(
                    icon: Icons.settings_brightness,
                    label: 'System',
                    isSelected: themeMode == ThemeMode.system,
                    onPressed: () {
                      ref.read(themeModeProvider.notifier).setSystemMode();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Sample Buttons (to showcase theme)
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Theme is working! ✅'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Test Elevated Button'),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () {},
                child: const Text('Test Outlined Button'),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () {},
                child: const Text('Test Text Button'),
              ),

              const SizedBox(height: 32),

              // Info Text
              Text(
                '🎨 Themes are working!\nNext: Create Splash Screen',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => Icons.light_mode,
      ThemeMode.dark => Icons.dark_mode,
      ThemeMode.system => Icons.settings_brightness,
    };
  }

  String _getThemeText(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Light Mode',
      ThemeMode.dark => 'Dark Mode',
      ThemeMode.system => 'System Mode',
    };
  }
}

/// Custom Theme Button Widget
class _ThemeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ThemeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onPressed(),
      selectedColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: .2),
    );
  }
}
