import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:planora/core/theme/theme_notifier.dart';
import 'package:planora/features/auth/providers/auth_provider.dart';
import 'package:planora/features/profile/providers/profile_provider.dart';

/// Profile screen – shows user info and settings.
///
/// Uses [profileProvider] for all profile data operations and
/// [authProvider] only for the sign-out action.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ── Avatar upload ─────────────────────────────────────────────────────────

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;

      final ok = await ref.read(profileProvider.notifier).uploadAvatar(image);
      if (!mounted) return;
      _snack(
        ok ? 'Avatar updated!' : _profileError('Failed to upload avatar'),
        isError: !ok,
      );
    } catch (_) {
      _snack('Could not open image picker', isError: true);
    }
  }

  // ── Name update ───────────────────────────────────────────────────────────

  Future<void> _saveName() async {
    final text = _nameController.text.trim();
    if (text.isEmpty) {
      _snack('Name cannot be empty', isError: true);
      return;
    }
    final ok = await ref.read(profileProvider.notifier).updateDisplayName(text);
    if (!mounted) return;
    if (ok) {
      setState(() => _isEditingName = false);
      _snack('Name updated!', isError: false);
    } else {
      _snack(_profileError('Failed to update name'), isError: true);
    }
  }

  // ── Auth actions ──────────────────────────────────────────────────────────

  Future<void> _logout() async {
    final confirmed = await _confirm(
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      destructive: false,
    );
    if (confirmed != true || !mounted) return;
    await ref.read(authProvider.notifier).signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _confirm(
      title: 'Delete Account',
      message:
          'This cannot be undone. All your data will be permanently deleted.',
      confirmText: 'Delete Account',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    final ok = await ref.read(profileProvider.notifier).deleteAccount();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } else {
      _snack(_profileError('Failed to delete account'), isError: true);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _profileError(String fallback) =>
      ref.read(profileProvider).errorMessage ?? fallback;

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmText,
    required bool destructive,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: destructive
                    ? Theme.of(ctx).colorScheme.error
                    : Theme.of(ctx).colorScheme.primary,
              ),
              child: Text(confirmText),
            ),
          ],
        ),
      );

  void _snack(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: isError
              ? Theme.of(context).colorScheme.error
              : const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final user = profileState.user;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = ref.watch(isDarkModeProvider);

    // Full-screen spinner on first load
    if (profileState.isFetching && user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Error / no-user state with retry option
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 64, color: cs.outline),
              const SizedBox(height: 16),
              Text('Could not load profile', style: tt.titleMedium),
              if (profileState.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  profileState.errorMessage!,
                  style: tt.bodySmall?.copyWith(color: cs.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(profileProvider.notifier).fetchProfile(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(profileProvider.notifier).fetchProfile(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero section ────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        _Avatar(
                          avatarUrl: user.avatarUrl,
                          initials: user.initials,
                          isUploading: profileState.isUploadingAvatar,
                          colorScheme: cs,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: _AvatarEditButton(
                            onTap: profileState.isUploadingAvatar
                                ? null
                                : _pickAndUploadAvatar,
                            colorScheme: cs,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user.name,
                      style:
                          tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style:
                          tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Personal info card ───────────────────────────────────────
              _SectionLabel('Personal Info'),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    // Display name (editable)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                      child: _isEditingName
                          ? _NameEditRow(
                              controller: _nameController,
                              isLoading: profileState.isUpdatingName,
                              onSave: _saveName,
                              onCancel: () =>
                                  setState(() => _isEditingName = false),
                            )
                          : _NameDisplayRow(
                              name: user.displayName ?? user.name,
                              colorScheme: cs,
                              onEdit: () => setState(() {
                                _isEditingName = true;
                                _nameController.text =
                                    user.displayName ?? user.name;
                              }),
                            ),
                    ),
                    const Divider(height: 1, indent: 16),
                    ListTile(
                      leading: Icon(Icons.email_outlined, color: cs.primary),
                      title: const Text('Email'),
                      subtitle: Text(user.email),
                      trailing: Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: cs.outline,
                      ),
                    ),
                    const Divider(height: 1, indent: 16),
                    ListTile(
                      leading: Icon(Icons.calendar_today, color: cs.primary),
                      title: const Text('Member Since'),
                      subtitle: Text(_formatDate(user.createdAt)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Settings card ────────────────────────────────────────────
              _SectionLabel('Settings'),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode,
                        color: cs.primary,
                      ),
                      title: const Text('Dark Mode'),
                      subtitle: Text(isDark ? 'On' : 'Off'),
                      value: isDark,
                      onChanged: (_) =>
                          ref.read(themeModeProvider.notifier).toggleTheme(),
                    ),
                    const Divider(height: 1, indent: 16),
                    ListTile(
                      leading: Icon(
                        Icons.notifications_outlined,
                        color: cs.primary,
                      ),
                      title: const Text('Notifications'),
                      subtitle: const Text('Coming soon'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () =>
                          _snack('Notifications – coming soon!', isError: false),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Danger zone ──────────────────────────────────────────────
              _SectionLabel('Danger Zone', color: cs.error),
              const SizedBox(height: 10),
              Card(
                color: cs.error.withValues(alpha: 0.07),
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: cs.error),
                  title: Text(
                    'Delete Account',
                    style: TextStyle(
                      color: cs.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('Permanently delete your account'),
                  trailing: profileState.isDeletingAccount
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.error,
                          ),
                        )
                      : Icon(Icons.arrow_forward_ios,
                          size: 14, color: cs.error),
                  onTap:
                      profileState.isDeletingAccount ? null : _deleteAccount,
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.avatarUrl,
    required this.initials,
    required this.isUploading,
    required this.colorScheme,
  });

  final String? avatarUrl;
  final String initials;
  final bool isUploading;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primary,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.35),
          width: 3,
        ),
      ),
      child: ClipOval(
        child: isUploading
            ? Center(
                child: CircularProgressIndicator(
                  color: colorScheme.onPrimary,
                  strokeWidth: 2.5,
                ),
              )
            : avatarUrl != null
                ? Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    // Fall back to initials if network image fails
                    errorBuilder: (context, error, stack) =>
                        _Initials(initials: initials),
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                  )
                : _Initials(initials: initials),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _AvatarEditButton extends StatelessWidget {
  const _AvatarEditButton({required this.onTap, required this.colorScheme});
  final VoidCallback? onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.secondary,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _NameDisplayRow extends StatelessWidget {
  const _NameDisplayRow({
    required this.name,
    required this.colorScheme,
    required this.onEdit,
  });
  final String name;
  final ColorScheme colorScheme;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.person_outline, color: colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Display Name',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: onEdit,
          tooltip: 'Edit name',
        ),
      ],
    );
  }
}

class _NameEditRow extends StatelessWidget {
  const _NameEditRow({
    required this.controller,
    required this.isLoading,
    required this.onSave,
    required this.onCancel,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSave(),
            decoration: const InputDecoration(
              hintText: 'Enter display name',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 4),
        if (isLoading)
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
            ),
          )
        else ...[
          IconButton(
            icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
            tooltip: 'Save',
            onPressed: onSave,
          ),
          IconButton(
            icon: Icon(Icons.cancel_rounded, color: cs.error),
            tooltip: 'Cancel',
            onPressed: onCancel,
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color ?? cs.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
    );
  }
}
