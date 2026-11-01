extends SceneTree

## Headless test entry point.
##
##     godot --headless --path . --script res://tests/run_all.gd
##
## Exit code 0 = pass, 1 = fail, one line printed per suite. Suites are
## preloaded rather than discovered, so a test file that fails to compile is a
## loud startup error instead of a suite that silently stops being run.

const SUITES := {
	"shake_box_round": preload("res://tests/test_shake_box_round.gd"),
	"translations": preload("res://tests/test_translations.gd"),
}


func _initialize() -> void:
	var total_passed := 0
	var total_failed := 0
	var all_failures: Array[String] = []

	print("")
	for suite_name in SUITES:
		var test_case := TestCase.new()
		test_case.suite = suite_name
		var suite: RefCounted = (SUITES[suite_name] as GDScript).new()
		suite.call("run", test_case)
		total_passed += test_case.passed
		total_failed += test_case.failed
		all_failures.append_array(test_case.failures)
		print("  %-14s %3d passed, %d failed" % [suite_name, test_case.passed, test_case.failed])

	print("")
	if total_failed == 0:
		print("OK -- %d assertions passed." % total_passed)
	else:
		print("FAILED -- %d of %d assertions failed:" % [total_failed, total_passed + total_failed])
		for failure in all_failures:
			print("  %s" % failure)
	print("")

	quit(1 if total_failed > 0 else 0)
