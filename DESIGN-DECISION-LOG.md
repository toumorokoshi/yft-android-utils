# Design Decision Log

## 2026-11-27: Refresh Quick Open on resume and handle SAF EXTRA_LOADING

Adding new files to the saved root folder from another app or sync client
could leave Quick Open showing stale results: `QuickOpenPage` only
refreshed on mount, and `Documents.walkTree` did not wait for Storage Access
Framework providers that return `EXTRA_LOADING` cursors.

- **Refresh on `AppLifecycleState.resumed`.** `QuickOpenPage` now registers
  an `AppLifecycleListener` and refreshes the root folder when returning to
  the app, guarded by a `_refreshToken` generation counter so overlapping
  refreshes cannot clear the progress indicator early or apply stale
  results.
- **Wait for `DocumentsContract.EXTRA_LOADING`.** `Documents.walkTree` now
  observes `EXTRA_LOADING` cursors via `ContentObserver` (up to 5 seconds)
  and re-queries before reading children, and looks up column indices by
  name rather than assuming projection order.

## 2026-11-27: Collapsible right-hand navigation sidebar

Navigating between headings in longer markdown notes and switching to
recent files required backing out or scrolling manually. Main screens now
use `NavigationSidebarScaffold`, which adds a collapsible right-hand
navigation sidebar starting collapsed with a toggle button in the app bar.

- **`NavigationSidebarScaffold` shared wrapper.** Wrapping `LauncherPage`,
  `MarkdownFilesPage`, and `MarkdownEditorPage` in a shared `Scaffold`
  builder keeps the app bar toggle button and right-hand `AnimatedSize`
  panel consistent across screens while keeping screens full-bleed when
  collapsed (`SizedBox.shrink()`, mounting no extra `Scrollable` until
  expanded).
- **Pure `parseMarkdownHeadings` + shared slug deduplication.**
  `markdown_outline.dart` extracts ATX headings (`#`–`######`), skips
  fenced code blocks, and shares `deduplicateSlug` with
  `HeadingAnchorRegistry` in `markdown_links.dart` so outline taps in
  preview mode scroll to the exact rendered heading key.
- **Mode-aware heading navigation.** Tapping an outline heading scrolls the
  rendered preview when in preview mode, or moves the editor's selection
  cursor to the heading's character offset when in edit mode.

## 2026-11-23: Markdown formatting ribbon

Editing headings and lists on a mobile keyboard required typing `#` and `-`
manually. The editor now shows a horizontal formatting ribbon along the bottom
while editing (`H1`, `H2`, `H3`, bold, italic, inline code, bullet list,
checklist, blockquote, and link), hidden in preview mode.

- **Pure `TextEditingValue` transforms.** Formatting logic lives in
  `markdown_formatting.dart` as pure functions from `TextEditingValue` to
  `TextEditingValue`, so cursor and selection updates are unit tested without
  a widget tree. Heading actions toggle or replace existing ATX heading
  prefixes across the selected line(s).
- **`ExcludeFocus` on the ribbon.** Wrapping the ribbon in `ExcludeFocus`
  prevents tapping a formatting button from stealing focus from the
  `TextField` and dismissing the soft keyboard.
- **Bottom placement in the editor body.** Placing the ribbon below the
  expanded `TextField` inside `Scaffold.body` keeps it anchored right above
  the soft keyboard without crowding the app bar.

## 2026-11-22: Release 0.2.0

Bumped the app version from `0.1.0+1` to `0.2.0+2` and tagged `v0.2.0` to
publish a new minor release containing the saved root folder and fuzzy
quick open feature added since `v0.1.0`.

- **Minor version bump (`0.1.0` to `0.2.0`) with incremented build number (`+2`).**
  `v0.1.0` had build number `1`, and `.github/workflows/release.yml`
  requires a strictly higher `versionCode` on each tagged release.

## 2026-11-21: Preview anchor and external links

Tapping links in the markdown preview previously did nothing. Users need
to jump to headings within a document via `#anchor` links and open
external weblinks.

- **`MarkdownBody` inside `SingleChildScrollView` instead of `Markdown`.**
  `flutter_markdown_plus`'s `Markdown` widget uses a lazy `ListView`, so
  headings far down a document are not mounted yet when tapping a link at
  the top. Rendering `MarkdownBody` inside a `SingleChildScrollView` keeps
  every heading's `GlobalKey` mounted so `Scrollable.ensureVisible` can
  scroll to any heading immediately.
- **GitHub-style heading slugification.** `slugifyHeading` and
  `HeadingAnchorRegistry` normalize heading text to lowercase, strip
  punctuation, replace spaces with hyphens, and append `-1`, `-2`, … for
  duplicate headings. Links are classified into a sealed
  `MarkdownLinkTarget` (`AnchorLink`, `ExternalLink`, `UnsupportedLink`).
- **`LinkLauncher` interface in `AppServices`.** External links (`http`,
  `https`, `mailto`, `tel`) are launched via `url_launcher` with
  `LaunchMode.externalApplication` behind `LinkLauncher`, keeping widget
  tests free of platform channel mocks via `FakeLinkLauncher`.

## 2026-11-21: Re-resolve widget shortcuts via the Quick Open root folder

When another app or sync client updates a file atomically (writing a temp
file, deleting the original, and renaming), Android's Storage Access
Framework can assign a new document ID or revoke the old URI's persisted
permission, causing a home screen widget tap to fail silently.

- **Store `(treeUri, relativePath)` per widget when available.** When a
  widget is pinned or configured, `Documents.resolveTreePath` checks the
  file's own tree (if opened from Quick Open) or any persisted folder
  tree held by the app and records the tree URI and relative path in
  `MarkdownWidgets`.
- **Re-resolve on tap in `O(depth)` queries.** If the widget's stored
  URI is no longer persisted or `Documents.documentExists` returns
  false, `DocumentsChannel.launchDocument` walks only the relative
  path's folder segments under the persisted tree (`findInTreeByPath`),
  updates the widget to the new URI, and opens it.
- **Surface launch errors explicitly.** `DocumentsChannel` now catches
  exceptions on warm launches and reports failures via `initialDocument`
  or `openDocumentFailed`, which `App` displays as a `SnackBar` instead
  of silently falling back to the launcher.

## 2026-10-28: Root folder and quick open

Opening a file meant going through the system picker each time. Notes
usually live under one folder, so the app now saves a top-level folder
and finds files in it by typing part of the path.

- **A folder tree grant, not per-file grants.** The folder is picked with
  `ACTION_OPEN_DOCUMENT_TREE` and its grant persisted, so every file
  below it can be read and written without picking it again. This keeps
  the Storage Access Framework approach (no "all files access"
  permission). `Documents.isPersisted` also accepts document URIs under a
  granted tree, so widget taps and recents work for those files. The
  provider checks that a tree document is below its tree, so this does
  not widen access.
- **A native recursive listing.** `DocumentsContract` child queries walk
  the tree breadth first, on a separate thread from reads and writes so a
  large scan never holds up a save. Hidden entries are skipped and the
  listing is capped at 20,000 files.
- **Cache, then refresh.** `FolderIndex` keeps each listing for the
  session. Quick open shows it at once and lists again in the
  background, trading some battery for never showing stale results for
  long.
- **An fzf-style matcher written here.** pub's fuzzy packages do not fit:
  `fuzzy` is a Fuse.js (Bitap) port, and `fuzzywuzzy` and
  `string_similarity` score whole-string similarity. None of them return
  match positions or understand path segments. `fuzzyMatch` is a pure
  Smith-Waterman style alignment like fzf's v2 algorithm: subsequence
  matching with bonuses for path, word and camelCase starts, adjacency
  and the file name, gap penalties, smart case and space-separated terms.
  It returns positions for highlighting. It is about 150 lines and fully
  unit tested.
- **Quick open is generic, the button is not.** `quick_open/` returns a
  `Document` and knows nothing about sub-apps. `QuickOpenButton` lives
  with the markdown editor and opens the result there, above the
  launcher, as widget taps do. The launcher and editor take an `actions`
  list, so the button is added without them depending on it.
- **The folder is a `Document`.** A tree URI and display name have the
  same shape as a file, so the model, `fromMap` and storage code are
  reused rather than adding a parallel `Folder` type.

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
