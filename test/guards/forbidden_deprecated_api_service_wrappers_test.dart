import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'deprecated ApiService wrappers are not referenced by runtime code',
    () async {
      final libDir = Directory('lib');
      final matches = <String, List<String>>{};

      final simplePatterns = <String, RegExp>{
        '.getAdaptivePath(': RegExp(r'\.\s*getAdaptivePath\s*\('),
        '.getAdaptivePathResult(': RegExp(r'\.\s*getAdaptivePathResult\s*\('),
        '.getAdaptiveReview(': RegExp(r'\.\s*getAdaptiveReview\s*\('),
        '.getAdaptiveReviewResult(': RegExp(r'\.\s*getAdaptiveReviewResult\s*\('),
        '.getAdaptiveRecommendations(': RegExp(
          r'\.\s*getAdaptiveRecommendations\s*\(',
        ),
        '.getAdaptiveRecommendationsResult(': RegExp(
          r'\.\s*getAdaptiveRecommendationsResult\s*\(',
        ),
        '.fetchLeaderboardRivals(': RegExp(r'\.\s*fetchLeaderboardRivals\s*\('),
        '.fetchSchoolLeaderboard(': RegExp(r'\.\s*fetchSchoolLeaderboard\s*\('),
        '.fetchSchoolLeaderboardDetail(': RegExp(
          r'\.\s*fetchSchoolLeaderboardDetail\s*\(',
        ),
        '.fetchSchoolLeaderboardHistory(': RegExp(
          r'\.\s*fetchSchoolLeaderboardHistory\s*\(',
        ),
      };

      final sensitivePatterns = <String, RegExp>{
        '.getQuestions(': RegExp(r'\.\s*getQuestions\s*\('),
        '.submitAnswer(': RegExp(r'\.\s*submitAnswer\s*\('),
      };
      final typedServiceMarkers = <String>[
        'QuizApiService',
        'AdaptiveContentApiService',
        'LeaderboardApiService',
        'PracticeSessionApiService',
      ];

      await for (final entity
          in libDir.list(recursive: true, followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;

        final normalizedPath = entity.path.replaceAll('\\', '/');
        if (normalizedPath.endsWith('lib/services/api_service.dart')) continue;

        final content = await entity.readAsString();
        final usesTypedDomainService = typedServiceMarkers.any(content.contains);
        if (usesTypedDomainService) {
          continue;
        }

        for (final entry in simplePatterns.entries) {
          if (entry.value.hasMatch(content)) {
            matches.putIfAbsent(normalizedPath, () => []).add(entry.key);
          }
        }

        // These two names are intentionally ignored in files that use the
        // typed quiz domain service, because the same method names exist there.
        for (final entry in sensitivePatterns.entries) {
          if (entry.value.hasMatch(content) && !content.contains('_offline.')) {
            matches.putIfAbsent(normalizedPath, () => []).add(entry.key);
          }
        }
      }

      expect(
        matches.keys,
        isEmpty,
        reason:
            'Use typed domain API services instead of deprecated ApiService wrappers. Found: $matches',
      );
    },
  );
}
