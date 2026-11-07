@tool
class_name GravityIndicator
extends Control
## HUD widget: current gravity arrow + air-charge dots + "flip denied" flash.
## Implements: design/gdd/level-flow.md (UI Requirements), design/gdd/gravity-system.md (P3 readability)

@export var ring_color: Color = Color(1, 1, 1, 0.35)
@export var arrow_color: Color = Color(0.31, 0.86, 1)
@export var charge_color: Color = Color(1.0, 0.82, 0.3)
@export var empty_color: Color = Color(1, 1, 1, 0.2)
@export var deny_color: Color = Color(0.95, 0.3, 0.35)
@export var deny_fade_speed: float = 3.0

var direction: int = GravityMath.Dir.DOWN:
	set(value):
		direction = value
		queue_redraw()

var charges: int = 1
var max_charges: int = 1

var _deny_flash: float = 0.0


func set_charges(value: int, maximum: int) -> void:
	charges = value
	max_charges = maximum
	queue_redraw()


func flash_denied() -> void:
	_deny_flash = 1.0
	queue_redraw()


func _process(delta: float) -> void:
	if _deny_flash > 0.0:
		_deny_flash = maxf(_deny_flash - delta * deny_fade_speed, 0.0)
		queue_redraw()


func _draw() -> void:
	var radius := minf(size.x, size.y) * 0.32
	var center := Vector2(size.x * 0.5, radius + 4.0)
	var ring := ring_color.lerp(deny_color, _deny_flash)
	draw_arc(center, radius, 0.0, TAU, 48, ring, 3.0)

	# Arrow authored pointing DOWN, rotated to gravity.
	var s := radius / 30.0
	var arrow := PackedVector2Array([
		Vector2(-5, -20), Vector2(5, -20), Vector2(5, 0), Vector2(13, 0),
		Vector2(0, 20), Vector2(-13, 0), Vector2(-5, 0),
	])
	var angle := GravityMath.visual_rotation(direction)
	var pts := PackedVector2Array()
	for p in arrow:
		pts.append(center + (p * s).rotated(angle))
	draw_colored_polygon(pts, arrow_color.lerp(deny_color, _deny_flash))

	# Air-charge dots.
	var dot_r := 5.0
	var gap := 16.0
	var total := maxi(max_charges, 0)
	var start_x := size.x * 0.5 - (total - 1) * gap * 0.5
	var y := center.y + radius + 14.0
	for i in total:
		var c := charge_color if i < charges else empty_color
		draw_circle(Vector2(start_x + i * gap, y), dot_r, c)
