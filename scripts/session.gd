extends Node

## Autoload `Session`: state that has to survive scene changes, and the player's
## choices, which are saved so the app opens the way it was left.
##
## The UI language follows the device locale automatically; strings live in
## `i18n/strings.csv`, and a missing language falls back to German
## (`internationalization/locale/fallback`).

const SETTINGS_PATH := "user://settings.cfg"

const CUSTOM_FIXED := &"fixed"
const CUSTOM_RANGE := &"range"

## Range for the next game, set by the menu, read by the shake-box game.
var number_range: NumberRange = NumberRange.fixed(10)

## Last "Eigene" choice in the menu, offered again next time.
var custom_mode: StringName = CUSTOM_FIXED
var custom_fixed: int = 5
var custom_minimum: int = 10
var custom_maximum: int = 20

## Shake and settle at double speed.
var fast_mode: bool = false


func _ready() -> void:
	load_settings()


func custom_range() -> NumberRange:
	if custom_mode == CUSTOM_FIXED:
		return NumberRange.fixed(custom_fixed)
	return NumberRange.new(custom_minimum, custom_maximum)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return  # First start.
	var mode: String = config.get_value("custom", "mode", String(custom_mode))
	custom_mode = CUSTOM_RANGE if mode == String(CUSTOM_RANGE) else CUSTOM_FIXED
	custom_fixed = _clamp_marbles(config.get_value("custom", "fixed", custom_fixed))
	custom_minimum = _clamp_marbles(config.get_value("custom", "minimum", custom_minimum))
	custom_maximum = _clamp_marbles(config.get_value("custom", "maximum", custom_maximum))
	fast_mode = bool(config.get_value("game", "fast", fast_mode))


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("custom", "mode", String(custom_mode))
	config.set_value("custom", "fixed", custom_fixed)
	config.set_value("custom", "minimum", custom_minimum)
	config.set_value("custom", "maximum", custom_maximum)
	config.set_value("game", "fast", fast_mode)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Could not save settings (error %d)." % error)


func _clamp_marbles(value: Variant) -> int:
	return clampi(int(value), NumberRange.MIN_MARBLES, NumberRange.MAX_MARBLES)
