import 'package:flutter/material.dart';

import 'markdown_formatting.dart';

class _RibbonItem {
  const _RibbonItem({
    required this.tooltip,
    required this.onApply,
    this.label,
    this.icon,
  }) : assert(label != null || icon != null);

  final String tooltip;
  final MarkdownFormatAction onApply;
  final String? label;
  final IconData? icon;
}

final List<_RibbonItem> _items = [
  _RibbonItem(
    tooltip: 'Heading 1',
    label: 'H1',
    onApply: (v) => toggleHeading(v, 1),
  ),
  _RibbonItem(
    tooltip: 'Heading 2',
    label: 'H2',
    onApply: (v) => toggleHeading(v, 2),
  ),
  _RibbonItem(
    tooltip: 'Heading 3',
    label: 'H3',
    onApply: (v) => toggleHeading(v, 3),
  ),
  _RibbonItem(
    tooltip: 'Bold',
    icon: Icons.format_bold,
    onApply: (v) => toggleInlineWrap(v, '**'),
  ),
  _RibbonItem(
    tooltip: 'Italic',
    icon: Icons.format_italic,
    onApply: (v) => toggleInlineWrap(v, '*'),
  ),
  _RibbonItem(
    tooltip: 'Inline code',
    icon: Icons.code,
    onApply: (v) => toggleInlineWrap(v, '`'),
  ),
  const _RibbonItem(
    tooltip: 'Bullet list',
    icon: Icons.format_list_bulleted,
    onApply: toggleBulletList,
  ),
  const _RibbonItem(
    tooltip: 'Checklist',
    icon: Icons.checklist,
    onApply: toggleChecklist,
  ),
  const _RibbonItem(
    tooltip: 'Blockquote',
    icon: Icons.format_quote,
    onApply: toggleBlockquote,
  ),
  const _RibbonItem(tooltip: 'Link', icon: Icons.link, onApply: insertLink),
];

/// A horizontal formatting toolbar for a markdown [TextEditingController].
class FormattingRibbon extends StatelessWidget {
  const FormattingRibbon({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExcludeFocus(
      child: Material(
        key: const Key('formatting-ribbon'),
        color: theme.colorScheme.surfaceContainerLow,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 1),
              SizedBox(
                height: 44,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      for (final item in _items)
                        _RibbonButton(
                          item: item,
                          onPressed: () {
                            controller.value = item.onApply(controller.value);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RibbonButton extends StatelessWidget {
  const _RibbonButton({required this.item, required this.onPressed});

  final _RibbonItem item;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: item.tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: item.icon != null
                  ? Icon(item.icon, size: 20)
                  : Text(
                      item.label!,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
