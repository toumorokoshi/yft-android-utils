import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yft_android_utils/src/markdown_editor/markdown_formatting.dart';

TextEditingValue _val(String text, [int? base, int? extent]) {
  if (base == null) {
    return TextEditingValue(text: text);
  }
  return TextEditingValue(
    text: text,
    selection: extent == null
        ? TextSelection.collapsed(offset: base)
        : TextSelection(baseOffset: base, extentOffset: extent),
  );
}

void main() {
  group('toggleHeading', () {
    test('adds H2 prefix to current line and shifts cursor', () {
      final result = toggleHeading(_val('hello\nworld', 8), 2);
      expect(result.text, 'hello\n## world');
      expect(result.selection, const TextSelection.collapsed(offset: 11));
    });

    test('toggles H2 off when line is already H2', () {
      final result = toggleHeading(_val('## world', 5), 2);
      expect(result.text, 'world');
      expect(result.selection, const TextSelection.collapsed(offset: 2));
    });

    test('replaces H1 with H2', () {
      final result = toggleHeading(_val('# Title', 4), 2);
      expect(result.text, '## Title');
      expect(result.selection, const TextSelection.collapsed(offset: 5));
    });

    test('works on an empty document or invalid selection', () {
      final empty = toggleHeading(_val('', 0), 2);
      expect(empty.text, '## ');
      expect(empty.selection, const TextSelection.collapsed(offset: 3));

      final invalid = toggleHeading(_val('note'), 2);
      expect(invalid.text, '## note');
      expect(invalid.selection, const TextSelection.collapsed(offset: 7));
    });

    test('applies across multiple selected lines', () {
      final result = toggleHeading(_val('one\ntwo\nthree', 1, 6), 2);
      expect(result.text, '## one\n## two\nthree');
      expect(
        result.selection,
        const TextSelection(baseOffset: 4, extentOffset: 12),
      );
    });
  });

  group('list and quote toggles', () {
    test('toggleBulletList adds, removes, and converts from checklist', () {
      final added = toggleBulletList(_val('item', 2));
      expect(added.text, '- item');

      final removed = toggleBulletList(added);
      expect(removed.text, 'item');

      final fromCheck = toggleBulletList(_val('- [x] done', 6));
      expect(fromCheck.text, '- done');
    });

    test('toggleChecklist adds, removes, and converts from bullet', () {
      final added = toggleChecklist(_val('task', 0));
      expect(added.text, '- [ ] task');

      final removed = toggleChecklist(added);
      expect(removed.text, 'task');

      final fromBullet = toggleChecklist(_val('- item', 2));
      expect(fromBullet.text, '- [ ] item');
    });

    test('toggleBlockquote adds and removes > prefix', () {
      final added = toggleBlockquote(_val('quote', 0));
      expect(added.text, '> quote');

      final removed = toggleBlockquote(added);
      expect(removed.text, 'quote');
    });
  });

  group('toggleInlineWrap', () {
    test('inserts paired markers with cursor inside when collapsed', () {
      final result = toggleInlineWrap(_val('ab', 1), '**');
      expect(result.text, 'a****b');
      expect(result.selection, const TextSelection.collapsed(offset: 3));
    });

    test('wraps and unwraps selected text', () {
      final wrapped = toggleInlineWrap(_val('hello world', 6, 11), '**');
      expect(wrapped.text, 'hello **world**');
      expect(
        wrapped.selection,
        const TextSelection(baseOffset: 8, extentOffset: 13),
      );

      final unwrapped = toggleInlineWrap(wrapped, '**');
      expect(unwrapped.text, 'hello world');
      expect(
        unwrapped.selection,
        const TextSelection(baseOffset: 6, extentOffset: 11),
      );
    });
  });

  group('insertLink', () {
    test('inserts empty link with cursor inside brackets when collapsed', () {
      final result = insertLink(_val('see ', 4));
      expect(result.text, 'see [](url)');
      expect(result.selection, const TextSelection.collapsed(offset: 5));
    });

    test('wraps selected text and selects url placeholder', () {
      final result = insertLink(_val('visit docs', 6, 10));
      expect(result.text, 'visit [docs](url)');
      expect(
        result.selection,
        const TextSelection(baseOffset: 13, extentOffset: 16),
      );
    });
  });
}
