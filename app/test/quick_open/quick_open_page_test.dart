import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yft_android_utils/src/documents/document.dart';
import 'package:yft_android_utils/src/quick_open/quick_open_page.dart';
import 'package:yft_android_utils/src/services.dart';

import '../support/fakes.dart';

void main() {
  final files = [
    folderFile('notes.md'),
    folderFile('work/todo.md'),
    folderFile('work/meeting-notes.md'),
  ];

  /// Opens quick open from a button and returns a getter for its result.
  Future<Document? Function()> pumpQuickOpen(
    WidgetTester tester,
    AppServices services,
  ) async {
    Document? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                chosen = await showQuickOpen(context, services),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => chosen;
  }

  Finder richText(String text) => find.text(text, findRichText: true);

  testWidgets('without a folder, asks for one and lists it once chosen', (
    tester,
  ) async {
    final folders = FakeFolderStore(files: {notesFolder.uri: files})
      ..picked = notesFolder;
    final root = FakeRootFolder();
    await pumpQuickOpen(
      tester,
      fakeServices(folders: folders, rootFolder: root),
    );

    expect(find.text('Choose a folder for quick open to search.'), findsOne);
    await tester.tap(find.text('Choose folder'));
    await tester.pumpAndSettle();

    expect(root.folder, notesFolder);
    expect(richText('todo.md'), findsOne);
    expect(find.text('Search Notes'), findsOne);
  });

  testWidgets('typing filters the files and a tap returns one', (tester) async {
    final services = fakeServices(
      folders: FakeFolderStore(files: {notesFolder.uri: files}),
      rootFolder: FakeRootFolder(notesFolder),
    );
    final chosen = await pumpQuickOpen(tester, services);
    expect(richText('meeting-notes.md'), findsOne);

    await tester.enterText(find.byKey(const Key('quick-open-query')), 'todo');
    await tester.pumpAndSettle();

    expect(richText('meeting-notes.md'), findsNothing);
    await tester.tap(richText('todo.md'));
    await tester.pumpAndSettle();
    expect(chosen(), folderFile('work/todo.md').document);
  });

  testWidgets('submitting the query returns the best match', (tester) async {
    final services = fakeServices(
      folders: FakeFolderStore(files: {notesFolder.uri: files}),
      rootFolder: FakeRootFolder(notesFolder),
    );
    final chosen = await pumpQuickOpen(tester, services);

    await tester.enterText(find.byKey(const Key('quick-open-query')), 'mn');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();

    expect(chosen(), folderFile('work/meeting-notes.md').document);
  });

  testWidgets('says when nothing matches', (tester) async {
    final services = fakeServices(
      folders: FakeFolderStore(files: {notesFolder.uri: files}),
      rootFolder: FakeRootFolder(notesFolder),
    );
    await pumpQuickOpen(tester, services);

    await tester.enterText(find.byKey(const Key('quick-open-query')), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No matching files.'), findsOne);
  });

  testWidgets('a failed listing offers a retry', (tester) async {
    final folders = FakeFolderStore(files: {notesFolder.uri: files})
      ..failLists = true;
    await pumpQuickOpen(
      tester,
      fakeServices(folders: folders, rootFolder: FakeRootFolder(notesFolder)),
    );

    expect(find.text('Could not list Notes.'), findsOne);
    folders.failLists = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(richText('notes.md'), findsOne);
  });

  group('highlightSpans', () {
    const bold = TextStyle(fontWeight: FontWeight.bold);

    List<(String?, bool)> describe(List<TextSpan> spans) => [
      for (final span in spans) (span.text, span.style == bold),
    ];

    test('groups runs of matched and unmatched characters', () {
      expect(describe(highlightSpans('notes.md', {0, 1, 4}, bold)), [
        ('no', true),
        ('te', false),
        ('s', true),
        ('.md', false),
      ]);
    });

    test('shifts positions by offset', () {
      expect(describe(highlightSpans('todo.md', {5, 6}, bold, offset: 5)), [
        ('to', true),
        ('do.md', false),
      ]);
    });

    test('returns nothing for empty text', () {
      expect(highlightSpans('', {0}, bold), isEmpty);
    });
  });
}
