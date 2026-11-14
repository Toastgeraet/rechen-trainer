extends RefCounted

## Rules of the shake-box game: number ranges, box sizes, judging answers.


func run(t: TestCase) -> void:
	_test_ranges(t)
	_test_box_sizes_stay_in_range(t)
	_test_box_sizes_never_repeat(t)
	_test_fixed_number_repeats(t)
	_test_correct_answer(t)
	_test_wrong_then_reveal(t)
	_test_must_shake_out_a_marble(t)


func _test_ranges(t: TestCase) -> void:
	t.test("1 to 10 includes a single marble")
	var up_to_10 := NumberRange.new(1, 10)
	t.eq(up_to_10.minimum, 1)
	t.eq(up_to_10.maximum, 10)
	t.not_ok(up_to_10.is_fixed())

	t.test("a fixed number is a one-value range")
	var seven := NumberRange.fixed(7)
	t.eq(seven.minimum, 7)
	t.eq(seven.maximum, 7)
	t.ok(seven.is_fixed())

	t.test("custom ranges are ordered and clamped to what fits in the box")
	var swapped := NumberRange.new(15, 12)
	t.eq(swapped.minimum, 12)
	t.eq(swapped.maximum, 15)
	t.test("menu labels")
	TranslationServer.set_locale("de")
	t.eq(NumberRange.fixed(10).label(), "Immer 10")
	t.eq(NumberRange.new(1, 10).label(), "1 bis 10")

	t.test("custom ranges are clamped to what fits in the box")
	var wide := NumberRange.new(0, 99)
	t.eq(wide.minimum, NumberRange.MIN_MARBLES)
	t.eq(wide.maximum, NumberRange.MAX_MARBLES)


func _test_box_sizes_stay_in_range(t: TestCase) -> void:
	for range_ in [NumberRange.new(1, 10), NumberRange.new(10, 20), NumberRange.new(2, 20)]:
		t.test("box sizes cover %d..%d and stay inside it" % [range_.minimum, range_.maximum])
		var round_ := ShakeBoxRound.new(range_, 7)
		var seen := {}
		for i in 500:
			var total := round_.next_box()
			seen[total] = true
			t.ok(range_.contains(total), "box of %d" % total)
		t.eq(seen.size(), range_.maximum - range_.minimum + 1, "every size shows up")


func _test_fixed_number_repeats(t: TestCase) -> void:
	# Regression: next_box() refused to repeat a size and spun forever.
	t.test("a fixed number gives that box every time")
	var round_ := ShakeBoxRound.new(NumberRange.fixed(5), 1)
	for i in 20:
		t.eq(round_.next_box(), 5)


func _test_box_sizes_never_repeat(t: TestCase) -> void:
	t.test("two boxes in a row differ")
	var round_ := ShakeBoxRound.new(NumberRange.new(1, 10), 3)
	var previous := round_.next_box()
	var repeats := 0
	for i in 200:
		var total := round_.next_box()
		if total == previous:
			repeats += 1
		previous = total
	t.eq(repeats, 0)

	t.test("a two-value range alternates")
	var pair := ShakeBoxRound.new(NumberRange.new(4, 5), 3)
	var first := pair.next_box()
	t.ne(pair.next_box(), first)


func _test_correct_answer(t: TestCase) -> void:
	t.test("right answer on first try scores")
	var round_ := ShakeBoxRound.new(NumberRange.new(1, 10), 1)
	var total := round_.next_box()
	round_.set_visible_count(1)
	t.eq(round_.hidden_count(), total - 1)
	t.eq(round_.answer(total - 1), ShakeBoxRound.RESULT_CORRECT)
	t.eq(round_.boxes_played, 1)
	t.eq(round_.boxes_correct, 1)


func _test_wrong_then_reveal(t: TestCase) -> void:
	t.test("wrong answers lead to the solution")
	var round_ := ShakeBoxRound.new(NumberRange.new(1, 10), 1)
	var total := round_.next_box()
	round_.set_visible_count(total)  # All out: 0 hidden.
	t.eq(round_.answer(1), ShakeBoxRound.RESULT_WRONG)
	t.eq(round_.answer(2), ShakeBoxRound.RESULT_REVEAL)
	t.eq(round_.boxes_played, 1)
	t.eq(round_.boxes_correct, 0)

	t.test("right after one wrong try does not score")
	round_.next_box()
	round_.set_visible_count(1)
	t.eq(round_.answer(round_.hidden_count() + 1), ShakeBoxRound.RESULT_WRONG)
	t.eq(round_.answer(round_.hidden_count()), ShakeBoxRound.RESULT_CORRECT)
	t.eq(round_.boxes_played, 2)
	t.eq(round_.boxes_correct, 0)


func _test_must_shake_out_a_marble(t: TestCase) -> void:
	t.test("nothing to ask until a marble is visible")
	var round_ := ShakeBoxRound.new(NumberRange.new(2, 20), 1)
	round_.next_box()
	t.not_ok(round_.can_ask())
	round_.set_visible_count(1)
	t.ok(round_.can_ask())
