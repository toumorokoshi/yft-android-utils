import 'dart:async';
import 'dart:developer' as developer;

import 'package:logging/logging.dart';

/// Formats [record] as one line: `LEVEL logger: message`, followed by the
/// error when there is one.
String formatLogRecord(LogRecord record) {
  final line = '${record.level.name} ${record.loggerName}: ${record.message}';
  final error = record.error;
  return error == null ? line : '$line ($error)';
}

/// Sends every record at [level] or above to `dart:developer`'s log, which
/// shows in `flutter run`, DevTools and `adb logcat`.
///
/// Returns the subscription so tests can cancel it.
StreamSubscription<LogRecord> setUpLogging({Level level = Level.INFO}) {
  Logger.root.level = level;
  return Logger.root.onRecord.listen(
    (record) => developer.log(
      formatLogRecord(record),
      name: record.loggerName,
      level: record.level.value,
      error: record.error,
      stackTrace: record.stackTrace,
      time: record.time,
    ),
  );
}
