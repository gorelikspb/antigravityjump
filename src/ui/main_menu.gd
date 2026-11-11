class_name MainMenu
extends Control
## Main Menu UI script with streamlined stage selection and continue flow.

@onready var _btn_play: Button = %BtnPlay
@onready var _btn_mode: Button = %BtnMode
@onready var _btn_level_0: Button = %BtnLevel0
@onready var _btn_level_1: Button = %BtnLevel1
@onready var _btn_level_2: Button = %BtnLevel2
@onready var _btn_level_3: Button = %BtnLevel3
@onready var _btn_level_4: Button = %BtnLevel4
@onready var _btn_quit: Button = %BtnQuit

const STAGES: Array[Dictionary] = [
	{"id": "level_00_tutorial", "path": "res://src/levels/level_00_tutorial.tscn", "title": "Tutorial: Gravity & Air Flips"},
	{"id": "level_01", "path": "res://src/levels/level_01.tscn", "title": "Stage 1: First Flight (3 Crystals)"},
	{"id": "level_02", "path": "res://src/levels/level_02.tscn", "title": "Stage 2: Ceiling Shift (2 Crystals)"},
	{"id": "level_03", "path": "res://src/levels/level_03.tscn", "title": "Stage 3: Moving Platforms (2 Crystals)"},
	{"id": "level_04", "path": "res://src/levels/level_04.tscn", "title": "Stage 4: The Gauntlet (4 Crystals)"},
]


func _ready() -> void:
	if OS.has_feature("web"):
		_btn_quit.visible = false

	var next_stage_path := "res://src/levels/level_00_tutorial.tscn"
	var next_stage_name := "Tutorial"

	if has_node("/root/SaveManager"):
		var sm := get_node("/root/SaveManager")
		for stage in STAGES:
			if not sm.call(&"is_completed", stage["id"]):
				next_stage_path = stage["path"]
				var parts: PackedStringArray = (stage["title"] as String).split(":")
				next_stage_name = parts[0]
				break

	_btn_play.text = "> PLAY (" + next_stage_name + ")"
	_btn_play.pressed.connect(func() -> void: _load_level(next_stage_path))

	_refresh_mode_button()
	_btn_mode.pressed.connect(_on_toggle_mode)

	_setup_stage_button(_btn_level_0, STAGES[0])
	_setup_stage_button(_btn_level_1, STAGES[1])
	_setup_stage_button(_btn_level_2, STAGES[2])
	_setup_stage_button(_btn_level_3, STAGES[3])
	_setup_stage_button(_btn_level_4, STAGES[4])

	_btn_quit.pressed.connect(func() -> void: get_tree().quit())
	_btn_play.grab_focus()


func _setup_stage_button(btn: Button, stage: Dictionary) -> void:
	var label: String = stage["title"]
	if has_node("/root/SaveManager"):
		var sm := get_node("/root/SaveManager")
		if sm.call(&"is_completed", stage["id"]):
			var t: float = sm.call(&"get_best_time", stage["id"])
			var d: int = sm.call(&"get_best_deaths", stage["id"])
			label += "  [Best: %.2fs | %d deaths]" % [t, d]
	btn.text = label
	btn.pressed.connect(func() -> void: _load_level(stage["path"]))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_0 or event.keycode == KEY_KP_0:
			_load_level("res://src/levels/level_00_tutorial.tscn")
		elif event.keycode == KEY_1 or event.keycode == KEY_KP_1:
			_load_level("res://src/levels/level_01.tscn")
		elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
			_load_level("res://src/levels/level_02.tscn")
		elif event.keycode == KEY_3 or event.keycode == KEY_KP_3:
			_load_level("res://src/levels/level_03.tscn")
		elif event.keycode == KEY_4 or event.keycode == KEY_KP_4:
			_load_level("res://src/levels/level_04.tscn")


func _load_level(path: String) -> void:
	get_tree().change_scene_to_file(path)


func _on_toggle_mode() -> void:
	if has_node("/root/SaveManager"):
		var sm := get_node("/root/SaveManager")
		var curr := bool(sm.call(&"get_require_all_crystals"))
		sm.call(&"set_require_all_crystals", not curr)
	_refresh_mode_button()


func _refresh_mode_button() -> void:
	var hard := false
	if has_node("/root/SaveManager"):
		hard = bool(get_node("/root/SaveManager").call(&"get_require_all_crystals"))
	if hard:
		_btn_mode.text = "Difficulty: HARD (All Crystals Required to Unlock Exit)"
		_btn_mode.set("theme_override_colors/font_color", Color(1.0, 0.72, 0.3))
	else:
		_btn_mode.text = "Difficulty: NORMAL (Open Exit · Crystals Optional)"
		_btn_mode.set("theme_override_colors/font_color", Color(0.31, 0.86, 1.0))
