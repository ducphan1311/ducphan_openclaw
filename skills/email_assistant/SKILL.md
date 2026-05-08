---
name: Safe Email Assistant
description: Handles Gmail-style email reading, search, summarization, draft writing, and controlled sending. Invoke when the user asks to check mail, summarize inbox, draft replies, send email, or extract tasks from email.
tools:
  - api_request
  - web_fetch
  - file_system
---

# Safe Email Assistant

Use this skill for email triage, summaries, drafts, and explicit outbound messages.

## Supported Backends
- Gmail API or Google Workspace connector when OAuth is available.
- Gmail SMTP/IMAP with `GMAIL_USER` and `GMAIL_APP_PASSWORD` when the user chooses app-password mode.
- Local summaries written to `workspace/email/` when requested.

## Required Runtime Secrets
- OAuth/API mode: `GMAIL_ACCOUNT` or connector-provided account context.
- App-password mode: `GMAIL_USER` and `GMAIL_APP_PASSWORD`.

Secrets must come from Vault or runtime env. Never ask the user to paste secrets into a normal chat unless there is no safer option.

## Safety Rules
- Never reveal email auth tokens, app passwords, raw headers, or full private threads unless explicitly requested.
- Confirm account, recipient, subject, and body before sending any email.
- Draft first by default; only send after explicit same-turn approval.
- Never permanently delete email without a same-turn confirmation that names the query/label and approximate count.
- For bulk label/archive/delete operations, show a preview of scope before execution.
- Do not auto-forward sensitive content such as invoices, legal documents, credentials, private HR messages, or financial records.
- Summaries should preserve exact dates, names, invoice numbers, deadlines, and amounts.

## Triage Workflow
1. Search unread or requested mailbox scope.
2. Group by sender/thread and urgency.
3. Extract tasks, deadlines, attachments, and risks.
4. Return a concise summary with suggested actions.
5. Offer drafts for replies when useful.

## External Skill Decision
- Prefer `r39132/gmail-agent` for inbox summary/labels if installing from ClawHub; it showed benign signals.
- Prefer `junkaixue/gmail-tool` for SMTP/IMAP send/read if app-password mode is acceptable; it showed benign signals.
- Avoid `r39132/gmail-skill` for now because the searched page showed Suspicious signals and includes destructive cleanup/background behavior.
