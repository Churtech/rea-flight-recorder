/// Configuration options for the Flight Recorder engine.
class FlightRecorderOptions {
  /// Maximum number of log entries maintained in the in-memory circular ring buffer.
  final int maxInMemoryLogs;

  /// Whether to write rotating log files on mobile and desktop platforms.
  final bool enableFilePersistence;

  /// Maximum file size in bytes before rotating the log file (e.g. 2 MB).
  final int maxFileSizeBytes;

  /// Name of the primary log file on disk.
  final String logFileName;

  /// Whether to echo recorded logs to the standard debug console (`debugPrint`).
  final bool echoToConsole;

  /// Whether to automatically redact known sensitive keys in metadata (passwords, tokens, cards).
  final bool sanitizeSecrets;

  /// Whether to automatically bind global error hooks ([FlutterError.onError] and [PlatformDispatcher.instance.onError])
  /// during [FlightRecorder.init]. Defaults to false.
  final bool attachErrorHooks;

  const FlightRecorderOptions({
    this.maxInMemoryLogs = 500,
    this.enableFilePersistence = true,
    this.maxFileSizeBytes = 2 * 1024 * 1024, // 2 MB
    this.logFileName = 'flight_recorder.log',
    this.echoToConsole = false,
    this.sanitizeSecrets = true,
    this.attachErrorHooks = false,
  });
}
