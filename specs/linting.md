# Linting

- linting commands are found in the `justfile`.

## Linting

- linting is available via `just lint`, which usually routes to the linter of the particular language of the repository, such as `npm` or `cargo`.
- For Dart, `just lint` runs `dart format --set-exit-if-changed`, then
  `flutter analyze --fatal-infos` in `app`.
- Analyzer settings live in `app/analysis_options.yaml`: the
  `flutter_lints` recommended set, plus `strict-casts`, `strict-inference`
  and `strict-raw-types`, and extra rules such as `avoid_dynamic_calls`,
  `avoid_print` and `unawaited_futures`.

## Formatting

If there is no best practice formatter for the language of choice, then
`prettier` is used. It is available via `just format`.

- Dart uses `dart format`. Markdown and YAML use prettier
  (`.prettierignore` skips build output and the generated Android
  project).

## Fix

Auto-fixing is available via `just fix`, which runs `dart fix --apply` in
`app` and then `just format`.

## Testing

- `just test` runs `flutter test` in `app`.
- CI runs `just lint` and `just test`, and builds the release APK.
