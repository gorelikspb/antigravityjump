@tool
class_name GravityMath
extends RefCounted
## Pure, stateless gravity-direction math. No game state lives here.
## Implements: design/gdd/gravity-system.md (Formulas), design/gdd/player-movement.md (Formulas)
## Architecture: docs/architecture/ADR-0001-custom-player-gravity.md
## Marked @tool so editor-side greybox scripts (GravityZone, HUD indicator) can call it.

enum Dir { DOWN, UP, LEFT, RIGHT }

const ALL_DIRS: Array[int] = [Dir.DOWN, Dir.UP, Dir.LEFT, Dir.RIGHT]

## Input action that sets each absolute gravity direction (registered by InputBootstrap).
const FLIP_ACTIONS: Dictionary = {
	Dir.DOWN: &"gravity_down",
	Dir.UP: &"gravity_up",
	Dir.LEFT: &"gravity_left",
	Dir.RIGHT: &"gravity_right",
}


## Unit vector pointing "down" for the given gravity direction (screen space, +Y is down).
static func to_vector(dir: int) -> Vector2:
	match dir:
		Dir.UP:
			return Vector2.UP
		Dir.LEFT:
			return Vector2.LEFT
		Dir.RIGHT:
			return Vector2.RIGHT
		_:
			return Vector2.DOWN


## Nearest cardinal direction for an arbitrary vector. Zero vector -> DOWN.
static func from_vector(v: Vector2) -> int:
	if v == Vector2.ZERO:
		return Dir.DOWN
	if absf(v.x) > absf(v.y):
		return Dir.RIGHT if v.x > 0.0 else Dir.LEFT
	return Dir.DOWN if v.y > 0.0 else Dir.UP


## "up_direction" for CharacterBody2D: opposite of gravity.
static func up_vector(dir: int) -> Vector2:
	return -to_vector(dir)


## Screen-relative movement axis (GDD player-movement, rule 1):
## horizontal for DOWN/UP gravity, vertical for LEFT/RIGHT gravity.
## The sign is fixed in screen space so controls never invert on ceilings/walls.
static func tangent_axis(dir: int) -> Vector2:
	if dir == Dir.LEFT or dir == Dir.RIGHT:
		return Vector2.DOWN
	return Vector2.RIGHT


## Splits a world velocity into (tangent, normal) components.
## x = speed along tangent_axis, y = speed along gravity (positive = falling).
static func split_velocity(velocity: Vector2, dir: int) -> Vector2:
	return Vector2(velocity.dot(tangent_axis(dir)), velocity.dot(to_vector(dir)))


## Inverse of split_velocity.
static func compose_velocity(tangent_speed: float, normal_speed: float, dir: int) -> Vector2:
	return tangent_axis(dir) * tangent_speed + to_vector(dir) * normal_speed


## Rotation (radians) that turns a sprite authored "feet down" so its feet face gravity.
static func visual_rotation(dir: int) -> float:
	match dir:
		Dir.UP:
			return PI
		Dir.LEFT:
			return PI * 0.5
		Dir.RIGHT:
			return -PI * 0.5
		_:
			return 0.0


static func is_opposite(a: int, b: int) -> bool:
	return to_vector(a) + to_vector(b) == Vector2.ZERO


static func dir_name(dir: int) -> String:
	match dir:
		Dir.UP:
			return "UP"
		Dir.LEFT:
			return "LEFT"
		Dir.RIGHT:
			return "RIGHT"
		_:
			return "DOWN"


## Peak jump height in px: h = v^2 / (2g).
static func jump_height(jump_velocity: float, gravity_strength: float) -> float:
	if gravity_strength <= 0.0:
		return INF
	return jump_velocity * jump_velocity / (2.0 * gravity_strength)


## Flat-ground air time in seconds: t = 2v / g.
static func air_time(jump_velocity: float, gravity_strength: float) -> float:
	if gravity_strength <= 0.0:
		return INF
	return 2.0 * jump_velocity / gravity_strength
