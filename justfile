# Linting, formatting, tests and running. See specs/linting.md.

prettier := "npx --yes prettier@3.3.3"

# Check formatting and linting (markdown, YAML and Dart).
lint:
    {{prettier}} --check "**/*.{md,yml,yaml}"
    dart format --output=none --set-exit-if-changed .
    cd app && flutter analyze --fatal-infos

# Format markdown, YAML and Dart files.
format:
    {{prettier}} --write "**/*.{md,yml,yaml}"
    dart format .

# Apply lint fixes, then format.
fix:
    cd app && dart fix --apply
    just format

# Run the unit and widget tests.
test:
    cd app && flutter test

# Build the release APK into app/build/dist/ (debug-signed unless the
# signing secrets are set; see docs/android.md). Needs a JDK 17.
apk:
    scripts/package-android

# Run the app on a device or emulator, e.g. `just run emulator-5554`.
run device="":
    cd app && flutter run {{ if device == "" { "" } else { "-d " + device } }}
