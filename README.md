# yft-android-utils

An Android app (Flutter/Dart) for personal utilities.

The home screen is a grid of sub-apps. So far there is one:

- **Markdown**: open or create a markdown file on the device and edit it,
  with autosave and a rendered preview. A 1x1 home screen widget opens a
  chosen file straight in the editor.

See [GAPS.md](GAPS.md) for work not yet done.

## Layout

- [`app/`](app/): the Flutter app (Android only).
- [`scripts/`](scripts/): build and maintenance scripts.
- [`docs/`](docs/): how the code is organized and built.
- [`specs/`](specs/): requirements.
- [`design/`](design/): design guidelines shared across projects.

The root `pubspec.yaml` is a [pub workspace](https://dart.dev/tools/pub/workspaces),
so one `flutter pub get` at the root resolves every package, and packages
can be split out of `app/` later without changing the tooling.

## Documentation

- [docs/architecture.md](docs/architecture.md): how the code is organized.
- [docs/android.md](docs/android.md): building, running and signing the
  APK.
- [specs/android-app.md](specs/android-app.md): app requirements and the
  sub-app launcher.
- [specs/markdown-editor.md](specs/markdown-editor.md): the markdown
  editor and its home screen widget.
- [specs/linting.md](specs/linting.md): linting, formatting and tests.
- [GAPS.md](GAPS.md): open questions and work not yet done.
- [DESIGN-DECISION-LOG.md](DESIGN-DECISION-LOG.md): design decisions, by date.

## Development

Requires Flutter 3.47.7 (Dart 3.13), Node.js (for prettier),
[just](https://github.com/casey/just), and a JDK 17 plus the Android SDK
to build or run the app.

```sh
flutter pub get          # resolves the whole workspace
just lint                # prettier, dart format, flutter analyze
just fix                 # dart fix, then format
just test                # unit and widget tests
just apk                 # build the release APK into app/build/dist/
just run                 # flutter run on the connected device or emulator
just run emulator-5554   # flutter run on a specific device
```
