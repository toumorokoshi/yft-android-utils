import 'package:flutter/material.dart';

/// One utility in the launcher grid.
@immutable
class SubApp {
  const SubApp({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.builder,
  });

  /// A stable, unique identifier, used for the route name and widget keys.
  final String id;
  final String title;

  /// One short sentence shown under the title.
  final String description;
  final IconData icon;

  /// Builds the sub-app's first screen.
  final WidgetBuilder builder;

  String get routeName => '/$id';
}

/// Opens [subApp] on top of the launcher.
Future<void> openSubApp(BuildContext context, SubApp subApp) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: subApp.routeName),
        builder: subApp.builder,
      ),
    );
