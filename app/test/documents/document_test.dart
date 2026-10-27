import 'package:flutter_test/flutter_test.dart';
import 'package:yft_android_utils/src/documents/document.dart';

void main() {
  group('Document', () {
    test('round-trips through a map', () {
      const document = Document(uri: 'content://a', name: 'a.md');

      expect(Document.fromMap(document.toMap()), document);
    });

    test('fromMap returns null for missing or mistyped fields', () {
      expect(Document.fromMap(null), isNull);
      expect(Document.fromMap({'uri': 'content://a'}), isNull);
      expect(Document.fromMap({'uri': 1, 'name': 'a.md'}), isNull);
    });
  });
}
