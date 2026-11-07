@tool
class_name Goal
extends RectTrigger
## Level exit. Implements: design/gdd/level-flow.md (Core Rule 2, AC-L3)

signal reached

@export var color: Color = Color(1.0, 0.82, 0.3)
@export var pulse_speed: float = 3.0

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
	var pulse := 0.5 + 0.5 * sin(_t * pulse_speed)
	var fill := color
	fill.a = 0.15 + 0.2 * pulse
	draw_rect(Rect2(Vector2.ZERO, size), fill)
	draw_rect(Rect2(Vector2.ZERO, size), color, false, 3.0)
	draw_circle(size * 0.5, 6.0 + 3.0 * pulse, color)
