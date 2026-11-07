@tool
class_name RechargeCrystal
extends RectTrigger
## Air-charge refill pickup in mid-air.
## Implements: design/gdd/level-flow.md (Level Elements -> RechargeCrystal)

signal collected

@export var respawn_time: float = 2.5
@export var always_consume: bool = false
@export var color: Color = Color(0.2, 0.85, 1.0)
@export var inactive_color: Color = Color(0.2, 0.85, 1.0, 0.25)

var is_active: bool = true
var _timer: float = 0.0
var _pulse_t: float = 0.0


func _init() -> void:
	size = Vector2(32, 32)


func _ready() -> void:
	super()
	add_to_group(&"crystals")


func reset() -> void:
	is_active = true
	_timer = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	_pulse_t += delta
	if not is_active:
		_timer -= delta
		if _timer <= 0.0:
			is_active = true
			queue_redraw()
	if Engine.is_editor_hint() or is_active:
		queue_redraw()


func _on_player_entered(player: Player) -> void:
	if not is_active:
		return
	var refilled: bool = player.refill_air_charges()
	if refilled or always_consume:
		is_active = false
		_timer = respawn_time
		if has_node("/root/SoundManager"):
			get_node("/root/SoundManager").play(AudioSynthesizer.Sound.CHECKPOINT, 1.3)
		collected.emit()
		queue_redraw()


func _draw() -> void:
	var mid := size * 0.5
	var pts := PackedVector2Array([
		Vector2(mid.x, 0.0),
		Vector2(size.x, mid.y),
		Vector2(mid.x, size.y),
		Vector2(0.0, mid.y)
	])
	var loop_pts := PackedVector2Array([
		pts[0], pts[1], pts[2], pts[3], pts[0]
	])
	
	if is_active:
		var pulse := 0.7 + 0.3 * sin(_pulse_t * 4.0)
		var fill := color
		fill.a = 0.35 * pulse
		draw_colored_polygon(pts, fill)
		draw_polyline(loop_pts, color, 2.5)
		
		# Inner core
		var core_pts := PackedVector2Array([
			Vector2(mid.x, mid.y * 0.5),
			Vector2(mid.x + (size.x - mid.x) * 0.5, mid.y),
			Vector2(mid.x, mid.y + (size.y - mid.y) * 0.5),
			Vector2(mid.x * 0.5, mid.y)
		])
		var core_color := Color.WHITE
		core_color.a = 0.8 * pulse
		draw_colored_polygon(core_pts, core_color)
	else:
		draw_polyline(loop_pts, inactive_color, 1.5)
