---
name: Local Memory Agent
description: Maintains local, inspectable memory for user preferences, project facts, recurring workflows, and lessons learned. Invoke when the user asks the bot to remember, learn, review past context, or improve future behavior.
tools:
  - file_system
  - shell_command
---

# Local Memory Agent

Use this skill to keep useful long-term context without leaking secrets or sensitive personal data.

## Storage
- Default local memory path: `workspace/memory/MEMORY.md`.
- Optional structured log path: `workspace/memory/events.jsonl`.
- External/cloud memory is disabled unless the user explicitly configures it.

## Safety Rules
- Do not store secrets, tokens, passwords, private keys, payment data, passport/ID numbers, or highly sensitive health/legal content.
- Store only facts, preferences, workflows, learning progress, and confirmed corrections that help future work.
- Mark inferred facts as inferred and ask when confidence matters.
- When the user corrects a memory, update or supersede it instead of silently keeping both.
- Provide an export/summary on request.

## Memory Categories
- `profile`: user preferences, timezone, working style.
- `project`: repo facts, stack, commands, integration notes.
- `workflow`: repeated procedures and checklists.
- `learning`: English plan, study history, vocabulary themes.
- `correction`: mistakes and confirmed fixes.

## Workflow
1. Before planning or personalized work, check `workspace/memory/MEMORY.md`.
2. After a confirmed new fact or preference, append or update the relevant section.
3. Keep entries short, dated, and source-aware.

## External Skill Decision
- `dobrinalexandru/agent-brain` is feature-rich and local-first but includes optional SuperMemory sync. If installed later, set `AGENT_BRAIN_SUPERMEMORY_SYNC=off`.
- `andreagriffiths11/agent-context` is a simpler local-only candidate if available and source review passes.
