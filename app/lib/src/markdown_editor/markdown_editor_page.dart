import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:logging/logging.dart';
import 'package:markdown/markdown.dart' as md;

import '../documents/document.dart';
import '../links/link_launcher.dart';
import 'markdown_editor_controller.dart';
import 'markdown_links.dart';

final _log = Logger('markdown_editor');

/// Shown when the home screen cannot add widgets for apps.
const pinUnsupportedMessage =
    'This home screen cannot add widgets from apps. Long-press the home '
    'screen and add "Markdown file" from its widgets instead.';

/// Edits [document], saving as you type, with a rendered preview.
class MarkdownEditorPage extends StatefulWidget {
  const MarkdownEditorPage({
    super.key,
    required this.document,
    required this.store,
    required this.widgets,
    this.links = const PlatformLinkLauncher(),
    this.saveDelay = const Duration(milliseconds: 750),
    this.actions = const [],
  });

  final Document document;
  final DocumentStore store;
  final DocumentWidgets widgets;
  final LinkLauncher links;
  final Duration saveDelay;

  /// App bar buttons shown before the editor's own, such as quick open.
  final List<Widget> actions;

  @override
  State<MarkdownEditorPage> createState() => _MarkdownEditorPageState();
}

class _MarkdownEditorPageState extends State<MarkdownEditorPage> {
  late final _controller = MarkdownEditorController(
    document: widget.document,
    store: widget.store,
    saveDelay: widget.saveDelay,
  );
  late final AppLifecycleListener _lifecycle;
  bool _preview = false;

  @override
  void initState() {
    super.initState();
    unawaited(_controller.load());
    _lifecycle = AppLifecycleListener(
      onHide: () => unawaited(_controller.flush()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pinWidget() async {
    final String? message;
    try {
      message = await widget.widgets.pin(widget.document)
          ? null
          : pinUnsupportedMessage;
    } on PlatformException catch (error, stackTrace) {
      _log.warning('could not pin a widget', error, stackTrace);
      if (!mounted) return;
      _showMessage('Could not add the widget: ${error.message}');
      return;
    }
    if (message != null && mounted) _showMessage(message);
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final status = _controller.status;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.document.name, overflow: TextOverflow.ellipsis),
                Text(
                  saveStatusLabel(status),
                  key: const Key('save-status'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              ...widget.actions,
              if (_controller.isLoaded)
                IconButton(
                  tooltip: _preview ? 'Edit' : 'Preview',
                  icon: Icon(_preview ? Icons.edit : Icons.visibility),
                  onPressed: () => setState(() => _preview = !_preview),
                ),
              IconButton(
                tooltip: 'Add widget to home screen',
                icon: const Icon(Icons.add_to_home_screen),
                onPressed: _pinWidget,
              ),
            ],
          ),
          body: switch (status) {
            SaveStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            SaveStatus.loadFailed => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(saveStatusLabel(status)),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _controller.load,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            _ when _preview => _MarkdownPreview(
              data: _controller.text.text,
              links: widget.links,
              onMessage: _showMessage,
            ),
            _ => _Editor(controller: _controller.text),
          },
        );
      },
    );
  }
}

const _headingTags = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'];

class _MarkdownPreview extends StatefulWidget {
  const _MarkdownPreview({
    required this.data,
    required this.links,
    required this.onMessage,
  });

  final String data;
  final LinkLauncher links;
  final ValueChanged<String> onMessage;

  @override
  State<_MarkdownPreview> createState() => _MarkdownPreviewState();
}

class _MarkdownPreviewState extends State<_MarkdownPreview> {
  final _scrollController = ScrollController();
  final _anchors = HeadingAnchorRegistry();
  late final Map<String, MarkdownElementBuilder> _builders = {
    for (final tag in _headingTags) tag: _HeadingAnchorBuilder(_anchors),
  };

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleLinkTap(String text, String? href, String title) async {
    switch (parseMarkdownLink(href)) {
      case AnchorLink(:final anchor):
        final targetContext = _anchors.contextFor(anchor);
        if (targetContext == null) {
          widget.onMessage('Heading not found: $href');
          return;
        }
        await Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: 0.0,
        );
      case ExternalLink(:final uri):
        try {
          final launched = await widget.links.launch(uri);
          if (!launched && mounted) {
            widget.onMessage('Could not open $uri');
          }
        } on Exception catch (error, stackTrace) {
          _log.warning('could not open $uri', error, stackTrace);
          if (mounted) widget.onMessage('Could not open $uri');
        }
      case UnsupportedLink(:final href):
        if (href.isNotEmpty) {
          widget.onMessage('Cannot open link: $href');
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    _anchors.reset();
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: MarkdownBody(
        data: widget.data,
        selectable: true,
        fitContent: false,
        builders: _builders,
        onTapLink: (text, href, title) =>
            unawaited(_handleLinkTap(text, href, title)),
      ),
    );
  }
}

class _HeadingAnchorBuilder extends MarkdownElementBuilder {
  _HeadingAnchorBuilder(this.anchors);

  final HeadingAnchorRegistry anchors;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final key = anchors.register(element.textContent);
    return SelectableText(element.textContent, key: key, style: preferredStyle);
  }
}

class _Editor extends StatelessWidget {
  const _Editor({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        key: const Key('markdown-editor'),
        controller: controller,
        expands: true,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textAlignVertical: TextAlignVertical.top,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(fontFamily: 'monospace'),
        decoration: const InputDecoration.collapsed(hintText: 'Start writing…'),
      ),
    );
  }
}
