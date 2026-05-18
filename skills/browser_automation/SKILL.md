---
name: Safe Browser Automation Agent
description: Runs controlled browser automation for UI testing, screenshots, form checks, and public web research. Invoke when the user asks for Playwright-style UI testing, browser data collection, product search, sale hunting, or website interaction.
tools:
  - browser_automation
  - shell_command
  - file_system
  - web_fetch
---

# Safe Browser Automation Agent

Use this skill for UI testing, browser interaction, screenshots, and public website research.

## OpenClaw Browser Profiles
- Use OpenClaw browser profile `facebook-travel` for Facebook, Messenger, travel browsing, and any task that needs Danny's logged-in social/travel session.
- Prefer the first-class browser tool with profile `facebook-travel`; do not fall back to manual CDP probing unless the browser tool is unavailable.
- The profile is registered in OpenClaw config as the default browser profile and uses the local managed Chrome session on CDP port `18821`.
- If login, 2FA, captcha, checkpoint, or suspicious-login review appears, stop and ask Danny to complete it manually in the visible browser.
- Do not send messages, post, react, purchase, book travel, or change account settings without explicit same-turn approval.

## Token-Safe Browser Loop
- Keep browser snapshots small. Default to `maxChars` 2500-4000 for search/result pages, and only raise it when a narrower extraction is impossible.
- For pages with long result lists, capture the first useful screen, extract the top 3-5 candidates, then close or reuse tabs instead of opening many new tabs.
- Do not paste full OTA, Facebook, search, or marketplace page text back into the model. Summarize selected offers/leads with source URL, price/name, and confidence.
- After each large browser result, consolidate findings before the next model call. If a page output is truncated, narrow the query/filter or use targeted `evaluate`/element refs instead of requesting a larger snapshot.
- Close unrelated tabs once their data is captured.

## Approved Capabilities
1. Test local or staging pages with Playwright-style flows.
2. Check responsive layout, visible errors, form validation, redirects, and broken links.
3. Collect public product, sale, and travel information for comparison.
4. Fill forms up to the final review screen when the user explicitly asks.
5. Capture screenshots and concise findings.

## Safety Rules
- Write temporary automation scripts only under `/tmp`, never into the project or skill directory.
- Prefer visible browser mode for manual verification unless the user asks for headless/background mode.
- Do not bypass paywalls, CAPTCHAs, rate limits, account restrictions, or website access controls.
- Do not extract cookies, passwords, session tokens, saved browser data, or hidden credentials.
- Do not submit purchases, payments, bookings, account changes, messages, or posts without same-turn user approval.
- For login flows, use credentials only when the user provides them for that task or when they are available through approved runtime secrets.
- Summarize the target site, fields to submit, and expected side effect before any write action.
- For external websites, obey robots/terms constraints when known and keep request volume low.

## UI Testing Workflow
1. Detect the target URL. For local work, check running dev servers first.
2. Create a short script in `/tmp/playwright-test-<task>.js`.
3. Use stable selectors and explicit waits.
4. Capture screenshots for desktop and mobile when layout is relevant.
5. Report failures with URL, viewport, selector, console errors, and screenshot path.

## Browser Research Workflow
1. Prefer official APIs or public pages over fragile scraping.
2. Record source URL, observed price/date/time, currency, shipping/fees if visible, and confidence.
3. Do not treat browser-displayed prices as final checkout prices.
4. For shopping or travel, return a comparison table and ask before any cart, checkout, or booking step.

## External Skill Notes
- `vmercel/playwright-skill` is useful but was listed with Suspicious audit signals on clawskills.sh, so run only after source review.
- `spiceman161/playwright-mcp` and `mahone-bot/playwright-npx` had benign signals in the searched registry pages and are safer candidates if installing a third-party package later.
