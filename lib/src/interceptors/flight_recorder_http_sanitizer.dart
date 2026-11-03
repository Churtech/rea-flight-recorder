/// Utility to redact sensitive credentials, tokens, and personal data from logs.
class FlightRecorderHttpSanitizer {
  static const Set<String> defaultSensitiveKeys = {
    'password',
    'pass',
    'pwd',
    'secret',
    'token',
    'access_token',
    'refresh_token',
    'authorization',
    'auth',
    'bearer',
    'pin',
    'cvv',
    'cvc',
    'card_number',
    'credit_card',
    'pan',
  };

  /// Redacts sensitive values in a key-value map recursively.
  static Map<String, dynamic> sanitizeMap(
    Map<String, dynamic> map, {
    Set<String>? sensitiveKeys,
  }) {
    final keysToSanitize = sensitiveKeys ?? defaultSensitiveKeys;
    final sanitized = <String, dynamic>{};

    for (final entry in map.entries) {
      final keyLower = entry.key.toLowerCase();
      if (keysToSanitize.any((s) => keyLower.contains(s))) {
        sanitized[entry.key] = '***REDACTED***';
      } else if (entry.value is Map<String, dynamic>) {
        sanitized[entry.key] = sanitizeMap(
          entry.value as Map<String, dynamic>,
          sensitiveKeys: keysToSanitize,
        );
      } else if (entry.value is List) {
        sanitized[entry.key] = _sanitizeList(
          entry.value as List,
          keysToSanitize,
        );
      } else {
        sanitized[entry.key] = entry.value;
      }
    }

    return sanitized;
  }

  static List<dynamic> _sanitizeList(
    List<dynamic> list,
    Set<String> sensitiveKeys,
  ) {
    return list.map((item) {
      if (item is Map<String, dynamic>) {
        return sanitizeMap(item, sensitiveKeys: sensitiveKeys);
      } else if (item is List) {
        return _sanitizeList(item, sensitiveKeys);
      }
      return item;
    }).toList();
  }
}
