extends SceneTree
## QA bot: drives Level 02 with simulated input and verifies acceptance criteria end-to-end.
## Usage (project root):
##   godot --headless --fixed-fps 60 -s res://tests/integration/level_02_bot.gd -- --scenario=solve

const LEVEL_PATH := "res://src/levels/level_02.tscn"
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
var crystals_collected: int = 0
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
	
	var pickups := level.get_node_or_null(^"Pickups")
	if pickups:
		for c in pickups.get_children():
			if c.has_signal(&"collected"):
				c.collected.connect(func() -> void:
					crystals_collected += 1
				)
	
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
		return _finish(false, "timeout in phase %d at %s (gravity %s, crystals %d/2)" % [
			phase, player.global_position.round(), GravityMath.dir_name(player.gravity_dir), crystals_collected])

	match scenario:
		"solve":
			return _solve()
	return _finish(false, "unknown scenario")


func _solve() -> bool:
	var p := player.global_position
	match phase:
		0:  # Start on floor: run right, flip UP before pit spikes (x=320)
			Input.action_press(&"move_right")
			if p.x >= 200.0 and player.is_on_floor():
				_tap(&"gravity_up")
				phase = 1
				print("[bot] Phase 0 -> 1: flipped UP at %s" % p.round())
		1:  # Rising to ceiling, land on ceiling
			if player.gravity_dir == D.UP and player.is_on_floor():
				phase = 2
				print("[bot] Phase 1 -> 2: landed on ceiling at %s" % p.round())
		2:  # Running right on ceiling towards chasm crystal
			# Ceiling spikes are at x=640..880. Flip DOWN at x >= 560
			if p.x >= 560.0:
				_tap(&"gravity_down")
				phase = 3
				print("[bot] Phase 2 -> 3: flipped DOWN at %s" % p.round())
		3:  # Falling toward CrystalChasm (704, 360). When crystal collected or near x=735, flip UP
			if crystals_collected >= 1 or p.x >= 735.0:
				_tap(&"gravity_up")
				phase = 4
				print("[bot] Phase 3 -> 4: flipped UP at %s (crystals: %d)" % [p.round(), crystals_collected])
		4:  # Flying up to ceiling past spikes (x=640..880), landing on ceiling
			if player.gravity_dir == D.UP and player.is_on_floor() and p.x > 880.0:
				phase = 5
				print("[bot] Phase 4 -> 5: landed on ceiling at %s" % p.round())
		5:  # Run right on ceiling over central pillar (x=1440..1504) to x=1520, then jump down
			if p.x >= 1520.0 and player.is_on_floor():
				Input.action_release(&"move_right")
				_hold(&"jump", 20)
				phase = 6
				print("[bot] Phase 5 -> 6: jumped DOWN from ceiling at %s" % p.round())
		6:  # Airborne moving down through gap. Wait until y reaches beside pillar (y >= 165)
			if p.y >= 165.0:
				_tap(&"gravity_left")
				phase = 7
				print("[bot] Phase 6 -> 7: flipped LEFT onto pillar at %s" % p.round())
		7:  # Land on right face of CentralPillar (x=1504), walk down
			if player.gravity_dir == D.LEFT and player.is_on_floor():
				Input.action_press(&"move_down")
				phase = 8
				print("[bot] Phase 7 -> 8: landed on pillar at %s" % p.round())
		8:  # Walk down pillar to y=310, jump right towards crystal (1580, 320)
			if p.y >= 310.0:
				Input.action_release(&"move_down")
				_hold(&"jump", 20)
				phase = 9
				print("[bot] Phase 8 -> 9: jumping right towards crystal at %s" % p.round())
		9:  # In mid-air reaching crystal / apex: flip RIGHT towards ledge and goal
			if crystals_collected >= 2 or p.x >= 1585.0:
				_tap(&"gravity_right")
				phase = 10
				print("[bot] Phase 9 -> 10: flipped RIGHT at %s (crystals: %d)" % [p.round(), crystals_collected])
		10:
			pass

	if completed:
		var ok: bool = completion["deaths"] == 0 and crystals_collected >= 2
		return _finish(ok, "completed in %.2fs, deaths=%d, crystals=%d/2" % [completion["time"], completion["deaths"], crystals_collected])
	if deaths > 0:
		return _finish(false, "died in phase %d at %s" % [phase, p.round()])
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
