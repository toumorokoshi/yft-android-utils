import 'dart:async';

import 'package:flutter/services.dart';
import 'package:yft_android_utils/src/documents/document.dart';
import 'package:yft_android_utils/src/documents/folder.dart';
import 'package:yft_android_utils/src/documents/recent_documents.dart';
import 'package:yft_android_utils/src/documents/root_folder.dart';
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

const notesFolder = Document(uri: 'content://docs/tree/notes', name: 'Notes');
const workFolder = Document(uri: 'content://docs/tree/work', name: 'Work');

/// A file named [path]'s last segment, with a URI derived from [path].
FolderFile folderFile(String path) => FolderFile(
  document: Document(
    uri: 'content://docs/tree/notes/document/$path',
    name: path.split('/').last,
  ),
  path: path,
);

/// Folders whose listings are [files], keyed by folder URI. Throws on
/// [list] when [failLists] is set.
class FakeFolderStore implements FolderStore {
  FakeFolderStore({Map<String, List<FolderFile>>? files}) : files = {...?files};

  final Map<String, List<FolderFile>> files;
  Document? picked;
  bool failLists = false;
  int lists = 0;

  @override
  Future<Document?> pickFolder() async => picked;

  @override
  Future<List<FolderFile>> list(Document folder) async {
    lists++;
    if (failLists) throw PlatformException(code: 'io', message: 'list failed');
    return files[folder.uri] ?? const [];
  }
}

class FakeRootFolder implements RootFolder {
  FakeRootFolder([this.folder]);

  Document? folder;

  @override
  Future<Document?> load() async => folder;

  @override
  Future<void> save(Document folder) async => this.folder = folder;
}

AppServices fakeServices({
  FakeDocumentStore? documents,
  FakeFolderStore? folders,
  FakeDocumentLaunches? launches,
  FakeRecentDocuments? recents,
  FakeRootFolder? rootFolder,
  FakeDocumentWidgets? widgets,
}) => AppServices(
  documents: documents ?? FakeDocumentStore(),
  folders: folders ?? FakeFolderStore(),
  launches: launches ?? FakeDocumentLaunches(),
  recents: recents ?? FakeRecentDocuments(),
  rootFolder: rootFolder ?? FakeRootFolder(),
  widgets: widgets ?? FakeDocumentWidgets(),
);
