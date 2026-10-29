import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../documents/document.dart';
import '../documents/folder.dart';
import '../documents/root_folder.dart';
import '../services.dart';
import 'fuzzy_match.dart';

final _log = Logger('quick_open');

/// Shows the [QuickOpenPage]. Returns the chosen file, or null.
Future<Document?> showQuickOpen(BuildContext context, AppServices services) =>
    Navigator.of(context).push(
      MaterialPageRoute<Document>(
        settings: const RouteSettings(name: '/quick-open'),
        builder: (_) => QuickOpenPage(services: services),
      ),
    );

/// Finds a file in the root folder by typing part of its path. Pops with
/// the chosen [Document].
///
/// Shows the cached listing straight away and lists the folder again in the
/// background, so new files appear without waiting on every open.
class QuickOpenPage extends StatefulWidget {
  const QuickOpenPage({super.key, required this.services});

  final AppServices services;

  @override
  State<QuickOpenPage> createState() => _QuickOpenPageState();
}

class _QuickOpenPageState extends State<QuickOpenPage> {
  final _query = TextEditingController();
  bool _loaded = false;
  Document? _folder;
  List<FolderFile> _files = const [];
  List<String> _recent = const [];
  bool _listing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final services = widget.services;
    final folder = await services.rootFolder.load();
    final recent = await services.recents.load();
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _folder = folder;
      _recent = [for (final document in recent) document.uri];
    });
    if (folder != null) await _refresh(folder);
  }

  Future<void> _refresh(Document folder) async {
    final index = widget.services.folderIndex;
    setState(() {
      _files = index.cached(folder) ?? const [];
      _listing = true;
      _error = null;
    });
    try {
      final files = await index.refresh(folder);
      if (mounted && _folder == folder) setState(() => _files = files);
    } on PlatformException catch (error, stackTrace) {
      _log.warning('could not list $folder', error, stackTrace);
      if (mounted && _folder == folder) {
        setState(() => _error = 'Could not list ${folder.name}.');
      }
    } finally {
      if (mounted && _folder == folder) setState(() => _listing = false);
    }
  }

  Future<void> _chooseFolder() async {
    final Document? folder;
    try {
      folder = await chooseRootFolder(
        widget.services.folders,
        widget.services.rootFolder,
      );
    } on PlatformException catch (error, stackTrace) {
      _log.warning('could not choose a folder', error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open the folder: ${error.message}'),
          ),
        );
      }
      return;
    }
    if (folder == null || !mounted) return;
    setState(() => _folder = folder);
    await _refresh(folder);
  }

  List<RankedFile> _results({int limit = 100}) =>
      rankFiles(_query.text, _files, recent: _recent, limit: limit);

  void _openBest(String _) {
    if (_results(limit: 1) case [final best]) {
      Navigator.of(context).pop(best.file.document);
    }
  }

  @override
  Widget build(BuildContext context) {
    final folder = _folder;
    final results = _results();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('quick-open-query'),
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.go,
          decoration: InputDecoration(
            hintText: folder == null ? 'Search files' : 'Search ${folder.name}',
            border: InputBorder.none,
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: _openBest,
        ),
        actions: [
          IconButton(
            tooltip: 'Change folder',
            icon: const Icon(Icons.folder_open),
            onPressed: _chooseFolder,
          ),
          if (folder != null)
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: _listing ? null : () => _refresh(folder),
            ),
        ],
        bottom: _listing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: switch ((folder, _error)) {
        _ when !_loaded => const SizedBox.shrink(),
        (null, _) => _Message(
          text: 'Choose a folder for quick open to search.',
          action: FilledButton.icon(
            onPressed: _chooseFolder,
            icon: const Icon(Icons.folder_open),
            label: const Text('Choose folder'),
          ),
        ),
        (final folder?, final error?) => _Message(
          text: error,
          action: FilledButton(
            onPressed: () => _refresh(folder),
            child: const Text('Retry'),
          ),
        ),
        _ when results.isEmpty => _Message(
          text: _listing ? 'Listing files…' : 'No matching files.',
        ),
        _ => ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, i) => _ResultTile(result: results[i]),
        ),
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            if (action case final action?) ...[
              const SizedBox(height: 12),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result});

  final RankedFile result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlight = TextStyle(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );
    final path = result.file.path;
    final positions = result.match.positions.toSet();
    final nameStart = path.lastIndexOf('/') + 1;
    final folder = nameStart == 0 ? '' : path.substring(0, nameStart - 1);
    return ListTile(
      leading: const Icon(Icons.description_outlined),
      title: Text.rich(
        TextSpan(
          children: highlightSpans(
            path.substring(nameStart),
            positions,
            highlight,
            offset: nameStart,
          ),
        ),
      ),
      subtitle: folder.isEmpty
          ? null
          : Text.rich(
              TextSpan(children: highlightSpans(folder, positions, highlight)),
              overflow: TextOverflow.ellipsis,
            ),
      onTap: () => Navigator.of(context).pop(result.file.document),
    );
  }
}

/// Splits [text] into spans, styling the characters whose index plus
/// [offset] is in [positions] with [highlight].
List<TextSpan> highlightSpans(
  String text,
  Set<int> positions,
  TextStyle highlight, {
  int offset = 0,
}) {
  final spans = <TextSpan>[];
  var start = 0;
  for (var i = 1; i <= text.length; i++) {
    final matched = positions.contains(start + offset);
    if (i < text.length && positions.contains(i + offset) == matched) continue;
    spans.add(
      TextSpan(
        text: text.substring(start, i),
        style: matched ? highlight : null,
      ),
    );
    start = i;
  }
  return spans;
}
