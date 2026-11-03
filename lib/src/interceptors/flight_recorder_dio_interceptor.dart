import 'package:dio/dio.dart';

import '../flight_recorder.dart';
import 'flight_recorder_http_sanitizer.dart';

/// A [Dio] interceptor that captures HTTP network requests, responses,
/// and errors directly into the [FlightRecorder] blackbox.
class FlightRecorderDioInterceptor extends Interceptor {
  /// Whether to capture request and response headers. Defaults to true.
  final bool recordHeaders;

  /// Whether to capture the request body. Defaults to true.
  final bool recordRequestBody;

  /// Whether to capture the response body. Defaults to true.
  final bool recordResponseBody;

  /// Custom tag for HTTP log entries. Defaults to 'HTTP'.
  final String tag;

  /// Key used to store request start timestamp in [RequestOptions.extra].
  static const String _startTimeKey = '_flight_recorder_start_time';

  const FlightRecorderDioInterceptor({
    this.recordHeaders = true,
    this.recordRequestBody = true,
    this.recordResponseBody = true,
    this.tag = 'HTTP',
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startTimeKey] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = response.requestOptions.extra[_startTimeKey] as DateTime?;
    final duration = startTime != null
        ? DateTime.now().difference(startTime)
        : Duration.zero;

    final reqOptions = response.requestOptions;
    final sanitize = FlightRecorder.instance.options.sanitizeSecrets;

    final headers = recordHeaders
        ? (sanitize
            ? FlightRecorderHttpSanitizer.sanitizeMap(reqOptions.headers)
            : reqOptions.headers)
        : null;

    final reqBody = recordRequestBody ? _extractData(reqOptions.data, sanitize) : null;
    final resBody = recordResponseBody ? _extractData(response.data, sanitize) : null;

    FlightRecorder.instance.logHttp(
      method: reqOptions.method,
      url: reqOptions.uri.toString(),
      statusCode: response.statusCode ?? 200,
      duration: duration,
      requestHeaders: headers,
      requestBody: reqBody,
      responseBody: resBody,
      tag: tag,
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startTime = err.requestOptions.extra[_startTimeKey] as DateTime?;
    final duration = startTime != null
        ? DateTime.now().difference(startTime)
        : Duration.zero;

    final reqOptions = err.requestOptions;
    final sanitize = FlightRecorder.instance.options.sanitizeSecrets;

    final headers = recordHeaders
        ? (sanitize
            ? FlightRecorderHttpSanitizer.sanitizeMap(reqOptions.headers)
            : reqOptions.headers)
        : null;

    final reqBody = recordRequestBody ? _extractData(reqOptions.data, sanitize) : null;
    final resBody = recordResponseBody && err.response != null
        ? _extractData(err.response?.data, sanitize)
        : null;

    FlightRecorder.instance.logHttp(
      method: reqOptions.method,
      url: reqOptions.uri.toString(),
      statusCode: err.response?.statusCode ?? 0,
      duration: duration,
      requestHeaders: headers,
      requestBody: reqBody,
      responseBody: resBody ?? {'error': err.message, 'type': err.type.name},
      error: err,
      stackTrace: err.stackTrace,
      tag: tag,
    );

    handler.next(err);
  }

  Object? _extractData(dynamic data, bool sanitize) {
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      return sanitize ? FlightRecorderHttpSanitizer.sanitizeMap(data) : data;
    }

    if (data is Map) {
      final stringMap = data.map((k, v) => MapEntry(k.toString(), v));
      return sanitize ? FlightRecorderHttpSanitizer.sanitizeMap(stringMap) : stringMap;
    }

    if (data is FormData) {
      final fields = Map.fromEntries(data.fields);
      final files = data.files.map((f) => '[File: ${f.key} (${f.value.filename})]').toList();
      final map = <String, dynamic>{
        ...fields,
        if (files.isNotEmpty) 'files': files,
      };
      return sanitize ? FlightRecorderHttpSanitizer.sanitizeMap(map) : map;
    }

    if (data is List) {
      return data.map((item) => _extractData(item, sanitize)).toList();
    }

    return data.toString();
  }
}
