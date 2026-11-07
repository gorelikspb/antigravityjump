class_name HUD
extends CanvasLayer
## In-level HUD. Listens ONLY to Level signals (injected via bind()).
## Implements: design/gdd/level-flow.md (UI Requirements)

@onready var _level_name: Label = %LevelName
@onready var _timer: Label = %TimerLabel
@onready var _deaths: Label = %DeathsLabel
@onready var _crystals: Label = %CrystalsLabel
@onready var _indicator: GravityIndicator = %GravityIndicator
@onready var _complete_panel: Control = %CompletePanel
@onready var _stats: Label = %StatsLabel
@onready var _prompt: Label = %PromptLabel


func bind(level: Level) -> void:
	_level_name.text = level.level_name
	_complete_panel.visible = false
	level.timer_updated.connect(_on_timer_updated)
	level.deaths_changed.connect(_on_deaths_changed)
	level.crystals_changed.connect(_on_crystals_changed)
	level.gravity_changed.connect(_on_gravity_changed)
	level.air_charges_changed.connect(_indicator.set_charges)
	level.flip_denied.connect(_indicator.flash_denied)
	level.level_completed.connect(_on_level_completed.bind(not level.next_level.is_empty()))


static func format_time(seconds: float) -> String:
	var total := maxf(seconds, 0.0)
	var minutes := int(total / 60.0)
	return "%02d:%05.2f" % [minutes, total - minutes * 60.0]


func _on_timer_updated(seconds: float) -> void:
	_timer.text = format_time(seconds)


func _on_deaths_changed(count: int) -> void:
	_deaths.text = "Deaths: %d" % count


func _on_crystals_changed(collected: int, total: int, required: bool) -> void:
	if total <= 0:
		_crystals.visible = false
		return
	_crystals.visible = true
	var suffix := " (UNLOCKED!)" if (required and collected >= total) else (" (Required to unlock Exit)" if required else "")
	_crystals.text = "◆ Rhombuses: %d / %d%s" % [collected, total, suffix]


func _on_gravity_changed(dir: int) -> void:
	_indicator.direction = dir


func _on_level_completed(seconds: float, deaths: int, has_next: bool) -> void:
	_stats.text = "Time  %s\nDeaths  %d" % [format_time(seconds), deaths]
	_prompt.text = ("[Enter] Next level" if has_next else "[Enter] Play again") + "   ·   [R] Restart"
	_complete_panel.visible = true
