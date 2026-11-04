/// In-app diagnostic blackbox and flight recorder for Flutter.
///
/// Captures logs, errors, and network traffic into a memory ring buffer
/// and rotating file with an interactive in-app developer modal viewer.
library rea_flight_recorder;

export 'src/flight_recorder.dart';
export 'src/interceptors/flight_recorder_dio_interceptor.dart';
export 'src/interceptors/flight_recorder_http_sanitizer.dart';
export 'src/models/flight_log_entry.dart';
export 'src/models/flight_log_level.dart';
export 'src/models/flight_recorder_icons.dart';
export 'src/models/flight_recorder_options.dart';
export 'src/models/flight_recorder_strings.dart';
export 'src/models/flight_recorder_theme.dart';
export 'src/storage/flight_log_storage.dart';
export 'src/ui/flight_recorder_modal.dart';
export 'src/ui/flight_recorder_trigger.dart';
