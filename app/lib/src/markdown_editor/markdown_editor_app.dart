import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../documents/document.dart';
import '../launcher/sub_app.dart';
import '../services.dart';
import 'markdown_editor_page.dart';
import 'markdown_files_page.dart';

final _log = Logger('markdown_editor');

/// The launcher entry for the markdown editor.
SubApp markdownEditorSubApp(AppServices services) => SubApp(
  id: 'markdown',
  title: 'Markdown',
  description: 'Open and edit a markdown file',
  icon: Icons.edit_note,
  builder: (_) => MarkdownFilesPage(services: services),
);

/// Records [document] as recent and opens it in the editor.
///
/// With [aboveLauncher], every screen but the launcher is closed first, so
/// back from the editor returns to the grid. Opens from a home screen widget
/// use it so repeated taps do not stack editors.
Future<void> openMarkdownEditor(
  NavigatorState navigator,
  AppServices services,
  Document document, {
  bool aboveLauncher = false,
}) {
  unawaited(
    services.recents
        .add(document)
        .then<void>(
          (_) {},
          onError: (Object error, StackTrace stackTrace) =>
              _log.warning('could not record $document', error, stackTrace),
        ),
  );
  final route = MaterialPageRoute<void>(
    settings: const RouteSettings(name: '/markdown/edit'),
    builder: (_) => MarkdownEditorPage(
      document: document,
      store: services.documents,
      widgets: services.widgets,
    ),
  );
  return aboveLauncher
      ? navigator.pushAndRemoveUntil(route, (r) => r.isFirst)
      : navigator.push(route);
}
