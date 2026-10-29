import 'package:flutter/foundation.dart';

import 'document.dart';

/// A file found under a folder, with its path relative to that folder.
@immutable
class FolderFile {
  const FolderFile({required this.document, required this.path});

  /// Parses the `{uri, name, path}` map sent over the platform channel.
  /// Returns null when a field is missing.
  static FolderFile? fromMap(Map<Object?, Object?>? map) {
    final document = Document.fromMap(map);
    final path = map?['path'];
    return document != null && path is String
        ? FolderFile(document: document, path: path)
        : null;
  }

  final Document document;

  /// The path below the folder, such as `projects/todo.md`.
  final String path;

  @override
  bool operator ==(Object other) =>
      other is FolderFile && other.document == document && other.path == path;

  @override
  int get hashCode => Object.hash(document, path);

  @override
  String toString() => 'FolderFile($path)';
}

/// Picks folders and lists the files in them. A folder is a [Document]
/// whose URI is a Storage Access Framework tree.
abstract interface class FolderStore {
  /// Shows the system folder picker. Returns null when the user cancels.
  Future<Document?> pickFolder();

  /// Every file below [folder], skipping hidden files and folders.
  Future<List<FolderFile>> list(Document folder);
}

/// Caches each folder's files for the session: listing a folder makes one
/// provider query per subfolder, which is slow for large trees.
class FolderIndex {
  FolderIndex(this._store);

  final FolderStore _store;
  final _files = <String, List<FolderFile>>{};

  /// The files from the last [refresh] of [folder], if any.
  List<FolderFile>? cached(Document folder) => _files[folder.uri];

  /// Lists [folder] again and caches the result.
  Future<List<FolderFile>> refresh(Document folder) async =>
      _files[folder.uri] = await _store.list(folder);
}
