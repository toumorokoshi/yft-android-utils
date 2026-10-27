# Design Decision Log

## 2026-10-27: Release workflow for tagged APKs

CI only uploaded the APK as a run artifact, so there was no stable place
to download a release from. `release.yml` now publishes a GitHub Release
for each `v*` tag.

- **Modeled on shireitou's `release.yml`**, reduced to Android: the same
  tag-matches-pubspec and rising-build-number checks, then
  `scripts/package-android`, then `softprops/action-gh-release`.
- **Debug-signed prereleases instead of failing.** shireitou fails a
  tagged release without the signing key. This repository has no key
  yet, so a tag publishes a debug-signed APK marked as a prerelease with
  a warning in its notes, rather than blocking releases until the key
  exists.
- **Tags only.** CI already builds the APK on every push and pull
  request, so the release workflow does not run on `main`; a manual run
  builds without publishing.

## 2026-10-27: Add a widget from the editor

Placing a widget from the home screen's widget list means picking the
same file again. The editor now has an "add widget to home screen"
button for the open file.

- **`requestPinAppWidget` with a callback.** The home screen shows its
  own placement prompt; when the user places the widget, it sends the
  new widget id to `MarkdownWidgetPinnedReceiver` through a mutable
  `PendingIntent` carrying the file's URI and name, which binds them.
  The app already holds the file's persisted permission, so no new grant
  is needed.
- **A one-minute "just pinned" record.** Android does not say whether
  the home screen runs the configure activity for pinned widgets. If it
  does, the activity skips the picker for a widget pinned in the last
  minute, instead of asking for a file the widget already has.
- **`DocumentWidgets` is its own interface** in `AppServices`, like the
  other platform services, so the editor is tested with a fake.

## 2026-10-26: Sub-app launcher and markdown editor

The app had only a placeholder screen. It needs to hold many small
utilities, starting with editing a markdown file on the phone, opened
either from the app or from a 1x1 home screen widget.

- **A launcher grid of `SubApp`s.** Each utility is a `SubApp` (id,
  title, description, icon, first screen) in one list,
  `buildSubApps`. Adding a utility is one folder and one list entry, and
  the grid needs no changes.
- **Platform access behind interfaces in `AppServices`.** `DocumentStore`,
  `DocumentLaunches` and `RecentDocuments` are interfaces; `main` passes
  the platform ones and tests pass in-memory fakes, so widget tests do not
  mock channels.
- **The Storage Access Framework, not file paths.** Since Android 11,
  apps cannot write arbitrary paths without the "all files access"
  permission. The system picker works with every provider, needs no
  permission, and a persisted URI permission lets the widget reopen the
  file after restarts.
- **A small Kotlin channel instead of SAF plugins.** `saf_util` and
  `saf_stream` were considered, but `saf_util`'s file picker does not take
  a persisted permission, so access would end at the next restart. The
  widget needs native picker code anyway, so one `Documents` helper serves
  both the channel and the widget.
- **A native widget instead of `home_widget`.** `home_widget` 0.10 builds
  with the Kotlin 1.9 Gradle plugin and Glance, which risks breaking the
  AGP 9 build, and its value here (launch URIs into Flutter) is a few
  lines on the existing channel. The widget is a classic
  `AppWidgetProvider` with `RemoteViews`, and placing it runs a
  configure activity that shows the picker natively, without starting
  Flutter.
- **Autosave, debounced and queued.** The editor saves 750 ms after the
  last keystroke, when the app is hidden and when the editor closes.
  Writes go through one queue in Dart and one background thread in
  Kotlin, so an older save can never land after a newer one.
- **Only persisted URIs are opened from intents.** `MainActivity` is
  exported, so other apps can send it the open action; it ignores URIs the
  user did not pick, so it cannot be made to write another app's files.
- **`flutter_markdown_plus` for the preview.** `flutter_markdown` is
  discontinued; `flutter_markdown_plus` is its maintained fork.

## 2026-10-26: Gaps in GAPS.md, not an issue tracker

`AGENTS.md` asked agents to file issues with the `bd` (beads) CLI, which
this project does not use.

- **GAPS.md is the only place for open work.** The `bd` instructions are
  removed; agents already record remaining work in `GAPS.md`.
- **Descriptions follow `/yft-pr-commit-description`.** Commit and PR
  descriptions use that skill's template when it is available, so they
  share one structure.

## 2026-10-26: Project setup

The repository had only the shared agent guidelines. It needed an app to
build on, with the same tooling as shireitou so both projects are worked
on the same way.

- **Flutter, Android only.** `flutter create --platforms android` keeps
  only the Android project, so there are no iOS, web or desktop folders to
  maintain or lint. Another platform can be added later with
  `flutter create --platforms <name> .` in `app/`.
- **A pub workspace with the app in `app/`.** As in shireitou, the root
  `pubspec.yaml` is a workspace, so pure-Dart packages can move into
  `packages/` without changing the commands or CI.
- **The same lint settings as shireitou.** `flutter_lints` with strict
  casts, inference and raw types, plus `avoid_print` so console output
  goes through `package:logging` (design/logging-stdout-stderr.md).
- **Logging to `dart:developer`.** Records go to `developer.log` rather
  than `print`, so they show in `flutter run`, DevTools and
  `adb logcat` with their level, error and stack trace. The formatter is
  a pure function and tested on its own.
- **CI builds a release APK.** A second job builds with a JDK 17 and
  uploads the APK, so Gradle or Android SDK breakage fails CI even though
  the Dart tests pass. It uses shireitou's signing setup: a
  `key.properties` written from secrets, with the debug key as a
  fallback, so CI works before a release key exists.
- **The application id `dev.yft.yft_android_utils`.** It cannot change
  once the app is installed or published without making a new app.
