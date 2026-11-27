import 'package:flutter_test/flutter_test.dart';
import 'package:yft_android_utils/src/navigation_sidebar/markdown_outline.dart';

void main() {
  test('returns empty list for empty markdown', () {
    expect(parseMarkdownHeadings(''), isEmpty);
  });

  test('extracts ATX headings with levels, titles, slugs, and offsets', () {
    const md = '# Title\n\nBody\n## Sub Section ##\n###### Deep\n';
    final headings = parseMarkdownHeadings(md);

    expect(headings, hasLength(3));
    expect(headings[0].level, 1);
    expect(headings[0].title, 'Title');
    expect(headings[0].anchor, 'title');
    expect(headings[0].offset, 0);

    expect(headings[1].level, 2);
    expect(headings[1].title, 'Sub Section');
    expect(headings[1].anchor, 'sub-section');
    expect(headings[1].offset, md.indexOf('## Sub Section'));

    expect(headings[2].level, 6);
    expect(headings[2].title, 'Deep');
    expect(headings[2].anchor, 'deep');
    expect(headings[2].offset, md.indexOf('###### Deep'));
  });

  test('ignores headings inside fenced code blocks', () {
    const md = '''
# Before
```dart
# Not a heading
```
~~~
## Also not a heading
~~~
## After
''';
    final headings = parseMarkdownHeadings(md);
    expect(headings.map((h) => h.title), ['Before', 'After']);
  });

  test('deduplicates repeated heading anchors', () {
    const md = '# Repeat\n## Repeat\n### Repeat\n';
    final headings = parseMarkdownHeadings(md);
    expect(headings.map((h) => h.anchor), ['repeat', 'repeat-1', 'repeat-2']);
  });
}
