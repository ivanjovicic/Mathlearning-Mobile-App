import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generic ApiService get/post calls are not referenced by runtime code', () async {
    final libDir = Directory('lib');
    final matches = <String, List<String>>{};
    final patterns = <String, RegExp>{
      'ApiService().get(': RegExp(r'\bApiService\s*\(\s*\)\s*\.\s*get\s*\('),
      'ApiService().post(': RegExp(r'\bApiService\s*\(\s*\)\s*\.\s*post\s*\('),
    };

    await for (final entity in libDir.list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final normalizedPath = entity.path.replaceAll('\\', '/');
      if (normalizedPath.endsWith('lib/services/api_service.dart')) {
        continue;
      }

      final content = await entity.readAsString();
      for (final entry in patterns.entries) {
        if (entry.value.hasMatch(content)) {
          matches.putIfAbsent(normalizedPath, () => []).add(entry.key);
        }
      }
    }

    expect(
      matches.keys,
      isEmpty,
      reason: 'Found generic ApiService get/post calls in runtime code: $matches',
    );
  });
}
