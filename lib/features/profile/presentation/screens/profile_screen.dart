import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planora/core/theme/theme_notifier.dart';
import 'package:planora/features/auth/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';

/// 👤 Profile Screen
///
/// Allows users to:
/// - View their profile information
/// - Edit display name
/// - Upload profile picture
/// - Change theme
/// - Logout
/// - Delete account
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

  /// Handle logout
  Future<void> _handleLogout() async {
    final confirmed = await _showConfirmDialog(
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      isDestructive: false,
    );

    if (confirmed != true) return;

    await ref.read(authProvider.notifier).signOut();

    if (!mounted) return;

    // Navigate to login
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);

    _showSnackBar('Logged out successfully', isError: false);
  }

  /// Handle delete account
  Future<void> _handleDeleteAccount() async {
    final confirmed = await _showConfirmDialog(
      title: 'Delete Account',
      message:
          'Are you sure? This action cannot be undone. All your data will be permanently deleted.',
      confirmText: 'Delete Account',
      isDestructive: true,
    );

    if (confirmed != true) return;

    // TODO: Implement account deletion in auth_repository.dart
    _showSnackBar('Account deletion - Coming soon!', isError: false);
  }

  /// Handle name update
  Future<void> _handleUpdateName() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Name cannot be empty', isError: true);
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .updateProfile(displayName: _nameController.text.trim());

    if (success) {
      setState(() => _isEditingName = false);
      _showSnackBar('Name updated successfully', isError: false);
    } else {
      _showSnackBar('Failed to update name', isError: true);
    }
  }

  /// Handle avatar upload
  Future<void> _handleAvatarUpload() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return;

      // TODO: Upload to Supabase Storage
      // For now, just show message
      _showSnackBar('Avatar upload - Coming soon!', isError: false);
    } catch (e) {
      _showSnackBar('Failed to pick image', isError: true);
    }
  }

  /// Show confirmation dialog
  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required bool isDestructive,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: isDestructive
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Show snackbar
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar Section
            Center(
              child: Stack(
                children: [
                  // Avatar Circle
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary,
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Edit Button
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _handleAvatarUpload,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Name Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Display Name',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                        ),
                        if (!_isEditingName)
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () {
                              setState(() {
                                _isEditingName = true;
                                _nameController.text =
                                    user.displayName ?? user.name;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isEditingName)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: 'Enter your name',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: _handleUpdateName,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() => _isEditingName = false);
                            },
                          ),
                        ],
                      )
                    else
                      Text(
                        user.displayName ?? user.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Email Section
            Card(
              child: ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(user.email),
              ),
            ),

            const SizedBox(height: 16),

            // Member Since Section
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Member Since'),
                subtitle: Text(
                  '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Settings Section
            Text('Settings', style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: 16),

            // Theme Toggle
            Card(
              child: SwitchListTile(
                secondary: Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                title: const Text('Dark Mode'),
                subtitle: Text(isDarkMode ? 'On' : 'Off'),
                value: isDarkMode,
                onChanged: (value) {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
              ),
            ),

            const SizedBox(height: 16),

            // Notifications (Coming Soon)
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notifications'),
                subtitle: const Text('Coming soon'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showSnackBar('Notifications - Coming soon!', isError: false);
                },
              ),
            ),

            const SizedBox(height: 32),

            // Danger Zone
            Text(
              'Danger Zone',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),

            const SizedBox(height: 16),

            // Delete Account Button
            Card(
              color: Theme.of(context).colorScheme.error.withOpacity(0.1),
              child: ListTile(
                leading: Icon(
                  Icons.delete_forever,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete Account',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('Permanently delete your account'),
                onTap: _handleDeleteAccount,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
