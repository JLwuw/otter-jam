class_name ComponentPlayerChase
extends Node

@export_group("Movement")
@export var responsiveness: float = 55
@export var acceleration_factor: float = 30
@export var max_speed: float = 200
@export var drag: float = 0.5

var owner_body: CharacterBody2D
var player: Player
var has_warned_missing_player: bool = false
var max_speed_sq: float = 0.0

func _ready() -> void:
	owner_body = get_parent() as CharacterBody2D
	max_speed_sq = max_speed * max_speed

func _physics_process(delta: float) -> void:
	if owner_body == null:
		return

	if player == null:
		if not has_warned_missing_player:
			push_warning("No player in Slow Chase Component")
			has_warned_missing_player = true
		return

	has_warned_missing_player = false
	
	var direction: Vector2 = (player.global_position - owner_body.global_position).normalized()
	direction *= acceleration_factor
	var acceleration: Vector2 = owner_body.velocity.lerp(direction, delta * responsiveness) 
	owner_body.velocity += delta * acceleration
	
	if owner_body.velocity.length_squared() > max_speed_sq:
		owner_body.velocity = owner_body.velocity.normalized() * max_speed
	
	owner_body.move_and_slide()
