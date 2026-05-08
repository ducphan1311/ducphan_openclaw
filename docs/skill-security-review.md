# Skill Security Review

Review date: 2026-05-08

This repo uses local workspace skills as controlled wrappers around useful community skill patterns. Third-party skills can still be installed later, but browser, email, shopping, travel, and memory capabilities should stay behind human approval and Vault/env secrets.

## Decisions

| Need | Candidate | Observed status | Decision |
| --- | --- | --- | --- |
| UI testing and browser automation | `vmercel/playwright-skill` | clawskills.sh showed VirusTotal Suspicious and OpenClaw Suspicious | Do not install automatically. Use local `skills/browser_automation` wrapper; consider `spiceman161/playwright-mcp` or `mahone-bot/playwright-npx` after source review. |
| Gmail summary | `r39132/gmail-agent` | Benign signals in searched page | Approved candidate. Use local `skills/email_assistant` first. |
| Gmail SMTP/IMAP | `junkaixue/gmail-tool` | Benign signals in searched page | Approved candidate if app-password mode is acceptable. Store password only in Vault/env. |
| Gmail cleanup | `r39132/gmail-skill` | Suspicious signals and destructive cleanup/background behavior | Avoid for now. |
| Codebase navigation | `nguyenphutrong/agentlens` | Instruction-focused, low-risk pattern | Approved pattern. Use `.agentlens` when present. |
| Codebase map | `keshav55/atris` | ClawHub page showed benign, requires `rg` | Approved pattern. Local wrapper writes `atris/MAP.md`. |
| Amazon search | `phheng/amazon-product-search-api-skill` | Mixed: one page suspicious, ClawHub-style pages benign; requires BrowserAct | Conditional. Only with `BROWSERACT_API_KEY`, billing awareness, and no checkout automation. |
| Amazon ASIN lookup | `phheng/amazon-asin-lookup-api-skill` | Benign scan details in search result | Conditional. Only with BrowserAct and source-review gate. |
| Price monitor | `g4dr/ecommerce-price-monitor` | VirusTotal benign, OpenClaw suspicious; requires Apify | Conditional/caution. Use read-only comparisons only. |
| Shopping automation | `amazon-shopper` | Can buy/return items | Avoid. |
| Flights | `kirorab/amadeus-flights` | Low installs, API-key dependency | Conditional. Use read-only fare search only. |
| Memory | `dobrinalexandru/agent-brain` | Benign signals; local SQLite; optional SuperMemory sync | Conditional. Keep `AGENT_BRAIN_SUPERMEMORY_SYNC=off`. |
| Personal planning/English | Custom local skill | No external code | Approved. |

## Mandatory Controls

- Secrets must be stored in Vault or runtime env, not committed files.
- Outbound email, chat messages, purchases, bookings, account changes, and destructive deletes require same-turn user approval.
- Browser automation must not bypass CAPTCHA, paywalls, login restrictions, or rate limits.
- Memory must not store secrets, payment data, private IDs, health/legal details, or credentials.
- Shopping and flight results are advisory until re-checked at the provider checkout page.

## Suggested Install Order

1. Use local wrapper skills now: browser, email, codebase, shopping, flights, memory, English/planning.
2. Add provider secrets to Vault only when needed.
3. Install third-party packages one at a time after reviewing current ClawHub source and security scan.
4. Run any setup scripts in sandbox first, then restart OpenClaw so workspace skills reload.
