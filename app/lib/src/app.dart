import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'documents/document.dart';
import 'launcher/launcher_page.dart';
import 'markdown_editor/markdown_editor_app.dart';
import 'markdown_editor/quick_open_button.dart';
import 'services.dart';
import 'sub_apps.dart';

final _log = Logger('app');

/// The app's title, shown in the app bar and the Android task switcher.
const appTitle = 'yft android utils';

/// The root widget: the launcher grid, plus documents opened from outside
/// the app (home screen widgets) going straight to the markdown editor.
class App extends StatefulWidget {
  const App({super.key, required this.services});

  final AppServices services;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _navigator = GlobalKey<NavigatorState>();
  late final _subApps = buildSubApps(widget.services);
  late final StreamSubscription<Document> _launches;

  @override
  void initState() {
    super.initState();
    _launches = widget.services.launches.opened.listen(_open);
    unawaited(_openInitial());
  }

  Future<void> _openInitial() async {
    try {
      final document = await widget.services.launches.initial();
      if (document == null || !mounted) return;
      await WidgetsBinding.instance.endOfFrame;
      _open(document);
    } on Exception catch (error, stackTrace) {
      _log.warning('could not read the launch document', error, stackTrace);
    }
  }

  void _open(Document document) {
    final navigator = _navigator.currentState;
    if (navigator == null) return;
    unawaited(
      openMarkdownEditor(
        navigator,
        widget.services,
        document,
        aboveLauncher: true,
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_launches.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigator,
      title: appTitle,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: LauncherPage(
        title: appTitle,
        subApps: _subApps,
        actions: [QuickOpenButton(services: widget.services)],
      ),
    );
  }
}
