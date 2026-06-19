---
name: mobile_app_factory
description: Build mobile apps end-to-end with one commander and eight specialist workers: product/PRD, UX/UI, architecture, mobile client, backend/API, QA/testing, DevOps/release, and technical documentation/security. Use when the user asks to create, design, document, implement, test, or deploy a full mobile app.
---

# Mobile App Factory

Use this skill when Danny asks for an end-to-end mobile app: idea → requirements → UX/UI → architecture → client/server implementation → tests → deployment → handover docs.

## Team Model

One commander coordinates eight workers. The commander is mandatory for every end-to-end task and acts as Danny's proxy/owner after the first instruction: it owns plan, state, worker routing, retry after model/rate-limit failures, approval gates, and final synthesis. Load only the worker file needed for the current phase:

1. `agents/mobile-app-commander.md` — owns plan, durable task state, cron follow-up, gates, handoffs, final synthesis.
2. `agents/product-ba-worker.md` — PRD, scope, user stories, acceptance criteria.
3. `agents/ux-ui-design-worker.md` — flows, wireframes, screen specs, design system.
4. `agents/solution-architect-worker.md` — stack, architecture, API contract, DB/security design.
5. `agents/mobile-client-worker.md` — Flutter/React Native mobile implementation.
6. `agents/backend-api-worker.md` — server, database, auth, API, integration tests.
7. `agents/qa-test-worker.md` — test plan, manual QA, automation, bug reports.
8. `agents/devops-release-worker.md` — CI/CD, environments, backend deploy, mobile build/release.
9. `agents/technical-writer-security-worker.md` — README, runbooks, handover, security review.

## Default Workflow

0. **Commander bootstrap**: create a durable task record and start/confirm a 5-minute follow-up cron for this task. After Danny gives the initial goal, do not require repeated prompting; the commander keeps checking and delegating until `done`, `blocked_needs_user`, or Danny says stop/pause/cancel.
1. **Intake**: clarify app purpose, target users, platform, preferred stack, backend needs, auth, deployment target, deadline. If information is missing but safe assumptions exist, proceed with assumptions and list them in task state.
2. **Product gate**: product worker creates PRD/user stories/acceptance criteria. Ask Danny for approval before implementation only when scope/risk is ambiguous; otherwise continue with clearly stated assumptions.
3. **Design gate**: UX worker creates user flow, screen specs, design system. Ask approval if UI direction is ambiguous.
4. **Architecture gate**: architect creates app architecture, API contract, DB schema, security baseline, deployment plan.
5. **Build**: mobile and backend workers implement in parallel when contracts are stable.
6. **Integrate**: resolve API/client mismatches, env config, seed data.
7. **Test**: QA creates/runs unit, API, integration, widget/E2E/manual checks.
8. **Release**: DevOps builds artifacts and deploys only after explicit approval for production/external changes.
9. **Handover**: writer/security worker finalizes README, setup, API, deployment, test report, release notes, and security checklist.
10. **Stop cron**: when complete/cancelled, disable/remove the task's 5-minute follow-up cron and send final status.

## Durable Commander Loop

For long E2E work, rate limits/timeouts are expected. The commander must be durable:

- Store task state under `memory/mobile_app_factory/tasks/<task-id>.json` or the Commander task registry if available.
- State must include: `goal`, `repo`, `status`, `current_phase`, `worker_steps`, `open_questions`, `blocked_reason`, `last_progress_at`, `cron_job_id`, and `stop_requested`.
- Create a cron job every 5 minutes with `sessionTarget:"current"` or a persistent `session:<task-id>` and an `agentTurn` prompt like: “You are the mobile-app-factory commander for task <task-id>. Read state, inspect child sessions/processes, retry failed/rate-limited steps, steer/spawn workers, update state, and continue until done/blocked/stop.”
- On each tick, inspect active subagents/sessions once, not in a tight loop. Use push completion when possible.
- If a worker was rate-limited/timed out/skipped, mark the step `retry_pending`, wait for the next tick, and retry with smaller context or a cheaper/fallback model if available.
- Spawn/steer specialist workers with bounded instructions and concrete deliverables. Do not leave them with vague “continue” prompts.
- The commander may make safe local file edits/tests/builds without asking. It must pause at approval gates below.
- If Danny says stop/pause/cancel, set `stop_requested:true`, stop spawning work, and disable/remove the cron job.
- Do not send noisy “still working” updates every 5 minutes. Notify only on phase completion, blockers needing Danny, important failures, or final completion.

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

## Recommended Commander Cron Payload

When starting an E2E mobile app task, use a cron similar to:

```json
{
  "name": "mobile-app-factory commander: <short task name>",
  "schedule": { "kind": "every", "everyMs": 300000 },
  "sessionTarget": "current",
  "payload": {
    "kind": "agentTurn",
    "message": "You are the durable commander for mobile_app_factory task <task-id>. Read memory/mobile_app_factory/tasks/<task-id>.json, check subagents/sessions once, update worker statuses, retry rate-limited/failed safe steps, spawn or steer the next specialist worker, run safe local tests/builds if needed, update state, and only notify Danny for blockers/approvals/phase completion/final done. Stop and remove/disable this cron if stop_requested or done.",
    "timeoutSeconds": 300
  },
  "delivery": { "mode": "announce", "bestEffort": true }
}
```

Prefer a persistent session target for very long work (`session:mobile-app-factory-<task-id>`) when the commander needs continuity across many ticks.

## Quality Bar

Do not call the app “done” unless you can cite evidence:

- requirements covered by acceptance criteria
- design/spec docs exist
- client and server compile/build or blocker is named
- tests/manual checks executed or blocker is named
- deployment/build artifact status is clear
- setup/handover docs exist
