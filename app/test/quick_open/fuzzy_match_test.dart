import 'package:flutter_test/flutter_test.dart';
import 'package:yft_android_utils/src/quick_open/fuzzy_match.dart';

import '../support/fakes.dart';

void main() {
  group('fuzzyMatch', () {
    test('matches a subsequence and reports its positions', () {
      expect(fuzzyMatch('nts', 'notes.md')?.positions, [0, 2, 4]);
    });

    test('returns null when a character is missing or out of order', () {
      expect(fuzzyMatch('xyz', 'notes.md'), isNull);
      expect(fuzzyMatch('sn', 'notes.md'), isNull);
    });

    test('an empty query matches with no positions', () {
      final match = fuzzyMatch('  ', 'notes.md');

      expect(match?.score, 0);
      expect(match?.positions, isEmpty);
    });

    test('is case-insensitive for lowercase terms', () {
      expect(fuzzyMatch('readme', 'README.md'), isNotNull);
    });

    test('is case-sensitive for terms with an uppercase letter', () {
      expect(fuzzyMatch('ReadMe', 'readme.md'), isNull);
      expect(fuzzyMatch('ReadMe', 'ReadMe.md'), isNotNull);
    });

    test('every whitespace-separated term must match, in any order', () {
      expect(fuzzyMatch('todo work', 'work/todo.md'), isNotNull);
      expect(fuzzyMatch('todo home', 'work/todo.md'), isNull);
      expect(fuzzyMatch('todo work', 'work/todo.md')?.positions, [
        0,
        1,
        2,
        3,
        5,
        6,
        7,
        8,
      ]);
    });

    test('prefers the alignment on word starts', () {
      // "mn" could match "m" and "n" in "meeting", but the word starts win.
      expect(fuzzyMatch('mn', 'meeting-notes.md')?.positions, [0, 8]);
    });

    test('prefers matching in the file name over the folders', () {
      expect(fuzzyMatch('todo', 'todo-app/notes/todo.md')?.positions, [
        15,
        16,
        17,
        18,
      ]);
    });

    test('keeps indexes aligned when lowercasing changes length', () {
      expect(fuzzyMatch('x', 'İx')?.positions, [1]);
    });
  });

  group('scores', () {
    int score(String query, String text) => fuzzyMatch(query, text)!.score;

    test('adjacent characters beat scattered ones', () {
      expect(score('note', 'notes.md'), greaterThan(score('note', 'nxoxtxe')));
    });

    test('path and word starts beat the middle of a word', () {
      expect(score('n', 'a/notes.md'), greaterThan(score('n', 'a/annotate')));
      expect(score('n', 'my-notes'), greaterThan(score('n', 'mynotes')));
    });

    test('camelCase humps beat the middle of a word', () {
      expect(score('n', 'myNotes'), greaterThan(score('n', 'mynotes')));
    });
  });

  group('rankFiles', () {
    final files = [
      folderFile('archive/2025/notes.md'),
      folderFile('notes.md'),
      folderFile('projects/android/nested-overview.md'),
      folderFile('todo.md'),
    ];

    List<String> paths(List<RankedFile> ranked) => [
      for (final r in ranked) r.file.path,
    ];

    test('drops files that do not match and puts the best first', () {
      expect(paths(rankFiles('notes', files)), [
        'notes.md',
        'archive/2025/notes.md',
      ]);
    });

    test('an empty query lists every file, shortest path first', () {
      expect(paths(rankFiles('', files)), [
        'todo.md',
        'notes.md',
        'archive/2025/notes.md',
        'projects/android/nested-overview.md',
      ]);
    });

    test('recent files win ties', () {
      final ranked = rankFiles(
        '',
        files,
        recent: [folderFile('archive/2025/notes.md').document.uri],
      );

      expect(paths(ranked).first, 'archive/2025/notes.md');
    });

    test('returns at most limit files', () {
      expect(rankFiles('', files, limit: 2), hasLength(2));
    });
  });
}
