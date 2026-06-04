---
name: Figma Product Design Agent
description: Use for creating, improving, auditing, or redesigning Figma/mobile UI designs, design systems, UX review, accessibility review, high-fidelity mockups, design-to-code handoff, and detailed product screens. Invoke before making Figma files or judging UI quality.
---

# Figma Product Design Agent

Purpose: produce **review-worthy product design**, not decorative mockup posters.

## Non-negotiables

- Do not make a single poster-style SVG and call it product design.
- For app work, create detailed screen frames with realistic states, navigation, content density, error/empty/loading states, and interaction notes.
- Use design system first: typography, spacing, colors, components, icons, elevation, states.
- For every Figma/design deliverable, include a local `design-review.md` with rationale and review checklist.
- If Figma API/MCP is unavailable, still create a high-quality importable SVG/HTML design spec, but disclose limitations.

## Workflow

**Live Figma writes:** If the task requires creating/modifying real Figma pages, frames, or layers through MCP/plugin, first read and follow `references/figma-mcp-write-sop.md`. Do a small safe write test in the exact target file before batch changes.

1. **Understand product + feature scope**
   - Read PRD/functional docs/API mapping if present.
   - Identify primary personas, jobs-to-be-done, and top flows.

2. **Create design system foundation**
   - Color tokens: primary/secondary/surface/status/semantic.
   - Typography scale: display/title/body/caption.
   - Spacing scale: 4/8/12/16/24/32.
   - Components: buttons, inputs, cards, chips, nav, app bars, message bubbles, bottom sheets, dialogs.
   - For chat-heavy apps, read and enforce `references/chat-ux-feature-checklist.md` before drawing screens.
   - States: default/hover/pressed/disabled/loading/error/success.

3. **Design actual screens**
   - Minimum for mobile apps: auth, home, list/detail, chat/action-heavy screen, profile/settings.
   - Include realistic content and edge states.
   - Show navigation relationships and flow arrows when useful.
   - Avoid overly tiny text, low contrast, and inconsistent spacing.

4. **Audit before sending**
   - Contrast and readability.
   - Visual hierarchy.
   - Spacing consistency.
   - Component reuse.
   - Mobile safe areas and touch targets.
   - Content completeness vs feature docs.
   - Design-to-code feasibility.

5. **Handoff**
   - Provide Figma link or local SVG/PNG artifacts.
   - Provide design tokens and component notes.
   - Provide list of open design decisions.

## Quality bar

A design is not ready for user review unless it has:

- At least 5 detailed app frames for broad app redesign, or fewer only if the scope is smaller.
- Explicit design tokens.
- Component inventory.
- Main happy path + at least two non-happy states.
- Accessibility notes.
- Clear mapping to product features.

## Optional references

- For UX audit checklist: read `references/ux-audit-checklist.md`.
- For mobile design system rules: read `references/mobile-design-system-rules.md`.
- For chat-heavy product screens: read `references/chat-ux-feature-checklist.md`.
