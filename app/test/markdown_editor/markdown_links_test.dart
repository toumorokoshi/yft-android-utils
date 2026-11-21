import 'package:flutter_test/flutter_test.dart';
import 'package:yft_android_utils/src/markdown_editor/markdown_links.dart';

void main() {
  group('slugifyHeading', () {
    test('lowercases and replaces spaces with hyphens', () {
      expect(slugifyHeading('Getting Started'), 'getting-started');
    });

    test('removes punctuation while preserving hyphens and underscores', () {
      expect(slugifyHeading("What's New? (v2.0)"), 'whats-new-v20');
      expect(slugifyHeading('foo_bar-baz'), 'foo_bar-baz');
    });

    test('preserves consecutive hyphens like GitHub', () {
      expect(slugifyHeading('A & B'), 'a--b');
    });

    test('preserves unicode letters', () {
      expect(slugifyHeading('Café Menu'), 'café-menu');
    });
  });

  group('parseMarkdownLink', () {
    test('parses anchor links and normalizes them', () {
      expect(
        parseMarkdownLink('#getting-started'),
        isA<AnchorLink>().having((l) => l.anchor, 'anchor', 'getting-started'),
      );
      expect(
        parseMarkdownLink('#Getting%20Started'),
        isA<AnchorLink>().having((l) => l.anchor, 'anchor', 'getting-started'),
      );
      expect(
        parseMarkdownLink('  #Section-1  '),
        isA<AnchorLink>().having((l) => l.anchor, 'anchor', 'section-1'),
      );
    });

    test('parses supported external links', () {
      for (final url in [
        'https://example.com/docs?q=1',
        'http://example.com',
        'mailto:user@example.com',
        'tel:+15551234',
      ]) {
        expect(
          parseMarkdownLink(url),
          isA<ExternalLink>().having((l) => l.uri.toString(), 'uri', url),
        );
      }
    });

    test('treats empty, relative, and unsupported links as unsupported', () {
      for (final href in [
        null,
        '',
        '   ',
        'other.md',
        './sub/notes.md',
        'javascript:alert(1)',
        'file:///etc/passwd',
      ]) {
        expect(parseMarkdownLink(href), isA<UnsupportedLink>());
      }
    });
  });

  group('HeadingAnchorRegistry', () {
    test('deduplicates repeated headings and resets between renders', () {
      final registry = HeadingAnchorRegistry();
      registry.register('Section');
      registry.register('Section');
      registry.register('Section');

      expect(registry.slugs, ['section', 'section-1', 'section-2']);

      registry.reset();
      expect(registry.slugs, isEmpty);

      registry.register('Section');
      expect(registry.slugs, ['section']);
    });
  });
}
