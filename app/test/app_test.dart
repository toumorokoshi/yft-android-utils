import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yft_android_utils/src/app.dart';
import 'package:yft_android_utils/src/launcher/launcher_page.dart';
import 'package:yft_android_utils/src/markdown_editor/markdown_editor_page.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('starts on the launcher with the markdown sub-app', (
    tester,
  ) async {
    await tester.pumpWidget(App(services: fakeServices()));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, appTitle), findsOneWidget);
    expect(find.byType(LauncherPage), findsOneWidget);
    expect(find.byKey(const Key('sub-app-markdown')), findsOneWidget);
  });

  testWidgets('opens the launch document in the editor', (tester) async {
    await tester.pumpWidget(
      App(
        services: fakeServices(
          launches: FakeDocumentLaunches(initialDocument: notes),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MarkdownEditorPage), findsOneWidget);
    expect(find.text('notes.md'), findsOneWidget);
  });

  testWidgets('a widget tap replaces the open editor', (tester) async {
    final launches = FakeDocumentLaunches();
    await tester.pumpWidget(App(services: fakeServices(launches: launches)));
    await tester.pumpAndSettle();

    launches.controller.add(notes);
    await tester.pumpAndSettle();
    launches.controller.add(todo);
    await tester.pumpAndSettle();

    expect(find.text('todo.md'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(LauncherPage), findsOneWidget);
  });
}
