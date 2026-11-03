import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/flight_log_level.dart';
import '../models/flight_recorder_strings.dart';
import '../models/flight_recorder_theme.dart';
import '../storage/flight_log_storage.dart';

/// Modal dialog for inspecting, searching, and exporting in-app diagnostic logs.
class FlightRecorderModal extends StatefulWidget {
  final FlightLogStorage storage;
  final FlightRecorderTheme theme;
  final FlightRecorderStrings strings;

  const FlightRecorderModal({
    super.key,
    required this.storage,
    this.theme = const FlightRecorderTheme(),
    this.strings = const FlightRecorderStrings(),
  });

  /// Displays the modal dialog over the current [context].
  static Future<void> show(
    BuildContext context, {
    required FlightLogStorage storage,
    FlightRecorderTheme? theme,
    FlightRecorderStrings? strings,
  }) {
    final effectiveTheme = theme ?? const FlightRecorderTheme();
    final effectiveStrings = strings ?? const FlightRecorderStrings();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(effectiveTheme.borderRadius),
        ),
        backgroundColor: effectiveTheme.backgroundColor ??
            Theme.of(ctx).colorScheme.surface,
        child: FlightRecorderModal(
          storage: storage,
          theme: effectiveTheme,
          strings: effectiveStrings,
        ),
      ),
    );
  }

  @override
  State<FlightRecorderModal> createState() => _FlightRecorderModalState();
}

class _FlightRecorderModalState extends State<FlightRecorderModal> {
  final TextEditingController _searchController = TextEditingController();
  FlightLogLevel? _selectedLevel;
  String _searchQuery = '';
  String? _feedbackMessage;
  Timer? _feedbackTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _showFeedback(String message) {
    _feedbackTimer?.cancel();
    setState(() => _feedbackMessage = message);
    _feedbackTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _feedbackMessage = null);
      }
    });
  }

  Future<void> _confirmAndClear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.strings.confirmClearTitle),
        content: Text(widget.strings.confirmClearMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(widget.strings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(widget.strings.confirm),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.storage.clearLogs();
      if (!mounted) return;
      _showFeedback(widget.strings.logsCleared);
    }
  }

  Future<void> _copyLogs() async {
    final text = widget.storage.getLogsAsString(
      filterLevel: _selectedLevel,
      searchQuery: _searchQuery,
    );
    try {
      await Clipboard.setData(ClipboardData(text: text));
      await HapticFeedback.lightImpact();
    } catch (_) {}
    if (!mounted) return;
    _showFeedback(widget.strings.logsCopied);
  }

  Future<void> _exportLogs() async {
    final file = widget.storage.logFile;
    if (file != null && await file.exists()) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: widget.strings.shareSubject,
        ),
      );
    } else {
      final text = widget.storage.getLogsAsString();
      final bytes = Uint8List.fromList(text.codeUnits);
      final xFile = XFile.fromData(
        bytes,
        name: 'flight_recorder_logs.txt',
        mimeType: 'text/plain',
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: widget.strings.shareSubject,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return SizedBox(
      width: double.infinity,
      height: size.height * 0.85,
      child: Stack(
        children: [
          Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Icon(
                  Icons.terminal_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.strings.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: widget.strings.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.strings.searchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Level Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _buildFilterChip(
                  label: widget.strings.filterAll,
                  isSelected: _selectedLevel == null,
                  onSelected: () => setState(() => _selectedLevel = null),
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: widget.strings.filterDebug,
                  color: widget.theme.debugColor,
                  isSelected: _selectedLevel == FlightLogLevel.debug,
                  onSelected: () => setState(
                    () => _selectedLevel = _selectedLevel == FlightLogLevel.debug
                        ? null
                        : FlightLogLevel.debug,
                  ),
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: widget.strings.filterInfo,
                  color: widget.theme.infoColor,
                  isSelected: _selectedLevel == FlightLogLevel.info,
                  onSelected: () => setState(
                    () => _selectedLevel = _selectedLevel == FlightLogLevel.info
                        ? null
                        : FlightLogLevel.info,
                  ),
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: widget.strings.filterWarning,
                  color: widget.theme.warningColor,
                  isSelected: _selectedLevel == FlightLogLevel.warning,
                  onSelected: () => setState(
                    () => _selectedLevel =
                        _selectedLevel == FlightLogLevel.warning
                            ? null
                            : FlightLogLevel.warning,
                  ),
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: widget.strings.filterError,
                  color: widget.theme.errorColor,
                  isSelected: _selectedLevel == FlightLogLevel.error,
                  onSelected: () => setState(
                    () => _selectedLevel =
                        _selectedLevel == FlightLogLevel.error
                            ? null
                            : FlightLogLevel.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Log Entries List
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: widget.storage.logCountNotifier,
              builder: (ctx, count, _) {
                final logs = widget.storage.getLogs(
                  filterLevel: _selectedLevel,
                  searchQuery: _searchQuery,
                );

                if (logs.isEmpty) {
                  return Center(
                    child: Text(
                      widget.strings.noLogsFound,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  );
                }

                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.theme.cardColor ??
                        theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (ctx, index) {
                      // Show newest logs on top
                      final log = logs[logs.length - 1 - index];
                      final color = widget.theme.colorForLevel(log.level);

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 6),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: theme.dividerColor.withValues(alpha: 0.2),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: SelectableText.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '[${log.timestamp.toIso8601String().substring(11, 19)}] ',
                                style: TextStyle(
                                  color: theme.hintColor,
                                  fontSize: 11,
                                ),
                              ),
                              TextSpan(
                                text: '[${log.level.tag}] ',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              if (log.tag != null && log.tag!.isNotEmpty)
                                TextSpan(
                                  text: '[${log.tag}] ',
                                  style: TextStyle(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              TextSpan(
                                text: log.message,
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color,
                                  fontSize: 12,
                                ),
                              ),
                              if (log.metadata != null &&
                                  log.metadata!.isNotEmpty)
                                TextSpan(
                                  text: '\n  Meta: ${log.metadata}',
                                  style: TextStyle(
                                    color: theme.hintColor,
                                    fontSize: 11,
                                  ),
                                ),
                              if (log.error != null)
                                TextSpan(
                                  text: '\n  Error: ${log.error}',
                                  style: TextStyle(
                                    color: widget.theme.errorColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              if (log.stackTrace != null)
                                TextSpan(
                                  text: '\n  ${log.stackTrace}',
                                  style: TextStyle(
                                    color: widget.theme.errorColor
                                        .withValues(alpha: 0.7),
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                          style: TextStyle(
                            fontFamily: widget.theme.monospaceFontFamily,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Action Toolbar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton.outlined(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: widget.strings.clearLogs,
                      onPressed: _confirmAndClear,
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      tooltip: widget.strings.copyLogs,
                      onPressed: _copyLogs,
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: Text(widget.strings.exportLogs),
                  onPressed: _exportLogs,
                ),
              ],
            ),
          ),
        ],
      ),
      if (_feedbackMessage != null)
            Positioned(
              bottom: 68,
              left: 24,
              right: 24,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 8),
                      child: child,
                    ),
                  ),
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(24),
                    color: theme.colorScheme.inverseSurface,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: theme.colorScheme.onInverseSurface,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _feedbackMessage!,
                              style: TextStyle(
                                color: theme.colorScheme.onInverseSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    Color? color,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? (color ?? Theme.of(context).colorScheme.primary)
              : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onSelected: (_) => onSelected(),
    );
  }
}
