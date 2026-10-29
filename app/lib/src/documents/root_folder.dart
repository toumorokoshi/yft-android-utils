import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'document.dart';
import 'folder.dart';

/// The folder quick open searches, kept across restarts.
abstract interface class RootFolder {
  Future<Document?> load();

  Future<void> save(Document folder);
}

/// [RootFolder] stored in shared preferences.
class SharedPreferencesRootFolder implements RootFolder {
  SharedPreferencesRootFolder({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'root_folder';

  final SharedPreferencesAsync _preferences;

  @override
  Future<Document?> load() async =>
      decodeFolder(await _preferences.getString(_key));

  @override
  Future<void> save(Document folder) =>
      _preferences.setString(_key, jsonEncode(folder.toMap()));
}

/// Decodes a folder stored by [SharedPreferencesRootFolder]. Returns null for
/// null or invalid input.
Document? decodeFolder(String? encoded) {
  if (encoded == null) return null;
  try {
    final decoded = jsonDecode(encoded);
    return decoded is Map ? Document.fromMap(decoded) : null;
  } on FormatException {
    return null;
  }
}

/// Shows the folder picker and saves the chosen folder as the root. Returns
/// null when the user cancels.
Future<Document?> chooseRootFolder(FolderStore folders, RootFolder root) async {
  final folder = await folders.pickFolder();
  if (folder != null) await root.save(folder);
  return folder;
}
