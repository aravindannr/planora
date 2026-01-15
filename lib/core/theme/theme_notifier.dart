import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }
  static const String _themeModeKey = 'theme_mode';

  /// Load saved theme preference from SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final savedTheme = pref.getString(_themeModeKey);
      if (savedTheme != null) {
        state = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == savedTheme,
          orElse: () => ThemeMode.system,
        );
        debugPrint('Loaded theme: $state');
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  /// Save theme preference to SharedPreferences
  Future<void> _saveThemeMode(ThemeMode mode) async {
    try {
      final pref = await SharedPreferences.getInstance();
      await pref.setString(_themeModeKey, mode.toString());
      debugPrint('Saved theme: $mode');
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  /// Toggle between light and dark mode
  /// System mode will switch to light first
  Future<void> toggleTheme() async {
    final newMode = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system => ThemeMode.light,
    };
    state = newMode;
    await _saveThemeMode(newMode);
  }

  /// Set specific theme mode
  Future<void> setTheme(ThemeMode mode) async {
    if (state != mode) {
      state = mode;
      await _saveThemeMode(mode);
    }
  }

  /// Set to light mode
  Future<void> setLightMode() async {
    await setTheme(ThemeMode.light);
  }

  // Set to dark mode
  Future<void> setDarkMode() async {
    await setTheme(ThemeMode.dark);
  }

  /// Set to system mode (follow device settings)
  Future<void> setSystemMode() async {
    await setTheme(ThemeMode.system);
  }

  /// Check if current theme is light
  bool isLightMode() {
    return state == ThemeMode.light;
  }

  /// Check if following system theme
  bool isSystemMode() {
    return state == ThemeMode.system;
  }
}

/// Provider for theme mode
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

/// Helper provider to check if dark mode is active
/// Takes into account system theme when in system mode
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  if (themeMode == ThemeMode.system) {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }
  return themeMode == ThemeMode.dark;
});

/// Extension on WidgetRef for easy theme access
extension ThemeExtensions on WidgetRef {
  /// Get current theme mode
  ThemeMode get themeMode => watch(themeModeProvider);

  /// Check if dark mode is active
  bool get isDarkMode => watch(isDarkModeProvider);

  /// Toggle theme
  Future<void> toggleTheme() async {
    await read(themeModeProvider.notifier).toggleTheme();
  }

  /// Set specific theme
  Future<void> setTheme(ThemeMode mode) async {
    await read(themeModeProvider.notifier).setTheme(mode);
  }
}
