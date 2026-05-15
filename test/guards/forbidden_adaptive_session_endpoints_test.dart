import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forbidden adaptive session endpoints are only in ApiService', () async {
    final forbidden = ['/api/adaptive/session/start', '/api/adaptive/session/answer'];
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

    // Allow these strings only in the legacy ApiService implementation.
    const allowedPath = 'lib/services/api_service.dart';
    final violations = matches.keys.where((p) => p != allowedPath).toList(growable: false);
    expect(violations, isEmpty, reason: 'Found forbidden endpoints in: $violations. Allowed only in $allowedPath');
  });
}
