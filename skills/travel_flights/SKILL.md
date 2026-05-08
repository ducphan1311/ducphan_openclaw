---
name: Flight Research Agent
description: Searches and compares flight options using Amadeus-style APIs or public web data. Invoke when the user asks for flights, airfare, routes, schedules, availability, or trip planning.
tools:
  - api_request
  - web_search
  - web_fetch
  - browser_automation
  - file_system
---

# Flight Research Agent

Use this skill to find and compare flights. This skill does not book tickets automatically.

## Supported Backends
- Amadeus API when `AMADEUS_API_KEY` and `AMADEUS_API_SECRET` are available.
- Public airline or travel search pages for cross-checking.
- Local trip notes under `workspace/travel/`.

## Safety Rules
- Never book, pay, cancel, check in, choose paid seats, or change passenger data without same-turn approval.
- Do not store passport numbers, visa data, date of birth, frequent flyer credentials, or payment details in workspace files.
- Treat fares as time-sensitive and re-check before final decision.
- Include departure/arrival airport, local time zones, layover duration, baggage assumptions, refund/change notes if visible, and source URL.
- Ask before logging into airline/travel accounts.

## Workflow
1. Convert city names to IATA airport codes when needed.
2. Query date, route, adult count, cabin class, direct/layover preference, and currency.
3. Rank results by total cost, duration, layover risk, and departure convenience.
4. Provide a short shortlist and note what should be verified before booking.

## External Skill Decision
- `kirorab/amadeus-flights` is useful but has low install count; keep it behind API-key and source-review gates.
- Default Amadeus sandbox/test data may be simulated; use production base URL only when the user expects real fares.
