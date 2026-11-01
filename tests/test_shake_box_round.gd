extends RefCounted

## Rules of the shake-box game: number ranges, box sizes, judging answers.


func run(t: TestCase) -> void:
	_test_ranges(t)
	_test_box_sizes_stay_in_range(t)
	_test_box_sizes_never_repeat(t)
	_test_correct_answer(t)
	_test_wrong_then_reveal(t)
	_test_must_shake_out_a_marble(t)


func _test_ranges(t: TestCase) -> void:
	t.test("number ranges")
	var up_to_10 := NumberRange.from_id(NumberRange.UP_TO_10)
	t.eq(up_to_10.minimum, 2)
	t.eq(up_to_10.maximum, 10)
	var up_to_20 := NumberRange.from_id(NumberRange.UP_TO_20)
	t.eq(up_to_20.maximum, 20)
	var teens := NumberRange.from_id(NumberRange.FROM_10_TO_20)
	t.eq(teens.minimum, 10)
	t.eq(teens.maximum, 20)
	t.eq(NumberRange.IDS.size(), 3)


func _test_box_sizes_stay_in_range(t: TestCase) -> void:
	for range_id in NumberRange.IDS:
		t.test("box sizes cover %s and stay inside it" % range_id)
		var round_ := ShakeBoxRound.new(NumberRange.from_id(range_id), 7)
		var seen := {}
		for i in 500:
			var total := round_.next_box()
			seen[total] = true
			t.ok(round_.number_range.contains(total), "box of %d" % total)
		var span := round_.number_range.maximum - round_.number_range.minimum + 1
		t.eq(seen.size(), span, "every size shows up")


func _test_box_sizes_never_repeat(t: TestCase) -> void:
	t.test("two boxes in a row differ")
	var round_ := ShakeBoxRound.new(NumberRange.from_id(NumberRange.UP_TO_10), 3)
	var previous := round_.next_box()
	var repeats := 0
	for i in 200:
		var total := round_.next_box()
		if total == previous:
			repeats += 1
		previous = total
	t.eq(repeats, 0)


func _test_correct_answer(t: TestCase) -> void:
	t.test("right answer on first try scores")
	var round_ := ShakeBoxRound.new(NumberRange.from_id(NumberRange.UP_TO_10), 1)
	var total := round_.next_box()
	round_.set_visible_count(1)
	t.eq(round_.hidden_count(), total - 1)
	t.eq(round_.answer(total - 1), ShakeBoxRound.RESULT_CORRECT)
	t.eq(round_.boxes_played, 1)
	t.eq(round_.boxes_correct, 1)


func _test_wrong_then_reveal(t: TestCase) -> void:
	t.test("wrong answers lead to the solution")
	var round_ := ShakeBoxRound.new(NumberRange.from_id(NumberRange.UP_TO_10), 1)
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
	var round_ := ShakeBoxRound.new(NumberRange.from_id(NumberRange.UP_TO_20), 1)
	round_.next_box()
	t.not_ok(round_.can_ask())
	round_.set_visible_count(1)
	t.ok(round_.can_ask())
