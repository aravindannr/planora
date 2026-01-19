import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:planora/features/auth/data/model/user_model.dart';
import '../data/repositories/auth_repository.dart';

/// 🔐 Authentication State
enum AuthStatus { initial, authenticated, unauthenticated, loading }

/// Authentication State Class
class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({required this.status, this.user, this.errorMessage});

  /// Initial state
  factory AuthState.initial() {
    return const AuthState(status: AuthStatus.initial);
  }

  /// Loading state
  AuthState copyWithLoading() {
    return AuthState(status: AuthStatus.loading, user: user);
  }

  /// Authenticated state
  AuthState copyWithUser(UserModel user) {
    return AuthState(status: AuthStatus.authenticated, user: user);
  }

  /// Unauthenticated state
  AuthState copyWithUnauthenticated([String? error]) {
    return AuthState(status: AuthStatus.unauthenticated, errorMessage: error);
  }

  /// Check if authenticated
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  /// Check if loading
  bool get isLoading => status == AuthStatus.loading;
}

/// 🎯 Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState.initial()) {
    _checkAuthStatus();
  }

  /// Check initial auth status
  Future<void> _checkAuthStatus() async {
    try {
      final user = _authRepository.currentUser;
      if (user != null) {
        state = state.copyWithUser(user);
        debugPrint('✅ User already logged in: ${user.email}');
      } else {
        state = state.copyWithUnauthenticated();
        debugPrint('❌ No user logged in');
      }
    } catch (e) {
      debugPrint('❌ Error checking auth status: $e');
      state = state.copyWithUnauthenticated();
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWithLoading();

      final user = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );

      state = state.copyWithUser(user);
      debugPrint('✅ Sign in successful in provider');
      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      state = state.copyWithUnauthenticated(errorMessage);
      debugPrint('❌ Sign in failed in provider: $errorMessage');
      return false;
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      state = state.copyWithLoading();

      final user = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      state = state.copyWithUser(user);
      debugPrint('✅ Sign up successful in provider');
      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      state = state.copyWithUnauthenticated(errorMessage);
      debugPrint('❌ Sign up failed in provider: $errorMessage');
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      state = state.copyWithLoading();

      final user = await _authRepository.signInWithGoogle();

      state = state.copyWithUser(user);
      debugPrint('✅ Google sign in successful in provider');
      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      state = state.copyWithUnauthenticated(errorMessage);
      debugPrint('❌ Google sign in failed in provider: $errorMessage');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      state = state.copyWithUnauthenticated();
      debugPrint('✅ Sign out successful in provider');
    } catch (e) {
      debugPrint('❌ Sign out failed in provider: $e');
      // Still update state even if sign out fails
      state = state.copyWithUnauthenticated();
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _authRepository.resetPassword(email);
      debugPrint('✅ Password reset email sent');
      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      state = state.copyWithUnauthenticated(errorMessage);
      debugPrint('❌ Password reset failed: $errorMessage');
      return false;
    }
  }

  /// Update profile
  Future<bool> updateProfile({String? displayName, String? avatarUrl}) async {
    try {
      state = state.copyWithLoading();

      final user = await _authRepository.updateProfile(
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

      state = state.copyWithUser(user);
      debugPrint('✅ Profile updated in provider');
      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      // Don't change auth status, just log error
      debugPrint('❌ Profile update failed: $errorMessage');
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    if (state.errorMessage != null) {
      state = AuthState(status: state.status, user: state.user);
    }
  }
}

/// 🎯 Providers

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

/// 📝 USAGE EXAMPLES:
/// 
/// 1. Sign in:
/// ```dart
/// final success = await ref.read(authProvider.notifier).signInWithEmail(
///   email: 'user@example.com',
///   password: 'password123',
/// );
/// ```
/// 
/// 2. Get current user:
/// ```dart
/// final user = ref.watch(currentUserProvider);
/// ```
/// 
/// 3. Check if authenticated:
/// ```dart
/// final isAuth = ref.watch(isAuthenticatedProvider);
/// ```
/// 
/// 4. Sign out:
/// ```dart
/// await ref.read(authProvider.notifier).signOut();
/// ```