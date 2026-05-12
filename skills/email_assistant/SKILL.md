---
name: Safe Email Assistant
description: Handles Gmail-style email reading, search, summarization, draft writing, and controlled sending. For Gmail/check mail/summarize inbox, use local himalaya CLI first and do not use browser Gmail unless himalaya fails or the user explicitly asks for browser.
metadata:
  {
    "openclaw":
      {
        "emoji": "📧",
        "requires": { "env": ["GMAIL_USER", "GMAIL_APP_PASSWORD"] },
        "primaryEnv": "GMAIL_USER",
      },
  }
tools:
  - api_request
  - web_fetch
  - file_system
  - shell_command
---

# Safe Email Assistant

Use this skill for email triage, summaries, drafts, and explicit outbound messages.

## Supported Backends
- Primary local backend: `himalaya` CLI on macOS native.
- Gmail API or Google Workspace connector when OAuth is available.
- Local `himalaya` CLI when available; use it for native macOS Gmail IMAP/SMTP before falling back to browser Gmail.
- Gmail SMTP/IMAP with `GMAIL_USER` and `GMAIL_APP_PASSWORD` when the user chooses app-password mode.
- Local summaries written to `workspace/email/` when requested.

## Required Runtime Secrets
- OAuth/API mode: `GMAIL_ACCOUNT` or connector-provided account context.
- App-password mode: `GMAIL_USER` and `GMAIL_APP_PASSWORD`.

Secrets must come from Vault or runtime env. Never ask the user to paste secrets into a normal chat unless there is no safer option.

## Credential Check
- Before saying Gmail is not configured, run `himalaya folder list` or check the active OpenClaw runtime config for credential presence only.
- Do not print the values. Only report whether each key exists.
- Do not `read` or display the full raw OpenClaw config file because it may contain secrets.
- The expected active config path is `/Users/ducphan/Documents/trae_projects/openclaw_manager/openclaw_data/openclaw.json`.
- If both keys exist but direct environment variables are not visible to a shell, treat Gmail as configured through OpenClaw config and proceed with the email workflow.
- Never ask the user to recreate app passwords when `missing.env` is empty in `openclaw skills info "Safe Email Assistant" --json`.

## Safety Rules
- Never reveal email auth tokens, app passwords, raw headers, or full private threads unless explicitly requested.
- Confirm account, recipient, subject, and body before sending any email.
- Draft first by default; only send after explicit same-turn approval.
- Never permanently delete email without a same-turn confirmation that names the query/label and approximate count.
- For bulk label/archive/delete operations, show a preview of scope before execution.
- For any delete/move/archive action, show the message IDs, sender, subject, and folder before execution.
- Never run `himalaya folder expunge` unless the user explicitly asks for permanent deletion after previewing the affected folder.
- Important Gmail Bin behavior: `himalaya folder expunge "[Gmail]/Bin"` only permanently deletes messages already flagged `\\Deleted`; it does **not** empty all visible Bin messages by itself. To permanently empty Gmail Bin after explicit approval, first scan/list Bin IDs, run `himalaya message delete --folder "[Gmail]/Bin" <ids...>` in safe batches to mark those Bin messages deleted, then run `himalaya folder expunge "[Gmail]/Bin"`, then rescan `[Gmail]/Bin` and only report success when count is 0.
- Do not auto-forward sensitive content such as invoices, legal documents, credentials, private HR messages, or financial records.
- Summaries should preserve exact dates, names, invoice numbers, deadlines, and amounts.

## Triage Workflow
1. Search unread or requested mailbox scope.
2. Group by sender/thread and urgency.
3. Extract tasks, deadlines, attachments, and risks.
4. Return a concise summary with suggested actions.
5. Offer drafts for replies when useful.

## Importance Profile
- For proactive checks or "important mail" requests, read `/Users/ducphan/Documents/trae_projects/openclaw_manager/openclaw_data/.openclaw/workspace/MAIL_IMPORTANCE.md`.
- Use the profile to classify messages as urgent, important, or low priority.
- Default proactive cadence is hourly during 08:00-22:00 Asia/Ho_Chi_Minh, not per-message alerts, unless the user explicitly asks for active monitoring.
- Prioritize security/account, finance, cloud/dev account risk, recruiting with concrete next action, and high-fit senior mobile/fullstack roles.
- Do not mark automated job alerts, Reddit/Twitter/X digests, or newsletters as low priority by default. Classify by content fit, source quality, seniority/salary/tech-stack match, and whether it affects Danny's money/accounts/projects/career.
- If an email is borderline but matches Danny's career interests, include it in the digest with a short reason instead of discarding it.
- Do not expose OTPs, tokens, full account numbers, recovery links, app passwords, or raw headers.

## Himalaya Native Workflow
- If `himalaya` is model-visible or `himalaya --version` succeeds, use `himalaya` for Gmail instead of browser automation.
- First connectivity check: `himalaya folder list`.
- Use `himalaya envelope list --output json` for mailbox summaries and `himalaya message read <id>` for selected messages.
- For "all mail", "entire mailbox", or cleanup across Gmail, scan `[Gmail]/All Mail`, not just `INBOX`.
- Do not stop after the first 100/500/1000 envelopes for whole-mailbox cleanup. Paginate with `--page <n> --page-size <size>` until Himalaya returns an empty page, a short final page, or an out-of-bound page error.
- Prefer metadata-first cleanup: list envelopes across all pages, classify by sender/subject/date/flags, then read full messages only for borderline or important candidates.
- Local helper for whole-mailbox metadata scans: `node /Users/ducphan/Documents/trae_projects/openclaw_manager/scripts/scan_himalaya_mailbox.js --folder "[Gmail]/All Mail" --page-size 500`.
- Correct Himalaya v1.2 mutation syntax:
  - Soft-delete/move messages to Gmail Bin from INBOX: `himalaya message delete --folder INBOX <id>...`
  - Move messages from INBOX to a folder: `himalaya message move --folder INBOX "<target-folder>" <id>...`
  - Copy messages from INBOX to a folder: `himalaya message copy --folder INBOX "<target-folder>" <id>...`
- For `message move` and `message copy`, the target folder argument comes before the message IDs. Never run `himalaya message move <id> "<folder>"`.
- This Gmail account's trash folder is `[Gmail]/Bin`.
- Permanent empty-bin workflow for this account:
  1. Confirm the user explicitly approved permanent deletion and named `[Gmail]/Bin` / Gmail Bin plus approximate count.
  2. Scan `[Gmail]/Bin` metadata first, preferably with `node /Users/ducphan/Documents/trae_projects/openclaw_manager/scripts/scan_himalaya_mailbox.js --folder "[Gmail]/Bin" --page-size 500`.
  3. Extract every envelope ID from the scan output and run `himalaya message delete --folder "[Gmail]/Bin" <ids...>` in batches (for example 50-100 IDs per command). This marks visible Bin messages with `\\Deleted`.
  4. Run `himalaya folder expunge "[Gmail]/Bin"`.
  5. Rescan `[Gmail]/Bin`; do **not** tell the user it is done unless the verified count is 0. If Gmail web still shows messages, mention possible UI/sync delay only after IMAP count is 0.
- If Himalaya authentication fails with "Application-specific password required", report that the stored `GMAIL_APP_PASSWORD` is not a valid Gmail App Password for the configured account. Do not ask to use browser as the primary workaround.
- Use browser Gmail only as a temporary fallback when the user explicitly accepts it or when the CLI backend cannot be authenticated.

## External Skill Decision
- Prefer `r39132/gmail-agent` for inbox summary/labels if installing from ClawHub; it showed benign signals.
- Prefer `junkaixue/gmail-tool` for SMTP/IMAP send/read if app-password mode is acceptable; it showed benign signals.
- Avoid `r39132/gmail-skill` for now because the searched page showed Suspicious signals and includes destructive cleanup/background behavior.
