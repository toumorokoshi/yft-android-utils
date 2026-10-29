import 'dart:async';

import 'package:flutter/material.dart';

import '../quick_open/quick_open_page.dart';
import '../services.dart';
import 'markdown_editor_app.dart';

/// The app bar's quick open action: find a file in the root folder and open
/// it in the markdown editor, above the launcher.
class QuickOpenButton extends StatelessWidget {
  const QuickOpenButton({super.key, required this.services, this.onCancel});

  final AppServices services;

  /// Called when quick open closes without a file; the root folder may have
  /// changed.
  final VoidCallback? onCancel;

  Future<void> _quickOpen(BuildContext context) async {
    final navigator = Navigator.of(context);
    final document = await showQuickOpen(context, services);
    if (document == null) return onCancel?.call();
    unawaited(
      openMarkdownEditor(navigator, services, document, aboveLauncher: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('quick-open'),
      tooltip: 'Quick open',
      icon: const Icon(Icons.search),
      onPressed: () => _quickOpen(context),
    );
  }
}
