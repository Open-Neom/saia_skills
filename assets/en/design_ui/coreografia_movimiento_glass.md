---
name: Motion Choreography & Liquid Glass Restraint
description: UI animation physics, entrance/exit easing curves, stagger budgets, blur token scale, and restrained Liquid Glass surfaces.
pillar: crear
---

# Motion Choreography & Liquid Glass Restraint

- Motion in product UI is never decorative: it directs focus, explains spatial origin, and provides immediate physical confirmation of user actions.
- **Entrance vs. Exit Asymmetry**:
  - **Entrances (`ease-out` / `Curves.easeOutCubic`, `200–300ms`)**: Elements arrive quickly and decelerate smoothly into rest. Keep translation distances subtle (`8–16px`, never `50px+`).
  - **Exits (`ease-in` / `Curves.easeInCubic`, `150–200ms`)**: Always faster than entrances so departing elements never block the user.
  - **Tactile press feedback (`100–150ms`)**: Interactive buttons and cards compress slightly on press (`scale: 0.97`) and spring back on release.
  - **Layout transitions (`300–400ms`, `Curves.easeInOutCubic`)**: Side panels, accordions, and container bounds changes.

## Stagger Choreography
- Stagger sibling items by `40–80ms` following reading order (top-to-bottom, left-to-right).
- **Total cascade budget**: The entire stagger sequence must finish within `400ms`. For lists longer than 6 items, animate the first 5 and render the rest immediately.

## Blur Token Scale & Liquid Glass
- **Semantic blur scale**:
  - `blur.sm` (`4px`): Floating chips, media badges, and compact tooltips.
  - `blur.md` (`8px`): Lightweight translucent cards and overlay controls.
  - `blur.lg` (`16px`): Sticky navigation bars, floating docks, and bottom sheets.
  - `blur.xl` (`24px`): Modal backdrops and ambient canvas layers.
- **One-effect containment rule**: Use at most **one** hero surface effect (Liquid Glass or ambient glow) per view. Never stack multiple overlapping `BackdropFilter` layers.
- **Readable glass formula**: Pair `BackdropFilter` with `72–85%` surface opacity and a `1px` specular border (`Colors.white.withValues(alpha: 0.08)` in dark mode) to guarantee WCAG AA text contrast.

## Performance & Accessibility
- Animate only GPU-composited properties (`transform` and `opacity`) to maintain `60–120fps`.
- Always honor `MediaQuery.disableAnimationsOf(context)` / `prefers-reduced-motion` by replacing spatial translations with instant or `< 100ms` opacity crossfades.
