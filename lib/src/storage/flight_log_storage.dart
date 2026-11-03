import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import '../models/flight_log_entry.dart';
import '../models/flight_log_level.dart';
import '../models/flight_recorder_options.dart';
import 'web_storage.dart';

/// Storage manager handling in-memory ring buffer, file persistence, and web storage.
class FlightLogStorage {
  final FlightRecorderOptions options;
  final List<FlightLogEntry> _inMemoryLogs = [];
  final ValueNotifier<int> logCountNotifier = ValueNotifier(0);

  File? _logFile;
  bool _initialized = false;

  FlightLogStorage({FlightRecorderOptions? options})
      : options = options ?? const FlightRecorderOptions();

  /// Initializes the storage engine and loads prior logs if persistence is enabled.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      _loadLogsFromWebStorage();
    } else if (options.enableFilePersistence) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        _logFile = File('${dir.path}/${options.logFileName}');
        if (!await _logFile!.exists()) {
          await _logFile!.create(recursive: true);
        } else {
          await _loadLogsFromFile();
        }
      } catch (e) {
        debugPrint('[FlightRecorder] Failed to initialize log file: $e');
      }
    }
  }

  /// Appends an entry into memory, discards oldest if capacity exceeded,
  /// and writes to disk or web storage.
  void addEntry(FlightLogEntry entry) {
    _inMemoryLogs.add(entry);
    if (_inMemoryLogs.length > options.maxInMemoryLogs) {
      _inMemoryLogs.removeAt(0);
    }

    _notifyCount();

    if (kIsWeb) {
      saveWebLog(getLogsAsString());
    } else if (options.enableFilePersistence && _logFile != null) {
      _writeToFile(entry.formatted());
    }

    if (options.echoToConsole) {
      debugPrint(entry.formatted());
    }
  }

  void _notifyCount() {
    try {
      if (WidgetsBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          logCountNotifier.value = _inMemoryLogs.length;
        });
      } else {
        logCountNotifier.value = _inMemoryLogs.length;
      }
    } catch (_) {
      logCountNotifier.value = _inMemoryLogs.length;
    }
  }

  Future<void> _writeToFile(String formattedLine) async {
    if (_logFile == null) return;
    try {
      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }

      final size = await _logFile!.length();
      if (size > options.maxFileSizeBytes) {
        final parentDir = _logFile!.parent.path;
        final baseName = options.logFileName;
        final oldFile = File('$parentDir/$baseName.old.log');
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
        await _logFile!.rename(oldFile.path);
        _logFile = File('$parentDir/$baseName');
        await _logFile!.create();
      }

      await _logFile!.writeAsString('$formattedLine\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('[FlightRecorder] Error writing to log file: $e');
    }
  }

  Future<void> _loadLogsFromFile() async {
    if (_logFile == null || !await _logFile!.exists()) return;
    try {
      final lines = await _logFile!.readAsLines();
      _inMemoryLogs.clear();
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        _inMemoryLogs.add(_parseLineToEntry(line));
      }
      if (_inMemoryLogs.length > options.maxInMemoryLogs) {
        _inMemoryLogs.removeRange(
            0, _inMemoryLogs.length - options.maxInMemoryLogs);
      }
      logCountNotifier.value = _inMemoryLogs.length;
    } catch (e) {
      debugPrint('[FlightRecorder] Error reading log file: $e');
    }
  }

  void _loadLogsFromWebStorage() {
    try {
      final savedText = loadWebLog();
      if (savedText == null || savedText.trim().isEmpty) return;
      final lines = savedText.split('\n');
      _inMemoryLogs.clear();
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        _inMemoryLogs.add(_parseLineToEntry(line));
      }
      if (_inMemoryLogs.length > options.maxInMemoryLogs) {
        _inMemoryLogs.removeRange(
            0, _inMemoryLogs.length - options.maxInMemoryLogs);
      }
      logCountNotifier.value = _inMemoryLogs.length;
    } catch (_) {}
  }

  FlightLogEntry _parseLineToEntry(String line) {
    FlightLogLevel level = FlightLogLevel.info;
    if (line.contains('[WARN]')) {
      level = FlightLogLevel.warning;
    } else if (line.contains('[ERROR]')) {
      level = FlightLogLevel.error;
    } else if (line.contains('[DEBUG]')) {
      level = FlightLogLevel.debug;
    }

    return FlightLogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: line,
    );
  }

  /// Returns entries filtered by level, tag, and search query.
  List<FlightLogEntry> getLogs({
    FlightLogLevel? filterLevel,
    String? filterTag,
    String? searchQuery,
  }) {
    return _inMemoryLogs.where((log) {
      if (filterLevel != null && log.level != filterLevel) {
        return false;
      }
      if (filterTag != null && filterTag.isNotEmpty && log.tag != filterTag) {
        return false;
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesMsg = log.message.toLowerCase().contains(query);
        final matchesTag = log.tag?.toLowerCase().contains(query) ?? false;
        final matchesErr =
            log.error?.toString().toLowerCase().contains(query) ?? false;
        return matchesMsg || matchesTag || matchesErr;
      }
      return true;
    }).toList();
  }

  /// Returns all or filtered logs as a single combined plaintext string.
  String getLogsAsString({
    FlightLogLevel? filterLevel,
    String? filterTag,
    String? searchQuery,
  }) {
    final logs = getLogs(
      filterLevel: filterLevel,
      filterTag: filterTag,
      searchQuery: searchQuery,
    );
    return logs.map((l) => l.formatted()).join('\n');
  }

  /// Wipes all in-memory entries and clears the disk/web log file.
  Future<void> clearLogs() async {
    _inMemoryLogs.clear();
    logCountNotifier.value = 0;

    if (kIsWeb) {
      clearWebLog();
    } else if (_logFile != null && await _logFile!.exists()) {
      try {
        await _logFile!.writeAsString('');
      } catch (e) {
        debugPrint('[FlightRecorder] Failed to clear log file: $e');
      }
    }
  }

  /// Returns the underlying file handle if file persistence is active.
  File? get logFile => _logFile;

  /// Returns the current number of in-memory log entries.
  int get count => _inMemoryLogs.length;
}
