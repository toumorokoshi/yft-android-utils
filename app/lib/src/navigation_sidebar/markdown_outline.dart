import 'package:flutter/foundation.dart';

import '../markdown_editor/markdown_links.dart';

/// A heading extracted from a markdown document for outline navigation.
@immutable
class MarkdownHeading {
  const MarkdownHeading({
    required this.level,
    required this.title,
    required this.anchor,
    required this.offset,
  });

  /// Heading level from 1 (`#`) to 6 (`######`).
  final int level;

  /// Heading text with leading/trailing `#` markers stripped.
  final String title;

  /// Deduplicated GitHub-style anchor slug matching [HeadingAnchorRegistry].
  final String anchor;

  /// Character offset of the heading line's start in the source text.
  final int offset;
}

final _fencePattern = RegExp(r'^[ ]{0,3}(`{3,}|~{3,})');
final _headingPattern = RegExp(r'^[ ]{0,3}(#{1,6})(?:[ \t]+(.*?))?[ \t]*$');
final _trailingHashes = RegExp(r'[ \t]+#+$');

/// Parses ATX headings (`#` through `######`) from [markdown], ignoring
/// fenced code blocks and assigning deduplicated GitHub-style anchor slugs.
List<MarkdownHeading> parseMarkdownHeadings(String markdown) {
  if (markdown.isEmpty) return const [];
  final headings = <MarkdownHeading>[];
  final usedSlugs = <String>{};
  String? activeFenceChar;
  var activeFenceLength = 0;

  var offset = 0;
  final lines = markdown.split('\n');
  for (final rawLine in lines) {
    final line = rawLine.endsWith('\r')
        ? rawLine.substring(0, rawLine.length - 1)
        : rawLine;

    final fenceMatch = _fencePattern.firstMatch(line);
    if (fenceMatch != null) {
      final marker = fenceMatch.group(1)!;
      final fenceChar = marker[0];
      if (activeFenceChar == null) {
        activeFenceChar = fenceChar;
        activeFenceLength = marker.length;
      } else if (fenceChar == activeFenceChar &&
          marker.length >= activeFenceLength &&
          line.substring(fenceMatch.end).trim().isEmpty) {
        activeFenceChar = null;
        activeFenceLength = 0;
      }
      offset += rawLine.length + 1;
      continue;
    }

    if (activeFenceChar == null) {
      final match = _headingPattern.firstMatch(line);
      if (match != null) {
        final level = match.group(1)!.length;
        final rawTitle = (match.group(2) ?? '')
            .replaceFirst(_trailingHashes, '')
            .trim();
        if (rawTitle.isNotEmpty) {
          final anchor = deduplicateSlug(slugifyHeading(rawTitle), usedSlugs);
          headings.add(
            MarkdownHeading(
              level: level,
              title: rawTitle,
              anchor: anchor,
              offset: offset,
            ),
          );
        }
      }
    }

    offset += rawLine.length + 1;
  }

  return headings;
}
