import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yft_android_utils/src/markdown_editor/markdown_editor_controller.dart';

import '../support/fakes.dart';

const delay = Duration(milliseconds: 500);

void main() {
  late FakeDocumentStore store;
  late MarkdownEditorController controller;

  // Built inside fakeAsync by tests that use it, so its futures run on the
  // fake clock.
  MarkdownEditorController newController() =>
      MarkdownEditorController(document: notes, store: store, saveDelay: delay);

  setUp(() {
    store = FakeDocumentStore(files: {notes.uri: '# notes'});
    controller = newController();
  });

  test('load shows the file', () async {
    expect(controller.status, SaveStatus.loading);

    await controller.load();

    expect(controller.text.text, '# notes');
    expect(controller.status, SaveStatus.saved);
    expect(store.writes, isEmpty);
  });

  test('a failed load reports it', () async {
    store.failReads = true;

    await controller.load();

    expect(controller.status, SaveStatus.loadFailed);
    expect(controller.isLoaded, isFalse);
  });

  test('saves once, after the delay since the last edit', () {
    fakeAsync((async) {
      controller = newController()..load();
      async.flushMicrotasks();

      controller.text.text = '# notes\na';
      async.elapse(delay ~/ 2);
      controller.text.text = '# notes\nab';
      expect(controller.status, SaveStatus.pending);
      async.elapse(delay ~/ 2);
      expect(store.writes, isEmpty);

      async.elapse(delay);

      expect(store.writes, ['# notes\nab']);
      expect(controller.status, SaveStatus.saved);
    });
  });

  test('flush saves now and skips unchanged text', () async {
    await controller.load();
    controller.text.text = 'changed';

    await controller.flush();
    await controller.flush();

    expect(store.writes, ['changed']);
    expect(store.files[notes.uri], 'changed');
  });

  test('selection changes do not save', () async {
    await controller.load();

    controller.text.selection = const TextSelection.collapsed(offset: 2);
    await controller.flush();

    expect(controller.status, SaveStatus.saved);
    expect(store.writes, isEmpty);
  });

  test('a failed save reports it, and the next edit retries', () async {
    await controller.load();
    store.failWrites = true;
    controller.text.text = 'a';

    await controller.flush();
    expect(controller.status, SaveStatus.saveFailed);

    store.failWrites = false;
    controller.text.text = 'ab';
    await controller.flush();
    expect(controller.status, SaveStatus.saved);
    expect(store.writes, ['ab']);
  });

  test('dispose saves unsaved edits', () {
    fakeAsync((async) {
      controller = newController()..load();
      async.flushMicrotasks();
      controller.text.text = 'last words';

      controller.dispose();
      async.flushMicrotasks();

      expect(store.writes, ['last words']);
    });
  });

  test('saveStatusLabel has a label for every status', () {
    for (final status in SaveStatus.values) {
      expect(saveStatusLabel(status), isNotEmpty);
    }
  });
}
