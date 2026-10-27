# Gaps

Open issues and features not yet implemented.

## Implementation

Iteration 1 (2026-10-26) built a hello-world Android app with a pub
workspace, logging, tests, linting and CI that builds the APK.

Iteration 2 (2026-10-26) replaced the home screen with a launcher grid of
sub-apps and added the first one, a markdown editor with a 1x1 home
screen widget per file.

- **No release signing key.** CI signs the APK with the debug key until
  the `ANDROID_KEYSTORE*` secrets are set (see
  [docs/android.md](docs/android.md)). A script to create the keystore
  and upload the secrets, like shireitou's `scripts/android-keystore`, is
  not written.
- **No release workflow.** There is no tagged release that publishes the
  APK (shireitou's `release.yml` is the model); CI only uploads it as a
  run artifact.
- **No app icon.** The app uses Flutter's default launcher icon.
- **No device tests.** There are no `integration_test` tests run on an
  emulator, so CI does not start the app on Android. The Kotlin code (the
  documents channel and the widget) is only compiled by CI, not tested;
  the widget's placement, configuration and tap flows were not tried on a
  device.
- **No license.** The repository has no `LICENSE` file.

## Markdown editor

- **External changes are not detected.** If another app (or a sync
  client) changes the file while it is open, the editor keeps its text
  and the next save overwrites the other change. It could re-read the
  file when the app resumes and compare modification times.
- **No undo, search or formatting toolbar.** The editor is a plain text
  field.
- **Preview links do nothing.** Tapping a link in the preview does not
  open it (needs `url_launcher`).
- **Large files.** The whole file is read and written on each save;
  multi-megabyte files will be slow.
- **No "add widget" button.** A widget can only be added from the home
  screen's widget picker. `AppWidgetManager.requestPinAppWidget` could
  add one for the open file from inside the editor.
- **Widget names go stale.** The widget shows the file name from when it
  was placed; a renamed file keeps the old label until reconfigured.
- **Some providers may not support truncating writes.** Saves open the
  file with mode `"wt"`; a provider that rejects it shows a save error.
- **Recent files are not pruned** when their file is deleted or the
  permission is lost; opening one shows the load error.
