class_name ComponentSlowChase
extends Node

@export_group("Movement")
@export var acceleration: float = 10.0
@export var max_speed: float = 100

var owner_body: CharacterBody2D
var player: Player

func _ready() -> void:
	owner_body = get_parent()

func _physics_process(_delta: float) -> void:
	if player == null:
		print("No player in Slow Chase Component")
		return
		
	var direction: Vector2 = (player.global_position - owner_body.global_position).normalized()
	owner_body.velocity += direction * acceleration
	
	if owner_body.velocity.length() > max_speed:
		owner_body.velocity = owner_body.velocity.normalized() * max_speed
	
	owner_body.move_and_slide()
