import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:planora/features/auth/data/model/user_model.dart';
import 'package:planora/features/profile/data/repositories/profile_repository.dart';

// ---------------------------------------------------------------------------
// Loading operation enum – tracks exactly which operation is in flight
// ---------------------------------------------------------------------------
enum ProfileLoadingOperation {
  none,
  fetching,
  updatingName,
  uploadingAvatar,
  deletingAccount,
}

// ---------------------------------------------------------------------------
// ProfileState – immutable value object for the profile UI
// ---------------------------------------------------------------------------
class ProfileState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;
  final ProfileLoadingOperation loadingOperation;

  const ProfileState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.loadingOperation = ProfileLoadingOperation.none,
  });

  factory ProfileState.initial() => const ProfileState();

  // Convenience getters used by the UI to show targeted loading indicators
  bool get isUploadingAvatar =>
      loadingOperation == ProfileLoadingOperation.uploadingAvatar;
  bool get isUpdatingName =>
      loadingOperation == ProfileLoadingOperation.updatingName;
  bool get isDeletingAccount =>
      loadingOperation == ProfileLoadingOperation.deletingAccount;
  bool get isFetching =>
      loadingOperation == ProfileLoadingOperation.fetching;

  ProfileState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    ProfileLoadingOperation? loadingOperation,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      loadingOperation: loadingOperation ?? this.loadingOperation,
    );
  }

  // Internal helpers – keep mutation logic in one place
  ProfileState _loading(ProfileLoadingOperation op) => ProfileState(
        user: user,
        isLoading: true,
        loadingOperation: op,
      );

  ProfileState _error(String msg) => ProfileState(
        user: user,
        isLoading: false,
        errorMessage: msg,
        loadingOperation: ProfileLoadingOperation.none,
      );

  ProfileState _success(UserModel updatedUser) => ProfileState(
        user: updatedUser,
        isLoading: false,
        loadingOperation: ProfileLoadingOperation.none,
      );
}

// ---------------------------------------------------------------------------
// ProfileNotifier – business logic using Riverpod 3 Notifier pattern
// ---------------------------------------------------------------------------
class ProfileNotifier extends Notifier<ProfileState> {
  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  @override
  ProfileState build() {
    // Auto-fetch profile data when this provider is first read
    Future.microtask(fetchProfile);
    return ProfileState.initial();
  }

  // ── Fetch ────────────────────────────────────────────────────────────────

  Future<void> fetchProfile() async {
    state = state._loading(ProfileLoadingOperation.fetching);
    try {
      final data = await _repo.fetchProfile();
      if (data == null) throw Exception('Profile not found');

      final user = UserModel(
        id: data['id'] as String,
        email: data['email'] as String,
        displayName: data['display_name'] as String?,
        avatarUrl: data['avatar_url'] as String?,
        createdAt: DateTime.parse(data['created_at'] as String),
      );
      state = state._success(user);
    } catch (e) {
      state = state._error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── Update display name ───────────────────────────────────────────────────

  Future<bool> updateDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;

    state = state._loading(ProfileLoadingOperation.updatingName);
    try {
      await _repo.updateDisplayName(trimmed);
      // Update local state optimistically after successful server write
      final updated = state.user!.copyWith(displayName: trimmed);
      state = state._success(updated);
      return true;
    } catch (e) {
      state = state._error(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // ── Upload avatar ─────────────────────────────────────────────────────────

  Future<bool> uploadAvatar(XFile imageFile) async {
    state = state._loading(ProfileLoadingOperation.uploadingAvatar);
    try {
      // Read file bytes then upload to Supabase Storage
      final bytes = await imageFile.readAsBytes();
      final publicUrl = await _repo.uploadAvatar(imageFile.path, bytes);

      // Persist the public URL in the profiles table + auth metadata
      await _repo.updateAvatarUrl(publicUrl);

      final updated = state.user!.copyWith(avatarUrl: publicUrl);
      state = state._success(updated);
      return true;
    } catch (e) {
      state = state._error(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // ── Delete account ────────────────────────────────────────────────────────

  Future<bool> deleteAccount() async {
    state = state._loading(ProfileLoadingOperation.deletingAccount);
    try {
      await _repo.deleteAccount(); // deletes profile row + signs out
      state = ProfileState.initial();
      return true;
    } catch (e) {
      state = state._error(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void clearError() => state = state.copyWith(clearError: true);
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final profileRepositoryProvider = Provider<ProfileRepository>(
  (_) => ProfileRepository(),
);

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
