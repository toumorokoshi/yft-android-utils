import 'documents/document.dart';
import 'documents/folder.dart';
import 'documents/recent_documents.dart';
import 'documents/root_folder.dart';

/// The platform-backed dependencies sub-apps use. `main` builds the real
/// ones; tests pass fakes.
class AppServices {
  AppServices({
    required this.documents,
    required this.folders,
    required this.launches,
    required this.recents,
    required this.rootFolder,
    required this.widgets,
  }) : folderIndex = FolderIndex(folders);

  final DocumentStore documents;
  final FolderStore folders;
  final DocumentLaunches launches;
  final RecentDocuments recents;
  final RootFolder rootFolder;
  final DocumentWidgets widgets;

  /// The session's cache of [folders] listings.
  final FolderIndex folderIndex;
}
