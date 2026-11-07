# Architecture Overview — Anti-Gravity Jump (prototype)

> **Owner:** technical-director · **Date:** 2026-11-07

## Architecture review (Director ↔ Leads)

| Вопрос (TD) | Ответ | Ответственный |
|-------------|-------|---------------|
| Где живёт гравитация? | В игроке, не глобально → ADR-0001 | lead-programmer |
| Как хранить тюнинг? | `Resource` `PlayerConfig` → `.tres` | gameplay-programmer |
| Как собирать уровни без TileSet-ассетов? | `@tool`-сцены `Block`/`Spikes`/`GravityZone` с экспортируемым `size` (greybox), позже → TileMapLayer | level-designer |
| Как UI узнаёт о событиях? | Только сигналы `Level` → `HUD.bind(level)` | ui-programmer |
| Синглтоны? | Только `InputBootstrap` (регистрирует InputMap, без игрового состояния) | technical-director |
| Тесты? | Без аддонов: `tests/run_tests.gd` (`godot --headless -s`) | qa-lead |

## Scenes & Scripts

| Path | Type | Responsibility |
|------|------|----------------|
| `src/core/input_bootstrap.gd` | Autoload | Регистрирует действия ввода (клава + геймпад) |
| `src/gameplay/gravity/gravity_math.gd` | `class_name GravityMath` | Чистая математика направлений |
| `src/gameplay/player/player_config.gd` | `Resource` | Тюнинг-параметры |
| `src/gameplay/player/player.gd` + `player.tscn` | `CharacterBody2D` | Движение, прыжок, флип, смерть/респаун |
| `src/gameplay/level/level.gd` | `Node2D` | Медиатор: спаун, чекпоинты, смерть, таймер, финиш, рестарт |
| `src/gameplay/level/block.gd` + `.tscn` | `@tool StaticBody2D` | Greybox-геометрия |
| `src/gameplay/level/spikes.gd` + `.tscn` | `@tool Area2D` | Опасность |
| `src/gameplay/level/gravity_zone.gd` + `.tscn` | `@tool Area2D` | Принудительная гравитация |
| `src/gameplay/level/checkpoint.gd` + `.tscn` | `Area2D` | Точка респауна |
| `src/gameplay/level/goal.gd` + `.tscn` | `Area2D` | Финиш |
| `src/ui/hud.gd` + `hud.tscn` | `CanvasLayer` | Таймер, смерти, гравитация, заряды, панель итогов |
| `src/levels/level_01.tscn` | Scene | Тестовый уровень |
| `assets/data/player_config.tres` | Data | Значения тюнинга |
| `tests/run_tests.gd`, `tests/unit/**` | Tests | Юнит-тесты |

## Physics layers

| Layer | Name | Used by |
|-------|------|---------|
| 1 | world | Block |
| 2 | player | Player |
| 3 | triggers | Spikes, GravityZone, Checkpoint, Goal (mask = player) |
