/// Severity level of a recorded flight log entry.
enum FlightLogLevel {
  debug,
  info,
  warning,
  error;

  /// Short uppercase label representation (e.g. 'INFO', 'WARN').
  String get tag {
    switch (this) {
      case FlightLogLevel.debug:
        return 'DEBUG';
      case FlightLogLevel.info:
        return 'INFO';
      case FlightLogLevel.warning:
        return 'WARN';
      case FlightLogLevel.error:
        return 'ERROR';
    }
  }

  /// Whether this level represents a problem (warning or error).
  bool get isSevere => this == FlightLogLevel.warning || this == FlightLogLevel.error;
}
