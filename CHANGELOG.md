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
