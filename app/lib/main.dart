import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'src/app.dart';
import 'src/documents/platform_documents.dart';
import 'src/documents/recent_documents.dart';
import 'src/logging.dart';
import 'src/services.dart';

final _log = Logger('main');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setUpLogging();
  _log.info('starting');
  final documents = PlatformDocuments();
  runApp(
    App(
      services: AppServices(
        documents: documents,
        launches: documents,
        recents: SharedPreferencesRecentDocuments(),
      ),
    ),
  );
}
