import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yft_android_utils/src/markdown_editor/markdown_editor_page.dart';
import 'package:yft_android_utils/src/markdown_editor/markdown_files_page.dart';

import '../support/fakes.dart';

void main() {
  Future<void> pumpFiles(
    WidgetTester tester, {
    FakeDocumentStore? documents,
    FakeFolderStore? folders,
    FakeRecentDocuments? recents,
    FakeRootFolder? rootFolder,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MarkdownFilesPage(
          services: fakeServices(
            documents: documents,
            folders: folders,
            recents: recents,
            rootFolder: rootFolder,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the root folder and changes it', (tester) async {
    final folders = FakeFolderStore()..picked = workFolder;
    final root = FakeRootFolder(notesFolder);
    await pumpFiles(tester, folders: folders, rootFolder: root);

    expect(find.text('Notes'), findsOneWidget);
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();

    expect(find.text('Work'), findsOneWidget);
    expect(root.folder, workFolder);
  });

  testWidgets('shows when no root folder is chosen', (tester) async {
    await pumpFiles(tester);

    expect(find.text('No folder chosen'), findsOneWidget);
    expect(find.text('Choose'), findsOneWidget);
  });

  testWidgets('reloads the folder chosen in quick open', (tester) async {
    final folders = FakeFolderStore()..picked = workFolder;
    final root = FakeRootFolder();
    await pumpFiles(tester, folders: folders, rootFolder: root);

    await tester.tap(find.byKey(const Key('quick-open')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose folder'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Work'), findsOneWidget);
  });

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
