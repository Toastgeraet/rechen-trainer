class_name TestCase
extends RefCounted

## Assertions and a pass/fail tally, deliberately tiny.
##
## No addon dependency, one line printed per suite, exit 0 on pass and 1 on
## fail. GUT can come later; nothing here should block on it.

var suite: String = ""
var passed: int = 0
var failed: int = 0
var failures: Array[String] = []

var _current: String = ""


## Names the assertion that follows. Every assertion reports under the most
## recent name, so one test function can carry several checks.
func test(name: String) -> void:
	_current = name


func ok(condition: bool, detail: String = "") -> void:
	if condition:
		passed += 1
		return
	_record(detail if not detail.is_empty() else "expected true")


func not_ok(condition: bool, detail: String = "") -> void:
	ok(not condition, detail if not detail.is_empty() else "expected false")


func eq(actual: Variant, expected: Variant, detail: String = "") -> void:
	if _same(actual, expected):
		passed += 1
		return
	var message := "expected %s, got %s" % [_show(expected), _show(actual)]
	if not detail.is_empty():
		message = "%s (%s)" % [message, detail]
	_record(message)


func ne(actual: Variant, unexpected: Variant, detail: String = "") -> void:
	if not _same(actual, unexpected):
		passed += 1
		return
	_record("expected anything but %s%s" % [_show(unexpected), "" if detail.is_empty() else " (%s)" % detail])


## Floating point comparison. Prefer integers in game models (money, counts,
## turns) and compare those with [method eq].
func close(actual: float, expected: float, epsilon: float = 0.001, detail: String = "") -> void:
	if absf(actual - expected) <= epsilon:
		passed += 1
		return
	_record("expected %f +/- %f, got %f%s" % [expected, epsilon, actual, "" if detail.is_empty() else " (%s)" % detail])


func greater(actual: float, floor_value: float, detail: String = "") -> void:
	if actual > floor_value:
		passed += 1
		return
	_record("expected > %s, got %s%s" % [floor_value, actual, "" if detail.is_empty() else " (%s)" % detail])


func less(actual: float, ceiling: float, detail: String = "") -> void:
	if actual < ceiling:
		passed += 1
		return
	_record("expected < %s, got %s%s" % [ceiling, actual, "" if detail.is_empty() else " (%s)" % detail])


func _record(message: String) -> void:
	failed += 1
	var line := "%s / %s: %s" % [suite, _current, message]
	failures.append(line)
	print("    FAIL  %s" % line)


func _same(a: Variant, b: Variant) -> bool:
	# StringName and String compare equal with ==, which is what callers want
	# when they write eq(result.reason, "not_enough_money").
	if a is StringName or b is StringName:
		return String(a) == String(b)
	return a == b


func _show(value: Variant) -> String:
	if value is String or value is StringName:
		return "\"%s\"" % value
	return str(value)
