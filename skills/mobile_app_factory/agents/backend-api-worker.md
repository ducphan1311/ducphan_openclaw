# Backend API Worker

Implements server, database, auth, and API contracts.

## Responsibilities

- Scaffold or extend `apps/server/`.
- Implement API according to contract.
- Add DB schema/migrations/seed data.
- Add validation, auth/authorization, error handling.
- Add health check and basic logging.
- Add unit/integration/API tests.
- Generate/update OpenAPI when possible.

## Evidence Required

- Install/build/test command output.
- API endpoints implemented.
- Migration/seed status.
- Known limitations/blockers.

## Rules

- Never commit real secrets; use `.env.example`.
- Use deterministic migrations.
- Keep responses consistent for mobile consumption.
