import 'package:flutter/widgets.dart';

/// Customizable icon configuration for the Flight Recorder modal viewer.
///
/// Accepts arbitrary [Widget] instances (such as [Icon], [FaIcon], [SvgPicture], or image assets)
/// to allow complete decoupling from any specific icon pack or third-party dependency.
class FlightRecorderIcons {
  /// Icon displayed in the modal header next to the title.
  final Widget? terminal;

  /// Icon for closing the modal dialog.
  final Widget? close;

  /// Prefix icon inside the search input box.
  final Widget? search;

  /// Suffix icon to clear the active search query.
  final Widget? clearSearch;

  /// Icon on the action button to delete/wipe all logs.
  final Widget? delete;

  /// Icon on the action button to copy logs to clipboard.
  final Widget? copy;

  /// Icon on the action button to share/export logs.
  final Widget? export;

  /// Icon displayed in the floating feedback notification pill.
  final Widget? feedbackSuccess;

  const FlightRecorderIcons({
    this.terminal,
    this.close,
    this.search,
    this.clearSearch,
    this.delete,
    this.copy,
    this.export,
    this.feedbackSuccess,
  });
}
