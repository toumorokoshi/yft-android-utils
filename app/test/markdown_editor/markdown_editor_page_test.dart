import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yft_android_utils/src/markdown_editor/markdown_editor_page.dart';

import '../support/fakes.dart';

const delay = Duration(milliseconds: 500);

void main() {
  late FakeDocumentStore store;
  late FakeDocumentWidgets widgets;

  setUp(() {
    store = FakeDocumentStore(files: {notes.uri: '# Title'});
    widgets = FakeDocumentWidgets();
  });

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MarkdownEditorPage(
          document: notes,
          store: store,
          widgets: widgets,
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

  testWidgets('adds a home screen widget for the file', (tester) async {
    await pumpEditor(tester);

    await tester.tap(find.byTooltip('Add widget to home screen'));
    await tester.pump();

    expect(widgets.pinned, [notes]);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('explains when the home screen cannot add widgets', (
    tester,
  ) async {
    widgets.supported = false;
    await pumpEditor(tester);

    await tester.tap(find.byTooltip('Add widget to home screen'));
    await tester.pump();

    expect(find.text(pinUnsupportedMessage), findsOneWidget);
  });

  testWidgets('formatting ribbon inserts and toggles H1/H2/H3 headers', (
    tester,
  ) async {
    store = FakeDocumentStore(files: {notes.uri: 'Heading'});
    await pumpEditor(tester);

    final editorFinder = find.byKey(const Key('markdown-editor'));
    await tester.tap(editorFinder);
    await tester.pump();
    final field = tester.widget<TextField>(editorFinder);
    field.controller!.selection = const TextSelection.collapsed(offset: 7);

    await tester.tap(find.text('H1'));
    await tester.pump();
    expect(field.controller!.text, '# Heading');
    expect(
      field.controller!.selection,
      const TextSelection.collapsed(offset: 9),
    );
    expect(FocusManager.instance.primaryFocus?.context?.widget, isNotNull);
    expect(
      find.ancestor(
        of: find.byWidget(FocusManager.instance.primaryFocus!.context!.widget),
        matching: editorFinder,
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('H2'));
    await tester.pump();
    expect(field.controller!.text, '## Heading');

    await tester.tap(find.text('H3'));
    await tester.pump();
    expect(field.controller!.text, '### Heading');

    await tester.tap(find.text('H3'));
    await tester.pump();
    expect(field.controller!.text, 'Heading');

    // Triggers autosave after applying a heading.
    await tester.tap(find.text('H2'));
    await tester.pump();
    expect(find.text('Editing…'), findsOneWidget);
    await tester.pump(delay);
    await tester.pump();
    expect(store.files[notes.uri], '## Heading');
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('hides the formatting ribbon in preview mode', (tester) async {
    await pumpEditor(tester);

    expect(find.byKey(const Key('formatting-ribbon')), findsOneWidget);

    await tester.tap(find.byTooltip('Preview'));
    await tester.pump();
    expect(find.byKey(const Key('formatting-ribbon')), findsNothing);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pump();
    expect(find.byKey(const Key('formatting-ribbon')), findsOneWidget);
  });
}
