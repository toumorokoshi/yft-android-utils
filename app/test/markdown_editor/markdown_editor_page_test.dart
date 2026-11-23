import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yft_android_utils/src/markdown_editor/markdown_editor_page.dart';

import '../support/fakes.dart';

const delay = Duration(milliseconds: 500);

void main() {
  late FakeDocumentStore store;
  late FakeDocumentWidgets widgets;
  late FakeLinkLauncher links;

  setUp(() {
    store = FakeDocumentStore(files: {notes.uri: '# Title'});
    widgets = FakeDocumentWidgets();
    links = FakeLinkLauncher();
  });

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MarkdownEditorPage(
          document: notes,
          store: store,
          widgets: widgets,
          links: links,
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

    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(find.byKey(const Key('markdown-editor')), findsNothing);
    expect(find.byKey(const Key('formatting-ribbon')), findsNothing);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pump();
    expect(find.byKey(const Key('markdown-editor')), findsOneWidget);
    expect(find.byKey(const Key('formatting-ribbon')), findsOneWidget);
  });

  testWidgets('formatting ribbon sets and toggles H2 and saves', (
    tester,
  ) async {
    store = FakeDocumentStore(files: {notes.uri: 'Subtitle'});
    await pumpEditor(tester);

    expect(find.byKey(const Key('formatting-ribbon')), findsOneWidget);
    expect(find.byTooltip('Heading 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Heading 2'));
    await tester.pump();
    expect(find.text('## Subtitle'), findsOneWidget);

    await tester.pump(delay);
    await tester.pump();
    expect(store.files[notes.uri], '## Subtitle');

    await tester.tap(find.byTooltip('Heading 2'));
    await tester.pump();
    expect(find.text('Subtitle'), findsOneWidget);
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

  testWidgets('opens external weblinks from the preview', (tester) async {
    store.files[notes.uri] = '[Open Example](https://example.com/docs)';
    await pumpEditor(tester);

    await tester.tap(find.byTooltip('Preview'));
    await tester.pump();

    await tester.tap(find.text('Open Example', findRichText: true));
    await tester.pump();

    expect(links.launched, [Uri.parse('https://example.com/docs')]);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('reports when an external link cannot be opened', (tester) async {
    store.files[notes.uri] = '[Open Example](https://example.com)';
    links.shouldSucceed = false;
    await pumpEditor(tester);

    await tester.tap(find.byTooltip('Preview'));
    await tester.pump();

    await tester.tap(find.text('Open Example', findRichText: true));
    await tester.pump();

    expect(find.text('Could not open https://example.com'), findsOneWidget);
  });

  testWidgets('scrolls to anchor links in the preview', (tester) async {
    final filler = List.filled(40, 'Paragraph line of text.\n').join('\n');
    store.files[notes.uri] =
        '[Jump to End](#end-section)\n\n$filler\n\n## End Section\n\nReached!';
    await pumpEditor(tester);

    await tester.tap(find.byTooltip('Preview'));
    await tester.pump();

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.pixels, 0);

    await tester.tap(find.text('Jump to End', findRichText: true));
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, greaterThan(0));
  });

  testWidgets('reports missing anchor links and unsupported relative links', (
    tester,
  ) async {
    store.files[notes.uri] = '[Missing](#nope)\n\n[Other](other.md)';
    await pumpEditor(tester);

    await tester.tap(find.byTooltip('Preview'));
    await tester.pump();

    await tester.tap(find.text('Missing', findRichText: true));
    await tester.pump();
    expect(find.text('Heading not found: #nope'), findsOneWidget);

    await tester.tap(find.text('Other', findRichText: true));
    await tester.pumpAndSettle();
    expect(find.text('Cannot open link: other.md'), findsOneWidget);
  });
}
