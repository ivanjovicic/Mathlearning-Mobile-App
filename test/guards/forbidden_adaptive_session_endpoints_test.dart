import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unsupported backend endpoints are not referenced by runtime code', () async {
    // Backend OpenAPI is partial; this protects the critical Flutter runtime contract until full OpenAPI/codegen exists.
    final forbidden = [
      '/api/adaptive/session/start',
      '/api/adaptive/session/answer',
      '/api/analytics/mastery',
      '/api/chase/',
    ];
    final libDir = Directory('lib');
    final matches = <String, List<String>>{};

    await for (final entity in libDir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final content = await entity.readAsString();
        for (final f in forbidden) {
          if (content.contains(f)) {
            matches.putIfAbsent(entity.path.replaceAll('\\', '/'), () => []).add(f);
          }
        }
      }
    }

    // No runtime code should reference unsupported backend endpoints.
    final violations = matches.keys.toList(growable: false);
    expect(violations, isEmpty, reason: 'Found unsupported backend endpoints in runtime code: $violations');
  });
}
