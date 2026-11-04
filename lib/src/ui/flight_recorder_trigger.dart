import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../flight_recorder.dart';
import '../models/flight_recorder_icons.dart';
import '../models/flight_recorder_strings.dart';
import '../models/flight_recorder_theme.dart';

/// Gesture activation mode for the [FlightRecorderTrigger].
enum FlightRecorderTriggerMode {
  /// Opens on a standard long press gesture.
  longPress,

  /// Opens on a double tap gesture.
  doubleTap,

  /// Opens after a specific number of consecutive taps (e.g. 5 taps like developer settings).
  multiTap,
}

/// A wrapper widget that triggers the Flight Recorder diagnostic viewer on secret gestures.
///
/// Typical usage:
/// ```dart
/// FlightRecorderTrigger(
///   mode: FlightRecorderTriggerMode.longPress,
///   child: Text('Version 1.0.0'),
/// )
/// ```
class FlightRecorderTrigger extends StatefulWidget {
  /// Child widget displayed in the tree (e.g. app logo, build version text, profile banner).
  final Widget child;

  /// Trigger gesture mode.
  final FlightRecorderTriggerMode mode;

  /// Required number of taps when [mode] is [FlightRecorderTriggerMode.multiTap]. Default is 5.
  final int requiredTaps;

  /// Time window to complete consecutive taps. Default is 2.5 seconds.
  final Duration multiTapWindow;

  /// Optional custom theme overrides for the modal viewer.
  final FlightRecorderTheme? theme;

  /// Optional custom localized strings for the modal viewer.
  final FlightRecorderStrings? strings;

  /// Optional custom icons for the modal viewer.
  final FlightRecorderIcons? icons;

  /// Whether to emit haptic feedback when the viewer triggers.
  final bool enableHaptics;

  /// Optional custom callback invoked instead of opening the default modal.
  final VoidCallback? onCustomTrigger;

  const FlightRecorderTrigger({
    super.key,
    required this.child,
    this.mode = FlightRecorderTriggerMode.longPress,
    this.requiredTaps = 5,
    this.multiTapWindow = const Duration(milliseconds: 2500),
    this.theme,
    this.strings,
    this.icons,
    this.enableHaptics = true,
    this.onCustomTrigger,
  });

  @override
  State<FlightRecorderTrigger> createState() => _FlightRecorderTriggerState();
}

class _FlightRecorderTriggerState extends State<FlightRecorderTrigger> {
  int _tapCount = 0;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _fireTrigger() {
    if (widget.enableHaptics) {
      HapticFeedback.heavyImpact();
    }

    if (widget.onCustomTrigger != null) {
      widget.onCustomTrigger!();
    } else {
      FlightRecorder.instance.showViewer(
        context,
        theme: widget.theme,
        strings: widget.strings,
        icons: widget.icons,
      );
    }
  }

  void _handleTap() {
    if (widget.mode != FlightRecorderTriggerMode.multiTap) return;

    _resetTimer?.cancel();
    _tapCount++;

    if (_tapCount >= widget.requiredTaps) {
      _tapCount = 0;
      _fireTrigger();
    } else {
      _resetTimer = Timer(widget.multiTapWindow, () {
        if (mounted) setState(() => _tapCount = 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.mode == FlightRecorderTriggerMode.multiTap ? _handleTap : null,
      onDoubleTap: widget.mode == FlightRecorderTriggerMode.doubleTap ? _fireTrigger : null,
      onLongPress: widget.mode == FlightRecorderTriggerMode.longPress ? _fireTrigger : null,
      child: widget.child,
    );
  }
}
