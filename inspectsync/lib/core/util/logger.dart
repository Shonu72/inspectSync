import 'package:talker/talker.dart';

class AppLogger {
  static final Talker _talker = Talker(
    settings: TalkerSettings(useConsoleLogs: true, useHistory: true),
  );

  static Talker get talker => _talker;

  static void info(String message) {
    _talker.info(message);
  }

  static void debug(String message) {
    _talker.debug(message);
  }

  static void success(String message) {
    _talker.log(message, pen: AnsiPen()..green());
  }

  static void warning(String message) {
    _talker.warning(message);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _talker.error(message, error, stackTrace);
  }

  static void critical(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _talker.critical(message, error, stackTrace);
  }

  static void verbose(String message) {
    _talker.verbose(message);
  }
}
