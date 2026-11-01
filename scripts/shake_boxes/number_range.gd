class_name NumberRange
extends RefCounted

## A number range the player picks before a shake-box game ("bis 10" …).
##
## `minimum` and `maximum` bound the number of marbles in a box, inclusive.

const UP_TO_10 := &"up_to_10"
const UP_TO_20 := &"up_to_20"
const FROM_10_TO_20 := &"from_10_to_20"

## Order in which the range picker lists them.
const IDS: Array[StringName] = [UP_TO_10, UP_TO_20, FROM_10_TO_20]

## Starts at 2: a box with one marble has nothing to split.
const _BOUNDS := {
	UP_TO_10: Vector2i(2, 10),
	UP_TO_20: Vector2i(2, 20),
	FROM_10_TO_20: Vector2i(10, 20),
}

const _LABEL_KEYS := {
	UP_TO_10: "RANGE_UP_TO_10",
	UP_TO_20: "RANGE_UP_TO_20",
	FROM_10_TO_20: "RANGE_10_TO_20",
}

var id: StringName
var minimum: int
var maximum: int
## Translation key for the picker button.
var label_key: String


static func from_id(range_id: StringName) -> NumberRange:
	assert(_BOUNDS.has(range_id), "Unknown number range '%s'." % range_id)
	var result := NumberRange.new()
	var bounds: Vector2i = _BOUNDS[range_id]
	result.id = range_id
	result.minimum = bounds.x
	result.maximum = bounds.y
	result.label_key = _LABEL_KEYS[range_id]
	return result


func contains(value: int) -> bool:
	return value >= minimum and value <= maximum
