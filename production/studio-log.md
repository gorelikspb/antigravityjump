# Studio Log — multi-agent session 2026-11-07

Протокол работы виртуальной студии (по методологии Claude-Code-Game-Studios: Directors → Leads → Specialists).

| # | Agent (tier) | Действие | Артефакт |
|---|--------------|----------|----------|
| 1 | creative-director (T1) | Концепт, 4 pillars + anti-pillars | `design/gdd/game-concept.md` |
| 2 | game-designer (T2) | GDD систем по шаблону (Core Rules, Formulas, Edge Cases, Tuning Knobs, AC) | `design/gdd/*.md` |
| 3 | technical-director (T1) | Architecture review: «где живёт гравитация?» → в игроке (ADR-0001) | `docs/architecture/*` |
| 4 | lead-programmer (T2) | Интерфейсы Player/Level, сигналы, слои физики | ADR-0001 §Key Interfaces |
| 5 | gameplay-programmer (T3) | GravityMath, Player, Level-объекты | `src/gameplay/**` |
| 6 | ui-programmer (T3) | HUD, GravityIndicator (только сигналы) | `src/ui/**` |
| 7 | level-designer (T3) | Level 01 «First Flip», все 4 направления | `design/levels/…`, `src/levels/level_01.tscn` |
| 8 | qa-lead (T2) | Unit-тесты + QA-бот, найден BUG-001 (чекпоинт), исправлен | `tests/**`, `tools/run_qa.ps1` |
| 9 | producer (T2) | Sprint 1 report, roadmap S2–S5 | `production/**` |

## Отклонения от протокола CCGS
- CCGS требует «Question → Options → Decision → Draft → Approval» с подтверждением каждой записи файла. Владелец явно запросил **автономный режим**, поэтому решения приняты Director-ом и задокументированы здесь и в ADR; все они открыты для пересмотра.
