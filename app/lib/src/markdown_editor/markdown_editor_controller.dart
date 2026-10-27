import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

import '../documents/document.dart';

final _log = Logger('markdown_editor');

/// Where the editor's text is relative to the file.
enum SaveStatus {
  loading,
  loadFailed,

  /// The file holds the text being shown.
  saved,

  /// Edits are waiting for the autosave delay.
  pending,
  saving,
  saveFailed,
}

/// A short label for [status], shown under the file name.
String saveStatusLabel(SaveStatus status) => switch (status) {
  SaveStatus.loading => 'Loading…',
  SaveStatus.loadFailed => 'Could not open the file',
  SaveStatus.saved => 'Saved',
  SaveStatus.pending => 'Editing…',
  SaveStatus.saving => 'Saving…',
  SaveStatus.saveFailed => 'Could not save, retrying on the next edit',
};

/// Loads [document] into [text] and writes edits back to it [saveDelay]
/// after the last keystroke.
class MarkdownEditorController extends ChangeNotifier {
  MarkdownEditorController({
    required this.document,
    required this._store,
    this.saveDelay = const Duration(milliseconds: 750),
  }) {
    text.addListener(_onTextChanged);
  }

  final Document document;
  final Duration saveDelay;
  final DocumentStore _store;

  final text = TextEditingController();

  SaveStatus get status => _status;
  SaveStatus _status = SaveStatus.loading;

  /// The text the file is known to hold, or null before it is loaded.
  String? _savedText;
  Timer? _timer;
  Future<void> _writes = Future.value();

  bool get isLoaded => _savedText != null;

  bool get _isDirty => isLoaded && text.text != _savedText;

  Future<void> load() async {
    _setStatus(SaveStatus.loading);
    try {
      final contents = await _store.read(document);
      _savedText = contents;
      text.text = contents;
      _setStatus(SaveStatus.saved);
    } on Exception catch (error, stackTrace) {
      _log.warning('could not read $document', error, stackTrace);
      _setStatus(SaveStatus.loadFailed);
    }
  }

  void _onTextChanged() {
    if (!_isDirty) return;
    _setStatus(SaveStatus.pending);
    _timer?.cancel();
    _timer = Timer(saveDelay, () => unawaited(flush()));
  }

  /// Writes any unsaved edits now. Writes are queued, so they reach the file
  /// in order.
  Future<void> flush() {
    _timer?.cancel();
    _timer = null;
    final snapshot = text.text;
    return _writes = _writes.then((_) => _write(snapshot));
  }

  Future<void> _write(String snapshot) async {
    if (!isLoaded || snapshot == _savedText) return;
    _setStatus(SaveStatus.saving);
    try {
      await _store.write(document, snapshot);
      _savedText = snapshot;
      if (!_disposed) {
        _setStatus(_isDirty ? SaveStatus.pending : SaveStatus.saved);
      }
    } on Exception catch (error, stackTrace) {
      _log.warning('could not write $document', error, stackTrace);
      _setStatus(SaveStatus.saveFailed);
    }
  }

  bool _disposed = false;

  void _setStatus(SaveStatus status) {
    if (_disposed || status == _status) return;
    _status = status;
    notifyListeners();
  }

  /// Queues a write of any unsaved edits, then releases the controller.
  @override
  void dispose() {
    unawaited(flush());
    _disposed = true;
    text.dispose();
    super.dispose();
  }
}
