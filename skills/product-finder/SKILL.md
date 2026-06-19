---
name: product-finder
description: Finds and ranks products the user wants across Vietnamese/local and global marketplaces, using requirement intake, multi-source research, price/quality checks, fake-risk filtering, and concise buy/shortlist recommendations. Invoke for any product search, product comparison, sale hunting, wishlist building, deal monitoring, or “find me X” request; especially useful for shoes, clothing, electronics, accessories, household items, gifts, and hard-to-find products.
tools:
  - web_search
  - web_fetch
  - browser
  - file_system
---

# Product Finder

Use this skill to turn vague product wishes into a reliable shortlist. It extends the existing Shopping Research Agent with stronger requirement intake, Vietnam-aware marketplaces, quality/fake-risk checks, and output templates.

## Core Rules

- Never purchase, bid, subscribe, add to cart with intent to buy, message sellers, or enter payment/shipping details without explicit same-turn approval.
- Ask before logging into retail/social accounts. Prefer public pages/search first.
- Treat prices as observed snapshots. Always include observed date/time if available.
- Prefer total cost: item price + shipping + platform fees + discount conditions.
- Flag uncertainty: stock, sizing, seller trust, authenticity, return policy, warranty.
- For private or social marketplace leads, summarize and link; do not contact sellers unless approved.
- Save reusable findings only when useful or requested, under `shopping/` in the workspace.

## Intake: Ask Only What Blocks a Good Search

If the user gives enough detail, start searching. Otherwise ask the few missing questions that materially change results.

Minimum useful fields:
- Product type and purpose/use case.
- Budget range and currency.
- Location/region and delivery preference.
- Must-have specs/constraints.

Category-specific fields:
- Shoes/clothing: size, gender/fit, style, color, authentic vs replica tolerance, new/used tolerance.
- Electronics: exact model/specs, warranty needs, new/used/refurbished tolerance.
- Gifts: recipient, occasion, vibe, deadline.
- Furniture/home: dimensions, material, room constraints.

If user says “tìm tốt nhất” without details, infer sensible defaults from context but label assumptions.

## Search Strategy

1. Define the target profile:
   - Must-have, nice-to-have, exclusions, budget, location, deadline.
2. Search in layers:
   - Official brand/product pages for baseline specs and MSRP.
   - Reputable marketplaces/retailers.
   - Local Vietnam platforms when relevant: Shopee, Lazada, Tiki, Sendo, CellphoneS, FPT Shop, The Gioi Di Dong, Hoang Ha, Ananas, Supersports, Decathlon, Nike/Adidas official VN, etc.
   - Social/local leads only when appropriate: Facebook groups/pages, marketplace posts, TikTok shop signals, local sneaker/clothing stores.
3. Validate candidates:
   - Seller reputation, reviews, return policy, warranty/authenticity, stock/size availability, shipping time.
   - Compare against official specs and typical market price.
   - Check for fake/deal-risk signals.
4. Rank candidates:
   - Best overall, best value, cheapest acceptable, premium/safest, and “avoid”.
5. Produce a concise recommendation with next actions.

## Quality and Fake-Risk Heuristics

Use these checks before recommending:
- Price is far below market with weak seller/review history → suspicious.
- Product photos are stock-only, inconsistent, or copied across sellers → risk.
- No return policy or unclear warranty → downgrade.
- Marketplace seller has low rating, few sales, or many recent negative reviews → downgrade.
- For shoes/apparel: verify size chart, EU/US/CM conversion, return/exchange rules, and whether shop is official/authentic.
- For electronics: verify model number, region version, warranty center, included accessories, and battery/condition if used.

See `references/category-checklists.md` for category-specific checks when needed.

## Output Template

Default answer in Vietnamese for Danny unless user asks otherwise.

```markdown
## Tóm tắt nhanh
- Mình tìm theo: <assumptions/requirements>
- Khuyến nghị: <best option + why>
- Rủi ro chính: <size/fake/warranty/shipping/etc.>

## Shortlist
| Rank | Sản phẩm | Giá quan sát | Nguồn/Seller | Điểm mạnh | Điểm cần kiểm tra | Link |
|---|---|---:|---|---|---|---|

## Kết luận
1. Best overall: ...
2. Best value: ...
3. Nếu muốn rẻ nhất: ...
4. Nên tránh: ...

## Next step
- Nếu anh muốn, em có thể theo dõi giá / tìm thêm size màu / so thêm shop.
```

For quick/simple requests, compress to 3–5 bullets and a small shortlist.

## Watchlists

When user asks to monitor or remember candidates:
- Create/update `shopping/watchlist.md`.
- Include product, URL, observed price, seller, desired threshold, last checked time, notes.
- Use cron only for explicit reminders/monitoring requests; do not silently create recurring jobs.

## Reuse Existing Skills

- Use **Shopping Research Agent** for general price comparison and marketplace safety baseline.
- Use **Research Agent** for broader source-backed web research or when pages need browser interaction.
- Use **Safe Browser Automation Agent** when screenshots, UI testing, or browser data collection is needed.
- Use **hanoi-date-spot-finder** only for places/itineraries, not product buying.

## Evidence Standard

Final answer should cite or link sources used, and state what was directly observed vs inferred. If sources are weak or pages block access, say so and suggest a safer next check.
