# Player Movement

> **Owner:** game-designer · **Reviewed by:** lead-programmer · **Status:** Approved (prototype) · **Date:** 2026-11-07

## Summary

Отзывчивое движение платформера, полностью выраженное в системе координат текущей
гравитации: «пол», «прыжок», «падение» вычисляются относительно `gravity_dir`.

## Overview

`CharacterBody2D` с кастомной гравитацией. Скорость раскладывается на **касательную**
(бег) и **нормальную** (прыжок/падение) компоненты.

## Player Fantasy

Точный, «липкий» контроль уровня Celeste — смерть всегда вина игрока, а не физики.

## Detailed Design

### Core Rules

1. **Экранно-относительное управление:** ввод движения — 2D-вектор (WASD / стик). Учитывается только его проекция на касательную ось. При гравитации вниз/вверх работают A/D, при гравитации влево/вправо — W/S. Направление на экране = направление движения (никакой инверсии на потолке).
2. **Ускорение/торможение** раздельные для земли и воздуха.
3. **Прыжок:** мгновенная скорость `jump_velocity` против гравитации.
4. **Variable jump height:** отпускание прыжка при движении вверх умножает нормальную скорость на `jump_cut_multiplier`.
5. **Coyote time:** прыжок разрешён `coyote_time` секунд после схода с края.
6. **Jump buffer:** нажатие прыжка за `jump_buffer_time` до приземления исполняется при касании.
7. **Max fall speed** ограничивает только скорость вдоль гравитации.

### States and Transitions

| From | To | Условие |
|------|----|---------|
| Idle/Run | Jump | `jump` (или buffer) и (`on_floor` или coyote) |
| Idle/Run | Fall | потеря пола |
| Jump | Fall | `v_n ≥ 0` |
| Fall | Idle/Run | `is_on_floor()` |
| any | Dead | hazard / out of bounds |
| Dead | Idle | respawn |

## Formulas

- `input_t = input_vec.dot(tangent_axis)`, где `tangent_axis = (1,0)` при DOWN/UP и `(0,1)` при LEFT/RIGHT.
- `v_t = move_toward(v_t, input_t · move_speed, accel · Δt)`; `accel ∈ {ground_accel, ground_decel, air_accel, air_decel}`.
- `velocity = tangent_axis · v_t + g_dir · v_n`.
- Горизонтальная дальность прыжка ≈ `move_speed · 2 · jump_velocity / gravity` = 230 · 0.69 ≈ **158 px** (~5 тайлов).

## Edge Cases

- **Сход с края + флип в coyote-окне:** флип считается «наземным» (бесплатным) — щедрость в пользу игрока.
- **Удар головой о «потолок»:** `v_n` обнуляется (`is_on_ceiling`).
- **Ввод по диагонали стиком:** проекция, мёртвая зона 0.2.

## Dependencies

Gravity System (двусторонне), Level Flow (`kill()`, `respawn()`).

## Tuning Knobs

| Knob | Default | Safe range |
|------|---------|------------|
| `move_speed` | 230 | 150–350 |
| `ground_accel` / `ground_decel` | 2200 / 2600 | 800–5000 |
| `air_accel` / `air_decel` | 1500 / 900 | 500–3000 |
| `jump_velocity` | 480 | 350–700 |
| `jump_cut_multiplier` | 0.45 | 0.2–1.0 |
| `coyote_time` | 0.10 s | 0–0.2 |
| `jump_buffer_time` | 0.12 s | 0–0.2 |

## Game Feel

Время от нажатия до движения — 1 физический кадр. Рестарт по `R` — мгновенный.

## Acceptance Criteria

- [ ] AC-M1: На потолке D двигает персонажа вправо по экрану.
- [ ] AC-M2: На правой стене W двигает вверх по экрану; A/D не влияют.
- [ ] AC-M3: Короткое нажатие прыжка даёт заметно меньшую высоту, чем удержание.
- [ ] AC-M4: Прыжок через ≤ 0.1 s после схода с края срабатывает.
- [ ] AC-M5: Персонаж запрыгивает на ступень 64 px, но не на 96 px.
