import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:yft_android_utils/src/documents/root_folder.dart';

import '../support/fakes.dart';

void main() {
  test('decodeFolder returns null for missing or invalid input', () {
    expect(decodeFolder(null), isNull);
    expect(decodeFolder('not json'), isNull);
    expect(decodeFolder('[]'), isNull);
    expect(decodeFolder('{"uri": "x"}'), isNull);
  });

  test('SharedPreferencesRootFolder persists the saved folder', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final root = SharedPreferencesRootFolder();

    expect(await root.load(), isNull);
    await root.save(notesFolder);
    await root.save(workFolder);
    expect(await SharedPreferencesRootFolder().load(), workFolder);
  });

  group('chooseRootFolder', () {
    test('saves the picked folder', () async {
      final folders = FakeFolderStore()..picked = notesFolder;
      final root = FakeRootFolder();

      expect(await chooseRootFolder(folders, root), notesFolder);
      expect(root.folder, notesFolder);
    });

    test('keeps the old folder when cancelled', () async {
      final root = FakeRootFolder(workFolder);

      expect(await chooseRootFolder(FakeFolderStore(), root), isNull);
      expect(root.folder, workFolder);
    });
  });
}
