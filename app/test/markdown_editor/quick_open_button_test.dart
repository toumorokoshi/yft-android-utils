import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yft_android_utils/src/app.dart';
import 'package:yft_android_utils/src/launcher/launcher_page.dart';
import 'package:yft_android_utils/src/markdown_editor/markdown_editor_page.dart';

import '../support/fakes.dart';

void main() {
  final todo = folderFile('work/todo.md');

  testWidgets('opens the chosen file in the editor above the launcher', (
    tester,
  ) async {
    final recents = FakeRecentDocuments();
    await tester.pumpWidget(
      App(
        services: fakeServices(
          folders: FakeFolderStore(
            files: {
              notesFolder.uri: [todo],
            },
          ),
          recents: recents,
          rootFolder: FakeRootFolder(notesFolder),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quick-open')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('todo.md', findRichText: true));
    await tester.pumpAndSettle();

    expect(find.byType(MarkdownEditorPage), findsOne);
    expect(recents.documents, [todo.document]);

    await tester.tap(find.byKey(const Key('quick-open')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('todo.md', findRichText: true));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(LauncherPage), findsOne);
  });

  testWidgets('closing quick open stays put', (tester) async {
    await tester.pumpWidget(App(services: fakeServices()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quick-open')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(LauncherPage), findsOne);
    expect(find.byType(MarkdownEditorPage), findsNothing);
  });
}
