import 'package:talker_flutter/talker_flutter.dart';

/// Global talker instance
final talker = TalkerFlutter.init(
  settings: TalkerSettings(
    enabled: true,
    useConsoleLogs: true,
    useHistory: true,
    maxHistoryItems: 500,
  ),
  logger: TalkerLogger(
    settings: TalkerLoggerSettings(enableColors: true, level: LogLevel.verbose),
  ),
);

/// Logger wrapper class for easier usage
class AppLogger {
  final Talker _talker;

  AppLogger(this._talker);

  /// Log info message
  void info(String message) {
    _talker.info(message);
  }

  /// Log debug message
  void debug(String message) {
    _talker.debug(message);
  }

  /// Log warning message
  void warning(String message) {
    _talker.warning(message);
  }

  /// Log error message with optional exception and stack trace
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (error != null && stackTrace != null) {
      _talker.handle(error, stackTrace, message);
    } else if (error != null) {
      _talker.error('$message: $error');
    } else {
      _talker.error(message);
    }
  }
}

/// Convenient logger instance
final logger = AppLogger(talker);
