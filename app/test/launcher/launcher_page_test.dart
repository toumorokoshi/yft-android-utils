import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yft_android_utils/src/launcher/launcher_page.dart';
import 'package:yft_android_utils/src/launcher/sub_app.dart';

SubApp fakeSubApp(String id) => SubApp(
  id: id,
  title: 'Title $id',
  description: 'Does $id',
  icon: Icons.star,
  builder: (_) => Text('screen $id'),
);

void main() {
  testWidgets('shows a tile per sub-app and opens the tapped one', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LauncherPage(
          title: 'utils',
          subApps: [fakeSubApp('a'), fakeSubApp('b')],
        ),
      ),
    );

    expect(find.byType(SubAppTile), findsNWidgets(2));
    expect(find.text('Does a'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sub-app-b')));
    await tester.pumpAndSettle();

    expect(find.text('screen b'), findsOneWidget);
  });

  test('routeName is derived from the id', () {
    expect(fakeSubApp('x').routeName, '/x');
  });
}
