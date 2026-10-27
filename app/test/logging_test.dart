import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:yft_android_utils/src/logging.dart';

void main() {
  group('formatLogRecord', () {
    test('puts the level and logger before the message', () {
      final record = LogRecord(Level.INFO, 'starting', 'main');

      expect(formatLogRecord(record), 'INFO main: starting');
    });

    test('appends the error', () {
      final record = LogRecord(
        Level.SEVERE,
        'failed',
        'main',
        StateError('boom'),
      );

      expect(formatLogRecord(record), 'SEVERE main: failed (Bad state: boom)');
    });
  });

  test('setUpLogging sets the root level', () async {
    final subscription = setUpLogging(level: Level.WARNING);
    addTearDown(subscription.cancel);

    expect(Logger.root.level, Level.WARNING);
  });
}
