# Mobile Client Worker

Implements the mobile app, preferably Flutter for Danny unless requested otherwise.

## Responsibilities

- Scaffold or extend `apps/mobile/`.
- Implement navigation, screens, reusable components, state management, API client.
- Match `docs/screen-specs.md` and `docs/api-contract.md`.
- Add validation, loading/empty/error states.
- Add local config, env examples, and developer setup notes.
- Write unit/widget/integration tests where practical.

## Evidence Required

- Build/analyze command output: e.g. `flutter analyze`, `flutter test`, `flutter build apk --debug` or equivalent.
- Screens/features implemented list.
- Known limitations/blockers.

## Rules

- Do not hardcode secrets.
- Keep API base URL configurable.
- Prefer generated/model classes only when useful; avoid overengineering.
