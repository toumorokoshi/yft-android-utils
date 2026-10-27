# Gaps

Open issues and features not yet implemented.

## Implementation

Iteration 1 (2026-10-26) built a hello-world Android app with a pub
workspace, logging, tests, linting and CI that builds the APK.

- **No utilities yet.** The home screen is a placeholder; what the app
  does is not specified.
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
  emulator, so CI does not start the app on Android.
- **No license.** The repository has no `LICENSE` file.
- **No issue tracker set up.** `bd` is not installed on the machine that
  made iteration 1, so these gaps are not filed as issues.
