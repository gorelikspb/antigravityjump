extends SceneTree
## QA bot: drives Level 01 with simulated input and verifies acceptance criteria end-to-end.
## Usage (project root):
##   godot --headless --fixed-fps 60 -s res://tests/integration/level_01_bot.gd -- --scenario=solve
## Scenarios:
##   solve       â€” full intended route using all 4 gravity directions, 0 deaths (level-01 AC, AC-G1/G2, AC-L3)
##   pit         â€” walk into the pit without flipping: death + respawn at spawn (AC-L1)
##   checkpoint  â€” after checkpoint, flip UP into ceiling spikes: respawn at checkpoint (AC-L2, AC-G5)

const LEVEL_PATH := "res://src/levels/level_01.tscn"
const TIMEOUT_SECONDS := 30.0
const D := GravityMath.Dir

var scenario: String = "solve"
var level: Level
var player: Player
var phase: int = 0
var elapsed: float = 0.0
var completed: bool = false
var completion: Dictionary = {}
var deaths: int = 0
var _to_release: Array[StringName] = []
var _held: Dictionary = {}  # action -> frames left
var _wait: float = 0.0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scenario="):
			scenario = arg.get_slice("=", 1)
	if not InputMap.has_action(&"jump"):
		root.add_child(load("res://src/core/input_bootstrap.gd").new())
	level = load(LEVEL_PATH).instantiate()
	root.add_child(level)
	player = level.get_node(^"Player")
	level.level_completed.connect(func(t: float, d: int) -> void:
		completed = true
		completion = {"time": t, "deaths": d})
	level.deaths_changed.connect(func(c: int) -> void: deaths = c)
	print("[bot] scenario=%s" % scenario)


func _physics_process(delta: float) -> bool:
	for a in _to_release:
		Input.action_release(a)
	_to_release.clear()
	for a in _held.keys():
		_held[a] -= 1
		if _held[a] <= 0:
			Input.action_release(a)
			_held.erase(a)

	elapsed += delta
	if elapsed > TIMEOUT_SECONDS:
		return _finish(false, "timeout in phase %d at %s (gravity %s)" % [
			phase, player.global_position.round(), GravityMath.dir_name(player.gravity_dir)])

	match scenario:
		"solve":
			return _solve()
		"pit":
			return _pit()
		"checkpoint":
			return _checkpoint()
	return _finish(false, "unknown scenario")


func _solve() -> bool:
	var p := player.global_position
	match phase:
		0:  # run right, hop the step, flip UP before the pit
			Input.action_press(&"move_right")
			if p.x >= 345.0 and p.x < 380.0 and player.is_on_floor():
				_hold(&"jump", 20)
			if p.x >= 700.0 and player.is_on_floor():
				_tap(&"gravity_up")
				phase = 1
		1:  # ride the ceiling; the safety zone forces gravity DOWN past x=1120
			if player.gravity_dir == D.UP and player.is_on_floor() and p.x < 1100.0:
				pass  # on ceiling, keep running
			if player.gravity_dir == D.DOWN and player.is_on_floor() and p.x > 1120.0:
				phase = 2
		2:  # enter the chamber under the left wall, jump
			if p.x >= 1700.0 and player.is_on_floor():
				_hold(&"jump", 20)
				phase = 3
		3:  # at apex: air-flip LEFT onto the wall face
			if player.velocity.y >= 0.0 and not player.is_on_floor():
				Input.action_release(&"move_right")
				_tap(&"gravity_left")
				phase = 4
		4:  # landed on the wall: walk up
			if player.gravity_dir == D.LEFT and player.is_on_floor():
				Input.action_press(&"move_up")
				phase = 5
		5:  # above the ledge: flip RIGHT and fall into the goal
			if p.y < 225.0:
				Input.action_release(&"move_up")
				_tap(&"gravity_right")
				phase = 6
		6:
			pass
	if completed:
		var ok: bool = completion["deaths"] == 0
		return _finish(ok, "completed in %.2fs, deaths=%d" % [completion["time"], completion["deaths"]])
	if deaths > 0:
		return _finish(false, "died in phase %d at %s" % [phase, p.round()])
	return false


func _pit() -> bool:
	var p := player.global_position
	match phase:
		0:
			Input.action_press(&"move_right")
			if p.x >= 345.0 and p.x < 380.0 and player.is_on_floor():
				_hold(&"jump", 20)
			if deaths == 1:
				Input.action_release(&"move_right")
				phase = 1
				_wait = 0.0
		1:
			_wait += 1.0 / 60.0
			if _wait > 0.6:
				var ok := not player.is_dead() and p.distance_to(Vector2(100, 628)) < 16.0
				return _finish(ok, "deaths=%d, respawned at %s" % [deaths, p.round()])
	return false


func _checkpoint() -> bool:
	var p := player.global_position
	match phase:
		0:  # same route as solve up to the floor past the safety zone
			Input.action_press(&"move_right")
			if p.x >= 345.0 and p.x < 380.0 and player.is_on_floor():
				_hold(&"jump", 20)
			if p.x >= 700.0 and player.is_on_floor() and player.gravity_dir == D.DOWN and p.x < 800.0:
				_tap(&"gravity_up")
			if player.gravity_dir == D.DOWN and player.is_on_floor() and p.x > 1300.0:
				phase = 1
		1:  # left of the ledge: flip UP into the ceiling spikes
			if p.x >= 1720.0 and player.is_on_floor():
				Input.action_release(&"move_right")
				_tap(&"gravity_up")
				phase = 2
		2:
			if deaths == 1:
				phase = 3
				_wait = 0.0
		3:
			_wait += 1.0 / 60.0
			if _wait > 0.6:
				var ok := p.distance_to(Vector2(1260, 628)) < 16.0 and player.gravity_dir == D.DOWN
				return _finish(ok, "respawned at %s, gravity %s" % [p.round(), GravityMath.dir_name(player.gravity_dir)])
	return false


func _tap(action: StringName) -> void:
	Input.action_press(action)
	_to_release.append(action)


func _hold(action: StringName, frames: int) -> void:
	Input.action_press(action)
	_held[action] = frames


func _finish(ok: bool, msg: String) -> bool:
	print("[bot] %s: %s" % ["PASS" if ok else "FAIL", msg])
	quit(0 if ok else 1)
	return true
