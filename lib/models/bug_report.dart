class BugReport {
  final String id;
  final String reportType;
  final String screen;
  final String description;
  final String? stepsToReproduce;
  final String? severity;
  final String status;
  final String platform;
  final String locale;
  final String? username;
  final String? userId;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? screenshotUrl;
  final int? uxRating;
  final bool? liked;
  final String? suggestion;

  const BugReport({
    required this.id,
    required this.reportType,
    required this.screen,
    required this.description,
    required this.status,
    required this.platform,
    required this.locale,
    required this.createdAt,
    this.stepsToReproduce,
    this.severity,
    this.resolvedAt,
    this.screenshotUrl,
    this.username,
    this.userId,
    this.uxRating,
    this.liked,
    this.suggestion,
  });

  factory BugReport.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return BugReport(
      id: (json['id'] ?? '').toString(),
      reportType: (json['reportType'] ?? 'bug').toString(),
      screen: (json['screen'] ?? 'unknown').toString(),
      description: (json['description'] ?? '').toString(),
      stepsToReproduce: json['stepsToReproduce']?.toString(),
      severity: json['severity']?.toString(),
      status: (json['status'] ?? 'open').toString(),
      platform: (json['platform'] ?? '').toString(),
      locale: (json['locale'] ?? '').toString(),
      username: json['username']?.toString(),
      userId: json['userId']?.toString(),
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      resolvedAt: parseDate(json['resolvedAt']),
      screenshotUrl: json['screenshotUrl']?.toString(),
      uxRating: (json['uxRating'] as num?)?.toInt(),
      liked: json['liked'] as bool?,
      suggestion: json['suggestion']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportType': reportType,
      'screen': screen,
      'description': description,
      'stepsToReproduce': stepsToReproduce,
      'severity': severity,
      'status': status,
      'platform': platform,
      'locale': locale,
      'username': username,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'screenshotUrl': screenshotUrl,
      'uxRating': uxRating,
      'liked': liked,
      'suggestion': suggestion,
    };
  }
}
