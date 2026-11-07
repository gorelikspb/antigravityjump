class_name PlayerConfig
extends Resource
## All player tuning values. Edit assets/data/player_config.tres, never hardcode in scripts.
## Implements: design/gdd/player-movement.md (Tuning Knobs), design/gdd/gravity-system.md (Tuning Knobs)

@export_group("Run")
@export_range(50.0, 600.0, 1.0, "suffix:px/s") var move_speed: float = 230.0
@export_range(100.0, 8000.0, 10.0, "suffix:px/s²") var ground_accel: float = 2200.0
@export_range(100.0, 8000.0, 10.0, "suffix:px/s²") var ground_decel: float = 2600.0
@export_range(100.0, 8000.0, 10.0, "suffix:px/s²") var air_accel: float = 1500.0
@export_range(100.0, 8000.0, 10.0, "suffix:px/s²") var air_decel: float = 900.0

@export_group("Jump")
@export_range(100.0, 1200.0, 1.0, "suffix:px/s") var jump_velocity: float = 480.0
@export_range(0.05, 1.0, 0.01) var jump_cut_multiplier: float = 0.45
@export_range(0.0, 0.3, 0.01, "suffix:s") var coyote_time: float = 0.10
@export_range(0.0, 0.3, 0.01, "suffix:s") var jump_buffer_time: float = 0.12

@export_group("Gravity")
@export_range(200.0, 4000.0, 10.0, "suffix:px/s²") var gravity_strength: float = 1400.0
@export_range(100.0, 2000.0, 10.0, "suffix:px/s") var max_fall_speed: float = 720.0
@export_range(0, 5, 1) var air_flip_charges: int = 1
## Max speed kept *against* the new gravity right after a flip (anti-catapult).
@export_range(0.0, 1200.0, 10.0, "suffix:px/s") var flip_carry_limit: float = 240.0

@export_group("Presentation")
@export_range(1.0, 60.0, 0.5, "suffix:rad/s") var rotate_visual_speed: float = 18.0
@export var camera_follows_gravity: bool = false

@export_group("Death")
@export_range(0.0, 2.0, 0.05, "suffix:s") var respawn_delay: float = 0.35
