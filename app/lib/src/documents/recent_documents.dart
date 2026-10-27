import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'document.dart';

/// How many recent documents are kept.
const maxRecentDocuments = 10;

/// Returns [recent] with [document] moved, or added, to the front, keeping at
/// most [max] entries.
List<Document> addRecentDocument(
  List<Document> recent,
  Document document, {
  int max = maxRecentDocuments,
}) => [
  document,
  ...recent.where((d) => d.uri != document.uri),
].take(max).toList();

/// Encodes [documents] for storage as a single string.
String encodeDocuments(List<Document> documents) =>
    jsonEncode([for (final d in documents) d.toMap()]);

/// Decodes [encodeDocuments]'s output, skipping malformed entries. Returns an
/// empty list for null or invalid input.
List<Document> decodeDocuments(String? encoded) {
  if (encoded == null) return const [];
  try {
    final decoded = jsonDecode(encoded);
    if (decoded is! List) return const [];
    return [
      for (final entry in decoded)
        if (entry is Map) ?Document.fromMap(entry),
    ];
  } on FormatException {
    return const [];
  }
}

/// The documents opened most recently, newest first.
abstract interface class RecentDocuments {
  Future<List<Document>> load();

  /// Records that [document] was opened, and returns the updated list.
  Future<List<Document>> add(Document document);
}

/// [RecentDocuments] stored in shared preferences.
class SharedPreferencesRecentDocuments implements RecentDocuments {
  SharedPreferencesRecentDocuments({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'recent_documents';

  final SharedPreferencesAsync _preferences;

  @override
  Future<List<Document>> load() async =>
      decodeDocuments(await _preferences.getString(_key));

  @override
  Future<List<Document>> add(Document document) async {
    final recent = addRecentDocument(await load(), document);
    await _preferences.setString(_key, encodeDocuments(recent));
    return recent;
  }
}
