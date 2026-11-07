@tool
class_name Spikes
extends RectTrigger
## Instant-death hazard. Implements: design/gdd/level-flow.md (Hazards: Spikes, AC-L1)

enum Facing { UP, DOWN, LEFT, RIGHT }

@export var facing: Facing = Facing.UP:
	set(value):
		facing = value
		queue_redraw()

## Approximate width of a single spike tooth (visual only).
@export var tooth_size: float = 16.0:
	set(value):
		tooth_size = maxf(value, 4.0)
		queue_redraw()

@export var color: Color = Color(0.95, 0.3, 0.35):
	set(value):
		color = value
		queue_redraw()


func _init() -> void:
	hitbox_inset = 4.0


func _on_player_entered(player: Player) -> void:
	player.kill()


func _draw() -> void:
	var horizontal := facing == Facing.UP or facing == Facing.DOWN
	var length := size.x if horizontal else size.y
	var count := maxi(1, roundi(length / tooth_size))
	var step := length / count
	for i in count:
		var a := i * step
		var b := a + step
		var mid := (a + b) * 0.5
		var pts: PackedVector2Array
		match facing:
			Facing.UP:
				pts = [Vector2(a, size.y), Vector2(b, size.y), Vector2(mid, 0)]
			Facing.DOWN:
				pts = [Vector2(a, 0), Vector2(b, 0), Vector2(mid, size.y)]
			Facing.LEFT:
				pts = [Vector2(size.x, a), Vector2(size.x, b), Vector2(0, mid)]
			Facing.RIGHT:
				pts = [Vector2(0, a), Vector2(0, b), Vector2(size.x, mid)]
		draw_colored_polygon(pts, color)
