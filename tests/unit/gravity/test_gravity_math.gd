extends "res://tests/test_case.gd"
## Unit tests for GravityMath. Covers: design/gdd/gravity-system.md AC-G6, player-movement.md AC-M1/AC-M2.

const GM := preload("res://src/gameplay/gravity/gravity_math.gd")


func test_to_vector_all_dirs() -> void:
	assert_eq(GM.to_vector(GM.Dir.DOWN), Vector2.DOWN)
	assert_eq(GM.to_vector(GM.Dir.UP), Vector2.UP)
	assert_eq(GM.to_vector(GM.Dir.LEFT), Vector2.LEFT)
	assert_eq(GM.to_vector(GM.Dir.RIGHT), Vector2.RIGHT)


func test_from_vector_roundtrip() -> void:
	for dir in GM.ALL_DIRS:
		assert_eq(GM.from_vector(GM.to_vector(dir)), dir, GM.dir_name(dir))
	assert_eq(GM.from_vector(Vector2(0.9, 0.2)), GM.Dir.RIGHT)
	assert_eq(GM.from_vector(Vector2.ZERO), GM.Dir.DOWN)


func test_up_is_opposite_of_gravity() -> void:
	for dir in GM.ALL_DIRS:
		assert_eq(GM.up_vector(dir), -GM.to_vector(dir))


func test_tangent_is_perpendicular_to_gravity() -> void:
	for dir in GM.ALL_DIRS:
		assert_almost(GM.tangent_axis(dir).dot(GM.to_vector(dir)), 0.0)


func test_controls_are_screen_relative_on_ceiling() -> void:
	# AC-M1: pressing right (input +X) on the ceiling moves right on screen.
	assert_eq(GM.tangent_axis(GM.Dir.UP), Vector2.RIGHT)


func test_controls_are_screen_relative_on_walls() -> void:
	# AC-M2: on walls, W (input -Y) moves up on screen.
	var input_up := Vector2(0, -1)
	for dir in [GM.Dir.LEFT, GM.Dir.RIGHT]:
		var t := GM.tangent_axis(dir)
		assert_vec_almost(t * input_up.dot(t), Vector2(0, -1))


func test_split_compose_roundtrip() -> void:
	var v := Vector2(123.0, -45.0)
	for dir in GM.ALL_DIRS:
		var s := GM.split_velocity(v, dir)
		assert_vec_almost(GM.compose_velocity(s.x, s.y, dir), v, 0.001, GM.dir_name(dir))


func test_split_normal_positive_means_falling() -> void:
	assert_almost(GM.split_velocity(Vector2(0, 100), GM.Dir.DOWN).y, 100.0)
	assert_almost(GM.split_velocity(Vector2(0, -100), GM.Dir.UP).y, 100.0)
	assert_almost(GM.split_velocity(Vector2(-100, 0), GM.Dir.LEFT).y, 100.0)


func test_visual_rotation_points_feet_at_gravity() -> void:
	for dir in GM.ALL_DIRS:
		var feet := Vector2.DOWN.rotated(GM.visual_rotation(dir))
		assert_vec_almost(feet, GM.to_vector(dir), 0.001, GM.dir_name(dir))


func test_is_opposite() -> void:
	assert_true(GM.is_opposite(GM.Dir.UP, GM.Dir.DOWN))
	assert_true(GM.is_opposite(GM.Dir.LEFT, GM.Dir.RIGHT))
	assert_true(not GM.is_opposite(GM.Dir.LEFT, GM.Dir.DOWN))


func test_jump_formulas() -> void:
	assert_almost(GM.jump_height(480.0, 1400.0), 82.2857, 0.01)
	assert_almost(GM.air_time(480.0, 1400.0), 0.6857, 0.001)
