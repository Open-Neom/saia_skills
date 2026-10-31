---
name: creador_habilidades_autonomo
category: agents
description: Create, edit, patch, and audit reusable procedural skills in Itzli when the user asks to turn a workflow into a skill or after solving a complex multi-step engineering task.
---

# Autonomous Skill Synthesis (Itzli Auto-Skill)

## 1. When to Synthesize or Patch a Procedural Skill
1. **Explicit User Request**: When the user asks to *"turn this into a skill"*, *"create a skill for..."*, *"save this workflow"*, or *"improve skill X"*.
2. **Closed-Loop Trajectory Distillation**: After solving a non-trivial multi-step workflow (complex debugging, browser automation recipe, API integration, or recurring document format) that will save tokens and time in future sessions.
3. **Surgical Refinement (`patch`)**: When an existing custom skill encounters a new edge case, refine it in place via `skill_catalog(action: "patch", id: "...", old_string: "...", new_string: "...")`.

## 2. Anatomy of a High-Signal Skill
- **Identifier (`id`)**: `snake_case`, specific and concise (max 64 chars).
- **Routing Description (`description`)**: Primary signal for **Itzli Phase 0 proactive routing**. State both what the skill does and the exact user intents/keywords that must trigger it.
- **Imperative Body (`content`)**:
  - Numbered, deterministic rules with zero filler.
  - Exact tool call sequence and parameters.
  - Output contract and anti-patterns to avoid.

## 3. Safety Guardrails
- Never embed destructive shell commands (`rm -rf /`), piped remote scripts (`curl | sh`), prompt injection overrides, or hardcoded secrets inside a skill.
