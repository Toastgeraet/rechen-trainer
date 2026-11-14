extends Control

## The shake-box game: shake the phone, some marbles fall into the open side,
## say how many are still hidden under the lid.
##
## Rules live in `ShakeBoxRound`; physics in `ShakeBox`. This script wires
## them to input and the screen.

@export_file("*.tscn") var main_menu_scene: String = "res://scenes/main_menu/main_menu.tscn"

## Linear acceleration (gravity removed) that counts as a shake, in m/s².
const SHAKE_THRESHOLD := 9.0
## Minimum real time between two shake impulses while the phone keeps shaking,
## in milliseconds. Real time, so fast mode doesn't double the impulses.
const SHAKE_COOLDOWN_MS := 250
## Fast mode runs the game clock this much faster.
const FAST_TIME_SCALE := 2.0
const NORMAL_PHYSICS_TICKS := 60
## Marbles shrink for bigger ranges so 20 fit on one side below the wedge.
const MARBLE_RADIUS_SMALL_RANGE := 26.0
const MARBLE_RADIUS_LARGE_RANGE := 17.0

const PAD_BUTTON_SIZE := Vector2(98, 90)
const COLOR_CORRECT := Color(0.13, 0.55, 0.2)
const COLOR_WRONG := Color(0.8, 0.35, 0.1)

const ICON_NORMAL := preload("res://assets/icons/speed_normal.svg")
const ICON_FAST := preload("res://assets/icons/speed_fast.svg")

enum Phase { READY, MOVING, ASK, DONE }

var _round: ShakeBoxRound
var _phase: Phase = Phase.READY
var _last_shake_msec: int = -SHAKE_COOLDOWN_MS
## Low-pass estimate of gravity, for devices without a gravity sensor.
var _gravity_estimate := Vector3.ZERO

@onready var _box: ShakeBox = %ShakeBox
@onready var _box_viewport: SubViewport = %BoxViewport
@onready var _box_area: TextureRect = %BoxArea
@onready var _prompt_label: Label = %PromptLabel
@onready var _score_label: Label = %ScoreLabel
@onready var _speed_button: Button = %SpeedButton
@onready var _shake_button: Button = %ShakeButton
@onready var _answer_pad: GridContainer = %AnswerPad
@onready var _feedback_label: Label = %FeedbackLabel
@onready var _next_button: Button = %NextButton


func _ready() -> void:
	_round = ShakeBoxRound.new(Session.number_range)
	_box.sides_decided.connect(_on_box_sides_decided)
	_setup_box_viewport()
	_apply_speed()
	_start_box()


func _process(_delta: float) -> void:
	_read_accelerometer()


func _exit_tree() -> void:
	# Engine settings outlive the scene; leave the menu at normal speed.
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = NORMAL_PHYSICS_TICKS


func _notification(what: int) -> void:
	# Android's back button / gesture. `quit_on_go_back` is off in project.godot.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_return_to_main_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_return_to_main_menu()


func _start_box() -> void:
	var total := _round.next_box()
	var radius := MARBLE_RADIUS_SMALL_RANGE if _round.number_range.maximum <= 10 \
			else MARBLE_RADIUS_LARGE_RANGE
	_box.fill(total, radius)
	_build_answer_pad(total)
	_feedback_label.text = ""
	_next_button.visible = false
	_update_score()
	_enter_phase(Phase.READY, tr("SHAKE_PROMPT"))


func _enter_phase(phase: Phase, prompt: String) -> void:
	_phase = phase
	_prompt_label.text = prompt
	_shake_button.visible = phase == Phase.READY or phase == Phase.MOVING
	_shake_button.disabled = phase == Phase.MOVING
	_answer_pad.visible = phase == Phase.ASK
	_next_button.visible = phase == Phase.DONE
	if phase == Phase.DONE:
		_next_button.grab_focus()


func _can_shake() -> bool:
	return _phase == Phase.READY or _phase == Phase.MOVING


func _shake(direction: Vector2, strength: float) -> void:
	var now := Time.get_ticks_msec()
	if not _can_shake() or now - _last_shake_msec < SHAKE_COOLDOWN_MS:
		return
	_last_shake_msec = now
	_box.shake(direction, strength)
	_feedback_label.text = ""
	if _phase != Phase.MOVING:
		_enter_phase(Phase.MOVING, tr("SHAKING"))


func _read_accelerometer() -> void:
	var acceleration := Input.get_accelerometer()
	if acceleration == Vector3.ZERO:
		return  # Desktop, or the sensor is off.
	var gravity := Input.get_gravity()
	if gravity == Vector3.ZERO:
		_gravity_estimate = acceleration if _gravity_estimate == Vector3.ZERO \
				else _gravity_estimate.lerp(acceleration, 0.1)
		gravity = _gravity_estimate
	var linear := acceleration - gravity
	if linear.length() < SHAKE_THRESHOLD:
		return
	# Sensor y points up the screen; the box's y points down.
	var direction := Vector2(linear.x, -linear.y).normalized()
	_shake(direction, clampf(linear.length() / 15.0, 0.7, 1.3))


func _on_box_sides_decided(visible_count: int) -> void:
	_round.set_visible_count(visible_count)
	if not _round.can_ask():
		_enter_phase(Phase.READY, tr("SHAKE_AGAIN"))
		return
	_enter_phase(Phase.ASK, tr("QUESTION_HIDDEN"))


func _build_answer_pad(total: int) -> void:
	for child in _answer_pad.get_children():
		child.queue_free()
	for value in range(total + 1):
		var button := Button.new()
		button.text = str(value)
		button.custom_minimum_size = PAD_BUTTON_SIZE
		button.add_theme_font_size_override(&"font_size", 40)
		button.pressed.connect(_on_answer_pressed.bind(value, button))
		_answer_pad.add_child(button)


func _on_answer_pressed(value: int, button: Button) -> void:
	if _phase != Phase.ASK:
		return
	match _round.answer(value):
		ShakeBoxRound.RESULT_CORRECT:
			_show_feedback(tr("CORRECT"), COLOR_CORRECT)
			_finish_box()
		ShakeBoxRound.RESULT_REVEAL:
			_show_feedback(tr("SOLUTION").format({"hidden": _round.hidden_count()}), COLOR_WRONG)
			_finish_box()
		ShakeBoxRound.RESULT_WRONG:
			_show_feedback(tr("WRONG_TRY_AGAIN"), COLOR_WRONG)
			button.disabled = true


func _finish_box() -> void:
	_box.reveal()
	_update_score()
	var equation := "%d + %d = %d" % [_round.visible_count, _round.hidden_count(), _round.total]
	_enter_phase(Phase.DONE, equation)


func _show_feedback(text: String, color: Color) -> void:
	_feedback_label.text = text
	_feedback_label.add_theme_color_override(&"font_color", color)


func _update_score() -> void:
	_score_label.text = tr("SCORE").format(
			{"correct": _round.boxes_correct, "total": _round.boxes_played})


## The box simulates in its own SubViewport at a fixed size. Scaling a parent
## of rigid bodies confuses the physics, so only the rendering is scaled (the
## canvas transform) and the TextureRect fits the picture to the screen.
func _setup_box_viewport() -> void:
	var render_scale := float(_box_viewport.size.x) / ShakeBox.DRAW_SIZE.x
	_box_viewport.canvas_transform = Transform2D(0.0, Vector2.ONE * render_scale, 0.0,
			Vector2(_box_viewport.size) / 2.0)
	_box.position = Vector2(0, 30)  # The tab sticks out above, so sit a bit lower.
	_box_area.texture = _box_viewport.get_texture()


## Fast mode speeds up the whole game clock. The physics tick rate goes up by
## the same factor, so each step still simulates 1/60 s and fast marbles don't
## tunnel through walls.
func _apply_speed() -> void:
	var scale := FAST_TIME_SCALE if Session.fast_mode else 1.0
	Engine.time_scale = scale
	Engine.physics_ticks_per_second = int(NORMAL_PHYSICS_TICKS * scale)
	_speed_button.icon = ICON_FAST if Session.fast_mode else ICON_NORMAL
	_speed_button.tooltip_text = tr("SPEED_FAST") if Session.fast_mode else tr("SPEED_NORMAL")


func _on_speed_button_pressed() -> void:
	Session.fast_mode = not Session.fast_mode
	Session.save_settings()
	_apply_speed()


func _on_shake_button_pressed() -> void:
	_shake(Vector2.ZERO, 1.0)


func _on_next_button_pressed() -> void:
	_start_box()


func _on_back_button_pressed() -> void:
	_return_to_main_menu()


func _return_to_main_menu() -> void:
	var error := get_tree().change_scene_to_file(main_menu_scene)
	if error != OK:
		push_error("Could not load '%s' (error %d)." % [main_menu_scene, error])
