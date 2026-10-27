import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../documents/document.dart';
import '../services.dart';
import 'markdown_editor_app.dart';

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

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final recent = await widget.services.recents.load();
    if (mounted) setState(() => _recent = recent);
  }

  Future<void> _choose(Future<Document?> Function() choose) async {
    final Document? document;
    try {
      document = await choose();
    } on PlatformException catch (error, stackTrace) {
      _log.warning('could not choose a file', error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the file: ${error.message}')),
        );
      }
      return;
    }
    if (document != null) await _open(document);
  }

  Future<void> _open(Document document) async {
    await openMarkdownEditor(Navigator.of(context), widget.services, document);
    await _loadRecent();
  }

  @override
  Widget build(BuildContext context) {
    final documents = widget.services.documents;
    return Scaffold(
      appBar: AppBar(title: const Text('Markdown')),
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
