import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yft_android_utils/src/app.dart';

void main() {
  testWidgets('shows the title and the greeting', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.widgetWithText(AppBar, appTitle), findsOneWidget);
    expect(find.text('Hello, world!'), findsOneWidget);
  });
}
