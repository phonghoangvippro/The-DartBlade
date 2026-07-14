import 'package:flutter/foundation.dart';

/// Lightweight logger. Logs only in debug builds.
class GameLogger {
  GameLogger._();

  static void info(String tag, String message) {
    if (kDebugMode) debugPrint('[INFO][$tag] $message');
  }

  static void warn(String tag, String message) {
    if (kDebugMode) debugPrint('[WARN][$tag] $message');
  }

  static void error(String tag, String message, [Object? err]) {
    if (kDebugMode) {
      debugPrint('[ERROR][$tag] $message${err != null ? ' -> $err' : ''}');
    }
  }
}
