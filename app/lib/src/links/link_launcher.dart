import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Opens external URIs outside the app.
abstract interface class LinkLauncher {
  Future<bool> launch(Uri uri);
}

/// Launches external URIs in an external application via `url_launcher`.
class PlatformLinkLauncher implements LinkLauncher {
  const PlatformLinkLauncher();

  @override
  Future<bool> launch(Uri uri) => url_launcher.launchUrl(
    uri,
    mode: url_launcher.LaunchMode.externalApplication,
  );
}
