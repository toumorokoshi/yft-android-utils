import 'package:flutter/foundation.dart';

/// A file on the device, addressed by its Storage Access Framework URI
/// (`content://...`), which stays valid across restarts once the app holds
/// a persisted permission for it.
@immutable
class Document {
  const Document({required this.uri, required this.name});

  /// Parses the `{uri, name}` map sent over platform channels and stored in
  /// preferences. Returns null when either field is missing.
  static Document? fromMap(Map<Object?, Object?>? map) {
    final uri = map?['uri'];
    final name = map?['name'];
    return uri is String && name is String
        ? Document(uri: uri, name: name)
        : null;
  }

  final String uri;

  /// The display name, such as `notes.md`.
  final String name;

  Map<String, String> toMap() => {'uri': uri, 'name': name};

  @override
  bool operator ==(Object other) =>
      other is Document && other.uri == uri && other.name == name;

  @override
  int get hashCode => Object.hash(uri, name);

  @override
  String toString() => 'Document($name, $uri)';
}

/// Picks, creates, reads and writes [Document]s.
abstract interface class DocumentStore {
  /// Shows the system file picker. Returns null when the user cancels.
  Future<Document?> pick();

  /// Shows the system "save as" picker for a new file named [suggestedName].
  /// Returns null when the user cancels.
  Future<Document?> create(String suggestedName);

  Future<String> read(Document document);

  /// Replaces the contents of [document] with [text].
  Future<void> write(Document document, String text);
}

/// Documents the app is asked to open from outside, such as a tap on a home
/// screen widget.
abstract interface class DocumentLaunches {
  /// The document the app was started to open, if any. Returns it only once.
  Future<Document?> initial();

  /// Documents requested while the app is already running.
  Stream<Document> get opened;
}
