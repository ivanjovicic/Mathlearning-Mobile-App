import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'deprecated ApiService wrappers are not referenced by runtime code',
    () async {
      final libDir = Directory('lib');
      final matches = <String, List<String>>{};
      final forbiddenWrapperNames = <String>[
        'getAdaptivePath',
        'getAdaptivePathResult',
        'getAdaptiveReview',
        'getAdaptiveReviewResult',
        'getAdaptiveRecommendations',
        'getAdaptiveRecommendationsResult',
        'fetchLeaderboardRivals',
        'fetchSchoolLeaderboard',
        'fetchSchoolLeaderboardDetail',
        'fetchSchoolLeaderboardHistory',
      ];

      final apiServiceVars = RegExp(
        r'\b(?:final|var|late\s+final|late)\s+(?:ApiService\s+)?([A-Za-z_]\w*)\s*=\s*ApiService\s*\(\s*\)',
        multiLine: true,
      );
      final apiServiceFields = RegExp(
        r'\bfinal\s+ApiService\s+([A-Za-z_]\w*)\s*;',
        multiLine: true,
      );

      await for (final entity in libDir.list(recursive: true, followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }

        final normalizedPath = entity.path.replaceAll('\\', '/');
        if (normalizedPath.endsWith('lib/services/api_service.dart')) {
          continue;
        }

        final content = await entity.readAsString();
        final candidateReceivers = <String>{
          ...apiServiceVars
              .allMatches(content)
              .map((m) => m.group(1))
              .whereType<String>(),
          ...apiServiceFields
              .allMatches(content)
              .map((m) => m.group(1))
              .whereType<String>(),
        };

        for (final method in forbiddenWrapperNames) {
          final directCall = RegExp(
            '\\bApiService\\s*\\(\\s*\\)\\s*\\.\\s*$method\\s*\\(',
          );
          if (directCall.hasMatch(content)) {
            matches.putIfAbsent(normalizedPath, () => []).add('$method(');
          }

          for (final receiver in candidateReceivers) {
            final receiverCall = RegExp(
              '\\b$receiver\\s*\\.\\s*$method\\s*\\(',
            );
            if (receiverCall.hasMatch(content)) {
              matches.putIfAbsent(normalizedPath, () => []).add('$method(');
            }
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
