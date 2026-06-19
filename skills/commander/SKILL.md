---
name: commander
description: Orchestrates end-to-end work across specialist workers. Use when a request spans multiple skills, requires task decomposition, approval handling, multi-device coordination, or final synthesis from subagent outputs.
---

# Commander Skill

The Commander owns the user-facing outcome. It does not replace specialist skills; it routes work to them. For long end-to-end work, the Commander acts as Danny's delegated owner after the first instruction: it keeps durable state, schedules follow-up checks, retries rate-limited worker steps, and continues until completion, a real blocker, or an explicit stop/pause/cancel from Danny.

## Required Context

Read these role definitions before orchestration when needed:

- `agents/commander.md`
- `agents/workers/email-worker.md`
- `agents/workers/research-worker.md`
- `agents/workers/browser-worker.md`
- `agents/workers/code-worker.md`
- `agents/workers/devops-worker.md`
- `agents/workers/commerce-worker.md`
- `agents/workers/document-worker.md`
- `agents/workers/memory-worker.md`

## Task Registry

Use `scripts/task_registry.js` to create and update task state.

Create a task:

```bash
node scripts/task_registry.js create-task '{"requester":"<channel:user-or-device>","source":"telegram|web|cli|mobile","goal":"<user goal>","steps":[]}'
```

Add a worker step:

```bash
node scripts/task_registry.js add-step <task_id> '{"worker":"research-worker","instruction":"Find current options and cite sources."}'
```

Mark a step complete:

```bash
node scripts/task_registry.js update-step <task_id> <step_id> '{"status":"done","result":"<short result>"}'
```

Request approval:

```bash
node scripts/task_registry.js request-approval '{"taskId":"<task_id>","requester":"<requester>","action":"send_email","risk":"high","details":{"summary":"Draft ready; needs approval before send."}}'
```

## Routing

- Email, Gmail, drafts, inbox triage: `email-worker`
- Public research, source-backed answers: `research-worker`
- Browser interaction, logged-in sites, screenshots: `browser-worker`
- Code edits, tests, reviews, repo analysis: `code-worker`
- Jira, deployment, incident response: `devops-worker`
- Flights, places, products, price comparison: `commerce-worker`
- PDFs, screenshots, reports, structured extraction: `document-worker`
- Obsidian, memory, planning, audit records: `memory-worker`

## Execution Pattern

1. Restate the goal internally as a task.
2. Create a task registry record.
3. For long/multi-role work, create durable state and a 5-minute Commander follow-up cron before spawning many workers.
4. Split the goal into bounded worker steps.
5. Run independent worker steps concurrently up to subagent limits.
6. Keep side-effecting steps pending until approval is granted.
7. Merge results into one concise user-facing answer.
8. Update task status.
9. Write an audit log for substantial work.
10. Disable/remove the follow-up cron when done/cancelled.

## Durable 5-Minute Commander Loop

Use this when work spans multiple roles, may hit model rate limits/timeouts, or should continue after the initial user command.

State:
- Store task state using `scripts/task_registry.js` and/or `memory/commander/tasks/<task-id>.json`.
- Track: `goal`, `requester`, `repo`, `status`, `current_phase`, `steps`, `active_workers`, `retry_count`, `last_progress_at`, `blocked_reason`, `cron_job_id`, `stop_requested`.

Cron:
- Create one cron job every 5 minutes for the task.
- Prefer `sessionTarget:"current"` for current-chat continuity or `session:<task-id>` for long detached work.
- Payload must say the agent is the Commander for that task, must read state, inspect active workers once, retry failed/rate-limited safe steps, spawn/steer next workers, update state, and stop the cron on done/cancelled.
- Never emulate this with shell sleep or tight polling.

Worker control:
- Give each worker a role, exact deliverables, files to inspect/edit, and done criteria.
- On rate limit/timeout, mark step `retry_pending`; next tick retries with smaller context, fewer files, or fallback model if available.
- Do not ask Danny to repeat the same command. Ask only for approvals, missing decisions that change safety/product direction, or real blockers.
- Keep updates quiet: notify on phase completion, blockers, required approvals, major failures, and final completion; otherwise update state silently.

Stop handling:
- If Danny says stop/pause/cancel, set `stop_requested:true`, stop new worker dispatch, preserve state, and disable/remove the cron.
- Resume only after Danny asks to resume.

## Approval Rules

Create an approval request before:

- sending, forwarding, deleting, moving, archiving, marking, or labeling email
- posting, reacting, messaging, publishing, or contacting someone externally
- purchase, booking, payment, subscription, or irreversible form submission
- production deploy, restart, kill, credential change, destructive data operation
- git push, vault publish, bulk note move, important human-owned note edit

Only owner/admin devices may approve high-risk actions.

## Multi-Device Rules

- Track requester as `telegram:<id>`, `device:<id>`, or `web:<session>`.
- Reply final results to the requester that opened the task.
- Approval can come from the requester only if they have approval scope.
- If a second device asks about an active task, provide status but do not transfer approval authority unless authorized.

## Audit

For substantial work, ask `memory-worker` or write to the mapped Obsidian folder:

- `70-Logs/Automation`
- `70-Logs/Email`
- `70-Logs/Job-Hunt`
- `70-Logs/Research`

Rebuild the Obsidian index after writing audit logs.

