class_name ShakeBoxRound
extends RefCounted

## Rules for one game of shake boxes: which box comes next and whether an
## answer is right. No nodes and no physics, so it runs in headless tests.
##
## The physics decides how many marbles end up visible; this class only takes
## that number and judges the player's guess for the hidden rest.

## Wrong guesses allowed before the solution is shown.
const MAX_WRONG_ATTEMPTS := 2

var number_range: NumberRange
## Marbles in the current box.
var total: int = 0
## Marbles that ended up in the visible compartment after shaking.
var visible_count: int = 0
var wrong_attempts: int = 0

var boxes_played: int = 0
## Boxes answered right on the first try.
var boxes_correct: int = 0

var _rng: RandomNumberGenerator


func _init(range_: NumberRange, seed_value: int = -1) -> void:
	number_range = range_
	_rng = RandomNumberGenerator.new()
	if seed_value >= 0:
		_rng.seed = seed_value


## Picks the next box size. Never repeats the previous size, so consecutive
## boxes always look different.
func next_box() -> int:
	var previous := total
	var candidate := previous
	while candidate == previous:
		candidate = _rng.randi_range(number_range.minimum, number_range.maximum)
	total = candidate
	visible_count = 0
	wrong_attempts = 0
	return total


func hidden_count() -> int:
	return total - visible_count


## Called whenever the marbles have settled after a shake.
func set_visible_count(count: int) -> void:
	assert(count >= 0 and count <= total)
	visible_count = count
	wrong_attempts = 0


## True once the box is ready to be asked about: at least one marble fell out.
func can_ask() -> bool:
	return visible_count > 0


## Judges a guess for the hidden marbles. Returns one of the result codes below.
const RESULT_CORRECT := &"correct"
const RESULT_WRONG := &"wrong"
const RESULT_REVEAL := &"reveal"


func answer(guess: int) -> StringName:
	if guess == hidden_count():
		boxes_played += 1
		if wrong_attempts == 0:
			boxes_correct += 1
		return RESULT_CORRECT
	wrong_attempts += 1
	if wrong_attempts >= MAX_WRONG_ATTEMPTS:
		boxes_played += 1
		return RESULT_REVEAL
	return RESULT_WRONG
