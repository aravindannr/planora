import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('No user logged in');
      }
      debugPrint('Fetching profile for user: $userId');

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      debugPrint('Profile fetched successfully');

      return response;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      rethrow;
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('No user logged in');
      }

      debugPrint('Updating display name to: $displayName');
      await _supabase
          .from('profiles')
          .update({
            'display_name': displayName,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      await _supabase.auth.updateUser(
        UserAttributes(data: {'display_name': displayName}),
      );
      debugPrint('Display name updated successfully');
    } catch (e) {
      debugPrint('Error updating display name: $e');
      throw Exception('Failed to update name. Please try again.');
    }
  }

  Future<void> updateAvatarUrl(String avatarUrl) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('No user logged in');
      }

      debugPrint('Updating avatar URL');

      // Update in profiles table
      await _supabase
          .from('profiles')
          .update({
            'avatar_url': avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Also update in auth metadata
      await _supabase.auth.updateUser(
        UserAttributes(data: {'avatar_url': avatarUrl}),
      );

      debugPrint('Avatar URL updated successfully');
    } catch (e) {
      debugPrint('Error updating avatar: $e');
      throw Exception('Failed to update avatar. Please try again.');
    }
  }

  Future<String> uploadAvatar(String filePath, Uint8List fileBytes) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('No user logged in');
      }

      debugPrint('Uploading avatar for user: $userId');

      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              cacheControl: '3600',
              upsert: true,
            ),
          );
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);
      debugPrint('Avatar uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      throw Exception('Failed to upload avatar. Please try again.');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('No user logged in');
      }

      debugPrint('Updating profile with data: $profileData');

      profileData['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('profiles').update(profileData).eq('id', userId);

      debugPrint('Profile updated successfully');
    } catch (e) {
      debugPrint('Error updating profile: $e');
      throw Exception('Failed to update profile. Please try again.');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('No user logged in');
      }

      debugPrint('Deleting account for user: $userId');

      await _supabase.from('profiles').delete().eq('id', userId);

      await _supabase.auth.signOut();

      debugPrint('Account deleted successfully');
    } catch (e) {
      debugPrint('Error deleting account: $e');
      throw Exception('Failed to delete account. Please try again.');
    }
  }

  Future<Map<String, dynamic>?> refreshProfile() async {
    return await fetchProfile();
  }
}
