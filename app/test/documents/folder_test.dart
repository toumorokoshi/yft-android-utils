import 'package:flutter_test/flutter_test.dart';
import 'package:yft_android_utils/src/documents/folder.dart';

import '../support/fakes.dart';

void main() {
  test('FolderFile.fromMap reads uri, name and path', () {
    final file = folderFile('a/notes.md');

    expect(
      FolderFile.fromMap({...file.document.toMap(), 'path': 'a/notes.md'}),
      file,
    );
    expect(FolderFile.fromMap(file.document.toMap()), isNull);
    expect(FolderFile.fromMap({'path': 'a/notes.md'}), isNull);
    expect(FolderFile.fromMap(null), isNull);
  });

  test('FolderIndex caches each folder until refreshed', () async {
    final store = FakeFolderStore(
      files: {
        notesFolder.uri: [folderFile('a.md')],
        workFolder.uri: [folderFile('b.md')],
      },
    );
    final index = FolderIndex(store);

    expect(index.cached(notesFolder), isNull);
    expect(await index.refresh(notesFolder), [folderFile('a.md')]);
    store.files[notesFolder.uri] = [folderFile('c.md')];

    expect(index.cached(notesFolder), [folderFile('a.md')]);
    expect(index.cached(workFolder), isNull);
    expect(await index.refresh(notesFolder), [folderFile('c.md')]);
    expect(store.lists, 2);
  });
}
