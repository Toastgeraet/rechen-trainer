class_name NumberRange
extends RefCounted

## How many marbles a box may hold, inclusive on both ends. A fixed number is
## a range whose minimum equals its maximum.

## A box with one marble has nothing to split.
const MIN_MARBLES := 2
## More don't fit on one side of the box below the wedge.
const MAX_MARBLES := 20

var minimum: int
var maximum: int


func _init(lowest: int = MIN_MARBLES, highest: int = 10) -> void:
	minimum = clampi(mini(lowest, highest), MIN_MARBLES, MAX_MARBLES)
	maximum = clampi(maxi(lowest, highest), MIN_MARBLES, MAX_MARBLES)


## The quick-start choice in the menu ("bis 10").
static func up_to_10() -> NumberRange:
	return NumberRange.new(MIN_MARBLES, 10)


static func fixed(value: int) -> NumberRange:
	return NumberRange.new(value, value)


func is_fixed() -> bool:
	return minimum == maximum


func contains(value: int) -> bool:
	return value >= minimum and value <= maximum
