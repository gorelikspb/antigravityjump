# Sprint 1 — 2026-11-07 to 2026-11-07 (bootstrap)

## Sprint Goal
Играбельный greybox-прототип core-loop: 4-сторонняя гравитация, 1 тестовый уровень, HUD, автотесты.

## Milestone Context
M0 «Prototype / Find the fun» → решение go/no-go после плейтеста.

## Tasks

### Must Have (Critical Path)
| ID | Task | Owner | Status |
|----|------|-------|--------|
| S1-01 | Game concept + pillars | creative-director | ✅ Done |
| S1-02 | GDD: Gravity, Movement, Level Flow | game-designer | ✅ Done |
| S1-03 | ADR-0001 + architecture overview | technical-director | ✅ Done |
| S1-04 | GravityMath + PlayerConfig + Player | gameplay-programmer | ✅ Done |
| S1-05 | Level objects (Block, Spikes, Zone, Checkpoint, Goal) + Level mediator | gameplay-programmer | ✅ Done |
| S1-06 | HUD + GravityIndicator | ui-programmer | ✅ Done |
| S1-07 | Level 01 greybox | level-designer | ✅ Done |
| S1-08 | Unit tests + QA bot (solve / pit / checkpoint) | qa-lead | ✅ Done |

### Should Have
| S1-09 | Ручной плейтест AC-M1…M5, AC-G1…G5 в редакторе | qa-tester | ⏳ Нужен человек |

## Bugs found & fixed in-sprint
| ID | Severity | Описание | Fix |
|----|----------|----------|-----|
| BUG-001 | S2 | Чекпоинт 32×64 у пола пропускался — игрок пролетает над ним после Safety Zone | Триггер стал колонной 32×560, флажок рисуется внизу |
| BUG-002 | S4 (тест) | QA-бот «тапал» прыжок 1 кадр → срабатывал jump cut, не запрыгивал на ступень | Бот удерживает прыжок 20 кадров (поведение игры корректно) |

## Definition of Done for this Sprint
- [x] `tools/run_qa.ps1` зелёный
- [x] Каждая фича ссылается на GDD в комментарии
- [x] Нет хардкода тюнинга (всё в `player_config.tres`)
- [ ] Плейтест владельцем
