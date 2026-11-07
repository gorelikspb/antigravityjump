@tool
class_name Goal
extends RectTrigger
## Level exit. Implements: design/gdd/level-flow.md (Core Rule 2, AC-L3)

signal reached

@export var color: Color = Color(1.0, 0.82, 0.3)
@export var locked_color: Color = Color(0.55, 0.25, 0.35)
@export var pulse_speed: float = 3.0

var is_locked: bool = false:
	set(value):
		is_locked = value
		queue_redraw()

var _t: float = 0.0


func _init() -> void:
	size = Vector2(40, 56)


func _ready() -> void:
	super()
	add_to_group(&"goals")


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _on_player_entered(_player: Player) -> void:
	reached.emit()


func _draw() -> void:
	var c := locked_color if is_locked else color
	var pulse := 0.5 + 0.5 * sin(_t * pulse_speed)
	var fill := c
	fill.a = 0.10 if is_locked else (0.15 + 0.2 * pulse)
	draw_rect(Rect2(Vector2.ZERO, size), fill)
	draw_rect(Rect2(Vector2.ZERO, size), c, false, 3.0)
	if is_locked:
		# Draw lock cross
		draw_line(Vector2(8, 8), size - Vector2(8, 8), c, 2.5)
		draw_line(Vector2(size.x - 8, 8), Vector2(8, size.y - 8), c, 2.5)
	else:
		draw_circle(size * 0.5, 6.0 + 3.0 * pulse, c)
