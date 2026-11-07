class_name MainMenu
extends Control
## Main Menu UI script. Implements level selection for 0 through 4 and quit.

@onready var _btn_level_0: Button = %BtnLevel0
@onready var _btn_level_1: Button = %BtnLevel1
@onready var _btn_level_2: Button = %BtnLevel2
@onready var _btn_level_3: Button = %BtnLevel3
@onready var _btn_level_4: Button = %BtnLevel4
@onready var _btn_quit: Button = %BtnQuit


func _ready() -> void:
	_btn_level_0.pressed.connect(func() -> void: _load_level("res://src/levels/level_00_tutorial.tscn"))
	_btn_level_1.pressed.connect(func() -> void: _load_level("res://src/levels/level_01.tscn"))
	_btn_level_2.pressed.connect(func() -> void: _load_level("res://src/levels/level_02.tscn"))
	_btn_level_3.pressed.connect(func() -> void: _load_level("res://src/levels/level_03.tscn"))
	_btn_level_4.pressed.connect(func() -> void: _load_level("res://src/levels/level_04.tscn"))
	_btn_quit.pressed.connect(func() -> void: get_tree().quit())
	_decorate_button(_btn_level_0, "level_00_tutorial")
	_decorate_button(_btn_level_1, "level_01")
	_decorate_button(_btn_level_2, "level_02")
	_decorate_button(_btn_level_3, "level_03")
	_decorate_button(_btn_level_4, "level_04")
	_btn_level_0.grab_focus()


func _decorate_button(btn: Button, level_id: String) -> void:
	if not has_node("/root/SaveManager"):
		return
	var sm := get_node("/root/SaveManager")
	if sm.call(&"is_completed", level_id):
		var t: float = sm.call(&"get_best_time", level_id)
		var d: int = sm.call(&"get_best_deaths", level_id)
		btn.text += "   ✓ Best: %.2fs (%d deaths)" % [t, d]


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
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_load_level("res://src/levels/level_00_tutorial.tscn")


func _load_level(path: String) -> void:
	get_tree().change_scene_to_file(path)
