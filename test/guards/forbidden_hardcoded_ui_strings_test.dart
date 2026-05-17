import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guard hardcoded user-facing UI strings', () async {
    final enforce =
        Platform.environment['ENFORCE_HARDCODED_UI_STRINGS'] == 'true';

    final libDir = Directory('lib');
    final findingsByFile = <String, List<_Finding>>{};

    await for (final entity in libDir.list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final normalizedPath = entity.path.replaceAll('\\', '/');
      if (_shouldSkipFile(normalizedPath)) {
        continue;
      }

      final content = await entity.readAsString();
      final findings = _scanFindings(content);
      if (findings.isEmpty) {
        continue;
      }

      findingsByFile[normalizedPath] = findings;
    }

    final totalFindings = findingsByFile.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    if (!enforce) {
      if (totalFindings > 0) {
        final topFiles = findingsByFile.entries.toList()
          ..sort((a, b) => b.value.length.compareTo(a.value.length));
        final topSummary = topFiles
            .take(10)
            .map((entry) => '${entry.key} (${entry.value.length})')
            .join('\n');
        // ignore: avoid_print
        print(
          'TODO (enforce=false): hardcoded UI string candidates: '
          '$totalFindings\n$topSummary',
        );
      }
      expect(true, isTrue);
      return;
    }

    expect(
      totalFindings,
      0,
      reason:
          'Move user-facing text to AppI18n and use context.t. Found: $totalFindings',
    );
  });
}

class _Finding {
  final int offset;
  final String value;

  const _Finding({required this.offset, required this.value});
}

bool _shouldSkipFile(String path) {
  if (path.endsWith('lib/l10n/app_i18n.dart')) return true;

  final generatedSuffixes = <String>[
    '.g.dart',
    '.freezed.dart',
    '.mocks.dart',
    '.gen.dart',
  ];
  if (generatedSuffixes.any(path.endsWith)) return true;
  if (path.endsWith('generated_plugin_registrant.dart')) return true;

  final noisyDirs = <String>[
    '/models/',
    '/routes/',
    '/route/',
    '/theme/',
  ];
  if (noisyDirs.any(path.contains)) return true;

  return false;
}

List<_Finding> _scanFindings(String content) {
  final patterns = <RegExp>[
    RegExp(r'''\bText\s*\(\s*(['"])(.*?)\1''', dotAll: true),
    RegExp(
      r'''\bSnackBar\s*\([\s\S]*?content\s*:\s*Text\s*\(\s*(['"])(.*?)\1''',
      dotAll: true,
    ),
    RegExp(
      r'''\bAppBar\s*\([\s\S]*?title\s*:\s*Text\s*\(\s*(['"])(.*?)\1''',
      dotAll: true,
    ),
    RegExp(
      r'''\bInputDecoration\s*\([\s\S]*?labelText\s*:\s*(['"])(.*?)\1''',
      dotAll: true,
    ),
    RegExp(
      r'''\bElevatedButton\s*\([\s\S]*?child\s*:\s*Text\s*\(\s*(['"])(.*?)\1''',
      dotAll: true,
    ),
  ];

  final findings = <_Finding>[];
  final seen = <String>{};

  for (final pattern in patterns) {
    for (final match in pattern.allMatches(content)) {
      final value = (match.group(2) ?? '').trim();
      if (_isAllowedLiteral(value)) {
        continue;
      }

      final key = '${match.start}:$value';
      if (!seen.add(key)) {
        continue;
      }
      findings.add(_Finding(offset: match.start, value: value));
    }
  }

  return findings;
}

bool _isAllowedLiteral(String value) {
  if (value.isEmpty) return true;

  final normalized = value.trim();
  if (normalized.isEmpty) return true;

  if (normalized.length <= 3 &&
      RegExp(r'^[A-Za-z0-9%/:+\-]+$').hasMatch(normalized)) {
    return true;
  }

  final lower = normalized.toLowerCase();
  if (lower.contains('debug') ||
      lower.startsWith('todo') ||
      lower.startsWith('fixme')) {
    return true;
  }

  if (normalized.contains('assets/') ||
      normalized.startsWith('http://') ||
      normalized.startsWith('https://') ||
      normalized.startsWith('/api/') ||
      normalized.startsWith('api/') ||
      normalized.startsWith('ws://') ||
      normalized.startsWith('wss://')) {
    return true;
  }

  if (normalized.contains('.png') ||
      normalized.contains('.jpg') ||
      normalized.contains('.jpeg') ||
      normalized.contains('.svg') ||
      normalized.contains('.json')) {
    return true;
  }

  if (RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(normalized) &&
      (normalized.contains('_') || normalized.endsWith('Key'))) {
    return true;
  }

  if (RegExp(r'^[A-Za-z0-9/_:%.-]+$').hasMatch(normalized) &&
      normalized.contains('/')) {
    return true;
  }

  if (RegExp(r'^(test|demo|admin|user|student)[/_-]?[A-Za-z0-9]*$')
      .hasMatch(lower)) {
    return true;
  }

  return false;
}
