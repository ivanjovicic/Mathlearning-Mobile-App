import 'dart:convert';

import 'package:go_router/go_router.dart';

final class RouteParserHelpers {
  const RouteParserHelpers._();

  static Uri buildUri(
    String path, {
    Map<String, String?> queryParameters = const <String, String?>{},
  }) {
    final filtered = <String, String>{};
    for (final entry in queryParameters.entries) {
      final value = entry.value;
      if (value == null || value.isEmpty) continue;
      filtered[entry.key] = value;
    }
    return Uri(path: path, queryParameters: filtered.isEmpty ? null : filtered);
  }

  static Uri locationUri(GoRouterState state) => Uri.parse(state.location);

  static int requireIntPathParam(GoRouterState state, String key) {
    final parsed = tryParseIntPathParam(state, key);
    if (parsed == null) {
      throw FormatException('Missing or invalid path parameter "$key".');
    }
    return parsed;
  }

  static int? tryParseIntPathParam(GoRouterState state, String key) {
    return int.tryParse(state.pathParameters[key] ?? '');
  }

  static int? tryParseIntQuery(GoRouterState state, String key) {
    return int.tryParse(state.queryParameters[key] ?? '');
  }

  static bool parseBoolQuery(
    GoRouterState state,
    String key, {
    bool defaultValue = false,
  }) {
    final raw = state.queryParameters[key];
    if (raw == null) return defaultValue;
    return raw == '1' || raw.toLowerCase() == 'true';
  }

  static String? maybeQuery(GoRouterState state, String key) {
    final value = state.queryParameters[key];
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static String encodeJsonPayload(Map<String, dynamic> payload) {
    final json = jsonEncode(payload);
    return base64Url.encode(utf8.encode(json));
  }

  static Map<String, dynamic>? decodeJsonPayload(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = utf8.decode(base64Url.decode(base64Url.normalize(raw)));
      final json = jsonDecode(decoded);
      if (json is Map<String, dynamic>) {
        return json;
      }
      if (json is Map) {
        return Map<String, dynamic>.from(json);
      }
    } catch (_) {
      // Invalid payload; caller decides fallback behavior.
    }
    return null;
  }

  static String encodeContinuation(String location) {
    return base64Url.encode(utf8.encode(location));
  }

  static String? decodeContinuation(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return utf8.decode(base64Url.decode(base64Url.normalize(encoded)));
    } catch (_) {
      return null;
    }
  }

  static String? sanitizeContinuation(
    String? location, {
    required Set<String> forbiddenPrefixes,
  }) {
    if (location == null || location.isEmpty) return null;
    final uri = Uri.tryParse(location);
    if (uri == null) return null;
    for (final prefix in forbiddenPrefixes) {
      if (uri.path.startsWith(prefix)) return null;
    }
    return uri.toString();
  }
}
