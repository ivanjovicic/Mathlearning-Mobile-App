import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Thin wrapper around the backend progress endpoints.
/// Uses the existing [ApiService] (Dio-backed with auth interceptor)
/// so tokens are attached automatically.
class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  final ApiService _api = ApiService();

  /// GET /api/progress/overview → full progress map
  Future<Map<String, dynamic>?> fetchProgress() async {
    try {
      return await _api.get('/api/progress/overview', null);
    } catch (e) {
      debugPrint('ProgressService.fetchProgress error: $e');
      return null;
    }
  }

  /// POST /api/progress/sync → push local progress to server
  Future<bool> pushProgress(Map<String, dynamic> progress) async {
    try {
      final result = await _api.post('/api/progress/sync', progress, null);
      return result != null;
    } catch (e) {
      debugPrint('ProgressService.pushProgress error: $e');
      return false;
    }
  }
}
