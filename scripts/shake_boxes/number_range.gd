class_name NumberRange
extends RefCounted

## How many marbles a box may hold, inclusive on both ends. A fixed number is
## a range whose minimum equals its maximum.

## A single marble still splits: 1 + 0 or 0 + 1.
const MIN_MARBLES := 1
## More don't fit on one side of the box below the wedge.
const MAX_MARBLES := 20

var minimum: int
var maximum: int


func _init(lowest: int = MIN_MARBLES, highest: int = 10) -> void:
	minimum = clampi(mini(lowest, highest), MIN_MARBLES, MAX_MARBLES)
	maximum = clampi(maxi(lowest, highest), MIN_MARBLES, MAX_MARBLES)


static func fixed(value: int) -> NumberRange:
	return NumberRange.new(value, value)


func is_fixed() -> bool:
	return minimum == maximum


func contains(value: int) -> bool:
	return value >= minimum and value <= maximum


## Menu text: "Immer 7" for a fixed number, "4 bis 15" for a range.
func label() -> String:
	if is_fixed():
		return TranslationServer.translate("RANGE_FIXED").format({"n": minimum})
	return TranslationServer.translate("RANGE_SPAN").format({"min": minimum, "max": maximum})
