import 'flight_log_level.dart';

/// Represents an immutable log entry in the flight recorder buffer.
class FlightLogEntry {
  /// Timestamp when the entry was recorded.
  final DateTime timestamp;

  /// Severity level of the entry.
  final FlightLogLevel level;

  /// Human-readable log message.
  final String message;

  /// Optional module or category tag (e.g. 'HTTP', 'AUTH', 'UI').
  final String? tag;

  /// Optional error or exception associated with the log.
  final Object? error;

  /// Optional stack trace captured with the error.
  final StackTrace? stackTrace;

  /// Optional structured metadata dictionary.
  final Map<String, dynamic>? metadata;

  const FlightLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
    this.metadata,
  });

  /// Formats the log entry into a standard logline string.
  String formatted({bool includeStackTrace = true}) {
    final iso = timestamp.toIso8601String();
    final time = iso.length >= 19 ? iso.substring(11, 19) : iso;
    final tagPrefix = tag != null && tag!.isNotEmpty ? '[$tag] ' : '';
    final buffer = StringBuffer('[$time] [${level.tag}] $tagPrefix$message');

    if (metadata != null && metadata!.isNotEmpty) {
      buffer.write('\n  Metadata: $metadata');
    }
    if (error != null) {
      buffer.write('\n  Error: $error');
    }
    if (includeStackTrace && stackTrace != null) {
      buffer.write('\n  StackTrace: $stackTrace');
    }

    return buffer.toString();
  }

  @override
  String toString() => formatted();
}
