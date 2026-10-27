import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:yft_android_utils/src/documents/document.dart';
import 'package:yft_android_utils/src/documents/recent_documents.dart';

import '../support/fakes.dart';

void main() {
  group('addRecentDocument', () {
    test('puts the document first', () {
      expect(addRecentDocument([notes], todo), [todo, notes]);
    });

    test('moves a document already in the list', () {
      expect(addRecentDocument([notes, todo], todo), [todo, notes]);
    });

    test('keeps at most max documents', () {
      final many = [
        for (var i = 0; i < 5; i++)
          Document(uri: 'content://$i', name: '$i.md'),
      ];

      expect(addRecentDocument(many, notes, max: 3), [notes, many[0], many[1]]);
    });
  });

  group('decodeDocuments', () {
    test('reads what encodeDocuments writes', () {
      expect(decodeDocuments(encodeDocuments([notes, todo])), [notes, todo]);
    });

    test('returns an empty list for missing or invalid input', () {
      expect(decodeDocuments(null), isEmpty);
      expect(decodeDocuments('not json'), isEmpty);
      expect(decodeDocuments('{"uri": "x"}'), isEmpty);
    });

    test('skips malformed entries', () {
      expect(decodeDocuments('[{"uri": "x"}, 3, {"uri": "u", "name": "n"}]'), [
        const Document(uri: 'u', name: 'n'),
      ]);
    });
  });

  test('SharedPreferencesRecentDocuments persists added documents', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final recents = SharedPreferencesRecentDocuments(
      preferences: SharedPreferencesAsync(),
    );

    expect(await recents.load(), isEmpty);
    await recents.add(notes);
    expect(await recents.add(todo), [todo, notes]);
    expect(await SharedPreferencesRecentDocuments().load(), [todo, notes]);
  });
}
