class_name MainMenu
extends Control
## Main Menu UI script. Implements: design/gdd/level-flow.md (UI Requirements)

@onready var _btn_level_1: Button = %BtnLevel1
@onready var _btn_level_2: Button = %BtnLevel2
@onready var _btn_level_3: Button = %BtnLevel3
@onready var _btn_quit: Button = %BtnQuit


func _ready() -> void:
	_btn_level_1.pressed.connect(func() -> void: _load_level("res://src/levels/level_01.tscn"))
	_btn_level_2.pressed.connect(func() -> void: _load_level("res://src/levels/level_02.tscn"))
	_btn_level_3.pressed.connect(func() -> void: _load_level("res://src/levels/level_03.tscn"))
	_btn_quit.pressed.connect(func() -> void: get_tree().quit())
	_btn_level_1.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1 or event.keycode == KEY_KP_1:
			_load_level("res://src/levels/level_01.tscn")
		elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
			_load_level("res://src/levels/level_02.tscn")
		elif event.keycode == KEY_3 or event.keycode == KEY_KP_3:
			_load_level("res://src/levels/level_03.tscn")
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_load_level("res://src/levels/level_01.tscn")


func _load_level(path: String) -> void:
	get_tree().change_scene_to_file(path)
