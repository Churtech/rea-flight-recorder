import 'package:web/web.dart' as web;

const _kStorageKey = 'flight_recorder_logs';

void saveWebLog(String content) {
  try {
    web.window.localStorage.setItem(_kStorageKey, content);
  } catch (_) {}
}

String? loadWebLog() {
  try {
    return web.window.localStorage.getItem(_kStorageKey);
  } catch (_) {
    return null;
  }
}

void clearWebLog() {
  try {
    web.window.localStorage.removeItem(_kStorageKey);
  } catch (_) {}
}
