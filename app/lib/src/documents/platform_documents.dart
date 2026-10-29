import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import 'document.dart';
import 'folder.dart';

final _log = Logger('documents');

/// The channel served by `DocumentsChannel.kt` in the Android app.
const documentsChannel = MethodChannel('dev.yft.yft_android_utils/documents');

/// [DocumentStore], [FolderStore], [DocumentLaunches] and [DocumentWidgets]
/// backed by the Android Storage Access Framework, through
/// [documentsChannel].
class PlatformDocuments
    implements DocumentStore, FolderStore, DocumentLaunches, DocumentWidgets {
  PlatformDocuments({this._channel = documentsChannel}) {
    _channel.setMethodCallHandler(_handle);
  }

  final MethodChannel _channel;
  final _opened = StreamController<Document>.broadcast();

  Future<Object?> _handle(MethodCall call) async {
    if (call.method != 'openDocument') {
      throw MissingPluginException('unknown method ${call.method}');
    }
    final document = _toDocument(call.arguments);
    if (document != null) {
      _log.info('asked to open $document');
      _opened.add(document);
    }
    return null;
  }

  Document? _toDocument(Object? value) =>
      value is Map ? Document.fromMap(value) : null;

  @override
  Future<Document?> pick() async =>
      _toDocument(await _channel.invokeMethod<Object?>('pick'));

  @override
  Future<Document?> create(String suggestedName) async => _toDocument(
    await _channel.invokeMethod<Object?>('create', {'name': suggestedName}),
  );

  @override
  Future<Document?> pickFolder() async =>
      _toDocument(await _channel.invokeMethod<Object?>('pickFolder'));

  @override
  Future<List<FolderFile>> list(Document folder) async {
    final files = await _channel.invokeListMethod<Object?>('listFolder', {
      'uri': folder.uri,
    });
    return [
      for (final file in files ?? const <Object?>[])
        if (file is Map) ?FolderFile.fromMap(file),
    ];
  }

  @override
  Future<String> read(Document document) async =>
      await _channel.invokeMethod<String>('read', {'uri': document.uri}) ?? '';

  @override
  Future<void> write(Document document, String text) =>
      _channel.invokeMethod<void>('write', {'uri': document.uri, 'text': text});

  @override
  Future<bool> pin(Document document) async =>
      await _channel.invokeMethod<bool>('pinWidget', document.toMap()) ?? false;

  @override
  Future<Document?> initial() async =>
      _toDocument(await _channel.invokeMethod<Object?>('initialDocument'));

  @override
  Stream<Document> get opened => _opened.stream;
}
