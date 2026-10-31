---
name: Flutter Design Tokens & 8 Interactive States
description: Semantic token architecture via Flutter ThemeExtension, mandatory 8 interactive component states, touch target sizing, and Semantics.
pillar: crear
---

# Flutter Design Tokens & 8 Interactive States

- Production Flutter widgets never scatter raw hex colors or magic padding numbers across build methods: they consume semantic tokens and implement all 8 interactive states.
- **Token Adapter (`ThemeExtension<DsTokens>`)**:
  - Organize tokens by semantic intent rather than raw appearance:
    - Surfaces: `bgCanvas`, `bgSurface`, `bgElevated`, `bgGlass`.
    - Typography: `textPrimary`, `textSecondary`, `textMuted`.
    - Borders: `borderSubtle`, `borderFocus`, `borderDanger`.
    - Accents & status: `accentPrimary`, `statusSuccess`, `statusWarning`, `statusDanger`.
  - Always implement `copyWith` and `lerp` on `ThemeExtension` so theme transitions interpolate smoothly.

## The 8 Mandatory Interactive States
1. **Default**: Rest state with clear visual hierarchy (`>= 4.5:1` text contrast, `>= 3:1` UI control contrast).
2. **Hover (Desktop / Web)**: Subtle surface lift or border highlight within `120ms` paired with `SystemMouseCursors.click`.
3. **Focus (Keyboard / A11y)**: Unmistakable `2px` focus ring (`borderFocus`) wired to `FocusNode` or `FocusableActionDetector`.
4. **Active / Pressed**: Immediate tactile compression (`scale: 0.97` or surface tint shift within `< 80ms`).
5. **Disabled**: `0.45` opacity, zero elevation shadow, `onPressed: null`, and a clear hint if the user needs to know how to unlock the action.
6. **Loading**: Preserve exact button width and height to prevent layout shift, render a `16x16` `CircularProgressIndicator(strokeWidth: 2)` at full foreground strength, and block duplicate taps.
7. **Error**: `statusDanger` border + warning icon + actionable recovery message below the control (`4px` gap).
8. **Selected / Active**: Clear distinction combining `12–18%` accent surface tint, active border or `2–3px` indicator pill, and `w600` font weight (never rely on color alone).

## Touch Targets & Flutter Accessibility
- Enforce `48x48 dp` minimum touch targets on mobile (`ConstrainedBox(constraints: BoxConstraints(minWidth: 48, minHeight: 48))`) and at least `24x24 px` on dense desktop toolbars.
- Wrap every icon-only button or custom interactive card in `Tooltip` and `Semantics(button: true, enabled: ..., label: ...)`.
- Support dynamic text scaling (`MediaQuery.textScalerOf(context)`) by using `Wrap` or `Flexible` instead of fixed-height `Row` containers.
