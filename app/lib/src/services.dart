import 'documents/document.dart';
import 'documents/recent_documents.dart';

/// The platform-backed dependencies sub-apps use. `main` builds the real
/// ones; tests pass fakes.
class AppServices {
  const AppServices({
    required this.documents,
    required this.launches,
    required this.recents,
    required this.widgets,
  });

  final DocumentStore documents;
  final DocumentLaunches launches;
  final RecentDocuments recents;
  final DocumentWidgets widgets;
}
