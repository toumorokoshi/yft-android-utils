import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yft_android_utils/src/markdown_editor/markdown_editor_page.dart';
import 'package:yft_android_utils/src/navigation_sidebar/markdown_outline.dart';
import 'package:yft_android_utils/src/navigation_sidebar/navigation_sidebar.dart';

import '../support/fakes.dart';

void main() {
  testWidgets('starts collapsed and expands/collapses on the right-hand side', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NavigationSidebarScaffold(
          title: Text('Test'),
          body: Center(child: Text('Main body')),
        ),
      ),
    );

    expect(find.byKey(const Key('navigation-sidebar')), findsNothing);
    expect(find.byKey(const Key('toggle-sidebar')), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggle-sidebar')));
    await tester.pumpAndSettle();

    final sidebarFinder = find.byKey(const Key('navigation-sidebar'));
    expect(sidebarFinder, findsOneWidget);
    final bodyCenter = tester.getCenter(find.text('Main body'));
    final sidebarCenter = tester.getCenter(sidebarFinder);
    expect(sidebarCenter.dx, greaterThan(bodyCenter.dx));

    await tester.tap(find.byKey(const Key('collapse-sidebar')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('navigation-sidebar')), findsNothing);
  });

  testWidgets('displays outline headings and notifies on tap', (tester) async {
    MarkdownHeading? tapped;
    const headings = [
      MarkdownHeading(level: 1, title: 'Intro', anchor: 'intro', offset: 0),
      MarkdownHeading(
        level: 2,
        title: 'Details',
        anchor: 'details',
        offset: 10,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: NavigationSidebarScaffold(
          title: const Text('Editor'),
          outline: headings,
          onHeadingTap: (heading) => tapped = heading,
          body: const SizedBox.expand(),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('toggle-sidebar')));
    await tester.pumpAndSettle();

    expect(find.text('Outline'), findsOneWidget);
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();

    expect(tapped?.title, 'Details');
    expect(tapped?.offset, 10);
  });

  testWidgets('lists recent files and opens a tapped file in the editor', (
    tester,
  ) async {
    final store = FakeDocumentStore(
      files: {notes.uri: '# Notes', todo.uri: '# Todo'},
    );
    final services = fakeServices(
      documents: store,
      recents: FakeRecentDocuments([notes, todo]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: NavigationSidebarScaffold(
          title: const Text('Home'),
          services: services,
          body: const SizedBox.expand(),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('toggle-sidebar')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sidebar-quick-open')), findsOneWidget);
    expect(find.text('notes.md'), findsOneWidget);
    expect(find.text('todo.md'), findsOneWidget);

    await tester.tap(find.text('todo.md'));
    await tester.pumpAndSettle();

    expect(find.byType(MarkdownEditorPage), findsOneWidget);
    expect(find.text('todo.md'), findsOneWidget);
  });

  testWidgets('jumps to heading offset in MarkdownEditorPage edit mode', (
    tester,
  ) async {
    const content = '# First\n\nSome text\n\n## Second\nMore text';
    final store = FakeDocumentStore(files: {notes.uri: content});
    final services = fakeServices(documents: store);

    await tester.pumpWidget(
      MaterialApp(
        home: MarkdownEditorPage(
          document: notes,
          store: store,
          widgets: FakeDocumentWidgets(),
          services: services,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('toggle-sidebar')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Second'));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(
      find.byKey(const Key('markdown-editor')),
    );
    expect(
      textField.controller!.selection.baseOffset,
      content.indexOf('## Second'),
    );
  });
}
