import 'dart:async';

import 'package:yft_android_utils/src/documents/document.dart';
import 'package:yft_android_utils/src/documents/recent_documents.dart';
import 'package:yft_android_utils/src/services.dart';

const notes = Document(uri: 'content://docs/notes', name: 'notes.md');
const todo = Document(uri: 'content://docs/todo', name: 'todo.md');

/// An in-memory [DocumentStore] that records every write.
class FakeDocumentStore implements DocumentStore {
  FakeDocumentStore({Map<String, String>? files}) : files = {...?files};

  final Map<String, String> files;
  final writes = <String>[];
  Document? picked;
  Document? created;
  bool failReads = false;
  bool failWrites = false;

  @override
  Future<Document?> pick() async => picked;

  @override
  Future<Document?> create(String suggestedName) async => created;

  @override
  Future<String> read(Document document) async {
    if (failReads) throw Exception('read failed');
    return files[document.uri] ?? '';
  }

  @override
  Future<void> write(Document document, String text) async {
    if (failWrites) throw Exception('write failed');
    writes.add(text);
    files[document.uri] = text;
  }
}

class FakeDocumentLaunches implements DocumentLaunches {
  FakeDocumentLaunches({this.initialDocument});

  final Document? initialDocument;
  final controller = StreamController<Document>.broadcast();

  @override
  Future<Document?> initial() async => initialDocument;

  @override
  Stream<Document> get opened => controller.stream;
}

class FakeRecentDocuments implements RecentDocuments {
  FakeRecentDocuments([List<Document> documents = const []])
    : documents = [...documents];

  List<Document> documents;

  @override
  Future<List<Document>> load() async => documents;

  @override
  Future<List<Document>> add(Document document) async =>
      documents = addRecentDocument(documents, document);
}

/// Records pinned documents; [supported] is what the home screen reports.
class FakeDocumentWidgets implements DocumentWidgets {
  bool supported = true;
  final pinned = <Document>[];

  @override
  Future<bool> pin(Document document) async {
    if (supported) pinned.add(document);
    return supported;
  }
}

AppServices fakeServices({
  FakeDocumentStore? documents,
  FakeDocumentLaunches? launches,
  FakeRecentDocuments? recents,
  FakeDocumentWidgets? widgets,
}) => AppServices(
  documents: documents ?? FakeDocumentStore(),
  launches: launches ?? FakeDocumentLaunches(),
  recents: recents ?? FakeRecentDocuments(),
  widgets: widgets ?? FakeDocumentWidgets(),
);
