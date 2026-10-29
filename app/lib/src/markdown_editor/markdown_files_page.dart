import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../documents/document.dart';
import '../documents/root_folder.dart';
import '../services.dart';
import 'markdown_editor_app.dart';
import 'quick_open_button.dart';

final _log = Logger('markdown_editor');

/// The name suggested for a new file.
const newFileName = 'notes.md';

/// The markdown sub-app's first screen: open or create a file, or reopen a
/// recent one.
class MarkdownFilesPage extends StatefulWidget {
  const MarkdownFilesPage({super.key, required this.services});

  final AppServices services;

  @override
  State<MarkdownFilesPage> createState() => _MarkdownFilesPageState();
}

class _MarkdownFilesPageState extends State<MarkdownFilesPage> {
  List<Document> _recent = const [];
  Document? _folder;

  @override
  void initState() {
    super.initState();
    _loadRecent();
    _loadFolder();
  }

  Future<void> _loadRecent() async {
    final recent = await widget.services.recents.load();
    if (mounted) setState(() => _recent = recent);
  }

  Future<void> _loadFolder() async {
    final folder = await widget.services.rootFolder.load();
    if (mounted) setState(() => _folder = folder);
  }

  /// Runs [choose], showing [failure] when the picker fails.
  Future<T?> _pick<T>(Future<T?> Function() choose, String failure) async {
    try {
      return await choose();
    } on PlatformException catch (error, stackTrace) {
      _log.warning(failure, error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$failure: ${error.message}')));
      }
      return null;
    }
  }

  Future<void> _choose(Future<Document?> Function() choose) async {
    final document = await _pick(choose, 'Could not open the file');
    if (document != null) await _open(document);
  }

  Future<void> _chooseFolder() async {
    final services = widget.services;
    final folder = await _pick(
      () => chooseRootFolder(services.folders, services.rootFolder),
      'Could not open the folder',
    );
    if (folder != null && mounted) setState(() => _folder = folder);
  }

  Future<void> _open(Document document) async {
    await openMarkdownEditor(Navigator.of(context), widget.services, document);
    await _loadRecent();
  }

  @override
  Widget build(BuildContext context) {
    final documents = widget.services.documents;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown'),
        actions: [
          QuickOpenButton(services: widget.services, onCancel: _loadFolder),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => _choose(documents.pick),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Open file'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _choose(() => documents.create(newFileName)),
                  icon: const Icon(Icons.note_add),
                  label: const Text('New file'),
                ),
              ],
            ),
          ),
          const ListTile(title: Text('Folder'), dense: true),
          ListTile(
            key: const Key('root-folder'),
            leading: const Icon(Icons.folder_outlined),
            title: Text(_folder?.name ?? 'No folder chosen'),
            subtitle: const Text('Quick open searches this folder'),
            trailing: TextButton(
              onPressed: _chooseFolder,
              child: Text(_folder == null ? 'Choose' : 'Change'),
            ),
          ),
          if (_recent.isNotEmpty)
            const ListTile(title: Text('Recent'), dense: true),
          for (final document in _recent)
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(document.name),
              onTap: () => _open(document),
            ),
        ],
      ),
    );
  }
}
