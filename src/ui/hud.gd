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
@onready var _medal_label: Label = %MedalLabel
@onready var _medal_reason: Label = %MedalReason
@onready var _btn_next: Button = %BtnNext
@onready var _btn_retry: Button = %BtnRetry
@onready var _btn_menu: Button = %BtnMenu
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
	if _btn_next:
		_btn_next.pressed.connect(_on_next_pressed)
	if _btn_retry:
		_btn_retry.pressed.connect(_on_retry_pressed)
	if _btn_menu:
		_btn_menu.pressed.connect(_on_menu_pressed)


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
	var flip_str := "Arrows (Up/Down/Left/Right)"
	if has_node("/root/InputBootstrap"):
		var ib := get_node("/root/InputBootstrap")
		if ib.current_scheme == ib.ControlScheme.ARROWS_MOVE_WASD_FLIP:
			move_str = "Arrows"
			flip_str = "W/A/S/D"

	var is_tutorial := _level_ref != null and (_level_ref.level_name.to_lower().contains("tutorial") or _level_ref.name.to_lower().contains("tutorial"))
	if is_tutorial:
		var px := _player_node.global_position.x if (_player_node and is_instance_valid(_player_node)) else 0.0
		if px < 900.0:
			_idle_label.text = "TIP: Press [Up Arrow] on ground to walk on the ceiling! (Move: [%s]  ·  Jump: [Space])" % move_str
		elif _level_ref.require_all_crystals:
			_idle_label.text = "TIP: Collect all floating crystals to unlock the Exit! (Touch crystal in air to restore flip)"
		else:
			_idle_label.text = "TIP: Touch crystals in air to restore your flip, or head right to the golden Exit!"
	else:
		_idle_label.text = "TIP: Move: [%s]  ·  Jump: [Space]  ·  Flip Gravity: [%s]  ·  Restart: [R]" % [move_str, flip_str]

	_idle_hint.visible = true


func _on_scheme_changed(scheme_name: String) -> void:
	if _scheme_toast:
		_scheme_toast.text = "Controls: " + scheme_name
		_scheme_toast.visible = true
		_toast_timer = 2.5


func bind(level: Level) -> void:
	_level_ref = level
	_level_name.text = level.level_name
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
	var suffix := ""
	if required:
		suffix = " (EXIT UNLOCKED!)" if collected >= total else " (Exit Locked)"
	else:
		suffix = " (ALL COLLECTED!)" if collected >= total else " (Bonus)"
	_crystals.text = "Crystals: %d / %d%s" % [collected, total, suffix]


func _on_gravity_changed(dir: int) -> void:
	_indicator.direction = dir


func _evaluate_medal(seconds: float, deaths: int) -> Dictionary:
	var gold_time := 25.0
	var silver_time := 45.0

	if deaths == 0 and seconds <= gold_time:
		return {
			"title": "[GOLD MEDAL]",
			"color": Color(1.0, 0.85, 0.2),
			"reason": "Perfect! 0 deaths & finished under 25s (Your time: %.1fs)." % seconds,
		}
	elif deaths <= 1 and seconds <= silver_time:
		var why := ""
		if deaths > 0:
			why = "Silver: %d death(s). Need 0 deaths & time < 25s for Gold." % deaths
		else:
			why = "Silver: time %.1fs. Need under 25s with 0 deaths for Gold." % seconds
		return {
			"title": "[SILVER MEDAL]",
			"color": Color(0.85, 0.88, 0.95),
			"reason": why,
		}
	else:
		var why := "Cleared! Gold requires 0 deaths & time < 25s (You: %d deaths, %.1fs)." % [deaths, seconds]
		return {
			"title": "[BRONZE MEDAL]",
			"color": Color(0.95, 0.65, 0.35),
			"reason": why,
		}


func _on_level_completed(seconds: float, deaths: int, has_next: bool) -> void:
	var medal_info := _evaluate_medal(seconds, deaths)
	_medal_label.text = medal_info["title"]
	_medal_label.set("theme_override_colors/font_color", medal_info["color"])
	_medal_reason.text = medal_info["reason"]
	_stats.text = "Time: %s  ·  Deaths: %d" % [format_time(seconds), deaths]

	if has_next:
		_btn_next.text = "> NEXT LEVEL  (Enter)"
	else:
		_btn_next.text = "> MAIN MENU  (Enter)"

	_complete_panel.visible = true
	_btn_next.grab_focus()


func _on_next_pressed() -> void:
	if _level_ref and not _level_ref.next_level.is_empty():
		get_tree().change_scene_to_file(_level_ref.next_level)
	else:
		get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")


func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")
