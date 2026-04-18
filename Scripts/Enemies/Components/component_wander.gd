class_name ComponentWander
extends Node

@export_group("Movement")
@export var acceleration_factor: float = 12
@export var max_speed: float = 50
@export var drag: float = 0.5
@export var direction_change_interval: float = 2.0

var owner_body: CharacterBody2D
var wander_direction: Vector2 = Vector2.RIGHT
var direction_timer: float = 0.0

func _ready() -> void:
	owner_body = get_parent() as CharacterBody2D
	if owner_body == null:
		push_warning("No owner body for Wander Component")
		set_physics_process(false)
		return

	direction_timer = direction_change_interval
	_pick_new_direction()
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	if owner_body == null:
		return

	# Update direction timer
	direction_timer -= delta
	if direction_timer <= 0.0:
		_pick_new_direction()
		direction_timer = direction_change_interval
	
	# Apply movement
	var acceleration: Vector2 = owner_body.velocity.lerp(wander_direction * acceleration_factor, delta * 5)
	owner_body.velocity += delta * acceleration
	
	# Clamp speed
	if owner_body.velocity.length() > max_speed:
		owner_body.velocity = owner_body.velocity.normalized() * max_speed
	
	owner_body.move_and_slide()

func set_active(is_active: bool) -> void:
	set_physics_process(is_active)

func reset_direction_timer() -> void:
	direction_timer = direction_change_interval
	_pick_new_direction()

func _pick_new_direction() -> void:
	var random_angle: float = randf() * TAU
	wander_direction = Vector2(cos(random_angle), sin(random_angle)).normalized()
