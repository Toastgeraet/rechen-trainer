class_name NumberStepper
extends HBoxContainer

## A number picker for small hands: big [−] value [+] buttons, no typing.

signal value_changed(value: int)

const BUTTON_SIZE := Vector2(96, 96)

var minimum: int = 0
var maximum: int = 100
var value: int = 0:
	set = set_value

var _minus: Button
var _plus: Button
var _label: Label


func _init() -> void:
	add_theme_constant_override(&"separation", 16)
	alignment = BoxContainer.ALIGNMENT_CENTER
	_minus = _make_button("−", -1)
	_label = Label.new()
	_label.custom_minimum_size = Vector2(110, 0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override(&"font_size", 56)
	add_child(_label)
	_plus = _make_button("+", 1)
	_refresh()


## Sets the value without emitting `value_changed`, clamped to the bounds.
func set_value(new_value: int) -> void:
	value = clampi(new_value, minimum, maximum)
	_refresh()


func set_bounds(lowest: int, highest: int) -> void:
	minimum = lowest
	maximum = highest
	set_value(value)


func _make_button(text: String, step: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = BUTTON_SIZE
	button.add_theme_font_size_override(&"font_size", 52)
	button.pressed.connect(_step.bind(step))
	add_child(button)
	return button


func _step(step: int) -> void:
	var before := value
	set_value(value + step)
	if value != before:
		value_changed.emit(value)


func _refresh() -> void:
	if _label == null:
		return
	_label.text = str(value)
	_minus.disabled = value <= minimum
	_plus.disabled = value >= maximum
