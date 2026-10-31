---
name: Anti-Slop Doctrine & UI Design Taste
description: Visual variance mandate, screen economy budgets, 3-second hierarchy rules, and elimination of generic AI-generated UI clichés.
pillar: crear
---

# Anti-Slop Doctrine & UI Design Taste

- Studio-grade interfaces avoid generic, repetitive layouts ("AI Slop") through intentional layout variance, strict screen economy, and unmistakable hierarchy.
- **Variance Mandate**: Never repeat the same card grid across consecutive sections or screens. Alternate between three core compositions:
  1. **Asymmetric Split (60/40 or 65/35)**: Best for hero views, live previews, or interactive side-by-side workspaces.
  2. **Dense Bento Grid (2–3 columns with unequal spans)**: Best for dashboards, capability catalogs, or multimodal studios.
  3. **Editorial Single-Column Stack (max 680px)**: Best for guided settings, consumer onboarding, or focused reading flows.

## Screen Economy
- **Viewport budget**: Maximum 4–5 distinct component groups visible without scrolling on mobile; maximum 6–8 on desktop.
- **Whitespace ratio**: Keep 25–35% of the viewport as open canvas or clean surface. When everything is emphasized, nothing stands out.
- **Card density**: Maximum 3 data points per card (title, primary status/metric, and one secondary detail or action) and maximum 3 cards in a single row.
- **Single primary navigation**: Never stack a top bar, sub-nav pills, breadcrumbs, sidebar, and bottom tab bar simultaneously in one view.

## 3-Second Hierarchy
- **Single focal point**: Every screen must establish one unmistakable primary element and primary action within 3 seconds.
- **Scale contrast**: Primary display titles or hero metrics should be at least `2.5x` the body text size.
- **Quiet hierarchy**: Separate information levels using font weight (`w700` vs `w400`) and semantic text opacity (`primary`, `secondary`, `muted`) before adding extra boxes or borders.

## Banned Patterns ("AI Slop")
- Three identical cards in a row (`Circular Icon + Title + 2-line blurb`) with equal visual weight.
- Thick one-sided colored borders (`border-left: 3px solid accent`) on informational cards.
- Unmotivated purple-to-blue neon gradients disconnected from brand tokens.
- Fake uppercase eyebrow labels above every section heading (`"FEATURES"`, `"OVERVIEW"`, `"SYSTEM"`).
- Raw developer terminals, file paths, or stack logs exposed by default to everyday users.
