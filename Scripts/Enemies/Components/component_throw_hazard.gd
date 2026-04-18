class_name ComponentThrowHazard
extends Node

@export var hazard_scene: PackedScene
@export var spawn_rate: float = 1
@export var hazard_speed: float = 200
@export var throw_distance: float = 200.0

var owner_body: CharacterBody2D
var spawn_timer: float = 0.0

func _ready() -> void:
	owner_body = get_parent()
	set_process(true)

func _process(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		throw_hazard()
		spawn_timer = 1.0 / spawn_rate

func throw_hazard() -> void:
	var hazard: Hazard = hazard_scene.instantiate()
	
	# Throw at random angle
	var random_angle: float = randf() * TAU
	var throw_dir: Vector2 = Vector2(cos(random_angle), sin(random_angle)).normalized()
	
	hazard.global_position = owner_body.global_position
	hazard.direction = throw_dir
	hazard.speed = hazard_speed
	hazard.travel_distance = throw_distance
	
	get_tree().current_scene.add_child(hazard)
