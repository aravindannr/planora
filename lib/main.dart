import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planora/app.dart';
import 'package:planora/core/config/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Main entry point of the FocusFlow app
///
/// This file handles:
/// 1. Flutter initialization
/// 2. Supabase initialization
/// 3. System UI configuration
/// 4. Shared Preferences initialization
/// 5. Error handling setup
/// 6. Running the app with ProviderScope

/// Helper to access Supabase client from anywhere in the app
/// Usage: supabase.auth.currentUser
final supabase = Supabase.instance.client;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configurSystemUi();

  await initializeService();

  setupErrorHandling();

  runApp(
    const ProviderScope(child: MyApp()),
  ); // Run the app wrapped with Riverpod's ProviderScope
}

Future<void> configurSystemUi() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure status bar and navigation bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

/// Initialize all core services
Future<void> initializeService() async {
  try {
    // Initialize Shared Preferences for local storage
    await SharedPreferences.getInstance();

    // Initialize Supabase
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce, // More secure auth flow
        // Enable automatic token refresh
        autoRefreshToken: true,
      ),
      // Optional: Enable debug mode in development
      debug: true,
    );
    debugPrint('All services initialized successfully');
  } catch (e, stackTrace) {
    // If initialization fails, log the error
    debugPrint('Error initializing services: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

/// Setup global error handling
void setupErrorHandling() {
  FlutterError.onError = (FlutterErrorDetails error) {
    FlutterError.presentError(error);
    debugPrint('Flutter Error: ${error.exception}');
    debugPrint('Stack trace: ${error.stack}');

    // TODO: Send to crash reporting service (Firebase Crashlytics, Sentry, etc.)
  };

  // Catch errors outside of Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    debugPrint('Stack trace: $stack');

    // TODO: Send to crash reporting service
    return true;
  };
}
