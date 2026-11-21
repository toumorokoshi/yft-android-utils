import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yft_android_utils/src/markdown_editor/markdown_formatting.dart';

void main() {
  group('applyHeading', () {
    test('inserts heading prefix on an empty line', () {
      const value = TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );

      final result = applyHeading(value, 1);

      expect(result.text, '# ');
      expect(result.selection, const TextSelection.collapsed(offset: 2));
    });

    test('treats an invalid selection as cursor at end of text', () {
      const value = TextEditingValue(text: 'Notes');

      final result = applyHeading(value, 2);

      expect(result.text, '## Notes');
      expect(result.selection, const TextSelection.collapsed(offset: 8));
    });

    test('inserts heading prefix and shifts cursor within the line', () {
      const value = TextEditingValue(
        text: 'Hello world',
        selection: TextSelection.collapsed(offset: 5),
      );

      final result = applyHeading(value, 3);

      expect(result.text, '### Hello world');
      expect(result.selection, const TextSelection.collapsed(offset: 9));
    });

    test('toggles off heading when the line already has the same level', () {
      const value = TextEditingValue(
        text: '## Hello',
        selection: TextSelection.collapsed(offset: 8),
      );

      final result = applyHeading(value, 2);

      expect(result.text, 'Hello');
      expect(result.selection, const TextSelection.collapsed(offset: 5));
    });

    test('clamps cursor to line start when toggling off inside the prefix', () {
      const value = TextEditingValue(
        text: '## Hello',
        selection: TextSelection.collapsed(offset: 1),
      );

      final result = applyHeading(value, 2);

      expect(result.text, 'Hello');
      expect(result.selection, const TextSelection.collapsed(offset: 0));
    });

    test('replaces heading level when a different level is applied', () {
      const value = TextEditingValue(
        text: '# Title',
        selection: TextSelection.collapsed(offset: 7),
      );

      final h3 = applyHeading(value, 3);
      expect(h3.text, '### Title');
      expect(h3.selection, const TextSelection.collapsed(offset: 9));

      final h1 = applyHeading(h3, 1);
      expect(h1.text, '# Title');
      expect(h1.selection, const TextSelection.collapsed(offset: 7));
    });

    test('does not treat hashtags without a space as a heading', () {
      const value = TextEditingValue(
        text: '#tag',
        selection: TextSelection.collapsed(offset: 4),
      );

      final result = applyHeading(value, 1);

      expect(result.text, '# #tag');
      expect(result.selection, const TextSelection.collapsed(offset: 6));
    });

    test('only modifies the line containing the cursor', () {
      const value = TextEditingValue(
        text: 'First\nSecond\nThird',
        selection: TextSelection.collapsed(offset: 8),
      );

      final result = applyHeading(value, 2);

      expect(result.text, 'First\n## Second\nThird');
      expect(result.selection, const TextSelection.collapsed(offset: 11));
    });

    test('preserves selection range within the modified line', () {
      const value = TextEditingValue(
        text: 'Hello world',
        selection: TextSelection(baseOffset: 6, extentOffset: 11),
      );

      final result = applyHeading(value, 1);

      expect(result.text, '# Hello world');
      expect(
        result.selection,
        const TextSelection(baseOffset: 8, extentOffset: 13),
      );
    });

    test('throws on out-of-range heading levels', () {
      expect(() => applyHeading(TextEditingValue.empty, 0), throwsRangeError);
      expect(() => applyHeading(TextEditingValue.empty, 7), throwsRangeError);
    });
  });
}
