extends Control

## Main menu: one tile per game. Picking a game asks for the number range,
## then switches to the game scene.

@export_file("*.tscn") var shake_boxes_scene: String = "res://scenes/shake_boxes/shake_box_game.tscn"

const RANGE_BUTTON_SIZE := Vector2(0, 110)

@onready var _shake_boxes_tile: Button = %ShakeBoxesTile
@onready var _range_overlay: Control = %RangeOverlay
@onready var _range_buttons: VBoxContainer = %RangeButtons


func _ready() -> void:
	for range_id in NumberRange.IDS:
		var number_range := NumberRange.from_id(range_id)
		var button := Button.new()
		button.text = number_range.label_key  # Translated automatically.
		button.custom_minimum_size = RANGE_BUTTON_SIZE
		button.add_theme_font_size_override(&"font_size", 44)
		button.pressed.connect(_on_range_chosen.bind(range_id))
		_range_buttons.add_child(button)
	_shake_boxes_tile.grab_focus()


func _notification(what: int) -> void:
	# Android's back button / gesture. `quit_on_go_back` is off in project.godot.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_go_back()


func _go_back() -> void:
	if _range_overlay.visible:
		_close_range_picker()
	else:
		get_tree().quit()


func _close_range_picker() -> void:
	_range_overlay.visible = false
	_shake_boxes_tile.grab_focus()


func _on_shake_boxes_tile_pressed() -> void:
	_range_overlay.visible = true
	(_range_buttons.get_child(0) as Button).grab_focus()


func _on_cancel_button_pressed() -> void:
	_close_range_picker()


func _on_range_chosen(range_id: StringName) -> void:
	Session.number_range = NumberRange.from_id(range_id)
	var error := get_tree().change_scene_to_file(shake_boxes_scene)
	if error != OK:
		push_error("Could not load '%s' (error %d)." % [shake_boxes_scene, error])
