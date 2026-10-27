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

## Building

`just apk` runs [`scripts/package-android`](../scripts/package-android),
which builds the release APK and copies it to
`app/build/dist/yft-android-utils-<version>.apk`. CI runs the same script
and uploads the APK as the `android-apk` artifact of each run.

The version comes from `version:` in `app/pubspec.yaml`: the part before
`+` is the `versionName` and the number after it the `versionCode`.

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
