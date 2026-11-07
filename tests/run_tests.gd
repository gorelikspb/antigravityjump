extends SceneTree
## Addon-free test runner.
## Usage (from project root):
##   godot --headless --import              # first time only (builds class cache)
##   godot --headless -s res://tests/run_tests.gd
## Exit code 0 = all passed, 1 = failures.

const TEST_DIRS: Array[String] = ["res://tests/unit", "res://tests/integration"]


func _initialize() -> void:
	var files: Array[String] = []
	for dir in TEST_DIRS:
		_collect(dir, files)

	var total := 0
	var failed: Array[String] = []
	for path in files:
		var script: GDScript = load(path)
		if script == null:
			failed.append("%s: failed to load" % path)
			continue
		var instance: Object = script.new()
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			total += 1
			instance.current_test = "%s::%s" % [path.get_file(), name]
			var before: int = instance.failures.size()
			instance.call(name)
			var ok: bool = instance.failures.size() == before
			print("  %s %s" % ["PASS" if ok else "FAIL", instance.current_test])
		failed.append_array(instance.failures)

	print("\n%d tests, %d failures" % [total, failed.size()])
	for f in failed:
		printerr("  - " + f)
	quit(1 if failed.size() > 0 else 0)


func _collect(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_collect(dir_path.path_join(sub), out)
	for file in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd"):
			out.append(dir_path.path_join(file))
