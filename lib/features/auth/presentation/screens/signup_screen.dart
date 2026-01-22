import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planora/features/auth/presentation/widgets/auth_button.dart';
import 'package:planora/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:planora/features/auth/providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool acceptTerms = false;

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> handleSignUp() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    if (!acceptTerms) {
      showErrorSnackBar('You must accept the terms and conditions to sign up.');
      return;
    }
    FocusScope.of(context).unfocus();
    final response = await ref
        .read(authProvider.notifier)
        .signUpWithEmail(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
    if (!mounted) return;
    if (response) {
      navigateToHome();
    } else {
      final error = ref.read(authProvider).errorMessage;
      showErrorSnackBar(error ?? 'Signup failed. Please try again.');
    }
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

  /// Navigate to home screen
  void navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
    showSuccessSnackBar('Account created successfully!');
  }

  /// Navigate back to login screen
  void navigateToLogin() {
    Navigator.of(context).pop();
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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    final isSignupLoading = authState.loadingType == AuthLoadingType.signup;

    // final isGoogleLoading =
    //     authState.loadingType == AuthLoadingType.googleLogin;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const .all(24.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: .start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: isSignupLoading ? null : navigateToLogin,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
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
                      Icons.person_add_outlined,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Sign up to get started with Planora',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),

                const SizedBox(height: 40),
                NameTextField(controller: nameController, autofocus: false),
                const SizedBox(height: 20),
                EmailTextField(controller: emailController, autofocus: false),
                const SizedBox(height: 20),
                PasswordTextField(
                  controller: passwordController,
                  label: 'Password',
                  hint: 'Create a password',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                PasswordTextField(
                  controller: confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  validator: validateConfirmPassword,
                  textInputAction: TextInputAction.done,
                  // onSubmitted: validateConfirmPassword,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: acceptTerms,
                        onChanged: isSignupLoading
                            ? null
                            : (value) {
                                setState(() {
                                  acceptTerms = value ?? false;
                                });
                              },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        children: [
                          Text(
                            'I agree to the ',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Terms & Conditions - Coming soon',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Text(
                              'Terms & Conditions',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                PrimaryAuthButton(
                  text: 'Create Account',
                  onPressed: handleSignUp,
                  isLoading: isSignupLoading,
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
                // const SizedBox(height: 24),
                // GoogleSignInButton(
                //   onPressed: handleGoogleSignIn,
                //   isLoading: isGoogleLoading,
                // ),
                const SizedBox(height: 32),

                // Login Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextLinkButton(
                        text: 'Login',
                        onPressed: isSignupLoading ? null : navigateToLogin,
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
