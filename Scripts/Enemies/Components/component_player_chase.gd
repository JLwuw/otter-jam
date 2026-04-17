class_name ComponentPlayerChase
extends Node

@export_group("Movement")
@export var responsiveness: float = 55
@export var acceleration_factor: float = 15
@export var max_speed: float = 100
@export var drag: float = 0.5

var owner_body: CharacterBody2D
var player: Player

func _ready() -> void:
	owner_body = get_parent()

func _physics_process(delta: float) -> void:
	if player == null:
		print("No player in Slow Chase Component")
		return
	
	var direction: Vector2 = (player.global_position- owner_body.global_position).normalized()
	direction *= acceleration_factor
	var acceleration: Vector2 = owner_body.velocity.lerp(direction, delta * responsiveness) 
	owner_body.velocity += delta * acceleration
	
	if owner_body.velocity.length() > max_speed:
		owner_body.velocity = owner_body.velocity.normalized() * max_speed
	
	owner_body.move_and_slide()
