extends Node
## Autoload: persists level completion, best time, and fewest deaths to user://save.cfg.

const SAVE_PATH: String = "user://save.cfg"

var _cfg: ConfigFile = ConfigFile.new()


func _ready() -> void:
	_cfg.load(SAVE_PATH)


func record_completion(level_id: String, time_sec: float, deaths: int) -> bool:
	var prev_best: float = _cfg.get_value(level_id, "best_time", INF)
	var prev_deaths: int = _cfg.get_value(level_id, "best_deaths", 999999)
	var is_new_record: bool = time_sec < prev_best
	_cfg.set_value(level_id, "completed", true)
	if is_new_record:
		_cfg.set_value(level_id, "best_time", time_sec)
	if deaths < prev_deaths:
		_cfg.set_value(level_id, "best_deaths", deaths)
	_cfg.save(SAVE_PATH)
	return is_new_record


func is_completed(level_id: String) -> bool:
	return bool(_cfg.get_value(level_id, "completed", false))


func get_best_time(level_id: String) -> float:
	return float(_cfg.get_value(level_id, "best_time", -1.0))


func get_best_deaths(level_id: String) -> int:
	return int(_cfg.get_value(level_id, "best_deaths", -1))


static func compute_medal(time_sec: float, deaths: int, gold_time: float = 22.0, silver_time: float = 40.0) -> String:
	if deaths == 0 and time_sec <= gold_time:
		return "★ GOLD"
	if time_sec <= silver_time:
		return "◆ SILVER"
	return "● BRONZE"
