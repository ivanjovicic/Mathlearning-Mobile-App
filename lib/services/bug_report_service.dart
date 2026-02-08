import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bug_report.dart';
import 'auth_service.dart';

enum BugReportSubmitResult { sent, queued }

class BugReportService {
  BugReportService._();
  static final BugReportService instance = BugReportService._();

  static const String _pendingKey = 'pending_bug_reports';
  static const String _myReportsCacheKey = 'my_bug_reports_cache';
  static const String _myFeedbackCacheKey = 'my_feedback_cache';
  static const String _legacyEndpoint = '/api/bugs/report';
  static const String _feedbackEndpoint = '/api/feedback/report';

  Future<BugReportSubmitResult> submitReport({
    required String screen,
    required String description,
    required String severity,
    required String stepsToReproduce,
    String? screenshotBase64,
  }) async {
    final payload = _buildCommonPayload(
      screen: screen,
      description: description,
      reportType: 'bug',
      screenshotBase64: screenshotBase64,
    )..addAll({
        'severity': severity,
        'stepsToReproduce': stepsToReproduce,
      });

    return _submitWithQueue(
      endpoint: _legacyEndpoint,
      fallbackEndpoint: null,
      payload: payload,
    );
  }

  Future<BugReportSubmitResult> submitUxUiFeedback({
    required String screen,
    required String description,
    required int uxRating,
    required bool liked,
    String? suggestion,
    String? screenshotBase64,
  }) async {
    final payload = _buildCommonPayload(
      screen: screen,
      description: description,
      reportType: 'ux_ui_feedback',
      screenshotBase64: screenshotBase64,
    )..addAll({
        'uxRating': uxRating,
        'liked': liked,
        'suggestion': suggestion,
      });

    // Tries dedicated endpoint first; falls back to legacy bugs endpoint.
    return _submitWithQueue(
      endpoint: _feedbackEndpoint,
      fallbackEndpoint: _legacyEndpoint,
      payload: payload,
    );
  }

  Map<String, dynamic> _buildCommonPayload({
    required String screen,
    required String description,
    required String reportType,
    String? screenshotBase64,
  }) {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    return <String, dynamic>{
      'reportType': reportType,
      'screen': screen,
      'description': description,
      'screenshotBase64': screenshotBase64,
      'createdAt': DateTime.now().toIso8601String(),
      'platform': defaultTargetPlatform.name,
      'isWeb': kIsWeb,
      'locale': dispatcher.locale.toLanguageTag(),
      'userId': AuthService.instance.userId,
      'username': AuthService.instance.username,
    };
  }

  Future<BugReportSubmitResult> _submitWithQueue({
    required String endpoint,
    required Map<String, dynamic> payload,
    String? fallbackEndpoint,
  }) async {
    final sent = await _trySend(
      endpoint: endpoint,
      payload: payload,
      fallbackEndpoint: fallbackEndpoint,
    );
    if (sent) {
      await syncPendingReports();
      return BugReportSubmitResult.sent;
    }

    await _enqueuePending(
      endpoint: endpoint,
      payload: payload,
      fallbackEndpoint: fallbackEndpoint,
    );
    return BugReportSubmitResult.queued;
  }

  Future<bool> _trySend({
    required String endpoint,
    required Map<String, dynamic> payload,
    String? fallbackEndpoint,
  }) async {
    try {
      await AuthService.instance.client.post(endpoint, data: payload);
      return true;
    } catch (_) {
      if (fallbackEndpoint == null) {
        return false;
      }
      try {
        await AuthService.instance.client.post(fallbackEndpoint, data: payload);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<void> syncPendingReports() async {
    final pending = await _loadPending();
    if (pending.isEmpty) {
      return;
    }

    final failed = <Map<String, dynamic>>[];
    for (final report in pending) {
      final endpoint = report['__endpoint']?.toString() ?? _legacyEndpoint;
      final fallbackEndpoint = report['__fallbackEndpoint']?.toString();
      final payload = report['payload'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(report['payload'] as Map)
          : Map<String, dynamic>.from(report);

      final sent = await _trySend(
        endpoint: endpoint,
        fallbackEndpoint: fallbackEndpoint,
        payload: payload,
      );
      if (!sent) {
        failed.add(report);
      }
    }

    await _savePending(failed);
  }

  Future<void> _enqueuePending({
    required String endpoint,
    required Map<String, dynamic> payload,
    String? fallbackEndpoint,
  }) async {
    final pending = await _loadPending();
    pending.add({
      '__endpoint': endpoint,
      '__fallbackEndpoint': fallbackEndpoint,
      'payload': payload,
    });
    await _savePending(pending);
  }

  Future<List<Map<String, dynamic>>> _loadPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
    } catch (_) {}
    return <Map<String, dynamic>>[];
  }

  Future<void> _savePending(List<Map<String, dynamic>> reports) async {
    final prefs = await SharedPreferences.getInstance();
    if (reports.isEmpty) {
      await prefs.remove(_pendingKey);
      return;
    }
    await prefs.setString(_pendingKey, jsonEncode(reports));
  }

  Future<List<BugReport>> fetchMyReports({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await AuthService.instance.client.get(
        '/api/bugs/mine',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final data = response.data;
      if (data is List) {
        final reports = data
            .map((item) => BugReport.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        await _saveMyReportsCache(reports);
        return reports;
      }
    } catch (_) {
      // Fallback to cache if offline / endpoint unavailable.
    }
    return _loadMyReportsCache();
  }

  Future<List<BugReport>> fetchMyFeedback({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await AuthService.instance.client.get(
        '/api/feedback/mine',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final data = response.data;
      if (data is List) {
        final feedback = data
            .map((item) => BugReport.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        await _saveMyFeedbackCache(feedback);
        return feedback;
      }
    } catch (_) {
      // Fallback below.
    }

    try {
      final reports = await fetchMyReports(limit: limit, offset: offset);
      final feedbackOnly = reports
          .where((item) => item.reportType.toLowerCase() == 'ux_ui_feedback')
          .toList();
      await _saveMyFeedbackCache(feedbackOnly);
      return feedbackOnly;
    } catch (_) {
      return _loadMyFeedbackCache();
    }
  }

  Future<List<BugReport>> _loadMyReportsCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_myReportsCacheKey);
    if (raw == null || raw.isEmpty) {
      return <BugReport>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((item) => BugReport.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {}
    return <BugReport>[];
  }

  Future<void> _saveMyReportsCache(List<BugReport> reports) async {
    final prefs = await SharedPreferences.getInstance();
    final data = reports.map((item) => item.toJson()).toList();
    await prefs.setString(_myReportsCacheKey, jsonEncode(data));
  }

  Future<List<BugReport>> _loadMyFeedbackCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_myFeedbackCacheKey);
    if (raw == null || raw.isEmpty) {
      return <BugReport>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((item) => BugReport.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {}
    return <BugReport>[];
  }

  Future<void> _saveMyFeedbackCache(List<BugReport> feedback) async {
    final prefs = await SharedPreferences.getInstance();
    final data = feedback.map((item) => item.toJson()).toList();
    await prefs.setString(_myFeedbackCacheKey, jsonEncode(data));
  }
}
