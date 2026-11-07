class_name Level
extends Node2D
## Level mediator: spawn, checkpoints, death/respawn, timer, goal, restart.
## Relays Player events to UI via its own signals (UI never touches Player directly).
## Implements: design/gdd/level-flow.md · Architecture: ADR-0001

signal timer_updated(seconds: float)
signal deaths_changed(count: int)
signal level_completed(seconds: float, deaths: int)
signal gravity_changed(dir: int)
signal air_charges_changed(charges: int, max_charges: int)
signal flip_denied
signal checkpoint_reached
signal crystals_changed(collected: int, total: int, required: bool)

@export var level_name: String = "Untitled Level"
@export var level_bounds: Rect2 = Rect2(0, 0, 1280, 720)
@export var start_gravity: GravityMath.Dir = GravityMath.Dir.DOWN
@export_file("*.tscn") var next_level: String = ""
## If true, the Goal stays locked until every RechargeCrystal in the level has been collected.
@export var require_all_crystals: bool = true
## Extra distance outside level_bounds before the player is killed (AC-L5).
@export var out_of_bounds_margin: float = 64.0

var _elapsed: float = 0.0
var _deaths: int = 0
var _running: bool = true
var _completed: bool = false
var _respawn_position: Vector2
var _respawn_gravity: int
var _respawn_timer: Timer
var _total_crystals: int = 0
var _collected_crystals: Array[RechargeCrystal] = []
var _checkpoint_crystals: Array[RechargeCrystal] = []

@onready var _player: Player = $Player
@onready var _spawn: Marker2D = $Spawn
@onready var _hud: HUD = get_node_or_null(^"HUD") as HUD


func _ready() -> void:
	_setup_neon_backdrop()
	_respawn_position = _spawn.global_position
	_respawn_gravity = start_gravity

	_respawn_timer = Timer.new()
	_respawn_timer.one_shot = true
	_respawn_timer.timeout.connect(_do_respawn)
	add_child(_respawn_timer)

	if _hud:
		_hud.bind(self)

	_player.died.connect(_on_player_died)
	_player.gravity_changed.connect(gravity_changed.emit)
	_player.air_charges_changed.connect(air_charges_changed.emit)
	_player.flip_denied.connect(flip_denied.emit)
	_player.set_camera_limits(level_bounds)

	for node in get_tree().get_nodes_in_group(&"checkpoints"):
		if is_ancestor_of(node):
			(node as Checkpoint).activated.connect(_on_checkpoint_activated)
	for node in get_tree().get_nodes_in_group(&"goals"):
		if is_ancestor_of(node):
			(node as Goal).reached.connect(_on_goal_reached)
	for node in get_tree().get_nodes_in_group(&"crystals"):
		if is_ancestor_of(node):
			var c := node as RechargeCrystal
			_total_crystals += 1
			c.always_consume = true
			c.collected.connect(_on_crystal_collected.bind(c))

	_player.respawn(_respawn_position, _respawn_gravity)
	_update_goal_lock()
	deaths_changed.emit(_deaths)
	timer_updated.emit(_elapsed)
	crystals_changed.emit(_collected_crystals.size(), _total_crystals, require_all_crystals)


func _physics_process(delta: float) -> void:
	if not _running:
		return
	_elapsed += delta
	timer_updated.emit(_elapsed)
	if not _player.is_dead() and not is_inside_bounds(_player.global_position):
		_player.kill()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"menu"):
		get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")
	elif event.is_action_pressed(&"restart"):
		get_tree().reload_current_scene()
	elif _completed and event.is_action_pressed(&"confirm"):
		if next_level.is_empty():
			get_tree().reload_current_scene()
		else:
			get_tree().change_scene_to_file(next_level)


func is_inside_bounds(point: Vector2) -> bool:
	return level_bounds.grow(out_of_bounds_margin).has_point(point)


func get_deaths() -> int:
	return _deaths


func get_elapsed() -> float:
	return _elapsed


func _on_player_died() -> void:
	_deaths += 1
	deaths_changed.emit(_deaths)
	_respawn_timer.start(maxf(_player.config.respawn_delay, 0.01))


func _do_respawn() -> void:
	if _completed:
		return
	_collected_crystals = _checkpoint_crystals.duplicate()
	for node in get_tree().get_nodes_in_group(&"crystals"):
		if is_ancestor_of(node):
			node.call(&"reset")
	_update_goal_lock()
	crystals_changed.emit(_collected_crystals.size(), _total_crystals, require_all_crystals)
	_player.respawn(_respawn_position, _respawn_gravity)


func _on_checkpoint_activated(respawn_position: Vector2) -> void:
	_respawn_position = respawn_position
	_respawn_gravity = _player.gravity_dir
	_checkpoint_crystals = _collected_crystals.duplicate()
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play(AudioSynthesizer.Sound.CHECKPOINT)
	checkpoint_reached.emit()


func _on_crystal_collected(crystal: RechargeCrystal) -> void:
	if not _collected_crystals.has(crystal):
		_collected_crystals.append(crystal)
		_update_goal_lock()
		crystals_changed.emit(_collected_crystals.size(), _total_crystals, require_all_crystals)


func _is_goal_locked() -> bool:
	return require_all_crystals and _total_crystals > 0 and _collected_crystals.size() < _total_crystals


func _update_goal_lock() -> void:
	var locked := _is_goal_locked()
	for node in get_tree().get_nodes_in_group(&"goals"):
		if is_ancestor_of(node):
			(node as Goal).is_locked = locked


func _on_goal_reached() -> void:
	if _completed or _player.is_dead():
		return
	if _is_goal_locked():
		if has_node("/root/SoundManager"):
			get_node("/root/SoundManager").play(AudioSynthesizer.Sound.DENY)
		return
	_completed = true
	_running = false
	_player.freeze(true)
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").call(&"record_completion", scene_file_path.get_file().get_basename(), _elapsed, _deaths)
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play(AudioSynthesizer.Sound.GOAL)
	level_completed.emit(_elapsed, _deaths)


func _setup_neon_backdrop() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.65
	env.glow_bloom = 0.18
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
