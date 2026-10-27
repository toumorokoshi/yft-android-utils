import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yft_android_utils/src/markdown_editor/markdown_editor_page.dart';

import '../support/fakes.dart';

const delay = Duration(milliseconds: 500);

void main() {
  late FakeDocumentStore store;

  setUp(() => store = FakeDocumentStore(files: {notes.uri: '# Title'}));

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MarkdownEditorPage(
          document: notes,
          store: store,
          saveDelay: delay,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the file and saves edits', (tester) async {
    await pumpEditor(tester);

    expect(find.text('notes.md'), findsOneWidget);
    expect(find.text('# Title'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('markdown-editor')), 'new');
    await tester.pump();
    expect(find.text('Editing…'), findsOneWidget);

    await tester.pump(delay);
    await tester.pump();
    expect(store.files[notes.uri], 'new');
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('toggles a rendered preview', (tester) async {
    await pumpEditor(tester);

    await tester.tap(find.byTooltip('Preview'));
    await tester.pump();

    expect(find.byType(Markdown), findsOneWidget);
    expect(find.byKey(const Key('markdown-editor')), findsNothing);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pump();
    expect(find.byKey(const Key('markdown-editor')), findsOneWidget);
  });

  testWidgets('offers a retry when the file cannot be read', (tester) async {
    store.failReads = true;
    await pumpEditor(tester);

    expect(find.text('Could not open the file'), findsWidgets);

    store.failReads = false;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.text('# Title'), findsOneWidget);
  });
}
