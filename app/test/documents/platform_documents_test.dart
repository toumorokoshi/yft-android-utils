import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yft_android_utils/src/documents/document.dart';
import 'package:yft_android_utils/src/documents/platform_documents.dart';

import '../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;
  late PlatformDocuments documents;

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(documentsChannel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'pick' || 'create' || 'initialDocument' => notes.toMap(),
        'read' => '# notes',
        'pinWidget' => true,
        _ => null,
      };
    });
    documents = PlatformDocuments();
  });

  tearDown(() => messenger.setMockMethodCallHandler(documentsChannel, null));

  test('pick and create return the chosen document', () async {
    expect(await documents.pick(), notes);
    expect(await documents.create('new.md'), notes);
    expect(calls.last.arguments, {'name': 'new.md'});
  });

  test('read and write pass the uri', () async {
    expect(await documents.read(notes), '# notes');
    await documents.write(notes, 'text');

    expect(calls.map((c) => c.method), ['read', 'write']);
    expect(calls.last.arguments, {'uri': notes.uri, 'text': 'text'});
  });

  test('pin sends the document', () async {
    expect(await documents.pin(notes), isTrue);
    expect(calls.single.method, 'pinWidget');
    expect(calls.single.arguments, notes.toMap());
  });

  test('pickFolder returns the chosen folder', () async {
    messenger.setMockMethodCallHandler(
      documentsChannel,
      (call) async => notesFolder.toMap(),
    );

    expect(await documents.pickFolder(), notesFolder);
  });

  test('list passes the folder uri and skips malformed files', () async {
    final file = folderFile('work/todo.md');
    messenger.setMockMethodCallHandler(documentsChannel, (call) async {
      calls.add(call);
      return [
        {...file.document.toMap(), 'path': file.path},
        {'uri': 'missing-path', 'name': 'x'},
        3,
      ];
    });

    expect(await documents.list(notesFolder), [file]);
    expect(calls.single.method, 'listFolder');
    expect(calls.single.arguments, {'uri': notesFolder.uri});
  });

  test('initial returns the launch document', () async {
    expect(await documents.initial(), notes);
  });

  test('openDocument calls from Android are sent to opened', () async {
    final opened = documents.opened.first;

    await messenger.handlePlatformMessage(
      documentsChannel.name,
      documentsChannel.codec.encodeMethodCall(
        MethodCall('openDocument', todo.toMap()),
      ),
      (_) {},
    );

    expect(await opened, todo);
  });

  test('a cancelled pick returns null', () async {
    messenger.setMockMethodCallHandler(documentsChannel, (_) async => null);

    expect(await documents.pick(), isNull);
    expect(await documents.pickFolder(), isNull);
    expect(await documents.list(notesFolder), isEmpty);
    expect(await documents.initial(), isNull);
    expect(await documents.pin(notes), isFalse);
    expect(await documents.read(const Document(uri: 'u', name: 'n')), '');
  });
}
