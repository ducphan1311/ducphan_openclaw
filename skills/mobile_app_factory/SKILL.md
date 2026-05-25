---
name: mobile_app_factory
description: Build mobile apps end-to-end with one commander and eight specialist workers: product/PRD, UX/UI, architecture, mobile client, backend/API, QA/testing, DevOps/release, and technical documentation/security. Use when the user asks to create, design, document, implement, test, or deploy a full mobile app.
---

# Mobile App Factory

Use this skill when Danny asks for an end-to-end mobile app: idea → requirements → UX/UI → architecture → client/server implementation → tests → deployment → handover docs.

## Team Model

One commander coordinates eight workers. Load only the worker file needed for the current phase:

1. `agents/mobile-app-commander.md` — owns plan, gates, handoffs, final synthesis.
2. `agents/product-ba-worker.md` — PRD, scope, user stories, acceptance criteria.
3. `agents/ux-ui-design-worker.md` — flows, wireframes, screen specs, design system.
4. `agents/solution-architect-worker.md` — stack, architecture, API contract, DB/security design.
5. `agents/mobile-client-worker.md` — Flutter/React Native mobile implementation.
6. `agents/backend-api-worker.md` — server, database, auth, API, integration tests.
7. `agents/qa-test-worker.md` — test plan, manual QA, automation, bug reports.
8. `agents/devops-release-worker.md` — CI/CD, environments, backend deploy, mobile build/release.
9. `agents/technical-writer-security-worker.md` — README, runbooks, handover, security review.

## Default Workflow

1. **Intake**: clarify app purpose, target users, platform, preferred stack, backend needs, auth, deployment target, deadline.
2. **Product gate**: product worker creates PRD/user stories/acceptance criteria. Ask Danny for approval before implementation.
3. **Design gate**: UX worker creates user flow, screen specs, design system. Ask approval if UI direction is ambiguous.
4. **Architecture gate**: architect creates app architecture, API contract, DB schema, security baseline, deployment plan.
5. **Build**: mobile and backend workers implement in parallel when contracts are stable.
6. **Integrate**: resolve API/client mismatches, env config, seed data.
7. **Test**: QA creates/runs unit, API, integration, widget/E2E/manual checks.
8. **Release**: DevOps builds artifacts and deploys only after explicit approval for production/external changes.
9. **Handover**: writer/security worker finalizes README, setup, API, deployment, test report, release notes, and security checklist.

## Approval Gates

Ask before:

- production deploy, cloud resource creation, paid services, app store submission
- git push to remote, release tagging, sending external messages
- destructive database/file operations
- changing secrets or exposing credentials

Safe without approval: local files, local tests, local builds, docs, mockups, non-production scaffolding.

## Standard Deliverables

Prefer this structure unless the user/repo says otherwise:

```text
docs/
  PRD.md
  user-stories.md
  acceptance-criteria.md
  design-system.md
  screen-specs.md
  architecture.md
  api-contract.md
  database-schema.md
  test-plan.md
  manual-test-report.md
  deployment-guide.md
  security-checklist.md
apps/
  mobile/
  server/
```

Use templates from `templates/` when creating new docs.

## Quality Bar

Do not call the app “done” unless you can cite evidence:

- requirements covered by acceptance criteria
- design/spec docs exist
- client and server compile/build or blocker is named
- tests/manual checks executed or blocker is named
- deployment/build artifact status is clear
- setup/handover docs exist
