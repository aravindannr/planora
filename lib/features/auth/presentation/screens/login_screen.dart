import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

/// 🔐 Login Screen
///
/// Allows users to sign in with:
/// - Email and password
/// - Google OAuth (optional)
/// - Guest mode
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handle login button press
  Future<void> _handleLogin() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      // Attempt login
      final success = await ref
          .read(authProvider.notifier)
          .signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;

      if (success) {
        // Login successful - navigate to home
        _navigateToHome();
      } else {
        // Login failed - show error
        final error = ref.read(authProvider).errorMessage;
        _showErrorSnackBar(error ?? 'Login failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handle Google sign in
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final success = await ref.read(authProvider.notifier).signInWithGoogle();

      if (!mounted) return;

      if (success) {
        _navigateToHome();
      } else {
        final error = ref.read(authProvider).errorMessage;
        _showErrorSnackBar(error ?? 'Google sign in failed.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handle guest mode
  void _handleGuestMode() {
    // TODO: Implement guest mode navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Guest mode - Coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Navigate to home screen
  void _navigateToHome() {
    // TODO: Replace with actual home screen when created
    Navigator.of(context).pushReplacementNamed('/home');

    _showSuccessSnackBar('Welcome back!');
  }

  /// Navigate to signup screen
  void _navigateToSignup() {
    // TODO: Replace with actual signup screen when created
    Navigator.of(context).pushNamed('/signup');
  }

  /// Navigate to forgot password screen
  void _navigateToForgotPassword() {
    // TODO: Implement forgot password screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Forgot password - Coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show success message
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Sign in to continue to FocusFlow',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 40),

                // Email Field
                EmailTextField(
                  controller: _emailController,
                  autofocus: false,
                  onSubmitted: (_) => _handleLogin(),
                ),

                const SizedBox(height: 20),

                // Password Field
                PasswordTextField(
                  controller: _passwordController,
                  onSubmitted: (_) => _handleLogin(),
                  textInputAction: TextInputAction.done,
                ),

                const SizedBox(height: 12),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextLinkButton(
                    text: 'Forgot Password?',
                    onPressed: _isLoading ? null : _navigateToForgotPassword,
                  ),
                ),

                const SizedBox(height: 32),

                // Login Button
                PrimaryAuthButton(
                  text: 'Login',
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 24),

                // Divider with "OR"
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.5),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Google Sign In Button
                GoogleSignInButton(
                  onPressed: _handleGoogleSignIn,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 16),

                // Guest Mode Button
                SecondaryAuthButton(
                  text: 'Continue as Guest',
                  onPressed: _isLoading ? null : _handleGuestMode,
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 32),

                // Sign Up Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextLinkButton(
                        text: 'Sign Up',
                        onPressed: _isLoading ? null : _navigateToSignup,
                        bold: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 📝 SAVE THIS FILE AS:
/// lib/features/auth/presentation/screens/login_screen.dart
/// 
/// NEXT STEPS:
/// 
/// 1. Update splash_screen.dart to navigate here:
/// ```dart
/// void _navigateToLogin() {
///   if (!mounted) return;
///   Navigator.of(context).pushReplacement(
///     MaterialPageRoute(builder: (_) => const LoginScreen()),
///   );
/// }
/// ```
/// 
/// 2. Add route in app.dart:
/// ```dart
/// routes: {
///   '/login': (context) => const LoginScreen(),
///   // ...
/// }
/// ```
/// 
/// 3. Create Signup Screen next!