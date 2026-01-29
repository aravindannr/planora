// Authentication State
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:planora/features/auth/data/model/user_model.dart';
import 'package:planora/features/auth/data/repositories/auth_repository.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

// Authentication State Class
class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final AuthLoadingType loadingType;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.loadingType = AuthLoadingType.none,
  });

  factory AuthState.initial() {
    return const AuthState(
      status: AuthStatus.initial,
      loadingType: AuthLoadingType.none,
    );
  }

  AuthState copyWithLoading(AuthLoadingType type) {
    return AuthState(status: AuthStatus.loading, user: user, loadingType: type);
  }

  AuthState copyWithUser(UserModel user) {
    return AuthState(
      status: AuthStatus.authenticated,
      user: user,
      loadingType: AuthLoadingType.none,
    );
  }

  AuthState copyWithUnauthenticated([String? error]) {
    return AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: error,
      loadingType: AuthLoadingType.none,
    );
  }

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
}

enum AuthLoadingType { none, emailLogin, googleLogin, signup, profileUpdate }

//Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository authRepository;
  AuthNotifier(this.authRepository) : super(AuthState.initial()) {
    _checkAuthStatus();
    _listenToAuthChanges();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Add a small delay to ensure Supabase is fully initialized
      await Future.delayed(const Duration(milliseconds: 100));

      final user = authRepository.getCurretUser();
      if (user != null) {
        state = state.copyWithUser(user);
        debugPrint('User already logged in: ${user.email}');
      } else {
        state = state.copyWithUnauthenticated();
        debugPrint('No user logged in');
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      state = state.copyWithUnauthenticated();
    }
  }

  void _listenToAuthChanges() {
    authRepository.authStateChanges.listen((authState) {
      final user = authState.session?.user;
      if (user != null) {
        final userModel = UserModel.fromSupabaseUser(user);
        state = state.copyWithUser(userModel);
        debugPrint('Auth state changed - User logged in: ${user.email}');
      } else {
        state = state.copyWithUnauthenticated();
        debugPrint('Auth state changed - User logged out');
      }
    });
  }

  // Sign in with email and password
  Future<bool> signInwithEmail({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWithLoading(AuthLoadingType.emailLogin);

      final user = await authRepository.signInwithEmail(
        email: email,
        password: password,
      );

      state = state.copyWithUser(user);
      debugPrint('Sign in successful in provider');
      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      state = state.copyWithUnauthenticated(errorMessage);
      debugPrint('Sign in failed in provider: $errorMessage');
      return false;
    }
  }

  // Sign up with email and password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      state = state.copyWithLoading(AuthLoadingType.signup);
      final user = await authRepository.signUpWithEmail(
        email: email,
        password: password,
      );
      state = state.copyWithUser(user);
      debugPrint('Sign up successful in provider');
      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      state = state.copyWithUnauthenticated(errorMessage);
      debugPrint('Sign up failed in provider: $errorMessage');
      return false;
    }
  }

  // // Sign in with Google
  // Future<bool> signInwithGoogle() async {
  //   try {
  //     state = state.copyWithLoading(AuthLoadingType.googleLogin);
  //     final user = await authRepository.signInwithGoogle();
  //     state = state.copyWithUser(user);
  //     debugPrint('Google sign in successful in provider');
  //     return true;
  //   } catch (e) {
  //     final errorMessage = e.toString().replaceAll('Exception: ', '');
  //     state = state.copyWithUnauthenticated(errorMessage);
  //     debugPrint('Google sign in failed in provider: $errorMessage');
  //     return false;
  //   }
  // }

  // Sign out
  Future<void> signOut() async {
    try {
      await authRepository.signOut();
      state = state.copyWithUnauthenticated();
      debugPrint('Sign out successful in provider');
    } catch (e) {
      debugPrint('Sign out failed in provider: $e');
      state = state.copyWithUnauthenticated();
    }
  }

  // Reset password
  Future<bool> resetPassword({required String email}) async {
    try {
      await authRepository.resetPassword(email);
      debugPrint('Password reset email sent in provider');
      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Password reset failed in provider: $errorMessage');
      return false;
    }
  }

  // Resend confirmation email
  Future<bool> resendConfirmation({required String email}) async {
    try {
      await authRepository.resendConfirmation(email);
      debugPrint('Confirmation email resent in provider');
      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Resend confirmation failed in provider: $errorMessage');
      return false;
    }
  }

  // Update profile
  Future<bool> updateProfile({String? displayName, String? avatarUrl}) async {
    try {
      state = state.copyWithLoading(AuthLoadingType.profileUpdate);
      final user = await authRepository.updateProfile(
        displayName: displayName,
        avatarUrl: avatarUrl,
      );
      state = state.copyWithUser(user);
      debugPrint('Profile update successful in provider');
      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      state = state.copyWithUnauthenticated(errorMessage);
      debugPrint('Profile update failed in provider: $errorMessage');
      return false;
    }
  }

  // Clear error message
  void clearError() {
    if (state.errorMessage != null) {
      state = AuthState(
        status: state.status,
        user: state.user,
        loadingType: state.loadingType,
      );
    }
  }
}

//Providers

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return authRepository;
});

/// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

/// Current user provider (convenience)
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

/// Is authenticated provider (convenience)
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
