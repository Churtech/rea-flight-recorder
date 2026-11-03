import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rea_flight_recorder/rea_flight_recorder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlightLogStorage', () {
    test('enforces max in-memory capacity and discards oldest', () {
      final storage = FlightLogStorage(
        options: const FlightRecorderOptions(
          maxInMemoryLogs: 3,
          enableFilePersistence: false,
        ),
      );

      for (int i = 1; i <= 5; i++) {
        storage.addEntry(
          FlightLogEntry(
            timestamp: DateTime.now(),
            level: FlightLogLevel.info,
            message: 'Log #$i',
          ),
        );
      }

      expect(storage.count, equals(3));
      final logs = storage.getLogs();
      expect(logs.first.message, equals('Log #3'));
      expect(logs.last.message, equals('Log #5'));
    });

    test('filters logs by level correctly', () {
      final storage = FlightLogStorage(
        options: const FlightRecorderOptions(enableFilePersistence: false),
      );

      storage.addEntry(FlightLogEntry(
        timestamp: DateTime.now(),
        level: FlightLogLevel.debug,
        message: 'Debug details',
      ));
      storage.addEntry(FlightLogEntry(
        timestamp: DateTime.now(),
        level: FlightLogLevel.info,
        message: 'User logged in',
      ));
      storage.addEntry(FlightLogEntry(
        timestamp: DateTime.now(),
        level: FlightLogLevel.error,
        message: 'Database timeout',
      ));

      expect(storage.getLogs(filterLevel: FlightLogLevel.error).length, equals(1));
      expect(storage.getLogs(filterLevel: FlightLogLevel.info).length, equals(1));
      expect(storage.getLogs().length, equals(3));
    });

    test('filters logs by search query and tag', () {
      final storage = FlightLogStorage(
        options: const FlightRecorderOptions(enableFilePersistence: false),
      );

      storage.addEntry(FlightLogEntry(
        timestamp: DateTime.now(),
        level: FlightLogLevel.info,
        message: 'GET /api/v1/users',
        tag: 'HTTP',
      ));
      storage.addEntry(FlightLogEntry(
        timestamp: DateTime.now(),
        level: FlightLogLevel.info,
        message: 'Screen viewed: ProfileScreen',
        tag: 'NAV',
      ));

      expect(storage.getLogs(filterTag: 'HTTP').length, equals(1));
      expect(storage.getLogs(searchQuery: 'users').length, equals(1));
      expect(storage.getLogs(searchQuery: 'nonexistent').length, equals(0));
    });

    test('clears in-memory logs and updates count notifier', () async {
      final storage = FlightLogStorage(
        options: const FlightRecorderOptions(enableFilePersistence: false),
      );

      storage.addEntry(FlightLogEntry(
        timestamp: DateTime.now(),
        level: FlightLogLevel.info,
        message: 'Log to wipe',
      ));
      expect(storage.count, equals(1));

      await storage.clearLogs();
      expect(storage.count, equals(0));
      expect(storage.logCountNotifier.value, equals(0));
    });
  });

  group('FlightRecorderHttpSanitizer', () {
    test('redacts sensitive keys in nested maps', () {
      final payload = {
        'username': 'john_doe',
        'password': 'superSecretPassword123',
        'credentials': {
          'token': 'jwt_bearer_token_xyz',
          'account': '123456',
        },
        'cards': [
          {'credit_card': '4532015012345678', 'bank': 'Bancolombia'},
        ],
      };

      final sanitized = FlightRecorderHttpSanitizer.sanitizeMap(payload);

      expect(sanitized['username'], equals('john_doe'));
      expect(sanitized['password'], equals('***REDACTED***'));
      expect((sanitized['credentials'] as Map)['token'], equals('***REDACTED***'));
      expect((sanitized['credentials'] as Map)['account'], equals('123456'));
      expect(((sanitized['cards'] as List).first as Map)['credit_card'],
          equals('***REDACTED***'));
      expect(((sanitized['cards'] as List).first as Map)['bank'],
          equals('Bancolombia'));
    });
  });

  group('FlightRecorder Facade', () {
    test('records HTTP logs with metadata and sanitized secrets', () async {
      final recorder = FlightRecorder.instance;
      await recorder.init(
        options: const FlightRecorderOptions(
          enableFilePersistence: false,
          sanitizeSecrets: true,
        ),
      );

      recorder.logHttp(
        method: 'POST',
        url: 'https://api.example.com/auth/login',
        statusCode: 200,
        duration: const Duration(milliseconds: 150),
        requestBody: {'user': 'admin', 'password': 'plainPassword'},
      );

      final logs = recorder.getLogs(filterTag: 'HTTP');
      expect(logs.isNotEmpty, isTrue);
      expect(logs.last.message, contains('POST https://api.example.com/auth/login [200]'));
      final meta = logs.last.metadata!;
      final reqBody = meta['req_body'] as Map<String, dynamic>;
      expect(reqBody['password'], equals('***REDACTED***'));
    });

    test('formats diagnostic header correctly', () async {
      final recorder = FlightRecorder.instance;
      await recorder.clear();

      recorder.setDiagnosticHeader(
        appName: 'TestApp',
        appVersion: '1.2.0',
        buildNumber: '42',
        deviceModel: 'Pixel 8',
        osVersion: 'Android 14',
      );

      final logs = recorder.getLogs(filterTag: 'DIAGNOSTICS');
      expect(logs.isNotEmpty, isTrue);
      expect(logs.last.message, contains('App Name    : TestApp'));
      expect(logs.last.message, contains('App Version : 1.2.0+42'));
      expect(logs.last.message, contains('Device Model: Pixel 8'));
    });
  });

  group('FlightRecorderTrigger Widget', () {
    testWidgets('triggers callback on long press', (tester) async {
      bool triggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlightRecorderTrigger(
              mode: FlightRecorderTriggerMode.longPress,
              onCustomTrigger: () => triggered = true,
              child: const Text('Version 1.0.0'),
            ),
          ),
        ),
      );

      expect(triggered, isFalse);
      await tester.longPress(find.text('Version 1.0.0'));
      expect(triggered, isTrue);
    });

    testWidgets('triggers callback on multiTap after required count', (tester) async {
      bool triggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlightRecorderTrigger(
              mode: FlightRecorderTriggerMode.multiTap,
              requiredTaps: 3,
              onCustomTrigger: () => triggered = true,
              child: const Text('Tap Me 3 Times'),
            ),
          ),
        ),
      );

      expect(triggered, isFalse);
      await tester.tap(find.text('Tap Me 3 Times'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Tap Me 3 Times'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(triggered, isFalse);

      await tester.tap(find.text('Tap Me 3 Times'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(triggered, isTrue);
    });
  });

  group('FlightRecorderDioInterceptor', () {
    test('records response and redacts secrets in headers and body', () {
      final recorder = FlightRecorder.instance;
      recorder.clear();

      const interceptor = FlightRecorderDioInterceptor();
      final reqOptions = RequestOptions(
        path: 'https://api.example.com/login',
        method: 'POST',
        headers: {'Authorization': 'Bearer 123456'},
        data: {'username': 'test', 'password': 'plainPassword'},
      );

      final response = Response(
        requestOptions: reqOptions,
        statusCode: 200,
        data: {'token': 'jwt_token_secret', 'success': true},
      );

      interceptor.onRequest(reqOptions, RequestInterceptorHandler());
      interceptor.onResponse(response, ResponseInterceptorHandler());

      final logs = recorder.getLogs(filterTag: 'HTTP');
      expect(logs.isNotEmpty, isTrue);
      expect(logs.last.message, contains('HTTP POST https://api.example.com/login [200]'));
      final meta = logs.last.metadata!;
      final headers = meta['req_headers'] as Map;
      final body = meta['req_body'] as Map;
      final resBody = meta['res_body'] as Map;
      expect(headers['Authorization'], equals('***REDACTED***'));
      expect(body['password'], equals('***REDACTED***'));
      expect(resBody['token'], equals('***REDACTED***'));
    });

    test('records network error with stack trace', () async {
      final recorder = FlightRecorder.instance;
      recorder.clear();

      const interceptor = FlightRecorderDioInterceptor();
      final reqOptions = RequestOptions(
        path: 'https://api.example.com/fail',
        method: 'GET',
      );
      final dioError = DioException(
        requestOptions: reqOptions,
        message: 'Connection timed out',
        type: DioExceptionType.connectionTimeout,
      );

      final handler = _TestErrorHandler();
      interceptor.onError(dioError, handler);
      try {
        await handler.completion;
      } catch (_) {}

      final logs = recorder.getLogs(filterTag: 'HTTP');
      expect(logs.isNotEmpty, isTrue);
      expect(logs.last.level, equals(FlightLogLevel.error));
      expect(logs.last.message, contains('HTTP GET https://api.example.com/fail [0]'));
    });
  });

  group('Global Error Hooks', () {
    test('intercepts FlutterError and records into blackbox', () {
      final recorder = FlightRecorder.instance;
      recorder.clear();
      recorder.installErrorHooks();

      FlutterError.reportError(
        FlutterErrorDetails(
          exception: Exception('Widget build exploded'),
          library: 'rendering library',
          context: ErrorDescription('during layout pass'),
        ),
      );

      final logs = recorder.getLogs(filterTag: 'FLUTTER_ERROR');
      expect(logs.isNotEmpty, isTrue);
      expect(logs.last.level, equals(FlightLogLevel.error));
      expect(logs.last.message, contains('Widget build exploded'));
      expect(logs.last.metadata?['library'], equals('rendering library'));
    });
  });

  group('FlightRecorderModal Feedback Toast', () {
    testWidgets('displays in-modal toast on copy action', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall message) async => null,
      );

      final storage = FlightLogStorage(
        options: const FlightRecorderOptions(enableFilePersistence: false),
      );
      storage.addEntry(FlightLogEntry(
        timestamp: DateTime.now(),
        level: FlightLogLevel.info,
        message: 'Sample test log',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlightRecorderModal(storage: storage),
          ),
        ),
      );

      expect(find.textContaining('Sample test log'), findsOneWidget);
      expect(find.textContaining('Logs copied'), findsNothing);

      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Logs copied'), findsOneWidget);
    });
  });
}

class _TestErrorHandler extends ErrorInterceptorHandler {
  Future<dynamic> get completion => future;
}
