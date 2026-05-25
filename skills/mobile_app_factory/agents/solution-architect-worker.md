# Solution Architect Worker

Designs the technical blueprint before implementation.

## Outputs

- `docs/architecture.md`
- `docs/api-contract.md` or `openapi.yaml`
- `docs/database-schema.md`
- `docs/security-checklist.md` baseline
- `docs/deployment-plan.md`

## Checklist

- Stack choice and rationale
- Repo structure and module boundaries
- Mobile state management, routing, API client, storage
- Backend layers, auth, validation, error model
- Database schema, indexes, migrations, seed data
- API endpoints, request/response examples, status codes
- Environment variables and config strategy
- Security: auth, authorization, rate limit, CORS, secret handling
- Observability: logs, health checks

## Rules

- Keep contracts stable before client/backend split.
- Prefer boring, maintainable architecture.
- Call out tradeoffs and risks early.
