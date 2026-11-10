extends Node
## Autoload: registers all input actions (keyboard + gamepad) at startup.
## Supports switching between:
##   Scheme 1 (default): WASD to move + Arrow Keys to flip gravity
##   Scheme 2: Arrow Keys to move + WASD to flip gravity
## Press [Tab] anytime to switch schemes!

signal scheme_changed(scheme_name: String)

enum ControlScheme { WASD_MOVE_ARROWS_FLIP, ARROWS_MOVE_WASD_FLIP }

const DEADZONE: float = 0.2

var current_scheme: ControlScheme = ControlScheme.WASD_MOVE_ARROWS_FLIP

const BASE_JOY_BUTTONS: Dictionary = {
	&"jump": [JOY_BUTTON_A],
	&"gravity_up": [JOY_BUTTON_DPAD_UP, JOY_BUTTON_Y],
	&"gravity_down": [JOY_BUTTON_DPAD_DOWN],
	&"gravity_left": [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_LEFT_SHOULDER],
	&"gravity_right": [JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_RIGHT_SHOULDER],
	&"restart": [JOY_BUTTON_BACK],
	&"confirm": [JOY_BUTTON_START],
}

const BASE_JOY_AXES: Dictionary = {
	&"move_left": [JOY_AXIS_LEFT_X, -1.0],
	&"move_right": [JOY_AXIS_LEFT_X, 1.0],
	&"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	&"move_down": [JOY_AXIS_LEFT_Y, 1.0],
}


func _enter_tree() -> void:
	_init_all_actions()
	_apply_keyboard_scheme(current_scheme)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB or event.physical_keycode == KEY_TAB:
			toggle_scheme()
			get_viewport().set_input_as_handled()


func toggle_scheme() -> void:
	if current_scheme == ControlScheme.WASD_MOVE_ARROWS_FLIP:
		current_scheme = ControlScheme.ARROWS_MOVE_WASD_FLIP
	else:
		current_scheme = ControlScheme.WASD_MOVE_ARROWS_FLIP
	_apply_keyboard_scheme(current_scheme)
	var name_str := get_scheme_name()
	scheme_changed.emit(name_str)


func get_scheme_name() -> String:
	if current_scheme == ControlScheme.ARROWS_MOVE_WASD_FLIP:
		return "Move: ARROWS  |  Flip: W/A/S/D"
	return "Move: A / D  |  Flip: ARROWS"


func _init_all_actions() -> void:
	var all_actions: Array[StringName] = [
		&"move_left", &"move_right", &"move_up", &"move_down",
		&"jump", &"gravity_up", &"gravity_down", &"gravity_left", &"gravity_right",
		&"restart", &"confirm", &"menu"
	]
	for action in all_actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action, DEADZONE)

	# Register fixed Gamepad bindings
	for action in BASE_JOY_BUTTONS.keys():
		for button in BASE_JOY_BUTTONS[action]:
			var joy_event := InputEventJoypadButton.new()
			joy_event.button_index = button
			InputMap.action_add_event(action, joy_event)

	for action in BASE_JOY_AXES.keys():
		var motion := InputEventJoypadMotion.new()
		motion.axis = BASE_JOY_AXES[action][0]
		motion.axis_value = BASE_JOY_AXES[action][1]
		InputMap.action_add_event(action, motion)

	# Register fixed utilities
	_add_key_if_missing(&"restart", KEY_R)
	_add_key_if_missing(&"confirm", KEY_ENTER)
	_add_key_if_missing(&"confirm", KEY_KP_ENTER)
	_add_key_if_missing(&"menu", KEY_ESCAPE)


func _apply_keyboard_scheme(scheme: ControlScheme) -> void:
	_clear_action_keys(&"move_left")
	_clear_action_keys(&"move_right")
	_clear_action_keys(&"move_up")
	_clear_action_keys(&"move_down")
	_clear_action_keys(&"jump")
	_clear_action_keys(&"gravity_up")
	_clear_action_keys(&"gravity_down")
	_clear_action_keys(&"gravity_left")
	_clear_action_keys(&"gravity_right")

	if scheme == ControlScheme.ARROWS_MOVE_WASD_FLIP:
		# Arrows Move + WASD Flip
		_add_key(&"move_left", KEY_LEFT)
		_add_key(&"move_right", KEY_RIGHT)
		_add_key(&"move_up", KEY_UP)
		_add_key(&"move_down", KEY_DOWN)
		_add_key(&"jump", KEY_SPACE)
		_add_key(&"jump", KEY_K)
		_add_key(&"gravity_up", KEY_W)
		_add_key(&"gravity_down", KEY_S)
		_add_key(&"gravity_left", KEY_A)
		_add_key(&"gravity_right", KEY_D)
	else:
		# Default: WASD Move + Arrows Flip
		_add_key(&"move_left", KEY_A)
		_add_key(&"move_right", KEY_D)
		_add_key(&"move_up", KEY_W)
		_add_key(&"move_down", KEY_S)
		_add_key(&"jump", KEY_SPACE)
		_add_key(&"jump", KEY_K)
		_add_key(&"gravity_up", KEY_UP)
		_add_key(&"gravity_down", KEY_DOWN)
		_add_key(&"gravity_left", KEY_LEFT)
		_add_key(&"gravity_right", KEY_RIGHT)


func _add_key(action: StringName, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)


func _add_key_if_missing(action: StringName, keycode: Key) -> void:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode == keycode:
			return
	_add_key(action, keycode)


func _clear_action_keys(action: StringName) -> void:
	var events := InputMap.action_get_events(action)
	for ev in events:
		if ev is InputEventKey:
			InputMap.action_erase_event(action, ev)
