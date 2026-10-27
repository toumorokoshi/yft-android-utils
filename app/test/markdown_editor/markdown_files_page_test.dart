import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yft_android_utils/src/markdown_editor/markdown_editor_page.dart';
import 'package:yft_android_utils/src/markdown_editor/markdown_files_page.dart';

import '../support/fakes.dart';

void main() {
  Future<void> pumpFiles(
    WidgetTester tester, {
    FakeDocumentStore? documents,
    FakeRecentDocuments? recents,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MarkdownFilesPage(
          services: fakeServices(documents: documents, recents: recents),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('opens a picked file and records it as recent', (tester) async {
    final documents = FakeDocumentStore()..picked = notes;
    final recents = FakeRecentDocuments();
    await pumpFiles(tester, documents: documents, recents: recents);

    await tester.tap(find.text('Open file'));
    await tester.pumpAndSettle();

    expect(find.byType(MarkdownEditorPage), findsOneWidget);
    expect(recents.documents, [notes]);
  });

  testWidgets('a cancelled pick stays on the page', (tester) async {
    await pumpFiles(tester);

    await tester.tap(find.text('New file'));
    await tester.pumpAndSettle();

    expect(find.byType(MarkdownEditorPage), findsNothing);
  });

  testWidgets('lists recent files and reopens them', (tester) async {
    final recents = FakeRecentDocuments([notes, todo]);
    await pumpFiles(tester, recents: recents);

    expect(find.text('Recent'), findsOneWidget);
    await tester.tap(find.text('todo.md'));
    await tester.pumpAndSettle();

    expect(find.byType(MarkdownEditorPage), findsOneWidget);
    expect(recents.documents, [todo, notes]);
  });
}
