class_name ComponentThrowHazard
extends Node

@export var hazard_scene: PackedScene
@export var spawn_rate: float = 0.3
@export var hazard_speed: float = 200
@export var throw_distance: float = 200.0
@export var spawn_origin_path: NodePath = NodePath("Shoot Origin")

var owner_body: CharacterBody2D
var spawn_timer: float = 0.0
var spawn_origin_node: Node2D
@onready var current_scene_root: Node = get_tree().current_scene

func _ready() -> void:
	owner_body = get_parent()
	spawn_origin_node = owner_body.get_node_or_null(spawn_origin_path) as Node2D if owner_body != null else null
	if current_scene_root == null:
		current_scene_root = get_tree().root
	set_process(true)

func _process(delta: float) -> void:
	if spawn_rate <= 0.0:
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		throw_hazard()
		spawn_timer = 1.0 / spawn_rate

func throw_hazard() -> void:
	if hazard_scene == null or owner_body == null:
		return

	var hazard: Node2D = hazard_scene.instantiate() as Node2D
	if hazard == null:
		return
	
	# Throw at random angle
	var random_angle: float = randf() * TAU
	var throw_dir: Vector2 = Vector2(cos(random_angle), sin(random_angle)).normalized()
	
	hazard.global_position = _get_spawn_position()
	hazard.set("direction", throw_dir)
	hazard.set("speed", hazard_speed)
	hazard.set("travel_distance", throw_distance)
	
	current_scene_root.add_child(hazard)


func _get_spawn_position() -> Vector2:
	if spawn_origin_node != null:
		return spawn_origin_node.global_position

	return owner_body.global_position
