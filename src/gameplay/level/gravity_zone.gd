@tool
class_name GravityZone
extends RectTrigger
## Forces gravity on enter (free, refills air charges).
## Implements: design/gdd/gravity-system.md (Core Rule 8, AC-G4), design/gdd/level-flow.md

@export var direction: GravityMath.Dir = GravityMath.Dir.DOWN:
	set(value):
		direction = value
		queue_redraw()

@export var color: Color = Color(0.55, 0.45, 1.0):
	set(value):
		color = value
		queue_redraw()

## Spacing between chevrons (visual only).
@export var chevron_spacing: float = 48.0


func _on_player_entered(player: Player) -> void:
	player.set_gravity(direction, true)


func _draw() -> void:
	var fill := color
	fill.a = 0.12
	draw_rect(Rect2(Vector2.ZERO, size), fill)
	var edge := color
	edge.a = 0.5
	draw_rect(Rect2(Vector2.ZERO, size), edge, false, 2.0)

	var angle := GravityMath.visual_rotation(direction)
	var chevron := PackedVector2Array([Vector2(-10, -4), Vector2(0, 6), Vector2(10, -4)])
	var spacing := maxf(chevron_spacing, 16.0)
	var cols := maxi(1, int(size.x / spacing))
	var rows := maxi(1, int(size.y / spacing))
	for cx in cols:
		for cy in rows:
			var center := Vector2((cx + 0.5) * size.x / cols, (cy + 0.5) * size.y / rows)
			var pts := PackedVector2Array()
			for p in chevron:
				pts.append(center + p.rotated(angle))
			draw_polyline(pts, edge, 3.0)
