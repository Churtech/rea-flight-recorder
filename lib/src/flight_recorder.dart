import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'interceptors/flight_recorder_http_sanitizer.dart';
import 'models/flight_log_entry.dart';
import 'models/flight_log_level.dart';
import 'models/flight_recorder_icons.dart';
import 'models/flight_recorder_options.dart';
import 'models/flight_recorder_strings.dart';
import 'models/flight_recorder_theme.dart';
import 'storage/flight_log_storage.dart';
import 'ui/flight_recorder_modal.dart';

/// Central facade and singleton manager for the Flight Recorder blackbox engine.
class FlightRecorder {
  static final FlightRecorder _instance = FlightRecorder._internal();
  factory FlightRecorder() => _instance;
  FlightRecorder._internal();

  /// Global singleton instance.
  static FlightRecorder get instance => _instance;

  FlightLogStorage _storage = FlightLogStorage();
  bool _initialized = false;

  /// Underlying storage manager.
  FlightLogStorage get storage => _storage;

  /// Active configuration options.
  FlightRecorderOptions get options => _storage.options;

  /// Reactive notifier with the count of active in-memory log entries.
  ValueNotifier<int> get logCountNotifier => _storage.logCountNotifier;

  /// Initializes the engine with custom [options].
  Future<void> init({FlightRecorderOptions? options}) async {
    if (_initialized) return;
    final opts = options ?? const FlightRecorderOptions();
    _storage = FlightLogStorage(options: opts);
    await _storage.init();
    _initialized = true;

    if (opts.attachErrorHooks) {
      installErrorHooks();
    }
  }

  /// Automatically intercepts unhandled Flutter framework errors and
  /// uncaught asynchronous platform errors, recording them as [FlightLogLevel.error].
  ///
  /// Preserves any pre-existing [FlutterError.onError] or [PlatformDispatcher.onError] handlers.
  void installErrorHooks({
    bool recordFlutterErrors = true,
    bool recordPlatformErrors = true,
  }) {
    if (recordFlutterErrors) {
      final originalFlutterOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        error(
          details.exceptionAsString(),
          tag: 'FLUTTER_ERROR',
          error: details.exception,
          stackTrace: details.stack,
          metadata: {
            if (details.library != null) 'library': details.library,
            if (details.context != null) 'context': details.context.toString(),
          },
        );
        originalFlutterOnError?.call(details);
      };
    }

    if (recordPlatformErrors) {
      final originalPlatformOnError = PlatformDispatcher.instance.onError;
      PlatformDispatcher.instance.onError = (Object errorObj, StackTrace stack) {
        error(
          errorObj.toString(),
          tag: 'UNCAUGHT_ASYNC',
          error: errorObj,
          stackTrace: stack,
        );
        return originalPlatformOnError?.call(errorObj, stack) ?? false;
      };
    }
  }

  /// Appends an informational message.
  void info(
    String message, {
    String? tag,
    Map<String, dynamic>? metadata,
  }) {
    log(message, level: FlightLogLevel.info, tag: tag, metadata: metadata);
  }

  /// Appends a debug message.
  void debug(
    String message, {
    String? tag,
    Map<String, dynamic>? metadata,
  }) {
    log(message, level: FlightLogLevel.debug, tag: tag, metadata: metadata);
  }

  /// Appends a warning message.
  void warn(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    log(
      message,
      level: FlightLogLevel.warning,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Appends an error or critical failure message.
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    log(
      message,
      level: FlightLogLevel.error,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Appends a general log entry.
  void log(
    String message, {
    FlightLogLevel level = FlightLogLevel.info,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    Map<String, dynamic>? sanitizedMeta;
    if (metadata != null) {
      sanitizedMeta = _storage.options.sanitizeSecrets
          ? FlightRecorderHttpSanitizer.sanitizeMap(metadata)
          : metadata;
    }

    final entry = FlightLogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      metadata: sanitizedMeta,
    );

    _storage.addEntry(entry);
  }

  /// Records an HTTP network call with request/response metadata and duration.
  void logHttp({
    required String method,
    required String url,
    int? statusCode,
    Duration? duration,
    Map<String, dynamic>? requestHeaders,
    dynamic requestBody,
    dynamic responseBody,
    Object? error,
    StackTrace? stackTrace,
    String tag = 'HTTP',
  }) {
    final status = statusCode != null ? '$statusCode' : 'FAILED';
    final durStr = duration != null ? '${duration.inMilliseconds}ms' : '-';
    final isSuccess = statusCode != null && statusCode >= 200 && statusCode < 400;

    final meta = <String, dynamic>{
      'method': method.toUpperCase(),
      'url': url,
      'status': status,
      'duration': durStr,
    };

    if (requestHeaders != null && requestHeaders.isNotEmpty) {
      meta['req_headers'] = requestHeaders;
    }
    if (requestBody != null) {
      meta['req_body'] = requestBody;
    }
    if (responseBody != null) {
      meta['res_body'] = responseBody;
    }

    log(
      'HTTP ${method.toUpperCase()} $url [$status] ($durStr)',
      level: isSuccess ? FlightLogLevel.info : FlightLogLevel.error,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      metadata: meta,
    );
  }

  /// Records a formatted diagnostic banner (e.g. app version, OS, user ID).
  void setDiagnosticHeader({
    String? appName,
    String? appVersion,
    String? buildNumber,
    String? osVersion,
    String? deviceModel,
    String? userId,
    Map<String, String>? customFields,
    String reason = 'APP STARTUP',
  }) {
    final buffer = StringBuffer('=== SESSION DIAGNOSTIC HEADER ($reason) ===\n');
    if (appName != null) buffer.writeln('  App Name    : $appName');
    if (appVersion != null) {
      final buildStr = buildNumber != null ? '+$buildNumber' : '';
      buffer.writeln('  App Version : $appVersion$buildStr');
    }
    if (deviceModel != null) buffer.writeln('  Device Model: $deviceModel');
    if (osVersion != null) buffer.writeln('  OS Version  : $osVersion');
    if (userId != null) buffer.writeln('  User ID     : $userId');

    if (customFields != null && customFields.isNotEmpty) {
      for (final entry in customFields.entries) {
        buffer.writeln('  ${entry.key.padRight(12)}: ${entry.value}');
      }
    }
    buffer.write('==============================================');

    log(buffer.toString(), level: FlightLogLevel.info, tag: 'DIAGNOSTICS');
  }

  /// Displays the interactive flight recorder viewer modal dialog.
  Future<void> showViewer(
    BuildContext context, {
    FlightRecorderTheme? theme,
    FlightRecorderStrings? strings,
    FlightRecorderIcons? icons,
  }) {
    return FlightRecorderModal.show(
      context,
      storage: _storage,
      theme: theme,
      strings: strings,
      icons: icons,
    );
  }

  /// Wipes all in-memory and disk logs.
  Future<void> clear() => _storage.clearLogs();

  /// Gets filtered logs.
  List<FlightLogEntry> getLogs({
    FlightLogLevel? filterLevel,
    String? filterTag,
    String? searchQuery,
  }) =>
      _storage.getLogs(
        filterLevel: filterLevel,
        filterTag: filterTag,
        searchQuery: searchQuery,
      );

  /// Gets filtered logs formatted as plaintext.
  String getLogsAsString({
    FlightLogLevel? filterLevel,
    String? filterTag,
    String? searchQuery,
  }) =>
      _storage.getLogsAsString(
        filterLevel: filterLevel,
        filterTag: filterTag,
        searchQuery: searchQuery,
      );
}
