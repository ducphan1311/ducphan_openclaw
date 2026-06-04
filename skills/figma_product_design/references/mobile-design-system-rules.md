# Mobile Design System Rules

## Typography
- Display: 32/40 bold
- Screen title: 24/32 bold
- Section title: 18/26 semibold
- Body: 15/22 regular
- Caption: 12/16 medium

## Spacing
- Base unit: 4
- Screen padding: 20 or 24
- Card padding: 16 or 20
- Between form fields: 12
- Section spacing: 24 or 32

## Components
- Primary button: 52 height, 16 radius, clear loading state.
- Text input: 52-56 height, visible label, error/helper text.
- Cards: 16-24 radius, border/elevation consistent.
- Chips: 28-34 height, clear selected/default state.
- Chat bubbles: max 72% width, timestamp/read state, reply/reaction affordance.
- Bottom navigation: 4-5 max top-level destinations.

## States
Always consider:
- Empty
- Loading
- Error
- Success
- Disabled
- Offline/reconnecting
- Permission/account required

## Color
- Use semantic roles, not random hex.
- Primary CTA must pass contrast.
- Status colors: success/warning/error/info.
- Dark mode surfaces need at least 3 levels.
