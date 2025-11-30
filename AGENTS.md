# Repository Guidelines

## Project Structure & Module Organization
- Flutter app code lives in `lib/`; entrypoint is `lib/main.dart` with feature modules such as `entry_*`, `menu_*`, and `subscription_*`.
- Tests sit in `test/` (`*_test.dart`), with shared fixtures alongside the files they cover.
- Assets are under `assets/` (icons, schemas); Firebase configs live in `firebase.json`, `firestore.rules`, and `firestore.indexes.json`.
- Generated API clients are in `apis/out/dart/` (do not hand-edit); regenerate via `scripts/generate_client.sh`.
- The Python provider service lives in `provider/` (packaged via `setup.py`); platform shells are in `android`, `ios`, `macos`, `linux`, `windows`, and `web`.

## Build, Test, and Development Commands
- Install deps: `flutter pub get` (root), `pip install -e . -r requirements.txt` inside `provider/` if working on the service.
- Run app locally: `flutter run -d macos` (pick your device via `-d`).
- Static checks: `flutter analyze` plus `dart format lib test` before sending changes.
- Unit tests: `flutter test` (add `--coverage` if you need a report).
- Web bundle: `make web-build` (respects `BASE_HREF`); create Docker image with `make web-image` and push via `make web-push`.
- Provider container: `make provider-image` then `make provider-push`; `make release` builds and deploys both stacks.

## Coding Style & Naming Conventions
- Follow `flutter_lints` (`analysis_options.yaml`); keep Dart indentation at two spaces and prefer expression-body where clear.
- File names use `snake_case.dart`; classes/mixins in `PascalCase`, methods/fields in `lowerCamelCase`, constants in `SCREAMING_SNAKE_CASE`.
- Keep widgets small and composable; push shared utilities to `lib/utils.dart` or feature-specific helpers nearby.

## Testing Guidelines
- Place new tests in `test/` mirroring the `lib/` path (e.g., `lib/apple_books.dart` -> `test/apple_books_test.dart`).
- Use `flutter_test` for widget/unit coverage; mock external services (Firebase, HTTP) rather than hitting live endpoints.
- When adding a regression fix, include a focused test that fails before the change and passes after.

## Commit & Pull Request Guidelines
- Follow the existing Conventional Commit style (`feat:`, `fix:`, `chore:`, etc.) seen in `git log`.
- Keep commits scoped and readable; include migration notes in the message body when altering data models or schemas.
- PRs should list the change summary, test evidence (`flutter test`, `flutter analyze`, any `make` targets), and UI screenshots for visual updates.
- Link related issues or tickets; call out breaking changes or manual steps (e.g., re-running `scripts/generate_client.sh` or rotating Firebase config).

## Security & Configuration Tips
- Do not commit secrets; Firebase keys, API tokens, and local `.env` files should stay out of VCS.
- Treat `firebase_options.dart` and generated OpenAPI clients as derived artifacts—regenerate instead of manual edits.
- For Dockerized builds, verify `BASE_HREF`, registry, and namespace values before running `make release` to avoid publishing to the wrong target.
