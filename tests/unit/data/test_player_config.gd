extends "res://tests/test_case.gd"
## Data validation: player_config.tres must satisfy level-design constraints.
## Covers: design/gdd/player-movement.md AC-M5, design/levels/level-01-first-flip.md (beats 1-2).

const GM := preload("res://src/gameplay/gravity/gravity_math.gd")
const CONFIG_PATH := "res://assets/data/player_config.tres"

const TILE := 32.0
const STEP_HEIGHT := 64.0      # level 01, beat 1 (must be jumpable)
const BLOCKING_HEIGHT := 96.0  # must NOT be jumpable
const PIT_WIDTH := 320.0       # level 01, beat 2 (must NOT be jumpable -> forces gravity flip)

var _cfg: Resource


func _load() -> Resource:
	if _cfg == null:
		_cfg = load(CONFIG_PATH)
	return _cfg


func test_config_loads() -> void:
	assert_true(_load() != null, "player_config.tres missing")


func test_step_is_jumpable_but_wall_is_not() -> void:
	var c := _load()
	var h := GM.jump_height(c.jump_velocity, c.gravity_strength)
	assert_true(h > STEP_HEIGHT + 8.0, "jump height %.1f must clear 64px step with margin" % h)
	assert_true(h < BLOCKING_HEIGHT, "jump height %.1f must not clear 96px" % h)


func test_pit_requires_gravity_flip() -> void:
	var c := _load()
	var distance: float = c.move_speed * GM.air_time(c.jump_velocity, c.gravity_strength)
	assert_true(distance < PIT_WIDTH - TILE, "jump distance %.1f must be < pit width" % distance)


func test_air_charges_in_safe_range() -> void:
	var c := _load()
	assert_true(c.air_flip_charges >= 0 and c.air_flip_charges <= 3)
