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
- **Releases are debug-signed until the key exists.** The release
  workflow publishes `v*` tags, but without the `ANDROID_KEYSTORE*`
  secrets each release is a debug-signed prerelease. Once the key is
  set, the first signed release cannot update an install of an earlier
  debug-signed one; it has to be uninstalled first.
- **Release workflow not yet run.** No `v*` tag has been pushed, so the
  publish job has not run on GitHub.
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
- **Pinning is untested across home screens.** Some home screens may run
  the configure activity for a widget pinned from the app. It skips the
  picker when the widget was pinned in the last minute, so a reconfigure
  started within that minute also closes without asking for a file.
- **Persisted permissions are never released.** Removing a widget or a
  recent file keeps the app's grant. Android caps persisted grants per app
  (128 before Android 11, 512 since), so a long-lived install could hit
  the cap. Grants no widget or recent file uses could be released with
  `releasePersistableUriPermission`.
- **Widget names go stale.** The widget shows the file name from when it
  was placed; a renamed file keeps the old label until reconfigured.
- **Some providers may not support truncating writes.** Saves open the
  file with mode `"wt"`; a provider that rejects it shows a save error.
- **Recent files are not pruned** when their file is deleted or the
  permission is lost; opening one shows the load error.
