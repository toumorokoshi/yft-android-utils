import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../documents/document.dart';
import '../markdown_editor/markdown_editor_app.dart';
import '../quick_open/quick_open_page.dart';
import '../services.dart';
import 'markdown_outline.dart';

/// A [Scaffold] with a collapsible right-hand navigation sidebar and an app bar
/// toggle button.
///
/// The sidebar starts collapsed so screens use the full viewport until
/// expanded. When expanded, it shows the markdown document outline (if
/// [onHeadingTap] is provided) and file navigation (Quick Open and recent
/// files, if [services] is provided).
class NavigationSidebarScaffold extends StatefulWidget {
  const NavigationSidebarScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.services,
    this.outline = const [],
    this.onHeadingTap,
    this.currentDocument,
    this.onQuickOpenCancel,
  });

  final Widget title;
  final Widget body;
  final List<Widget> actions;
  final AppServices? services;
  final List<MarkdownHeading> outline;
  final ValueChanged<MarkdownHeading>? onHeadingTap;
  final Document? currentDocument;
  final VoidCallback? onQuickOpenCancel;

  @override
  State<NavigationSidebarScaffold> createState() =>
      _NavigationSidebarScaffoldState();
}

class _NavigationSidebarScaffoldState extends State<NavigationSidebarScaffold> {
  bool _expanded = false;
  List<Document> _recent = const [];

  void _toggle() {
    final next = !_expanded;
    setState(() => _expanded = next);
    if (next) unawaited(_loadRecent());
  }

  void _collapse() {
    if (_expanded) setState(() => _expanded = false);
  }

  Future<void> _loadRecent() async {
    final services = widget.services;
    if (services == null) return;
    final recent = await services.recents.load();
    if (mounted) setState(() => _recent = recent);
  }

  Future<void> _quickOpen() async {
    final services = widget.services;
    if (services == null) return;
    final navigator = Navigator.of(context);
    final document = await showQuickOpen(context, services);
    if (document == null) {
      widget.onQuickOpenCancel?.call();
      return;
    }
    _collapse();
    unawaited(
      openMarkdownEditor(navigator, services, document, aboveLauncher: true),
    );
  }

  void _openDocument(Document document) {
    final services = widget.services;
    if (services == null) return;
    _collapse();
    if (document.uri == widget.currentDocument?.uri) return;
    unawaited(
      openMarkdownEditor(
        Navigator.of(context),
        services,
        document,
        aboveLauncher: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = math.min(280.0, MediaQuery.sizeOf(context).width * 0.75);
    return Scaffold(
      appBar: AppBar(
        title: widget.title,
        actions: [
          ...widget.actions,
          IconButton(
            key: const Key('toggle-sidebar'),
            tooltip: _expanded
                ? 'Collapse navigation sidebar'
                : 'Expand navigation sidebar',
            icon: Icon(
              _expanded ? Icons.chevron_right : Icons.view_sidebar_outlined,
            ),
            onPressed: _toggle,
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(child: widget.body),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.centerRight,
            child: _expanded
                ? SizedBox(
                    key: const Key('navigation-sidebar'),
                    width: width,
                    child: _NavigationSidebarPanel(
                      outline: widget.outline,
                      onHeadingTap: widget.onHeadingTap,
                      services: widget.services,
                      recent: _recent,
                      currentDocument: widget.currentDocument,
                      onCollapse: _collapse,
                      onQuickOpen: _quickOpen,
                      onDocumentTap: _openDocument,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _NavigationSidebarPanel extends StatelessWidget {
  const _NavigationSidebarPanel({
    required this.outline,
    required this.onHeadingTap,
    required this.services,
    required this.recent,
    required this.currentDocument,
    required this.onCollapse,
    required this.onQuickOpen,
    required this.onDocumentTap,
  });

  final List<MarkdownHeading> outline;
  final ValueChanged<MarkdownHeading>? onHeadingTap;
  final AppServices? services;
  final List<Document> recent;
  final Document? currentDocument;
  final VoidCallback onCollapse;
  final VoidCallback onQuickOpen;
  final ValueChanged<Document> onDocumentTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Navigation',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      IconButton(
                        key: const Key('collapse-sidebar'),
                        tooltip: 'Collapse navigation sidebar',
                        icon: const Icon(Icons.chevron_right),
                        onPressed: onCollapse,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (onHeadingTap != null) ...[
                        _SectionHeader('Outline', theme: theme),
                        if (outline.isEmpty)
                          const ListTile(
                            dense: true,
                            title: Text('No headings'),
                          )
                        else
                          for (final heading in outline)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.only(
                                left: 16.0 + (heading.level - 1) * 12.0,
                                right: 12,
                              ),
                              title: Text(
                                heading.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => onHeadingTap!(heading),
                            ),
                        if (services != null) const Divider(height: 16),
                      ],
                      if (services != null) ...[
                        _SectionHeader('Files', theme: theme),
                        ListTile(
                          key: const Key('sidebar-quick-open'),
                          dense: true,
                          leading: const Icon(Icons.search),
                          title: const Text('Quick open'),
                          onTap: onQuickOpen,
                        ),
                        if (recent.isEmpty)
                          const ListTile(
                            dense: true,
                            title: Text('No recent files'),
                          )
                        else ...[
                          _SectionHeader('Recent', theme: theme),
                          for (final document in recent)
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.description_outlined),
                              title: Text(
                                document.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              selected: document.uri == currentDocument?.uri,
                              onTap: () => onDocumentTap(document),
                            ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, {required this.theme});

  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
