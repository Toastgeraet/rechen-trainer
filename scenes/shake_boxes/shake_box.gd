class_name ShakeBox
extends Node2D

## A box with two compartments separated by a low wedge. The left side is open
## to view; the right side sits under a lid. Shaking throws the marbles around,
## some hop over the wedge, and once everything is still `settled` reports how
## many are visible.
##
## Coordinates are local, with the origin at the centre of the inner space.

signal settled(visible_count: int)

const INNER_SIZE := Vector2(640, 380)
const WALL := 80.0
## Low enough to hop over, high enough that 20 resting marbles stay put.
const DIVIDER_HEIGHT := 130.0
const DIVIDER_HALF_WIDTH := 40.0

## Outer bounds including the frame and the number tab, for fitting on screen.
const DRAW_SIZE := Vector2(700, 520)

## Shake impulses, in px/s per unit of mass. The shared sideways jolt is what
## carries marbles over the wedge; the scatter keeps every shake different.
const SHAKE_JOLT_MIN := 350.0
const SHAKE_JOLT_MAX := 700.0
const SHAKE_SCATTER := 200.0
const SHAKE_LIFT_MIN := 400.0
const SHAKE_LIFT_MAX := 850.0

## Speed under which a marble counts as resting, in px/s.
const REST_SPEED := 15.0
## How long everything must rest before the box counts as settled.
const REST_TIME := 0.5
## Give up waiting and count anyway; marbles may jitter forever on some devices.
const SETTLE_TIMEOUT := 4.5

const PAPER := Color(0.95, 0.97, 0.81)
const FRAME := Color(0.17, 0.66, 0.66)
const LID := Color(0.5, 0.84, 0.86)
const DIVIDER_FILL := Color(0.79, 0.93, 0.93)
const TAB_FILL := Color(0.89, 0.96, 0.95)
const TEXT := Color(0.12, 0.31, 0.36)

var total: int = 0
var is_moving: bool = false

var _marbles: Array[Marble] = []
var _marble_radius: float = 20.0
var _rest_timer: float = 0.0
var _move_timer: float = 0.0
var _rng := RandomNumberGenerator.new()
var _lid: Node2D
var _frame: Node2D
var _marble_layer: Node2D


func _ready() -> void:
	_rng.randomize()
	_build_walls()
	_marble_layer = Node2D.new()
	_marble_layer.name = "Marbles"
	add_child(_marble_layer)
	_lid = _LidLayer.new()
	_lid.name = "Lid"
	add_child(_lid)
	_frame = _FrameLayer.new()
	_frame.name = "Frame"
	_frame.set_meta(&"box", self)
	add_child(_frame)


## Empties the box and puts `count` marbles in the hidden compartment.
func fill(count: int, marble_radius: float) -> void:
	for marble in _marbles:
		marble.queue_free()
	_marbles.clear()
	total = count
	_marble_radius = marble_radius
	_lid.modulate.a = 1.0
	_frame.queue_redraw()

	var spacing := marble_radius * 2.0 + 2.0
	var left := DIVIDER_HALF_WIDTH + marble_radius + 4.0
	var right := INNER_SIZE.x / 2.0 - marble_radius - 2.0
	var per_row := int((right - left) / spacing) + 1
	for i in count:
		var row := i / per_row
		var column := i % per_row
		var marble := Marble.new(marble_radius)
		# Odd rows sit half a step over, as if they had rolled into the gaps.
		var x := left + column * spacing + (marble_radius if row % 2 == 1 else 0.0)
		marble.position = Vector2(
			minf(x, right),
			INNER_SIZE.y / 2.0 - marble_radius - row * spacing * 0.9 - 1.0)
		_marbles.append(marble)
		_marble_layer.add_child(marble)
	is_moving = false


## Jolts the box like a real shake: every marble gets the same sideways kick
## (the box moving under them) plus its own random bounce. `direction.x` picks
## the side (from the phone's motion); zero means toward the open side. `strength`
## scales everything, around 1.0.
func shake(direction: Vector2 = Vector2.ZERO, strength: float = 1.0) -> void:
	var side := signf(direction.x)
	if side == 0.0:
		# No motion data (the button): jolt toward the open side. A jolt the
		# other way mostly bounces off the right wall and nothing falls out.
		side = -1.0
	var jolt := side * _rng.randf_range(SHAKE_JOLT_MIN, SHAKE_JOLT_MAX)
	for marble in _marbles:
		var impulse := Vector2(
			jolt + _rng.randf_range(-SHAKE_SCATTER, SHAKE_SCATTER),
			-_rng.randf_range(SHAKE_LIFT_MIN, SHAKE_LIFT_MAX))
		marble.sleeping = false
		marble.apply_central_impulse(impulse * strength * marble.mass)
	is_moving = true
	_rest_timer = 0.0
	_move_timer = 0.0


func visible_count() -> int:
	var count := 0
	for marble in _marbles:
		if marble.position.x < 0.0:
			count += 1
	return count


func reveal() -> void:
	var tween := create_tween()
	tween.tween_property(_lid, "modulate:a", 0.0, 0.5)


func _physics_process(delta: float) -> void:
	if not is_moving:
		return
	_move_timer += delta
	_nudge_marbles_on_divider()
	var resting := true
	for marble in _marbles:
		if marble.linear_velocity.length() > REST_SPEED:
			resting = false
			break
	_rest_timer = _rest_timer + delta if resting else 0.0
	if _rest_timer >= REST_TIME or _move_timer >= SETTLE_TIMEOUT:
		is_moving = false
		settled.emit(visible_count())


## A marble balanced on the tip of the wedge belongs to neither side.
func _nudge_marbles_on_divider() -> void:
	var tip_y := INNER_SIZE.y / 2.0 - DIVIDER_HEIGHT
	for marble in _marbles:
		var p := marble.position
		if absf(p.x) < _marble_radius * 0.6 and p.y < tip_y and p.y > tip_y - _marble_radius * 1.5 \
				and marble.linear_velocity.length() < 30.0:
			var side := -1.0 if _rng.randf() < 0.5 else 1.0
			marble.apply_central_impulse(Vector2(side * 60.0, -20.0) * marble.mass)


func _build_walls() -> void:
	var body := StaticBody2D.new()
	body.name = "Walls"
	var material := PhysicsMaterial.new()
	material.bounce = 0.3
	material.friction = 0.5
	body.physics_material_override = material
	add_child(body)

	var half := INNER_SIZE / 2.0
	var outer := half + Vector2(WALL, WALL)
	# Floor, ceiling, left and right, each a thick slab outside the inner space.
	_add_rect(body, Vector2(0, half.y + WALL / 2.0), Vector2(outer.x * 2.0, WALL))
	_add_rect(body, Vector2(0, -half.y - WALL / 2.0), Vector2(outer.x * 2.0, WALL))
	_add_rect(body, Vector2(-half.x - WALL / 2.0, 0), Vector2(WALL, outer.y * 2.0))
	_add_rect(body, Vector2(half.x + WALL / 2.0, 0), Vector2(WALL, outer.y * 2.0))

	var divider := CollisionPolygon2D.new()
	divider.polygon = _divider_points()
	body.add_child(divider)


func _add_rect(body: StaticBody2D, center: Vector2, size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = center
	body.add_child(collision)


func _divider_points() -> PackedVector2Array:
	var floor_y := INNER_SIZE.y / 2.0
	return PackedVector2Array([
		Vector2(-DIVIDER_HALF_WIDTH, floor_y),
		Vector2(0, floor_y - DIVIDER_HEIGHT),
		Vector2(DIVIDER_HALF_WIDTH, floor_y),
	])


func _inner_rect() -> Rect2:
	return Rect2(-INNER_SIZE / 2.0, INNER_SIZE)


func _draw() -> void:
	_draw_rounded_rect(_inner_rect().grow(6.0), PAPER, 30.0)
	var points := _divider_points()
	draw_colored_polygon(points, DIVIDER_FILL)
	points.append(points[0])
	draw_polyline(points, FRAME, 4.0, true)


func _draw_rounded_rect(rect: Rect2, color: Color, radius: float, filled: bool = true,
		width: float = -1.0) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(radius))
	style.anti_aliasing = true
	if not filled:
		style.draw_center = false
		style.border_color = color
		style.set_border_width_all(int(width))
	draw_style_box(style, rect)


## Covers the hidden compartment. Drawn above the marbles.
class _LidLayer extends Node2D:
	func _ready() -> void:
		z_index = 2

	func _draw() -> void:
		var half := ShakeBox.INNER_SIZE / 2.0
		var style := StyleBoxFlat.new()
		style.bg_color = ShakeBox.LID
		style.corner_radius_top_right = 30
		style.corner_radius_bottom_right = 30
		style.anti_aliasing = true
		draw_style_box(style, Rect2(Vector2(0, -half.y - 6.0), Vector2(half.x + 6.0, half.y * 2.0 + 12.0)))


## Outline and the number tab. Drawn above everything.
class _FrameLayer extends Node2D:
	func _ready() -> void:
		z_index = 3

	func _draw() -> void:
		var box: ShakeBox = get_meta(&"box")
		var inner := Rect2(-ShakeBox.INNER_SIZE / 2.0, ShakeBox.INNER_SIZE).grow(6.0)
		box_outline(inner, 30.0, 8.0)

		var tab := Rect2(Vector2(-60, inner.position.y - 64), Vector2(120, 72))
		var style := StyleBoxFlat.new()
		style.bg_color = ShakeBox.TAB_FILL
		style.border_color = ShakeBox.FRAME
		style.set_border_width_all(6)
		style.corner_radius_top_left = 18
		style.corner_radius_top_right = 18
		style.anti_aliasing = true
		draw_style_box(style, tab)

		var font := ThemeDB.fallback_font
		var text := str(box.total)
		var size := 48
		var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string(font, Vector2(-text_width / 2.0, tab.position.y + 52), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, size, ShakeBox.TEXT)

	func box_outline(rect: Rect2, radius: float, width: float) -> void:
		var style := StyleBoxFlat.new()
		style.draw_center = false
		style.border_color = ShakeBox.FRAME
		style.set_border_width_all(int(width))
		style.set_corner_radius_all(int(radius))
		style.anti_aliasing = true
		draw_style_box(style, rect.grow(width / 2.0))
