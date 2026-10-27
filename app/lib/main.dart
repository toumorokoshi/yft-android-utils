import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'src/app.dart';
import 'src/logging.dart';

final _log = Logger('main');

void main() {
  setUpLogging();
  _log.info('starting');
  runApp(const App());
}
