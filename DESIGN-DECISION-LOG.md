# Design Decision Log

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
