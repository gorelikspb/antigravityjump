@tool
class_name Checkpoint
extends RectTrigger
## Respawn point; stores the player's gravity at activation (Level reads it).
## Implements: design/gdd/level-flow.md (Core Rule 4, AC-L2)

signal activated(respawn_position: Vector2)

## Distance from the bottom edge of the trigger to the player's respawn center.
@export var respawn_height: float = 12.0
## Height of the drawn flag at the bottom of the trigger (visual only).
@export var flag_height: float = 64.0

@export var inactive_color: Color = Color(0.55, 0.58, 0.65)
@export var active_color: Color = Color(0.35, 1.0, 0.55)

var is_active: bool = false


func _init() -> void:
	size = Vector2(32, 64)


func _ready() -> void:
	super()
	add_to_group(&"checkpoints")


func get_respawn_position() -> Vector2:
	return global_position + Vector2(size.x * 0.5, size.y - respawn_height)


func _on_player_entered(_player: Player) -> void:
	if is_active:
		return
	is_active = true
	queue_redraw()
	activated.emit(get_respawn_position())


func _draw() -> void:
	var c := active_color if is_active else inactive_color
	# Trigger may be a tall column (so falling players can't miss it); the flag sits at the bottom.
	var column := c
	column.a = 0.06
	draw_rect(Rect2(Vector2.ZERO, size), column)
	var pole_x := size.x * 0.5
	var top := maxf(size.y - flag_height, 0.0)
	draw_line(Vector2(pole_x, top), Vector2(pole_x, size.y), c, 3.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(pole_x, top + 2), Vector2(pole_x + size.x * 0.5, top + 10), Vector2(pole_x, top + 18)
	]), c)
