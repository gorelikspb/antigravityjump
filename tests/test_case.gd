extends RefCounted
## Minimal assertion base for addon-free tests. Run: see tests/run_tests.gd

var failures: Array[String] = []
var current_test: String = ""


func assert_true(cond: bool, msg: String = "") -> void:
	if not cond:
		failures.append("%s: expected true. %s" % [current_test, msg])


func assert_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual != expected:
		failures.append("%s: expected <%s>, got <%s>. %s" % [current_test, expected, actual, msg])


func assert_almost(actual: float, expected: float, eps: float = 0.001, msg: String = "") -> void:
	if absf(actual - expected) > eps:
		failures.append("%s: expected ~%s, got %s. %s" % [current_test, expected, actual, msg])


func assert_vec_almost(actual: Vector2, expected: Vector2, eps: float = 0.001, msg: String = "") -> void:
	if actual.distance_to(expected) > eps:
		failures.append("%s: expected ~%s, got %s. %s" % [current_test, expected, actual, msg])
