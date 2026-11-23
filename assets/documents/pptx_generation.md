# PPTX Presentation Creation & Editing

Create native, editable 16:9 PowerPoint (`.pptx`) decks directly with Itzli's `generate_pptx` tool across Desktop, Mobile, and Web.

- Primary workflow: call `generate_pptx` with a structured `slides` array (max 30 slides) and a visual `theme` (`executive`, `obsidiana`, `cuarzo`, `ambar`, `amatista`, `turquesa`, or `jade`).
- Available layouts (distilled from Presenton Template V2 `1280x720` canvas):
  - `cover` — title, subtitle, eyebrow badge
  - `bullets` — 2–6 concise points rendered as structured cards (<= 25 words per bullet)
  - `two_columns` — `left_title` / `left_items` vs `right_title` / `right_items` for comparisons
  - `kpis` — 2–4 `metrics` (`{value, label, detail}`) + optional takeaway bullets
  - `table` — native editable OOXML table (`table_headers`, `table_rows`)
  - `timeline` — 3–5 horizontal roadmap `steps` (`{title, detail}`)
  - `quote` — centered editorial pull-quote (`title` + `author`)
  - `closing` — final summary / call-to-action
- Always include concise speaker `notes` where helpful for presenters.
- Vary layouts across consecutive slides (avoid walls of text or repeating `bullets` on every slide).
- Reading existing `.pptx` files on Desktop: use `read_file` (Itzli extracts slide text natively from OOXML).
