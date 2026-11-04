import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rea_flight_recorder/rea_flight_recorder.dart';

const _fontAwesomeIcons = FlightRecorderIcons(
  terminal: FaIcon(FontAwesomeIcons.terminal, size: 20),
  close: FaIcon(FontAwesomeIcons.xmark, size: 20),
  search: FaIcon(FontAwesomeIcons.magnifyingGlass, size: 16),
  clearSearch: FaIcon(FontAwesomeIcons.xmark, size: 16),
  delete: FaIcon(FontAwesomeIcons.trashCan, size: 18),
  copy: FaIcon(FontAwesomeIcons.copy, size: 18),
  export: FaIcon(FontAwesomeIcons.download, size: 16),
  feedbackSuccess: FaIcon(FontAwesomeIcons.circleCheck, size: 16, color: Colors.greenAccent),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize the Flight Recorder engine with automatic error hooks
  await FlightRecorder.instance.init(
    options: const FlightRecorderOptions(
      maxInMemoryLogs: 500,
      echoToConsole: true,
      sanitizeSecrets: true,
      attachErrorHooks: true,
    ),
  );

  // 2. Set startup diagnostic header
  FlightRecorder.instance.setDiagnosticHeader(
    appName: 'FlightRecorderDemo',
    appVersion: '1.0.0',
    buildNumber: '1',
    deviceModel: 'Flutter Demo Device',
    osVersion: 'Android / iOS / Web',
    userId: 'user_dev_001',
    customFields: {
      'Environment': 'Staging',
      'Feature': 'Diagnostic Blackbox',
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flight Recorder Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _counter = 0;
  late final Dio _dio;

  @override
  void initState() {
    super.initState();
    _dio = Dio(BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 5),
    ));
    _dio.interceptors.add(const FlightRecorderDioInterceptor());
  }

  void _simulateSuccessAction() {
    setState(() => _counter++);
    FlightRecorder.instance.info(
      'User tapped button. Counter incremented to $_counter',
      tag: 'UI_ACTION',
      metadata: {'counter': _counter},
    );
  }

  void _simulateWarning() {
    FlightRecorder.instance.warn(
      'Device network signal is weak (latency > 800ms)',
      tag: 'NETWORK',
      metadata: {'latency_ms': 850},
    );
  }

  void _simulateError() {
    try {
      throw const FormatException('Simulated unexpected payload parse error');
    } catch (e, stackTrace) {
      FlightRecorder.instance.error(
        'Failed to process checkout payload',
        tag: 'CHECKOUT',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _simulateDioCall() async {
    try {
      await _dio.get('/posts/1');
    } catch (e) {
      debugPrint('Dio request failed: $e');
    }
  }

  void _simulateFlutterHookError() {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: StateError('Simulated unhandled state fault caught by hook'),
        library: 'checkout_module',
        context: ErrorDescription('testing global error interception'),
      ),
    );
  }

  void _simulateHttpCall() {
    FlightRecorder.instance.logHttp(
      method: 'POST',
      url: 'https://api.churtech.com/v1/auth/login',
      statusCode: 200,
      duration: const Duration(milliseconds: 142),
      requestHeaders: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer secret_token_xyz',
      },
      requestBody: {
        'username': 'john.doe@example.com',
        'password': 'superSecretPassword!',
      },
      responseBody: {
        'status': 'success',
        'token': 'jwt_access_token_123',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight Recorder Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_rounded),
            tooltip: 'Open Blackbox Logs',
            onPressed: () => FlightRecorder.instance.showViewer(
              context,
              strings: FlightRecorderStrings.spanish(),
              icons: _fontAwesomeIcons,
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flight_takeoff_rounded, size: 64, color: Colors.deepPurple),
              const SizedBox(height: 16),
              const Text(
                'In-App Flight Recorder',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Generate test logs below, then long-press the version text or tap the bug icon to view the blackbox modal.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Info Log'),
                    onPressed: _simulateSuccessAction,
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade100),
                    icon: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    label: const Text('Warn Log', style: TextStyle(color: Colors.black87)),
                    onPressed: _simulateWarning,
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100),
                    icon: const Icon(Icons.error_outline_rounded, color: Colors.red),
                    label: const Text('Error Log', style: TextStyle(color: Colors.red)),
                    onPressed: _simulateError,
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade100),
                    icon: const Icon(Icons.http_rounded, color: Colors.blue),
                    label: const Text('HTTP Call', style: TextStyle(color: Colors.blue)),
                    onPressed: _simulateHttpCall,
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade100),
                    icon: const Icon(Icons.cloud_sync_rounded, color: Colors.teal),
                    label: const Text('Dio Request', style: TextStyle(color: Colors.teal)),
                    onPressed: _simulateDioCall,
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade100),
                    icon: const Icon(Icons.flash_on_rounded, color: Colors.purple),
                    label: const Text('Crash Hook', style: TextStyle(color: Colors.purple)),
                    onPressed: _simulateFlutterHookError,
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Trigger wrapper matching the konjunto secret trigger pattern
              FlightRecorderTrigger(
                mode: FlightRecorderTriggerMode.longPress,
                strings: FlightRecorderStrings.spanish(),
                icons: _fontAwesomeIcons,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Version 1.0.0 (Hold to open blackbox)',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
