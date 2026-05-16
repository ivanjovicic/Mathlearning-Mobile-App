import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'deprecated ApiService wrappers are not referenced by runtime code',
    () async {
      final libDir = Directory('lib');
      final matches = <String, List<String>>{};

      final wrapperPatterns = <String, RegExp>{
        'getAdaptivePath': RegExp(
          r'\b(?:api|apiService|_api|service|ApiService\s*\(\s*\))\s*\.\s*getAdaptivePath\s*\(',
        ),
        'getAdaptiveReview': RegExp(
          r'\b(?:api|apiService|_api|service|ApiService\s*\(\s*\))\s*\.\s*getAdaptiveReview\s*\(',
        ),
        'getAdaptiveRecommendations': RegExp(
          r'\b(?:api|apiService|_api|service|ApiService\s*\(\s*\))\s*\.\s*getAdaptiveRecommendations\s*\(',
        ),
        'fetchLeaderboardRivals': RegExp(
          r'\b(?:api|apiService|_api|service|ApiService\s*\(\s*\))\s*\.\s*fetchLeaderboardRivals\s*\(',
        ),
        'fetchSchoolLeaderboard': RegExp(
          r'\b(?:api|apiService|_api|service|ApiService\s*\(\s*\))\s*\.\s*fetchSchoolLeaderboard\s*\(',
        ),
        'getQuestions': RegExp(
          r'\b(?:api|apiService|_api|service|ApiService\s*\(\s*\))\s*\.\s*getQuestions\s*\(',
        ),
        'submitAnswer': RegExp(
          r'\b(?:api|apiService|_api|service|ApiService\s*\(\s*\))\s*\.\s*submitAnswer\s*\(',
        ),
      };
      final typedServiceImports = <String>[
        "quiz_api_service.dart",
        "adaptive_content_api_service.dart",
        "leaderboard_api_service.dart",
        "practice_session_api_service.dart",
      ];

      await for (final entity
          in libDir.list(recursive: true, followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;

        final normalizedPath = entity.path.replaceAll('\\', '/');
        if (normalizedPath.endsWith('lib/services/api_service.dart')) {
          continue;
        }

        final content = await entity.readAsString();
        if (!content.contains("api_service.dart")) {
          continue;
        }
        if (typedServiceImports.any(content.contains)) {
          continue;
        }

        for (final entry in wrapperPatterns.entries) {
          if (entry.value.hasMatch(content)) {
            matches.putIfAbsent(normalizedPath, () => []).add(entry.key);
          }
        }
      }

      expect(
        matches.keys,
        isEmpty,
        reason:
            'Use typed domain API service instead of ApiService wrapper. Found deprecated wrapper calls: $matches',
      );
    },
  );
}
