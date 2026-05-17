import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stdout.writeln('Directory not found: lib/');
    return;
  }

  final textLiteralPattern = RegExp(r'''Text\s*\(\s*(['"])(.*?)\1''');
  final snackBarPattern = RegExp(r'''SnackBar\s*\(\s*content\s*:\s*Text\s*\(''');
  final appBarPattern = RegExp(r'''AppBar\s*\(\s*title\s*:\s*Text\s*\(''');
  final inputDecorationPattern = RegExp(r'''InputDecoration\s*\(\s*labelText\s*:''');
  final tooltipPattern = RegExp(r'''Tooltip\s*\(\s*message\s*:''');
  final semanticsPattern = RegExp(r'''Semantics\s*\(\s*label\s*:''');

  final matches = <String>[];

  for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }

    final path = entity.path.replaceAll('\\', '/');
    if (_shouldSkip(path)) {
      continue;
    }

    final lines = entity.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final lineNumber = index + 1;

      final textMatch = textLiteralPattern.firstMatch(line);
      if (textMatch != null) {
        final snippet = 'Text("${textMatch.group(2) ?? ''}")';
        matches.add('$path:$lineNumber  $snippet');
        continue;
      }

      if (snackBarPattern.hasMatch(line)) {
        matches.add('$path:$lineNumber  SnackBar(content: Text(');
        continue;
      }

      if (appBarPattern.hasMatch(line)) {
        matches.add('$path:$lineNumber  AppBar(title: Text(');
        continue;
      }

      if (inputDecorationPattern.hasMatch(line)) {
        matches.add('$path:$lineNumber  ${_clip(line)}');
        continue;
      }

      if (tooltipPattern.hasMatch(line)) {
        matches.add('$path:$lineNumber  ${_clip(line)}');
        continue;
      }

      if (semanticsPattern.hasMatch(line)) {
        matches.add('$path:$lineNumber  ${_clip(line)}');
      }
    }
  }

  stdout.writeln('Hardcoded Flutter UI string report');
  stdout.writeln('Scanned: lib/');
  stdout.writeln('Matches: ${matches.length}');
  stdout.writeln('');

  for (final match in matches) {
    stdout.writeln(match);
  }
}

bool _shouldSkip(String path) {
  if (path == 'lib/l10n/app_i18n.dart') {
    return true;
  }

  if (path.contains('/models/')) {
    return true;
  }

  if (path.contains('/services/network/')) {
    return true;
  }

  const generatedSuffixes = <String>[
    '.g.dart',
    '.freezed.dart',
    '.gen.dart',
    '.mocks.dart',
  ];
  if (generatedSuffixes.any(path.endsWith)) {
    return true;
  }

  return false;
}

String _clip(String line) {
  final trimmed = line.trim();
  if (trimmed.length <= 140) {
    return trimmed;
  }
  return '${trimmed.substring(0, 137)}...';
}
