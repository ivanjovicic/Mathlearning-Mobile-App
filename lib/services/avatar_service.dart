import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class AvatarService {
  static final AvatarService instance = AvatarService._internal();
  AvatarService._internal();

  /// Upload user avatar (multipart upload)
  Future<String?> uploadAvatar(String userId, String filePath) async {
    try {
      final dio = AuthService.instance.client;

      // Create multipart form data
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          filePath,
          filename: 'avatar_$userId.jpg',
        ),
      });

      final response = await dio.post('/users/$userId/avatar', data: formData);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        // Backend should return the new avatar URL
        final avatarUrl =
            response.data['avatarUrl'] ?? response.data['avatar_url'];
        debugPrint('✅ Avatar uploaded: $avatarUrl');
        return avatarUrl;
      }

      debugPrint('⚠️ Avatar upload failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  /// Delete user avatar
  Future<bool> deleteAvatar(String userId) async {
    try {
      final dio = AuthService.instance.client;
      final response = await dio.delete('/users/$userId/avatar');

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        debugPrint('✅ Avatar deleted for user $userId');
        return true;
      }

      debugPrint('⚠️ Avatar deletion failed: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Error deleting avatar: $e');
      return false;
    }
  }
}
