import 'package:flutter/foundation.dart';

class AdaptiveAnalyticsService {
  AdaptiveAnalyticsService._();
  static final AdaptiveAnalyticsService instance = AdaptiveAnalyticsService._();

  static const String adaptivePathLoaded = 'adaptive_path_loaded';
  static const String adaptivePracticeStarted = 'adaptive_practice_started';
  static const String adaptiveSessionCompleted = 'adaptive_session_completed';
  static const String adaptiveRetryTriggered = 'adaptive_retry_triggered';

  void logEvent(String name, [Map<String, Object?> params = const {}]) {
    debugPrint('[Analytics] $name ${params.isEmpty ? '' : params}');
  }
}
