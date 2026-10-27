# Android App

## Platform

- The app is written in Flutter/Dart and targets Android only. Other
  platform folders are not generated.
- The application id is `dev.yft.yft_android_utils`. Changing it later
  makes a new app on devices and in stores, so it stays fixed.
- The minimum and target SDKs follow Flutter's defaults
  (`flutter.minSdkVersion`, `flutter.targetSdkVersion`).

## UI

- Material 3, with light and dark themes that follow the system setting.
- Screens take the full screen (see [design/ui.md](../design/ui.md)).
- The first screen is the launcher: a grid with one tile per sub-app
  (icon, title and a one-line description). Tapping a tile opens the
  sub-app full screen; back returns to the grid.

## Sub-apps

- Each utility is a sub-app, listed once in `lib/src/sub_apps.dart`, in
  launcher order. A sub-app has a stable `id`, a title, a description, an
  icon and a builder for its first screen.
- Sub-apps get platform services (file access, preferences) from
  `AppServices`, so they can be tested with fakes.
- Sub-apps:
  - Markdown: open, create and live-edit a markdown file, with a 1x1 home
    screen widget per file (see [markdown-editor.md](markdown-editor.md)).

## Logging

- All console output uses `package:logging` (see
  [design/logging-stdout-stderr.md](../design/logging-stdout-stderr.md)),
  set up once in `main` by `setUpLogging`.

## Builds

- CI builds a release APK on every push to `main` and every pull
  request, and uploads it as an artifact.
- Release builds are signed with the release key when the signing secrets
  are set, and with the debug key otherwise (see
  [docs/android.md](../docs/android.md)).
