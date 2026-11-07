class_name Player
extends CharacterBody2D
## Player controller with 4-way custom gravity.
## Implements: design/gdd/player-movement.md, design/gdd/gravity-system.md
## Architecture: docs/architecture/ADR-0001-custom-player-gravity.md
##
## State table (GDD player-movement "States and Transitions"):
##   ALIVE (grounded/airborne derived from is_on_floor) --kill()--> DEAD --respawn()--> ALIVE
##   ALIVE --freeze(true)--> FROZEN --freeze(false)--> ALIVE   (level complete)

signal died
signal gravity_changed(dir: int)
signal air_charges_changed(charges: int, max_charges: int)
signal flip_denied
signal landed

@export var config: PlayerConfig

var gravity_dir: int = GravityMath.Dir.DOWN

var _air_charges: int = 0
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _is_jumping: bool = false
var _was_on_floor: bool = false
var _dead: bool = false
var _frozen: bool = false

# Juice variables (Sprint 2)
var _squash: Vector2 = Vector2.ONE
var _screen_shake_trauma: float = 0.0

@onready var _visual: Node2D = $Visual
@onready var _camera: Camera2D = $Camera2D
@onready var _death_burst: CPUParticles2D = $DeathBurst
@onready var _ghost_ray: RayCast2D = $GhostRay
@onready var _ghost_line: Line2D = $GhostLine
@onready var _ghost_marker: Polygon2D = $GhostMarker


func _ready() -> void:
	if config == null:
		push_warning("Player: no PlayerConfig assigned, using defaults.")
		config = PlayerConfig.new()
	_air_charges = config.air_flip_charges
	_camera.ignore_rotation = not config.camera_follows_gravity
	_apply_gravity_dir(gravity_dir)
	_visual.rotation = GravityMath.visual_rotation(gravity_dir)


func _physics_process(delta: float) -> void:
	if _dead or _frozen:
		return

	var on_floor := is_on_floor()
	_update_timers(delta, on_floor)

	var split := GravityMath.split_velocity(velocity, gravity_dir)
	var v_t := _compute_tangent_speed(split.x, on_floor, delta)
	var v_n := minf(split.y + config.gravity_strength * delta, config.max_fall_speed)

	# Jump (buffered + coyote). Resolved BEFORE flip: GDD gravity-system edge case.
	if _jump_buffer_timer > 0.0 and (on_floor or _coyote_timer > 0.0):
		v_n = -config.jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		_is_jumping = true
		_squash = Vector2(1.0 - config.squash_stretch_intensity, 1.0 + config.squash_stretch_intensity)
		if has_node("/root/SoundManager"):
			get_node("/root/SoundManager").play(AudioSynthesizer.Sound.JUMP)
	# Variable jump height.
	if _is_jumping and v_n < 0.0 and Input.is_action_just_released(&"jump"):
		v_n *= config.jump_cut_multiplier
	if v_n >= 0.0:
		_is_jumping = false

	velocity = GravityMath.compose_velocity(v_t, v_n, gravity_dir)

	_handle_flip_input()

	move_and_slide()
	
	if not _was_on_floor and is_on_floor():
		_squash = Vector2(1.0 + config.squash_stretch_intensity, 1.0 - config.squash_stretch_intensity)
		if has_node("/root/SoundManager"):
			get_node("/root/SoundManager").play(AudioSynthesizer.Sound.LAND)
			
	_was_on_floor = on_floor
	_update_visual(delta)
	_update_ghost_ray()
	_update_shake(delta)


# --- Public API (used by Level, GravityZone, Spikes) -------------------------

## Sets gravity. Manual flips (forced=false) may cost an air charge.
## Forced flips (zones) are free and refill charges. Returns true if gravity changed.
func set_gravity(dir: int, forced: bool = false) -> bool:
	if _dead or _frozen:
		return false
	if dir == gravity_dir:
		if forced:
			_refill_charges()
		return false

	if forced:
		_refill_charges()
	elif not _can_flip_for_free():
		if _air_charges <= 0:
			flip_denied.emit()
			if has_node("/root/SoundManager"):
				get_node("/root/SoundManager").play(AudioSynthesizer.Sound.DENY)
			return false
		_air_charges -= 1
		air_charges_changed.emit(_air_charges, config.air_flip_charges)

	_coyote_timer = 0.0
	_is_jumping = false
	_apply_gravity_dir(dir)

	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play(AudioSynthesizer.Sound.FLIP)
	_spawn_trail()

	# Rule 7: keep world velocity, but cap speed directed against the new gravity.
	var split := GravityMath.split_velocity(velocity, gravity_dir)
	split.y = maxf(split.y, -config.flip_carry_limit)
	velocity = GravityMath.compose_velocity(split.x, split.y, gravity_dir)

	gravity_changed.emit(gravity_dir)
	return true


## Requests death. Deferred so a Goal touched in the same physics frame wins (GDD level-flow edge case).
func kill() -> void:
	if _dead or _frozen:
		return
	call_deferred(&"_die")


func respawn(at: Vector2, dir: int) -> void:
	_dead = false
	_frozen = false
	global_position = at
	velocity = Vector2.ZERO
	_is_jumping = false
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_was_on_floor = false
	_apply_gravity_dir(dir)
	_visual.rotation = GravityMath.visual_rotation(dir)
	_visual.visible = true
	_camera.reset_smoothing()
	_refill_charges(true)
	gravity_changed.emit(gravity_dir)


func freeze(value: bool) -> void:
	_frozen = value
	if value:
		velocity = Vector2.ZERO


func is_dead() -> bool:
	return _dead


func get_air_charges() -> int:
	return _air_charges


func set_camera_limits(rect: Rect2) -> void:
	_camera.limit_left = int(rect.position.x)
	_camera.limit_top = int(rect.position.y)
	_camera.limit_right = int(rect.end.x)
	_camera.limit_bottom = int(rect.end.y)


# --- Internals ---------------------------------------------------------------

func _die() -> void:
	if _dead or _frozen:
		return
	_dead = true
	velocity = Vector2.ZERO
	_visual.visible = false
	_ghost_line.visible = false
	_ghost_marker.visible = false
	_death_burst.restart()
	_death_burst.emitting = true
	_screen_shake_trauma = 0.6
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play(AudioSynthesizer.Sound.DEATH)
	died.emit()


func _update_timers(delta: float, on_floor: bool) -> void:
	if on_floor:
		_coyote_timer = config.coyote_time
		if not _was_on_floor:
			_refill_charges()
			landed.emit()
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)
	if Input.is_action_just_pressed(&"jump"):
		_jump_buffer_timer = config.jump_buffer_time


func _compute_tangent_speed(current: float, on_floor: bool, delta: float) -> float:
	var input_vec := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var target := input_vec.dot(GravityMath.tangent_axis(gravity_dir)) * config.move_speed
	var has_input := absf(target) > 0.01
	var accel: float
	if on_floor:
		accel = config.ground_accel if has_input else config.ground_decel
	else:
		accel = config.air_accel if has_input else config.air_decel
	return move_toward(current, target, accel * delta)


func _handle_flip_input() -> void:
	for dir in GravityMath.ALL_DIRS:
		if Input.is_action_just_pressed(GravityMath.FLIP_ACTIONS[dir]):
			set_gravity(dir)
			return


func _can_flip_for_free() -> bool:
	# Coyote window counts as grounded: generosity in the player's favour (GDD player-movement edge case).
	return is_on_floor() or _coyote_timer > 0.0


func _apply_gravity_dir(dir: int) -> void:
	gravity_dir = dir
	up_direction = GravityMath.up_vector(dir)


func _refill_charges(always_emit: bool = false) -> void:
	var changed := _air_charges != config.air_flip_charges
	_air_charges = config.air_flip_charges
	if changed or always_emit:
		air_charges_changed.emit(_air_charges, config.air_flip_charges)


func _update_visual(delta: float) -> void:
	var target := GravityMath.visual_rotation(gravity_dir)
	var weight := 1.0 - exp(-config.rotate_visual_speed * delta)
	_visual.rotation = lerp_angle(_visual.rotation, target, weight)
	
	# Squash & Stretch recovery
	_squash = _squash.move_toward(Vector2.ONE, delta * 4.0)
	_visual.scale = _squash
	
	if config.camera_follows_gravity:
		_camera.rotation = _visual.rotation


func _update_shake(delta: float) -> void:
	if _screen_shake_trauma > 0.0:
		_screen_shake_trauma = maxf(_screen_shake_trauma - delta * 2.0, 0.0)
		var shake := _screen_shake_trauma * _screen_shake_trauma * 14.0
		_camera.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	else:
		_camera.offset = Vector2.ZERO


func _update_ghost_ray() -> void:
	if not config.show_ghost_ray or _dead or _frozen:
		_ghost_line.visible = false
		_ghost_marker.visible = false
		return
		
	var g_vec := GravityMath.to_vector(gravity_dir)
	_ghost_ray.target_position = g_vec * 1200.0
	_ghost_ray.force_raycast_update()
	
	if _ghost_ray.is_colliding():
		var hit_pt: Vector2 = _ghost_ray.get_collision_point()
		var local_hit: Vector2 = to_local(hit_pt)
		_ghost_line.clear_points()
		_ghost_line.add_point(Vector2.ZERO)
		_ghost_line.add_point(local_hit)
		_ghost_line.visible = true
		_ghost_marker.position = local_hit
		_ghost_marker.rotation = GravityMath.visual_rotation(gravity_dir)
		_ghost_marker.visible = true
	else:
		_ghost_line.visible = false
		_ghost_marker.visible = false


func _spawn_trail() -> void:
	var trail := Polygon2D.new()
	trail.polygon = PackedVector2Array([-11, -11, 11, -11, 11, 11, -11, 11])
	trail.color = Color(0.31, 0.86, 1.0, 0.45)
	trail.global_position = global_position
	trail.rotation = _visual.rotation
	get_parent().add_child(trail)
	
	var tween := trail.create_tween()
	tween.tween_property(trail, "scale", Vector2.ZERO, 0.22)
	tween.parallel().tween_property(trail, "modulate:a", 0.0, 0.22)
	tween.tween_callback(trail.queue_free)
