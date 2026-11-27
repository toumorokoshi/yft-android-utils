import 'package:flutter/widgets.dart';

const _supportedExternalSchemes = {'http', 'https', 'mailto', 'tel'};

/// A parsed target from a markdown link's `href`.
sealed class MarkdownLinkTarget {
  const MarkdownLinkTarget();
}

/// An in-document heading anchor link, such as `#getting-started`.
final class AnchorLink extends MarkdownLinkTarget {
  const AnchorLink(this.anchor);

  /// Normalized heading slug without the leading `#`.
  final String anchor;
}

/// An external URI link, such as `https://example.com`.
final class ExternalLink extends MarkdownLinkTarget {
  const ExternalLink(this.uri);

  final Uri uri;
}

/// A link that is empty, relative, or uses an unsupported scheme.
final class UnsupportedLink extends MarkdownLinkTarget {
  const UnsupportedLink(this.href);

  final String href;
}

/// Classifies a markdown link [href] into an [AnchorLink], [ExternalLink], or
/// [UnsupportedLink].
MarkdownLinkTarget parseMarkdownLink(String? href) {
  final trimmed = href?.trim() ?? '';
  if (trimmed.isEmpty) {
    return const UnsupportedLink('');
  }
  if (trimmed.startsWith('#')) {
    final raw = trimmed.substring(1);
    final decoded = _decodeUriComponent(raw);
    return AnchorLink(slugifyHeading(decoded));
  }
  final uri = Uri.tryParse(trimmed);
  if (uri != null &&
      uri.hasScheme &&
      _supportedExternalSchemes.contains(uri.scheme.toLowerCase())) {
    return ExternalLink(uri);
  }
  return UnsupportedLink(trimmed);
}

String _decodeUriComponent(String value) {
  try {
    return Uri.decodeComponent(value);
  } on ArgumentError {
    return value;
  }
}

final _nonSlugCharacters = RegExp(r'[^\p{L}\p{N} \-_]', unicode: true);

/// Converts a markdown heading's text into a GitHub-style anchor slug.
String slugifyHeading(String text) =>
    text.toLowerCase().replaceAll(_nonSlugCharacters, '').replaceAll(' ', '-');

/// Returns a unique slug based on [base] not yet present in [usedSlugs],
/// appending `-1`, `-2`, ... for duplicates, and records it in [usedSlugs].
String deduplicateSlug(String base, Set<String> usedSlugs) {
  var slug = base;
  var suffix = 1;
  while (!usedSlugs.add(slug)) {
    slug = '$base-$suffix';
    suffix++;
  }
  return slug;
}

/// Tracks [GlobalKey]s for rendered markdown headings, keyed by their
/// deduplicated anchor slugs.
class HeadingAnchorRegistry {
  final Map<String, GlobalKey> _keys = {};

  /// Clears registered headings before a new render pass.
  void reset() => _keys.clear();

  /// Registers [headingText] and returns a [GlobalKey] for its widget.
  ///
  /// Duplicate headings receive `-1`, `-2`, ... suffixes matching GitHub's
  /// anchor convention.
  GlobalKey register(String headingText) {
    final used = _keys.keys.toSet();
    final slug = deduplicateSlug(slugifyHeading(headingText), used);
    return _keys[slug] = GlobalKey();
  }

  /// Returns the [BuildContext] for the heading matching [anchor], or null if
  /// no such heading is currently mounted.
  BuildContext? contextFor(String anchor) => _keys[anchor]?.currentContext;

  /// The registered slugs in document order, exposed for testing.
  Iterable<String> get slugs => _keys.keys;
}
