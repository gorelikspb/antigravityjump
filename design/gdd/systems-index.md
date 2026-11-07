# Systems Index — Anti-Gravity Jump

> **Owner:** game-designer · **Date:** 2026-11-07

| System | Category | GDD | Code | Status | Depends on |
|--------|----------|-----|------|--------|------------|
| Gravity System | Core | [gravity-system.md](gravity-system.md) | `src/gameplay/gravity/` | Prototype | — |
| Player Movement | Gameplay | [player-movement.md](player-movement.md) | `src/gameplay/player/` | Prototype | Gravity System |
| Level Flow | Core | [level-flow.md](level-flow.md) | `src/gameplay/level/` | Prototype | Player Movement, Hazards |
| Hazards & Gravity Zones | Gameplay | [level-flow.md](level-flow.md#hazards--gravity-zones) | `src/gameplay/level/` | Prototype | Gravity System, Player Movement |
| HUD | UI | [level-flow.md](level-flow.md#ui-requirements) | `src/ui/` | Prototype | Level Flow (signals only) |
| Level 01 (test) | Content | [../levels/level-01-first-flip.md](../levels/level-01-first-flip.md) | `src/levels/level_01.tscn` | Greybox | all above |
