---
name: Product UX Writing & Microcopy
description: Human-centered interface copy: frontload-the-verb button labels, actionable error messages, purposeful empty states, and tone spectrum.
pillar: crear
---

# Product UX Writing & Microcopy

- Interface copy is interaction architecture: every label must remove ambiguity and tell the user exactly what will happen before they click or tap.
- **"Frontload the Verb" Rule for Buttons & CTAs**:
  - Every primary or secondary button must begin with a specific action verb followed by its object: `"Generate image"`, `"Preview voice"`, `"Save settings"`, `"Download model"`.
  - Never use vague labels: `"OK"`, `"Submit"`, `"Yes"`, `"Continue"`, `"Process"`, `"Execute"`.
  - For destructive confirmations, name the exact action on the button: `"Delete conversation"` paired with `"Keep conversation"` (never `"Confirm / Cancel"`).

## Error Message Formula (`What happened → Why → How to fix`)
- Never blame the user or expose raw stack traces (`SocketException`, `Error 500`, `Null check operator`, terminal logs).
- Keep error messages to at most 2 sentences:
  1. **What happened and why** in plain, everyday language.
  2. **How to resolve it immediately** with a direct action button.
- Example: `"Audio synthesis couldn't start because the selected voice isn't installed yet. Tap 'Enable voice' to download it in seconds."`

## Purposeful Empty States
- An empty state must never be a dead end (`"No data"` or `"0 items"`).
- Follow the **Value + Immediate Action** formula:
  - Short heading explaining what lives here and why it matters.
  - 1-line subtitle with a concrete example.
  - Primary CTA or clickable starter chips so the user can create their first item in one tap.

## Tone Spectrum by User Stress Level
- **Onboarding & completion**: Warm, encouraging, and concise without hype or exclamation spam.
- **Settings & everyday tools**: Direct and human; translate technical flags into user benefits (`"Voice clarity"` instead of `"Sample rate / ONNX threads"`), tucking dev parameters inside an optional `"Advanced options"` disclosure.
- **Errors & interruptions**: Calm, precise, and strictly focused on recovery (zero humor or sarcasm).
