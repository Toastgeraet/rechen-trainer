extends Control

## Main menu: one tile per game. Picking a game asks for the numbers: two
## quick choices ("Immer 10", "1 bis 10") and the player's own saved choice,
## changed with the gear button next to it.

@export_file("*.tscn") var shake_boxes_scene: String = "res://scenes/shake_boxes/shake_box_game.tscn"

## The two quick choices above the player's own.
var _quick_fixed_10 := NumberRange.fixed(10)
var _quick_up_to_10 := NumberRange.new(1, 10)

@onready var _shake_boxes_tile: Button = %ShakeBoxesTile
@onready var _range_overlay: Control = %RangeOverlay
@onready var _quick_page: Control = %QuickPage
@onready var _custom_page: Control = %CustomPage
@onready var _fixed_10_button: Button = %Fixed10Button
@onready var _up_to_10_button: Button = %UpTo10Button
@onready var _custom_play_button: Button = %CustomPlayButton
@onready var _fixed_mode_button: Button = %FixedModeButton
@onready var _range_mode_button: Button = %RangeModeButton
@onready var _fixed_row: Control = %FixedRow
@onready var _range_row: Control = %RangeRow
@onready var _start_button: Button = %StartButton

var _fixed_stepper := NumberStepper.new()
var _from_stepper := NumberStepper.new()
var _to_stepper := NumberStepper.new()


func _ready() -> void:
	var mode_group := ButtonGroup.new()
	_fixed_mode_button.button_group = mode_group
	_range_mode_button.button_group = mode_group
	_fixed_mode_button.pressed.connect(_set_custom_mode.bind(Session.CUSTOM_FIXED))
	_range_mode_button.pressed.connect(_set_custom_mode.bind(Session.CUSTOM_RANGE))

	for stepper in [_fixed_stepper, _from_stepper, _to_stepper]:
		stepper.set_bounds(NumberRange.MIN_MARBLES, NumberRange.MAX_MARBLES)
	%FixedRow.add_child(_fixed_stepper)
	%FromSlot.add_child(_from_stepper)
	%ToSlot.add_child(_to_stepper)
	_from_stepper.value_changed.connect(_on_from_changed)
	_to_stepper.value_changed.connect(_on_to_changed)

	_fixed_10_button.text = _quick_fixed_10.label()
	_up_to_10_button.text = _quick_up_to_10.label()
	_shake_boxes_tile.grab_focus()



func _notification(what: int) -> void:
	# Android's back button / gesture. `quit_on_go_back` is off in project.godot.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_go_back()


## One step back: custom page → quick page → menu → quit.
func _go_back() -> void:
	if _custom_page.visible:
		_show_quick_page()
	elif _range_overlay.visible:
		_range_overlay.visible = false
		_shake_boxes_tile.grab_focus()
	else:
		get_tree().quit()


func _show_quick_page() -> void:
	_custom_play_button.text = Session.custom_range().label()
	_custom_page.visible = false
	_quick_page.visible = true
	_fixed_10_button.grab_focus()


func _show_custom_page() -> void:
	_fixed_stepper.value = Session.custom_fixed
	_from_stepper.value = Session.custom_minimum
	_to_stepper.value = Session.custom_maximum
	_set_custom_mode(Session.custom_mode)
	_quick_page.visible = false
	_custom_page.visible = true
	_start_button.grab_focus()


## Only switches the page; the choice is kept when "Los geht's!" is pressed.
func _set_custom_mode(mode: StringName) -> void:
	var fixed := mode == Session.CUSTOM_FIXED
	_fixed_mode_button.button_pressed = fixed
	_range_mode_button.button_pressed = not fixed
	_fixed_row.visible = fixed
	_range_row.visible = not fixed


## Keeps "von" ≤ "bis" by moving the other end along.
func _on_from_changed(value: int) -> void:
	if _to_stepper.value < value:
		_to_stepper.value = value


func _on_to_changed(value: int) -> void:
	if _from_stepper.value > value:
		_from_stepper.value = value


func _on_shake_boxes_tile_pressed() -> void:
	_range_overlay.visible = true
	_show_quick_page()


func _on_fixed_10_button_pressed() -> void:
	_start_game(_quick_fixed_10)


func _on_up_to_10_button_pressed() -> void:
	_start_game(_quick_up_to_10)


func _on_custom_play_button_pressed() -> void:
	_start_game(Session.custom_range())


func _on_settings_button_pressed() -> void:
	_show_custom_page()


func _on_start_button_pressed() -> void:
	Session.custom_mode = Session.CUSTOM_FIXED if _fixed_mode_button.button_pressed \
			else Session.CUSTOM_RANGE
	Session.custom_fixed = _fixed_stepper.value
	Session.custom_minimum = _from_stepper.value
	Session.custom_maximum = _to_stepper.value
	Session.save_settings()
	_start_game(Session.custom_range())


func _start_game(number_range: NumberRange) -> void:
	Session.number_range = number_range
	var error := get_tree().change_scene_to_file(shake_boxes_scene)
	if error != OK:
		push_error("Could not load '%s' (error %d)." % [shake_boxes_scene, error])
