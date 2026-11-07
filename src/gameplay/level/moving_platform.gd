@tool
class_name MovingPlatform
extends AnimatableBody2D
## Greybox moving platform. Implements: design/gdd/level-flow.md

@export var size: Vector2 = Vector2(128, 24):
	set(value):
		size = value.max(Vector2(4, 4))
		_refresh()

@export var travel_offset: Vector2 = Vector2(240, 0):
	set(value):
		travel_offset = value
		queue_redraw()

@export var duration: float = 2.2
@export var color: Color = Color(0.32, 0.55, 0.72):
	set(value):
		color = value
		queue_redraw()

var _shape_node: CollisionShape2D
var _start_pos: Vector2 = Vector2.ZERO
var _t: float = 0.0


func _ready() -> void:
	_refresh()
	_start_pos = position


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if duration > 0.0:
		_t += delta
		var alpha: float = 0.5 - 0.5 * cos(_t * TAU / duration)
		position = _start_pos + travel_offset * alpha


func _refresh() -> void:
	if not is_node_ready():
		return
	if _shape_node == null:
		_shape_node = CollisionShape2D.new()
		add_child(_shape_node)
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape_node.shape = rect
	_shape_node.position = size * 0.5
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, color)
	draw_rect(r, color.lightened(0.35), false, 2.0)
	if Engine.is_editor_hint():
		# Draw line from platform center to destination center
		var center := size * 0.5
		draw_line(center, center + travel_offset, Color(1, 1, 1, 0.3), 2.0, true)
