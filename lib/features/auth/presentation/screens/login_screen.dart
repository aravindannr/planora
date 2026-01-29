import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planora/features/auth/presentation/widgets/auth_button.dart';
import 'package:planora/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:planora/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> handleLogin() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    final response = await ref
        .read(authProvider.notifier)
        .signInwithEmail(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
    if (!mounted) return;
    if (response) {
      navigateToHome();
    } else {
      final error = ref.read(authProvider).errorMessage;
      final errorMessage = error ?? 'Login failed. Please try again.';

      // Check if it's an email confirmation error
      if (errorMessage.toLowerCase().contains('verification') ||
          errorMessage.toLowerCase().contains('confirm')) {
        showEmailConfirmationDialog(errorMessage);
      } else {
        showErrorSnackBar(errorMessage);
      }
    }
  }

  void showEmailConfirmationDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Verification Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text('Would you like us to resend the verification email?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await ref
                  .read(authProvider.notifier)
                  .resendConfirmation(email: emailController.text.trim());
              if (mounted) {
                if (success) {
                  showSuccessSnackBar(
                    'Verification email sent! Please check your inbox.',
                  );
                } else {
                  showErrorSnackBar(
                    'Failed to send verification email. Please try again.',
                  );
                }
              }
            },
            child: const Text('Resend Email'),
          ),
        ],
      ),
    );
  }

  // Future<void> handleGoogleSignIn() async {
  //   final response = await ref.read(authProvider.notifier).signInwithGoogle();
  //   if (!mounted) return;
  //   if (response) {
  //     navigateToHome();
  //   } else {
  //     final error = ref.read(authProvider).errorMessage;
  //     showErrorSnackBar(error ?? 'Google sign in failed. Please try again.');
  //   }
  // }

  void handleGuestMode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Guest mode - Coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');

    showSuccessSnackBar('Welcome back!');
  }

  void navigateToProfile() {
    Navigator.of(context).pushReplacementNamed('/profile');

    showSuccessSnackBar('Welcome back!');
  }

  void navigateToSignup() {
    Navigator.of(context).pushNamed('/signup');
  }

  void navigateToForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Forgot password - Coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showErrorSnackBar(String message) {
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

  void showSuccessSnackBar(String message) {
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
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isEmailLoading = authState.loadingType == AuthLoadingType.emailLogin;

    // final isGoogleLoading =
    //     authState.loadingType == AuthLoadingType.googleLogin;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: .start,
              children: [
                const SizedBox(height: 20),
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
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Sign in to continue to Planora',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: .7),
                  ),
                ),
                const SizedBox(height: 40),
                EmailTextField(
                  controller: emailController,
                  autofocus: false,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                ),
                const SizedBox(height: 20),
                PasswordTextField(
                  controller: passwordController,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextLinkButton(
                    text: 'Forgot Password?',
                    onPressed: isEmailLoading ? null : navigateToForgotPassword,
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryAuthButton(
                  text: 'Login',
                  onPressed: isEmailLoading ? null : handleLogin,
                  isLoading: isEmailLoading,
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: .3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withValues(alpha: .5),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: .3),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // GoogleSignInButton(
                //   onPressed: isGoogleLoading ? null : handleGoogleSignIn,
                //   isLoading: isGoogleLoading,
                // ),

                // const SizedBox(height: 16),
                // SecondaryAuthButton(
                //   text: 'Continue as Guest',
                //   onPressed:  isEmailLoading
                //       ? null
                //       : handleGuestMode,
                //   icon: Icons.person_outline,
                // ),
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
                        onPressed: isEmailLoading ? null : navigateToSignup,
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
