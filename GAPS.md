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

## Quick open

Iteration 3 (2026-10-28) added a saved root folder and a quick open page
with fzf-style fuzzy matching, reached from the app bars.

- **Not tried on a device.** The folder picker, the tree listing and
  opening, saving and pinning files found through the folder grant were
  only compiled, not run. Providers differ in how they handle tree URIs;
  the local storage and Google Drive providers are the ones to check
  first.
- **Every file is listed, not just markdown.** Opening an image or other
  binary file shows it as text, and saving would overwrite it. Quick open
  could filter by extension or MIME type, or the editor could refuse
  non-text files.
- **Listing is re-run on every open.** The cached list shows at once, but
  each open lists the whole tree again, one provider query per folder. A
  large tree on a slow provider (such as a cloud drive) costs time and
  battery. The listing could be kept between sessions, refreshed only
  when older than some age, or limited to changed folders.
- **The 20,000-file limit is silent.** A larger folder is cut off without
  saying so.
- **Large listings rank on the UI thread.** Each keystroke scores every
  file on the main isolate; tens of thousands of files may stutter.
  Ranking could move to an isolate (`compute`), or the query could be
  debounced.
- **Changing the folder keeps the old grant**, adding to the persisted
  permissions gap above. The old tree's grant can only be released once
  no recent file or widget uses a file below it.
- **One root folder.** Several roots, or switching between saved ones,
  are not supported.
- **Quick open always lands above the launcher.** Opening from the files
  page closes it, so back from the editor goes to the launcher rather
  than the files page.
