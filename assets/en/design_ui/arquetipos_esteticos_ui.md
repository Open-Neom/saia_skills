---
name: UI Aesthetic Archetypes & Visual Systems
description: The 6 product aesthetic archetypes (Obsidian Dark-Tech, Warm Soft-SaaS, Editorial, Studio Bento, Industrial, and Glass) mapped to design tokens.
pillar: crear
---

# UI Aesthetic Archetypes & Visual Systems

- Committing to a single aesthetic archetype before building prevents visual Frankensteins. An archetype governs atmosphere, corner radii, elevation, and typography, but **never** overrides WCAG AA contrast or screen economy.

## The 6 Product Aesthetic Archetypes
1. **Obsidian Dark-Tech & Cinematic (Itzli / Linear / Raycast style)**:
   - *Surfaces*: Deep obsidian canvas (`#0A0D12` to `#0D1117`), elevated cards (`#121822`) with `1px` specular borders (`7–10%` white).
   - *Accents*: High-precision focal light (cyan `#00E5FF`, emerald `#00C9A7`, or amber `#F5A623`) reserved strictly for active states and primary focal points.
   - *Typography*: Clean geometric sans paired with `FontFeature.tabularFigures()` for live metrics.
2. **Warm Soft-SaaS (Notion / Claude / Craft style)**:
   - *Surfaces*: Warm paper and sand tones (`#FAF8F5`, `#F3EFEA`), friendly radii (`12–16px`), and soft low-opacity shadows (`4–6%`).
   - *Best for*: Long-form conversational assistants, knowledge bases, and everyday consumer tools without eye strain.
3. **Editorial Minimalism (Stripe Press / Read.cv style)**:
   - *Surfaces*: High typographic contrast, `35%+` open whitespace, crisp `1px` hairlines, and zero decorative drop shadows.
   - *Best for*: Reading experiences, portfolios, executive reports, and documentation.
4. **High-End Studio Showcase (Apple / Teenage Engineering style)**:
   - *Surfaces*: Asymmetric bento grids with generous radii (`16–24px`), a single hero visual or 3D object per section, and tactile micro-interactions.
   - *Best for*: Voice and image creation studios, interactive catalogs, and product showcases.
5. **Precision Industrial / Utilitarian**:
   - *Surfaces*: Exposed hairlines, tight radii (`4–6px`), and high data density.
   - *Rule*: Reserve strictly for pro telemetry or developer inspector views; never use as the default view for everyday users.
6. **Ambient Morphism & Layered Glass**:
   - *Surfaces*: Translucent panels (`blur 12–16px`, `75–85%` surface opacity) floating above a subtle ambient canvas.
   - *Rule*: Restrict blur to floating bars, media mini-players, and modals to preserve legibility and GPU frame rates.

## Translating Visual References into Tokens
- Instead of copying screenshots literally, extract 5 token decisions:
  1. **Surface polarity & contrast** (deep obsidian vs. warm paper).
  2. **Corner radius scale** (`4px` technical, `10–12px` balanced, `16–24px` expressive).
  3. **Separation strategy** (whitespace, `1px` specular border, or subtle luminance step).
  4. **Typographic voice** (geometric, humanist, or editorial serif).
  5. **Effect budget** (maximum 1 glow or translucent layer per viewport).
