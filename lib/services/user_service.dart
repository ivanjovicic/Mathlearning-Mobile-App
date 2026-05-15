import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/user_api_service.dart';

class UserService {
  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._();

  UserService._();

  final UserApiService _apiService = UserApiService();
  UserProfile? _currentProfile;

  /// Get current user profile (cached or from API)
  Future<UserProfile?> getCurrentProfile({bool forceRefresh = false}) async {
    if (_currentProfile != null && !forceRefresh) {
      return _currentProfile;
    }

    try {
      final profileData = await _apiService.getUserProfile();
      if (profileData != null) {
        _currentProfile = UserProfile.fromJson(profileData);
        debugPrint('✅ Profile loaded: ${_currentProfile?.displayName}');
        return _currentProfile;
      }
    } catch (e) {
      debugPrint('❌ Failed to load profile: $e');
    }

    return null;
  }

  Future<UserProfile?> getPublicProfile(String userId) async {
    try {
      final profileData = await _apiService.getUserProfileById(userId);
      if (profileData != null) {
        return UserProfile.fromJson(profileData);
      }
    } catch (e) {
      debugPrint('âŒ Failed to load public profile $userId: $e');
    }

    return null;
  }

  /// Update user profile
  Future<UserProfile?> updateProfile({
    String? displayName,
    String? email,
  }) async {
    try {
      final updateData = await _apiService.updateUserProfile(
        displayName: displayName,
        email: email,
      );

      if (updateData != null) {
        _currentProfile = UserProfile.fromJson(updateData);
        debugPrint('✅ Profile updated: ${_currentProfile?.displayName}');
        return _currentProfile;
      }
    } catch (e) {
      debugPrint('❌ Failed to update profile: $e');
    }

    return null;
  }

  /// Search for users
  Future<List<UserSearchResult>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final searchResults = await _apiService.searchUsers(query.trim());
      if (searchResults != null) {
        final users = searchResults
            .map((userData) => UserSearchResult.fromJson(userData))
            .toList();

        debugPrint('✅ Found ${users.length} users for query: "$query"');
        return users;
      }
    } catch (e) {
      debugPrint('❌ Failed to search users: $e');
    }

    return [];
  }

  /// Register new mobile user
  Future<UserProfile?> registerMobileUser({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final registrationData = await _apiService.registerMobileUser(
        username: username,
        email: email,
        password: password,
        displayName: displayName,
      );

      if (registrationData != null) {
        // Extract profile from registration response
        final profileData =
            registrationData['profile'] ?? registrationData['user'];
        if (profileData != null) {
          _currentProfile = UserProfile.fromJson(profileData);
          debugPrint(
            '✅ Mobile user registered: ${_currentProfile?.displayName} with ${_currentProfile?.coins} coins',
          );
          return _currentProfile;
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to register mobile user: $e');
    }

    return null;
  }

  /// Clear cached profile (for logout)
  void clearProfile() {
    _currentProfile = null;
    debugPrint('🔄 Profile cache cleared');
  }

  /// Get user coins (from profile or API)
  Future<int> getUserCoins() async {
    // Try to get coins from cached profile first
    if (_currentProfile != null) {
      return _currentProfile!.coins;
    }

    // Fallback to API call
    try {
      final coins = await _apiService.getUserCoins();
      return coins ?? 0;
    } catch (e) {
      debugPrint('❌ Failed to get user coins: $e');
      return 0;
    }
  }

  /// Update cached profile coins (for local updates)
  void updateLocalCoins(int newCoins) {
    if (_currentProfile != null) {
      _currentProfile = _currentProfile!.copyWith(coins: newCoins);
      debugPrint('🪙 Local coins updated: $newCoins');
    }
  }

  /// Demo mode profile for testing
  UserProfile get demoProfile => UserProfile(
    id: '1',
    username: 'demo_user',
    email: 'demo@example.com',
    displayName: 'Demo User',
    coins: 100,
    xp: 250,
    level: 3,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now(),
  );
}
