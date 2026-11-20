import 'package:flutter/widgets.dart';
import 'flight_log_level.dart';

/// Customizable visual styling for the Flight Recorder modal viewer.
class FlightRecorderTheme {
  final Color debugColor;
  final Color infoColor;
  final Color warningColor;
  final Color errorColor;
  final Color? backgroundColor;
  final Color? cardColor;
  final double borderRadius;
  final String? monospaceFontFamily;

  const FlightRecorderTheme({
    this.debugColor = const Color(0xFF78909C), // Blue Grey
    this.infoColor = const Color(0xFF1E88E5),  // Blue 600
    this.warningColor = const Color(0xFFFB8C00), // Orange 600
    this.errorColor = const Color(0xFFE53935),  // Red 600
    this.backgroundColor,
    this.cardColor,
    this.borderRadius = 16.0,
    this.monospaceFontFamily,
  });

  /// Resolves the color associated with a given [FlightLogLevel].
  Color colorForLevel(FlightLogLevel level) {
    switch (level) {
      case FlightLogLevel.debug:
        return debugColor;
      case FlightLogLevel.info:
        return infoColor;
      case FlightLogLevel.warning:
        return warningColor;
      case FlightLogLevel.error:
        return errorColor;
    }
  }

  /// Dark theme preset for developer consoles.
  factory FlightRecorderTheme.darkConsole() {
    return const FlightRecorderTheme(
      backgroundColor: Color(0xFF121212),
      cardColor: Color(0xFF1E1E1E),
      debugColor: Color(0xFFB0BEC5),
      infoColor: Color(0xFF64B5F6),
      warningColor: Color(0xFFFFB74D),
      errorColor: Color(0xFFE57373),
    );
  }
}
