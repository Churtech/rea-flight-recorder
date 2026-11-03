# rea_flight_recorder

An in-app diagnostic blackbox and flight recorder for Flutter applications.

Captures unhandled errors, user breadcrumbs, and HTTP network requests in a high-performance in-memory circular ring buffer and rotating file on disk. Includes an interactive developer modal viewer that can be triggered via secret gestures (such as long-pressing the app version text or tapping 5 times).

---

## Features

- **Circular Ring Buffer**: Maintains the latest $N$ logs in memory without memory leaks or performance degradation.
- **Rotating Disk Persistence**: Automatically writes logs to disk (`flight_recorder.log`) on iOS, Android, and Desktop, rotating out to `.old.log` once the size limit (e.g. 2 MB) is reached.
- **Web Storage**: Transparently saves and restores logs from `localStorage` on Web.
- **Secret Gesture Trigger (`FlightRecorderTrigger`)**: Wrap any widget (like version text, company logo, or profile banner) to open the blackbox modal on long-press, double-tap, or $N$ consecutive taps with haptic feedback.
- **Diagnostic Viewer Modal (`FlightRecorderModal`)**:
  - Real-time substring search across messages, errors, and tags.
  - Severity level filter chips (`Debug`, `Info`, `Warn`, `Error`).
  - Copy all or filtered logs to clipboard.
  - Native file sharing/exporting via share sheet.
  - Wipe logs with confirmation dialog.
- **Sensitive Data Redaction**: Automatically redacts passwords, bearer tokens, secret keys, PINs, and credit card numbers from metadata maps.
- **Dio HTTP Interceptor**: Zero-boilerplate network recording with `FlightRecorderDioInterceptor()`.
- **Automatic Crash & Error Hooks**: Captures unhandled Flutter widget build errors (`FlutterError.onError`) and uncaught async faults (`PlatformDispatcher.onError`) automatically.
- **HTTP Network Logger**: Built-in helper to record HTTP calls with status codes, latency, headers, and request/response payloads.
- **Multi-language Support**: English default with built-in Spanish preset (`FlightRecorderStrings.spanish()`) and fully customizable labels.
- **Zero Framework Lock-in**: Works with any state management (Bloc, Riverpod, Provider, GetX) and any router (GoRouter, AutoRoute, Navigator).

---

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  rea_flight_recorder: ^0.1.0
```

Or consume it via Git:

```yaml
dependencies:
  rea_flight_recorder:
    git:
      url: https://github.com/Churtech/rea-flight-recorder.git
      ref: main
```

---

## Quickstart

### 1. Initialize the recorder in `main()`

```dart
import 'package:flutter/material.dart';
import 'package:rea_flight_recorder/rea_flight_recorder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the engine
  await FlightRecorder.instance.init(
    options: const FlightRecorderOptions(
      maxInMemoryLogs: 500,
      enableFilePersistence: true,
      maxFileSizeBytes: 2 * 1024 * 1024, // 2 MB
      sanitizeSecrets: true,
      echoToConsole: false,
    ),
  );

  // Optional: Record app startup diagnostic header
  FlightRecorder.instance.setDiagnosticHeader(
    appName: 'MyAwesomeApp',
    appVersion: '1.2.0',
    buildNumber: '45',
    deviceModel: 'Pixel 8 / iPhone 15',
    osVersion: 'Android 14 / iOS 17',
    userId: 'user_12345',
  );

  runApp(const MyApp());
}
```

---

### 2. Add secret gesture trigger in your UI

Wrap any widget (like your build version label in the settings or login screen) using `FlightRecorderTrigger`:

```dart
FlightRecorderTrigger(
  mode: FlightRecorderTriggerMode.longPress, // or multiTap (e.g. 5 taps)
  strings: FlightRecorderStrings.spanish(),  // Optional Spanish labels
  child: Text(
    'Version 1.2.0 (Hold to open blackbox)',
    style: Theme.of(context).textTheme.bodySmall,
  ),
)
```

When a tester, QA engineer, or user long-presses this widget, the device emits a heavy haptic vibration and displays the diagnostic logs modal.

---

### 3. Recording logs throughout your app

```dart
// Info
FlightRecorder.instance.info('User completed KYC step 1', tag: 'ONBOARDING');

// Debug
FlightRecorder.instance.debug('Rendering frame with 12 items', tag: 'UI');

// Warning
FlightRecorder.instance.warn(
  'Payment API response was slow (> 1200ms)',
  tag: 'PAYMENTS',
  metadata: {'latency_ms': 1250},
);

// Error with StackTrace
try {
  throw Exception('Payment gateway timed out');
} catch (e, stackTrace) {
  FlightRecorder.instance.error(
    'Failed to charge credit card',
    tag: 'PAYMENTS',
    error: e,
    stackTrace: stackTrace,
  );
}

// HTTP Network Call with automatic password/token redaction
FlightRecorder.instance.logHttp(
  method: 'POST',
  url: 'https://api.example.com/v1/login',
  statusCode: 200,
  duration: const Duration(milliseconds: 180),
  requestHeaders: {'Authorization': 'Bearer secret_token'}, // Automatically masked!
  requestBody: {'user': 'admin', 'password': 'mySecretPassword'}, // Automatically masked!
);
```

---

### 4. Zero-boilerplate Dio HTTP Interceptor

If you use [Dio](https://pub.dev/packages/dio), add `FlightRecorderDioInterceptor` to capture requests, responses, status codes, latencies, and redacted headers/bodies automatically:

```dart
final dio = Dio();
dio.interceptors.add(const FlightRecorderDioInterceptor());
```

---

### 5. Automatic Crash & Uncaught Error Interception

Capture unhandled Flutter widget exceptions and async framework crashes without wrapping everything in manual `try/catch`:

```dart
// Option A: During init
await FlightRecorder.instance.init(
  options: const FlightRecorderOptions(attachErrorHooks: true),
);

// Option B: Explicitly anytime
FlightRecorder.instance.installErrorHooks();
```

---

### 6. Manually opening the viewer modal

If you want to open the modal from an admin drawer, debug menu, or shake detector:

```dart
FlightRecorder.instance.showViewer(
  context,
  strings: FlightRecorderStrings.spanish(),
  theme: FlightRecorderTheme.darkConsole(),
);
```

---

## Architecture Overview

```
                   +--------------------------------+
                   |         FlightRecorder         |  <-- Facade
                   +---------------+----------------+
                                   |
             +---------------------+---------------------+
             |                                           |
             v                                           v
   +--------------------+                      +--------------------+
   | FlightLogStorage   |                      | FlightRecorderUI   |
   +---------+----------+                      +---------+----------+
             |                                           |
    +--------+--------+                         +--------+--------+
    |                 |                         |                 |
    v                 v                         v                 v
In-Memory         Rotating File            Modal Viewer       Gesture Trigger
Ring Buffer       (Disk / Web)             (Search & Export)  (Long-press / Multi-tap)
```

---

## Example App

Check the [`example/`](example) directory for a fully functioning sample app with buttons simulating different logs, network requests, and secret trigger configurations.

---

## Running Tests

Run the unit and widget test suite:

```bash
flutter test
```

Analyze the codebase:

```bash
flutter analyze
```

---

## License

MIT License © 2026 Churtech
