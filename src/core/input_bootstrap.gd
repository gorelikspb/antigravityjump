extends Node
## Autoload: registers all input actions (keyboard + gamepad) at startup.
## Holds NO game state (allowed singleton per docs/architecture/architecture-overview.md).
## Actions already defined in Project Settings are left untouched, so designers can rebind there.

const DEADZONE: float = 0.2

const KEYS: Dictionary = {
	&"move_left": [KEY_A],
	&"move_right": [KEY_D],
	&"move_up": [KEY_W],
	&"move_down": [KEY_S],
	&"jump": [KEY_SPACE, KEY_K],
	&"gravity_up": [KEY_UP],
	&"gravity_down": [KEY_DOWN],
	&"gravity_left": [KEY_LEFT],
	&"gravity_right": [KEY_RIGHT],
	&"restart": [KEY_R],
	&"confirm": [KEY_ENTER, KEY_KP_ENTER],
}

const JOY_BUTTONS: Dictionary = {
	&"jump": [JOY_BUTTON_A],
	&"gravity_up": [JOY_BUTTON_DPAD_UP, JOY_BUTTON_Y],
	&"gravity_down": [JOY_BUTTON_DPAD_DOWN],
	&"gravity_left": [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_LEFT_SHOULDER],
	&"gravity_right": [JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_RIGHT_SHOULDER],
	&"restart": [JOY_BUTTON_BACK],
	&"confirm": [JOY_BUTTON_START],
}

## action -> [axis, direction sign]
const JOY_AXES: Dictionary = {
	&"move_left": [JOY_AXIS_LEFT_X, -1.0],
	&"move_right": [JOY_AXIS_LEFT_X, 1.0],
	&"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	&"move_down": [JOY_AXIS_LEFT_Y, 1.0],
}


func _enter_tree() -> void:
	var actions: Array = KEYS.keys()
	for action in JOY_BUTTONS.keys() + JOY_AXES.keys():
		if not actions.has(action):
			actions.append(action)

	for action in actions:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, DEADZONE)
		for keycode in KEYS.get(action, []):
			var key_event := InputEventKey.new()
			key_event.physical_keycode = keycode
			InputMap.action_add_event(action, key_event)
		for button in JOY_BUTTONS.get(action, []):
			var joy_event := InputEventJoypadButton.new()
			joy_event.button_index = button
			InputMap.action_add_event(action, joy_event)
		if JOY_AXES.has(action):
			var motion := InputEventJoypadMotion.new()
			motion.axis = JOY_AXES[action][0]
			motion.axis_value = JOY_AXES[action][1]
			InputMap.action_add_event(action, motion)
