class_name Marble
extends RigidBody2D

## One marble in a shake box. Builds its own collision shape so the box can
## spawn any number of them at any size.

## Hard cap so a violent shake can't tunnel a marble through a wall.
const MAX_SPEED := 1500.0

const COLOR := Color(0.08, 0.85, 0.75)
const SHADE := Color(0.05, 0.66, 0.6)
const SHINE := Color(1, 1, 1, 0.75)

var radius: float = 20.0


func _init(marble_radius: float = 20.0) -> void:
	radius = marble_radius
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

	var material := PhysicsMaterial.new()
	material.bounce = 0.35
	material.friction = 0.4
	physics_material_override = material
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	# Damping stands in for rolling resistance; without it marbles roll on
	# a flat floor for seconds before the box counts as settled.
	linear_damp = 0.6
	angular_damp = 4.0


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.linear_velocity.length() > MAX_SPEED:
		state.linear_velocity = state.linear_velocity.limit_length(MAX_SPEED)


func _draw() -> void:
	# Drawn without rotation so the highlight always sits top-left.
	draw_set_transform(Vector2.ZERO, -rotation)
	draw_circle(Vector2.ZERO, radius, SHADE)
	draw_circle(Vector2(-radius * 0.08, -radius * 0.08), radius * 0.9, COLOR)
	draw_circle(Vector2(-radius * 0.35, -radius * 0.35), radius * 0.22, SHINE)


func _physics_process(_delta: float) -> void:
	if not sleeping:
		queue_redraw()
