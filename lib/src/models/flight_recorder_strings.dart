/// Localized string provider for the Flight Recorder UI components.
class FlightRecorderStrings {
  final String title;
  final String searchHint;
  final String filterAll;
  final String filterDebug;
  final String filterInfo;
  final String filterWarning;
  final String filterError;
  final String clearLogs;
  final String confirmClearTitle;
  final String confirmClearMessage;
  final String cancel;
  final String confirm;
  final String logsCleared;
  final String copyLogs;
  final String logsCopied;
  final String exportLogs;
  final String shareSubject;
  final String noLogsFound;
  final String close;

  const FlightRecorderStrings({
    this.title = 'Diagnostic Logs (Blackbox)',
    this.searchHint = 'Search logs, errors, tags...',
    this.filterAll = 'All',
    this.filterDebug = 'Debug',
    this.filterInfo = 'Info',
    this.filterWarning = 'Warn',
    this.filterError = 'Error',
    this.clearLogs = 'Clear logs',
    this.confirmClearTitle = 'Clear all diagnostic logs?',
    this.confirmClearMessage = 'This action will wipe in-memory and local log storage.',
    this.cancel = 'Cancel',
    this.confirm = 'Clear',
    this.logsCleared = 'Diagnostic logs successfully cleared.',
    this.copyLogs = 'Copy logs to clipboard',
    this.logsCopied = 'Logs copied to clipboard.',
    this.exportLogs = 'Export logs',
    this.shareSubject = 'App Diagnostic Logs',
    this.noLogsFound = 'No logs matching current criteria.',
    this.close = 'Close',
  });

  /// Ready-to-use Spanish localization.
  factory FlightRecorderStrings.spanish() {
    return const FlightRecorderStrings(
      title: 'Registros de Diagnóstico (Caja Negra)',
      searchHint: 'Buscar en logs, errores, tags...',
      filterAll: 'Todos',
      filterDebug: 'Debug',
      filterInfo: 'Info',
      filterWarning: 'Alerta',
      filterError: 'Error',
      clearLogs: 'Limpiar logs',
      confirmClearTitle: '¿Eliminar todos los logs de diagnóstico?',
      confirmClearMessage: 'Esta acción borrará los logs de memoria y del archivo local.',
      cancel: 'Cancelar',
      confirm: 'Eliminar',
      logsCleared: 'Registros de diagnóstico eliminados correctamente.',
      copyLogs: 'Copiar al portapapeles',
      logsCopied: 'Logs copiados al portapapeles.',
      exportLogs: 'Exportar logs',
      shareSubject: 'Reporte de Diagnóstico de la App',
      noLogsFound: 'No se encontraron logs con los filtros actuales.',
      close: 'Cerrar',
    );
  }
}
