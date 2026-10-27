import 'launcher/sub_app.dart';
import 'markdown_editor/markdown_editor_app.dart';
import 'services.dart';

/// Every sub-app, in launcher order. Add new utilities here.
List<SubApp> buildSubApps(AppServices services) => [
  markdownEditorSubApp(services),
];
