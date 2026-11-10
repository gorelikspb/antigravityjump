class_name HUD
extends CanvasLayer
## In-level HUD. Listens ONLY to Level signals (injected via bind()).
## Tracks player idle time (shows hint after 3.5s of inactivity) and HUD stats.

@onready var _level_name: Label = %LevelName
@onready var _timer: Label = %TimerLabel
@onready var _deaths: Label = %DeathsLabel
@onready var _crystals: Label = %CrystalsLabel
@onready var _indicator: GravityIndicator = %GravityIndicator
@onready var _complete_panel: Control = %CompletePanel
@onready var _stats: Label = %StatsLabel
@onready var _prompt: Label = %PromptLabel
@onready var _idle_hint: Control = %IdleHint
@onready var _idle_label: Label = %IdleLabel
@onready var _scheme_toast: Label = %SchemeToast

var _idle_time: float = 0.0
const IDLE_THRESHOLD: float = 3.5
var _toast_timer: float = 0.0
var _level_ref: Level = null
var _player_node: CharacterBody2D = null
var _last_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	if has_node("/root/InputBootstrap"):
		var ib := get_node("/root/InputBootstrap")
		ib.scheme_changed.connect(_on_scheme_changed)


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0 and _scheme_toast:
			_scheme_toast.visible = false

	var player_moved := false
	if _player_node and is_instance_valid(_player_node):
		var cur_pos := _player_node.global_position
		if cur_pos.distance_to(_last_pos) > 2.0:
			player_moved = true
		_last_pos = cur_pos

	var has_input := _has_any_input()
	if has_input or player_moved:
		_idle_time = 0.0
		if _idle_hint and _idle_hint.visible:
			_idle_hint.visible = false
	else:
		_idle_time += delta
		if _idle_time >= IDLE_THRESHOLD and _idle_hint and not _idle_hint.visible and not _complete_panel.visible:
			_show_idle_hint()


func _has_any_input() -> bool:
	return Input.is_action_pressed(&"move_left") or Input.is_action_pressed(&"move_right") \
		or Input.is_action_pressed(&"move_up") or Input.is_action_pressed(&"move_down") \
		or Input.is_action_pressed(&"jump") \
		or Input.is_action_pressed(&"gravity_up") or Input.is_action_pressed(&"gravity_down") \
		or Input.is_action_pressed(&"gravity_left") or Input.is_action_pressed(&"gravity_right") \
		or Input.is_action_pressed(&"restart") or Input.is_action_pressed(&"menu")


func _show_idle_hint() -> void:
	var move_str := "A / D"
	var flip_str := "Arrows (↑ ↓ ← →)"
	if has_node("/root/InputBootstrap"):
		var ib := get_node("/root/InputBootstrap")
		if ib.current_scheme == ib.ControlScheme.ARROWS_MOVE_WASD_FLIP:
			move_str = "Arrows"
			flip_str = "W/A/S/D"

	var is_tutorial := _level_ref != null and (_level_ref.level_name.to_lower().contains("tutorial") or _level_ref.name.to_lower().contains("tutorial"))
	if is_tutorial:
		var px := _player_node.global_position.x if (_player_node and is_instance_valid(_player_node)) else 0.0
		if px < 900.0:
			_idle_label.text = "💡 Stuck? Press [Up Arrow] on ground to walk on the ceiling! (Move: [%s]  ·  Jump: [Space])" % move_str
		else:
			_idle_label.text = "💡 Collect all floating crystals to unlock the Exit! (Touch crystal in air to restore flip)"
	else:
		_idle_label.text = "💡 Move: [%s]  ·  Jump: [Space]  ·  Flip Gravity: [%s]  ·  Restart: [R]" % [move_str, flip_str]

	_idle_hint.visible = true


func _on_scheme_changed(scheme_name: String) -> void:
	if _scheme_toast:
		_scheme_toast.text = "Controls: " + scheme_name
		_scheme_toast.visible = true
		_toast_timer = 2.5


func bind(level: Level) -> void:
	_level_ref = level
	_player_node = level.get_node_or_null("Player") as CharacterBody2D
	if _player_node:
		_last_pos = _player_node.global_position
	_complete_panel.visible = false
	level.timer_updated.connect(_on_timer_updated)
	level.deaths_changed.connect(_on_deaths_changed)
	level.crystals_changed.connect(_on_crystals_changed)
	level.gravity_changed.connect(_on_gravity_changed)
	level.air_charges_changed.connect(_indicator.set_charges)
	level.flip_denied.connect(_indicator.flash_denied)
	level.level_completed.connect(_on_level_completed.bind(not level.next_level.is_empty()))


static func format_time(seconds: float) -> String:
	var total := maxf(seconds, 0.0)
	var minutes := int(total / 60.0)
	return "%02d:%05.2f" % [minutes, total - minutes * 60.0]


func _on_timer_updated(seconds: float) -> void:
	_timer.text = format_time(seconds)


func _on_deaths_changed(count: int) -> void:
	_deaths.text = "Deaths: %d" % count


func _on_crystals_changed(collected: int, total: int, required: bool) -> void:
	if total <= 0:
		_crystals.visible = false
		return
	_crystals.visible = true
	var suffix := " (EXIT UNLOCKED!)" if (required and collected >= total) else (" (Exit Locked)" if required else "")
	_crystals.text = "Crystals: %d / %d%s" % [collected, total, suffix]


func _on_gravity_changed(dir: int) -> void:
	_indicator.direction = dir


func _on_level_completed(seconds: float, deaths: int, has_next: bool) -> void:
	var medal := "[GOLD MEDAL]" if (deaths == 0 and seconds <= 25.0) else ("[SILVER MEDAL]" if seconds <= 45.0 else "[BRONZE MEDAL]")
	_stats.text = "Rank  %s\nTime  %s\nDeaths  %d" % [medal, format_time(seconds), deaths]
	_prompt.text = ("[Enter] Next Level" if has_next else "[Enter] Main Menu") + "   ·   [R] Restart   ·   [Esc] Menu"
	_complete_panel.visible = true
