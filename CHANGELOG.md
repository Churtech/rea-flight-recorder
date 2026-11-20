## 0.1.3

* Replace `package:flutter/material.dart` import with `package:flutter/widgets.dart` in `FlightRecorderTheme` to decouple from Material Design and eliminate deprecation notices on Flutter 3.47+.
* Ignore library deprecation diagnostic for `package:flutter/material.dart` in `FlightRecorderModal` to preserve backward compatibility across all Flutter releases without forcing early adoption of `package:material_ui`.
* Fix unresolved doc references for `FaIcon`, `SvgPicture`, `FlutterError.onError`, and `PlatformDispatcher.instance.onError` in DartDoc.
* Remove redundant library name in `rea_flight_recorder.dart` conforming to modern Dart conventions (`unnecessary_library_name`).
* Upgrade `flutter_lints` constraint to `">=3.0.0 <7.0.0"`.

## 0.1.2

* Add `FlightRecorderIcons` model to allow arbitrary custom icon widgets (FontAwesome, Cupertino, SVG, etc.) across all modal actions and headers without coupling the library to third-party icon packages.
* Support `icons` parameter in `FlightRecorderModal` and `FlightRecorder.instance.showViewer`.

## 0.1.1

* Expand `share_plus` dependency constraint to `>=10.0.0 <14.0.0` for full compatibility with apps on `share_plus` 13.x.

## 0.1.0

* Initial release of `rea_flight_recorder`.
* Circular in-memory FIFO ring buffer (configurable capacity).
* Rotating local disk file storage (2 MB max with automatic `.old.log` rotation).
* Web storage integration with `localStorage`.
* Full-featured developer modal viewer (`FlightRecorderModal`) with real-time text search, log-level filters (Debug, Info, Warn, Error), clipboard copy, and file sharing/export.
* Gesture trigger widget (`FlightRecorderTrigger`) supporting long-press, double-tap, and multi-tap (developer settings pattern) with haptic feedback.
* Automatic sensitive credential/token redaction (`FlightRecorderHttpSanitizer`).
* Structured HTTP logging with request/response metadata and duration.
* Startup diagnostic session header banner.
* First-class Dio HTTP client interceptor (`FlightRecorderDioInterceptor`).
* Automatic crash and unhandled framework error hooks (`installErrorHooks`).
* In-modal high-contrast toast feedback with haptic response for copy and clear actions.
* Multi-language support with English default and Spanish (`FlightRecorderStrings.spanish()`).
