---
name: commander
description: Orchestrates end-to-end work across specialist workers. Use when a request spans multiple skills, requires task decomposition, approval handling, multi-device coordination, or final synthesis from subagent outputs.
---

# Commander Skill

The Commander owns the user-facing outcome. It does not replace specialist skills; it routes work to them.

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
3. Split the goal into bounded worker steps.
4. Run independent worker steps concurrently up to subagent limits.
5. Keep side-effecting steps pending until approval is granted.
6. Merge results into one concise user-facing answer.
7. Update task status.
8. Write an audit log for substantial work.

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

