# CLAUDE.md / AGENTS.md — Anti-Gravity Jump Studio

Структура и методология: [Claude-Code-Game-Studios](https://github.com/Donchitos/Claude-Code-Game-Studios) (Directors → Leads → Specialists).

## Technology Stack
- **Engine**: Godot 4.7 (min 4.2) · **Language**: GDScript (typed) · **Renderer**: GL Compatibility
- **Version Control**: Git, trunk-based
- **Tests**: addon-free runner `tests/run_tests.gd` + QA bot `tests/integration/level_01_bot.gd` → `tools/run_qa.ps1`

## Directory Structure
```
src/            code root (Godot): core/, gameplay/{gravity,player,level}/, ui/, levels/
assets/data/    tuning resources (.tres) — ALL gameplay numbers live here
design/         gdd/, levels/
docs/           architecture/ (ADRs)
production/     sprints/, roadmap.md, studio-log.md, session-state/ (gitignored)
tests/          unit/, integration/
tools/          run_qa.ps1
prototypes/     throwaway code, never imported by src/
```

## Coding Rules (from CCGS gameplay-code / design-docs rules)
- Gameplay values from `PlayerConfig` (`assets/data/player_config.tres`), never hardcoded.
- Delta time for everything time-based.
- Gameplay never references UI. `Level` is the mediator; `HUD.bind(level)` subscribes to signals.
- No static singletons for game state (only `InputBootstrap`, which holds none).
- Every script header names the GDD section it implements.
- New system ⇒ GDD section (Core Rules, Formulas, Edge Cases, Tuning Knobs, Acceptance Criteria) BEFORE code.
- Architecture decisions ⇒ ADR in `docs/architecture/`.
- Greybox level objects: node position = top-left, `size` export, `@tool` so they render in editor.

## Collaboration Protocol
Question → Options → Decision → Draft → Approval. No commits without owner instruction.
Session checkpoint: `production/session-state/active.md`.
