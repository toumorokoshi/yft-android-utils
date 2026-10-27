import 'package:flutter/material.dart';

import 'sub_app.dart';

/// The home screen: a grid with one tile per [SubApp].
class LauncherPage extends StatelessWidget {
  const LauncherPage({super.key, required this.title, required this.subApps});

  final String title;
  final List<SubApp> subApps;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: GridView.extent(
        maxCrossAxisExtent: 180,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [for (final subApp in subApps) SubAppTile(subApp: subApp)],
      ),
    );
  }
}

/// A launcher tile that opens [subApp] when tapped.
class SubAppTile extends StatelessWidget {
  const SubAppTile({super.key, required this.subApp});

  final SubApp subApp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.filled(
      key: Key('sub-app-${subApp.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openSubApp(context, subApp),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(subApp.icon, size: 40, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                subApp.title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subApp.description,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
