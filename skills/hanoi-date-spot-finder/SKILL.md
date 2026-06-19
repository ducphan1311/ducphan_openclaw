---
name: hanoi-date-spot-finder
description: Finds and ranks places to hang out/date with a girlfriend in Hanoi, including classic spots and current hot trends. Uses multi-source research across web search, maps/review sites, local media, Facebook/TikTok/social signals when available, and writes structured Markdown recommendations. Invoke when the user asks for date ideas, places to go with girlfriend/boyfriend, Hanoi hangout spots, cafes, restaurants, activities, romantic places, trendy places, weekend plans, or itinerary suggestions in Hanoi.
---

# Hanoi Date Spot Finder

Purpose: produce practical, source-backed recommendations for places to go with a girlfriend in Hanoi, balancing romance, novelty, convenience, budget, vibe, and trendiness.

## Safety / Boundaries

- Do not purchase tickets, reserve tables, message venues, comment/post on social media, or contact anyone unless the user explicitly approves.
- For Facebook/TikTok: collect public/reachable information only. If login/browser access is needed, use browser automation carefully and summarize public signals; do not scrape private groups aggressively or bypass restrictions.
- Be transparent when a source could not be checked.
- Prefer recent information for “hot trend” claims; note date/time of check.

## Default Output

Unless user specifies otherwise, return:

1. **Top picks**: 5-10 places, grouped by vibe.
2. **Why it fits a date**: vibe, best time, photo potential, conversation/activity value.
3. **Practical details**: area, estimated budget, booking/crowd warning, weather suitability.
4. **Source signals**: where the recommendation came from: local articles, maps/reviews, TikTok/Facebook/social buzz, blogs, event listings.
5. **Smart plan**: 1-2 route/itinerary options, not just a list.
6. **Caveats**: uncertain hours/prices, needs reservation, outdoor/rain risk.

## Required Workflow

1. Clarify only if necessary:
   - date/time, budget, district, transport, food/cafe/activity preference, indoor/outdoor, quiet vs lively.
   - If not provided, assume Hanoi, next weekend/evening, mid-budget, couple-friendly.
2. Search broad web first:
   - Vietnamese and English queries.
   - Mix evergreen/classic and recent/trending queries.
3. Check trend signals:
   - TikTok/web-indexed TikTok queries.
   - Facebook/web-indexed public posts/groups/pages when possible.
   - Local media/blogs/event pages.
4. Score candidates using `references/scoring.md`.
5. Return ranked recommendations with reasons and routes.
6. For substantial research, save Markdown report to Obsidian:
   - `~/Documents/Obsidian/OpenClawBrain/70-Logs/Research/hanoi-date-spots-YYYY-MM-DD.md`
   - Rebuild index with `node scripts/obsidian_indexer.js` from workspace.

## Search Query Patterns

Use Vietnamese first, then English:

- `địa điểm hẹn hò Hà Nội mới nhất`
- `quán cafe hẹn hò Hà Nội hot TikTok`
- `địa điểm đi chơi với người yêu Hà Nội cuối tuần`
- `địa điểm sống ảo Hà Nội hot trend`
- `workshop couple Hà Nội cuối tuần`
- `triển lãm Hà Nội cuối tuần người yêu`
- `rooftop cafe Hà Nội hẹn hò`
- `hidden gem cafe Hà Nội date`
- `Hanoi date ideas 2026`
- `Hanoi romantic cafes new trending`
- `site:tiktok.com Hà Nội hẹn hò cafe hot`
- `site:facebook.com Hà Nội địa điểm hẹn hò hot`

## Source Mix

Aim for at least 3 source types:

- Maps/reviews: Google Maps-like snippets, Foody/DiaDiemAnUong/Tripadvisor/Klook/GetYourGuide where available.
- Local media/blogs: Kenh14, Yeah1, Halo Travel, Digiticket, Traveloka, local event pages.
- Social/trend: TikTok, Facebook public pages/groups/posts, Instagram/web snippets when reachable.
- Events: exhibitions, workshops, weekend markets, live music, cinema, theatre.
- Weather/time constraints: outdoor options need rain/heat caveat.

## Ranking Dimensions

Use the smart ranking in `references/scoring.md`. For quick tasks, explain ranking qualitatively. For larger tasks, include score table.

## Obsidian Integration

Before a deep search, optionally check prior notes:

```bash
node scripts/obsidian_search.js "Hanoi date spots cafe hẹn hò"
```

After creating a research report, use the template:

- `templates/date_spot_report.md`

Then rebuild:

```bash
node scripts/obsidian_indexer.js
```

## When to Use Browser

Use browser automation when:

- the user specifically wants Facebook/TikTok checks,
- search snippets are weak/stale,
- a site requires scrolling/filtering,
- screenshots or UI confirmation are useful.

Prefer `web_search`/`web_fetch` first for lightweight research.
