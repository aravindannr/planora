import 'package:flutter/material.dart';
import 'package:planora/features/auth/data/model/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user
  UserModel? getCurretUser() {
    try {
      final user = _supabase.auth.currentUser;
      final session = _supabase.auth.currentSession;

      debugPrint(
        'Getting current user - Session: ${session != null ? 'exists' : 'null'}',
      );
      debugPrint('Getting current user - User: ${user?.email ?? 'null'}');

      if (user != null && session != null) {
        return UserModel.fromSupabaseUser(user);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  /// Check if user is logged in
  bool get isLoggedIn {
    return _supabase.auth.currentUser != null;
  }

  /// Get auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign in with email and password
  Future<UserModel> signInwithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Attempting to sign in: $email');
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.user == null) {
        throw Exception('Login failed: No user returned');
      }
      debugPrint('Sign in successful: ${response.user!.email}');
      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      debugPrint('Auth error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected error during sign up: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Sign up with email and password
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      debugPrint('Attempting to sign up: $email');

      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );

      if (response.user == null) {
        throw Exception('Signup failed: No user returned');
      }

      debugPrint('Sign up successful: ${response.user!.email}');
      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      debugPrint('Auth error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected error during sign up: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Sign in with Google (OAuth)
  // Future<UserModel> signInwithGoogle() async {
  //   try {
  //     debugPrint('Attempting Google sign in');
  //     final response = await _supabase.auth.signInWithOAuth(
  //       OAuthProvider.google,
  //       redirectTo: 'https://mnwnustvtvfgxtxdmteo.supabase.co/auth/v1/callback',
  //     );
  //     if (!response) {
  //       throw Exception('Google sign in was cancelled');
  //     }
  //     // Wait for auth state change
  //     await Future.delayed(const Duration(seconds: 2));
  //     final user = _supabase.auth.currentUser;
  //     if (user == null) {
  //       throw Exception('Google sign in failed: No user found');
  //     }
  //     debugPrint('Google sign in successful: ${user.email}');
  //     return UserModel.fromSupabaseUser(user);
  //   } on AuthException catch (e) {
  //     debugPrint('Google auth error: ${e.message}');
  //     throw _handleAuthException(e);
  //   } catch (e) {
  //     debugPrint('Unexpected error during Google sign in: $e');
  //     throw Exception('Google sign in failed. Please try again.');
  //   }
  // }

  Future<void> signOut() async {
    try {
      debugPrint('Signing out');
      await _supabase.auth.signOut();
      debugPrint('Sign out successful');
    } catch (e) {
      debugPrint('Error signing out: $e');
      throw Exception('Failed to sign out. Please try again.');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      debugPrint('Sending password reset email to: $email');
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: "com.planora.app://login-callback",
      );
      debugPrint('Password reset email sent to: $email');
    } on AuthException catch (e) {
      debugPrint('Auth error during password reset: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected error during password reset: $e');
      throw Exception('Failed to send password reset email. Please try again.');
    }
  }

  // Update user profile
  Future<UserModel> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      debugPrint('Updating user profile');
      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      final response = await _supabase.auth.updateUser(
        UserAttributes(data: updates),
      );
      if (response.user == null) {
        throw Exception('Profile update failed');
      }
      debugPrint('Profile updated successfully');
      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      debugPrint('Profile update error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      throw Exception('Failed to update profile. Please try again.');
    }
  }

  // Refresh session
  Future<void> refreshSession() async {
    try {
      debugPrint('Refreshing session');
      await _supabase.auth.refreshSession();
      debugPrint('Session refreshed successfully');
    } catch (e) {
      debugPrint('Error refreshing session: $e');
      throw Exception('Failed to refresh session. Please try again.');
    }
  }

  String _handleAuthException(AuthException exception) {
    switch (exception.message.toLowerCase()) {
      case 'invalid login credentials':
      case 'invalid credentials':
        return 'Invalid email or password. Please try again.';

      case 'email not confirmed':
        return 'Please check your email and click the verification link before logging in.';

      case 'user already registered':
        return 'This email is already registered. Please sign in instead.';

      case 'password should be at least 6 characters':
        return 'Password must be at least 6 characters long.';

      case 'invalid email':
        return 'Please enter a valid email address.';

      case 'email rate limit exceeded':
        return 'Too many attempts. Please try again later.';

      case 'user not found':
        return 'No account found with this email.';

      default:
        return exception.message;
    }
  }

  // Resend confirmation email
  Future<void> resendConfirmation(String email) async {
    try {
      debugPrint('Resending confirmation email to: $email');
      await _supabase.auth.resend(type: OtpType.signup, email: email.trim());
      debugPrint('Confirmation email resent to: $email');
    } on AuthException catch (e) {
      debugPrint('Auth error during resend confirmation: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected error during resend confirmation: $e');
      throw Exception('Failed to resend confirmation email. Please try again.');
    }
  }
}

final authRepository = AuthRepository();
