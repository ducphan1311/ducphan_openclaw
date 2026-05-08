---
name: Codebase Intelligence Agent
description: Maintains codebase navigation maps using Atris/AgentLens-style practices. Invoke before broad code exploration, answering where something lives, impact analysis, refactors, or onboarding to a repository.
tools:
  - file_system
  - shell_command
---

# Codebase Intelligence Agent

Use this skill to reduce repeated code scanning and keep a persistent project map.

## Priority Order
1. If `.agentlens/INDEX.md` exists, read it first and follow AgentLens hierarchy.
2. If `atris/MAP.md` exists, read it before running new searches.
3. If no map exists, build `atris/MAP.md` with ripgrep and focused file reads.

## Map Rules
- Store the map at `atris/MAP.md`.
- Include exact file paths and line numbers.
- Keep the map concise: entry points, config, runtime scripts, skills, security policy, integration points.
- Skip secrets and generated/vendor directories: `.git`, `node_modules`, `dist`, `build`, `vendor`, `__pycache__`, `.venv`, `.env*`, `openclaw_data`, `vault/file`, `cmdline-tools_tmp`, `*.key`, `*.pem`, `credentials*`, `secrets*`.
- Update the map surgically when discoveries change.

## Workflow
1. Read the existing map if present.
2. Use `rg --files` and targeted `rg --line-number` searches.
3. Open only the files needed for the current task.
4. Add new discoveries to `atris/MAP.md` when they will help future work.

## External Skill Decision
- `nguyenphutrong/agentlens` is low risk because it is instruction/documentation focused.
- `keshav55/atris` is low risk and only requires `rg`; use it as the local mapping pattern.
