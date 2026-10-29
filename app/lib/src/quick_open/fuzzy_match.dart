import 'package:flutter/foundation.dart';

import '../documents/folder.dart';

/// A query's match in a text: its score (higher is better) and the indexes
/// of the matched characters, ascending.
@immutable
class FuzzyMatch {
  const FuzzyMatch(this.score, this.positions);

  final int score;
  final List<int> positions;
}

const _scoreMatch = 16;
const _gapStart = -3;
const _gapExtension = -1;
const _bonusPathStart = 10;
const _bonusWordStart = 8;
const _bonusCamelCase = 7;
const _bonusConsecutive = 5;
const _bonusFileName = 4;
const _firstCharMultiplier = 2;
const _none = -1 << 30;

/// Matches [query] against the path [text], fzf style.
///
/// The query is split on whitespace and every term must appear in [text] in
/// order, though not necessarily adjacent. Terms are case-insensitive unless
/// they contain an uppercase letter. Matches score higher at the start of a
/// path segment or word, on camelCase humps, in runs of adjacent characters
/// and in the file name, and lower across gaps. Returns null when a term does
/// not match.
FuzzyMatch? fuzzyMatch(String query, String text) {
  var score = 0;
  final positions = <int>{};
  for (final term in query.split(RegExp(r'\s+'))) {
    if (term.isEmpty) continue;
    final match = _matchTerm(term, text);
    if (match == null) return null;
    score += match.score;
    positions.addAll(match.positions);
  }
  return FuzzyMatch(score, positions.toList()..sort());
}

/// Finds the best-scoring alignment of [term] in [text] with a
/// Smith-Waterman style table: `score[i][j]` is the best score with the
/// term's character `i` matched at text index `j`.
FuzzyMatch? _matchTerm(String term, String text) {
  final caseSensitive = term.codeUnits.any(_isUpper);
  int fold(int unit) => caseSensitive ? unit : _toLower(unit);
  final pattern = [for (final unit in term.codeUnits) fold(unit)];
  final subject = [for (final unit in text.codeUnits) fold(unit)];
  if (!_isSubsequence(pattern, subject)) return null;

  final m = pattern.length;
  final n = subject.length;
  final fileNameStart = text.lastIndexOf('/') + 1;
  final bonus = [for (var j = 0; j < n; j++) _bonusAt(text, j)];
  final score = List<int>.filled(m * n, _none);
  final from = List<int>.filled(m * n, -1);

  for (var i = 0; i < m; i++) {
    var gapBest = _none;
    var gapFrom = -1;
    for (var j = i; j < n; j++) {
      if (i > 0 && j >= 2) {
        if (gapBest != _none) gapBest += _gapExtension;
        final open = score[(i - 1) * n + j - 2];
        if (open != _none && open + _gapStart > gapBest) {
          gapBest = open + _gapStart;
          gapFrom = j - 2;
        }
      }
      if (subject[j] != pattern[i]) continue;
      final charScore =
          _scoreMatch +
          bonus[j] * (i == 0 ? _firstCharMultiplier : 1) +
          (j >= fileNameStart ? _bonusFileName : 0);
      if (i == 0) {
        score[j] = charScore;
        continue;
      }
      var best = _none;
      var bestFrom = -1;
      final adjacent = score[(i - 1) * n + j - 1];
      if (adjacent != _none) {
        best = adjacent + _bonusConsecutive;
        bestFrom = j - 1;
      }
      if (gapBest > best) {
        best = gapBest;
        bestFrom = gapFrom;
      }
      if (best == _none) continue;
      score[i * n + j] = best + charScore;
      from[i * n + j] = bestFrom;
    }
  }

  var end = -1;
  for (var j = m - 1; j < n; j++) {
    final value = score[(m - 1) * n + j];
    if (value != _none && (end < 0 || value > score[(m - 1) * n + end])) {
      end = j;
    }
  }
  if (end < 0) return null;
  final positions = List<int>.filled(m, 0);
  for (var i = m - 1, j = end; i >= 0; j = from[i * n + j], i--) {
    positions[i] = j;
  }
  return FuzzyMatch(score[(m - 1) * n + end], positions);
}

bool _isSubsequence(List<int> pattern, List<int> subject) {
  var i = 0;
  for (var j = 0; j < subject.length && i < pattern.length; j++) {
    if (subject[j] == pattern[i]) i++;
  }
  return i == pattern.length;
}

int _bonusAt(String text, int j) {
  if (j == 0) return _bonusPathStart;
  final previous = text.codeUnitAt(j - 1);
  if (previous == 0x2f) return _bonusPathStart; // '/'
  if (' _-.'.codeUnits.contains(previous)) return _bonusWordStart;
  if (_isLower(previous) && _isUpper(text.codeUnitAt(j))) {
    return _bonusCamelCase;
  }
  return 0;
}

bool _isUpper(int unit) {
  final char = String.fromCharCode(unit);
  return char != char.toLowerCase();
}

bool _isLower(int unit) {
  final char = String.fromCharCode(unit);
  return char != char.toUpperCase();
}

/// Lowercases one UTF-16 unit, keeping it when lowercasing would change the
/// length (such as `İ`), so indexes stay aligned with the original text.
int _toLower(int unit) {
  final lower = String.fromCharCode(unit).toLowerCase();
  return lower.length == 1 ? lower.codeUnitAt(0) : unit;
}

/// A [FolderFile] that matched a query.
@immutable
class RankedFile {
  const RankedFile(this.file, this.match);

  final FolderFile file;

  /// The match against [FolderFile.path].
  final FuzzyMatch match;
}

/// The [files] whose paths match [query], best first, at most [limit].
///
/// Ties go to files in [recent] (URIs, newest first), then shorter paths,
/// then alphabetical order. An empty query matches every file.
List<RankedFile> rankFiles(
  String query,
  Iterable<FolderFile> files, {
  List<String> recent = const [],
  int limit = 100,
}) {
  final recency = {for (final (i, uri) in recent.indexed) uri: i};
  int recencyOf(RankedFile r) => recency[r.file.document.uri] ?? recent.length;
  final ranked = [
    for (final file in files)
      if (fuzzyMatch(query, file.path) case final match?)
        RankedFile(file, match),
  ];
  ranked.sort(
    (a, b) => [
      b.match.score.compareTo(a.match.score),
      recencyOf(a).compareTo(recencyOf(b)),
      a.file.path.length.compareTo(b.file.path.length),
      a.file.path.compareTo(b.file.path),
    ].firstWhere((order) => order != 0, orElse: () => 0),
  );
  return ranked.take(limit).toList();
}
