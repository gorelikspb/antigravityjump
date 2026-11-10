@tool
class_name Block
extends StaticBody2D
## Greybox solid geometry. Node position = TOP-LEFT corner, `size` in px.
## Implements: design/gdd/level-flow.md (Hazards & Gravity Zones -> Block)
## Later replaced/augmented by TileMapLayer (Sprint 2+).

@export var size: Vector2 = Vector2(64, 64):
	set(value):
		size = value.max(Vector2(4, 4))
		_refresh()

@export var color: Color = Color(0.23, 0.26, 0.34):
	set(value):
		color = value
		queue_redraw()

var _shape_node: CollisionShape2D


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	if _shape_node == null:
		_shape_node = CollisionShape2D.new()
		add_child(_shape_node)  # not owned -> never saved into the scene
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape_node.shape = rect
	_shape_node.position = size * 0.5
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, color)
	# Bright neon cyan contour so all walls and floors stand out clearly
	var border_color := Color(0.35, 0.78, 1.0, 0.9)
	draw_rect(r, border_color, false, 3.0)
	if size.x >= 16.0:
		draw_line(Vector2(2, 2), Vector2(size.x - 2, 2), Color(0.85, 0.95, 1.0, 0.95), 2.0)
