@tool
class_name RectTrigger
extends Area2D
## Base class for rectangular greybox triggers that react to the Player.
## Node position = TOP-LEFT corner, `size` in px. Subclasses override _on_player_entered().
## Physics: layer "triggers" (3), mask "player" (2) — see docs/architecture/architecture-overview.md

const LAYER_TRIGGERS: int = 1 << 2
const MASK_PLAYER: int = 1 << 1

@export var size: Vector2 = Vector2(64, 64):
	set(value):
		size = value.max(Vector2(4, 4))
		_refresh()

## Shrinks the hitbox on every side (fairness for hazards).
@export var hitbox_inset: float = 0.0:
	set(value):
		hitbox_inset = maxf(value, 0.0)
		_refresh()

var _shape_node: CollisionShape2D


func _ready() -> void:
	collision_layer = LAYER_TRIGGERS
	collision_mask = MASK_PLAYER
	monitorable = false
	_refresh()
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)


func _refresh() -> void:
	if not is_node_ready():
		return
	if _shape_node == null:
		_shape_node = CollisionShape2D.new()
		add_child(_shape_node)  # not owned -> never saved into the scene
	var rect := RectangleShape2D.new()
	rect.size = (size - Vector2.ONE * hitbox_inset * 2.0).max(Vector2.ONE)
	_shape_node.shape = rect
	_shape_node.position = size * 0.5
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_on_player_entered(body as Player)


## Override in subclasses.
func _on_player_entered(_player: Player) -> void:
	pass
