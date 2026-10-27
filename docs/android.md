# Android

## Requirements

- Flutter 3.47.7.
- A JDK 17 (for example `brew install --cask temurin@17`).
- The Android SDK, from Android Studio or the command-line tools. Run
  `flutter doctor --android-licenses` once to accept the licenses.

## Running

Start an emulator or plug in a device with USB debugging, then:

```sh
flutter devices          # lists the device ids
just run                 # the only connected device
just run emulator-5554   # a specific device
```

## Home screen widget

The app has a 1x1 "Markdown file" widget. To add one, long-press the home
screen, choose **Widgets**, find **yft android utils** and drag **Markdown
file** onto the screen. The system file picker opens; the file you choose
is the one the widget opens. Place one widget per file.

Or open the file in the editor and tap **Add widget to home screen** in
the app bar. The home screen asks where to place the widget, which then
opens that file with no picker. This needs Android 8.0 or later and a
home screen that lets apps add widgets (most do, including the Pixel
launcher).

The widget only stores the file's URI. Access comes from a persisted
Storage Access Framework permission: picking a file grants the app access
to it, and the app calls `takePersistableUriPermission` so Android keeps
that grant across restarts, reboots and updates. The grant belongs to the
app, so every widget, and the recent list, for the same file share it. It
ends when the app is uninstalled or its data is cleared, or when the user
or the file's provider revokes it. If the permission is
revoked, a tap opens the app on the launcher; if the file was moved or
deleted, the editor says it could not open the file.

## Building

`just apk` runs [`scripts/package-android`](../scripts/package-android),
which builds the release APK and copies it to
`app/build/dist/yft-android-utils-<version>.apk`. CI runs the same script
and uploads the APK as the `android-apk` artifact of each run.

The version comes from `version:` in `app/pubspec.yaml`: the part before
`+` is the `versionName` and the number after it the `versionCode`.

## Releasing

[`.github/workflows/release.yml`](../.github/workflows/release.yml)
publishes a GitHub Release with the APK and a `SHA256SUMS` file when a
`v*` tag is pushed:

1. Set `version:` in `app/pubspec.yaml`, for example `0.2.0+2`. Raise the
   build number (after `+`) on every release: Android refuses an update
   with a lower `versionCode`.
2. Commit and push to `main`.
3. Tag and push: `git tag v0.2.0 && git push origin v0.2.0`.

The workflow fails if the tag does not match the pubspec version (`v` plus
the part before `+`), or if the build number is not above the previous
tag's. Without the signing secrets the APK is debug-signed and the
release is marked as a prerelease. Running the workflow by hand
(**Actions > Release > Run workflow**) builds the APK as a run artifact
without publishing.

## Signing

Without signing secrets the APK is signed with the debug key: it installs
for testing, but cannot update, or be updated by, a release-signed build.

With these environment variables set (in CI, as repository secrets),
`scripts/package-android` writes `app/android/key.properties`, which
`app/android/app/build.gradle.kts` reads to sign the release build:

| Variable                    | Value                                     |
| --------------------------- | ----------------------------------------- |
| `ANDROID_KEYSTORE`          | base64 of the release keystore (`.jks`)   |
| `ANDROID_KEYSTORE_PASSWORD` | the keystore's password                   |
| `ANDROID_KEY_ALIAS`         | the key's alias                           |
| `ANDROID_KEY_PASSWORD`      | the key's password (default: the store's) |

`key.properties` and keystores are git-ignored, and the script deletes
`key.properties` when it exits.
