class_name Player
extends CharacterBody2D

@export_category("Movement")
@export var max_speed: float = 400.0
@export var responsiveness: float = 8.0
@export var drag: float = 3.0
@export var max_distance: float = 200.0

@export_category("Combat")
@export var max_health: int = 5
@onready var current_health: int = max_health

@export var invuln_time: float = 0.3
var invuln_timer: float = 0


func _physics_process(delta: float) -> void:
	var to_mouse: Vector2 = get_global_mouse_position() - global_position
	var distance_to_mouse: float = to_mouse.length()
	clamp(distance_to_mouse, 0, max_distance)

	if distance_to_mouse < 5:
		velocity *= 0.8
		move_and_slide()
		return

	velocity += to_mouse / responsiveness
	
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
	
	velocity *= 1.0 / (1.0 + drag * delta)

	move_and_slide()

func _process(delta: float) -> void:
	if invuln_timer > 0.0:
		invuln_timer -= delta

func take_damage(amount: int = 1) -> void:
	if invuln_timer > 0: return
	print("Taking damage!")
	current_health -= amount
	if current_health <= 0: die()
	invuln_timer = invuln_time
		
func die() -> void:
	print("ggwp")
