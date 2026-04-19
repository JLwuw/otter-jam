class_name HazardSpawner
extends Node2D

@export var player: Player
@onready var camera: Camera2D = player.get_node("Camera2D") if player else null
@export var rink: Rink

# Spawning parameters
@export var spawn_start_time: float = 0.0  # Start spawning immediately for debugging
@export var initial_spawn_interval: float = 8.0  # Very rare at start
@export var minimum_spawn_interval: float = 1.0  # Become very frequent
@export var interval_decrease_rate: float = 0.03  # How quickly interval decreases
@export var spawn_radius: float = 400.0  # Distance from player to spawn icicles
@export var max_icicles: int = 50

# Icicle scene
@export var icicle_scene: PackedScene = preload("res://Scenes/Risks/risk_falling.tscn")

var time_elapsed: float = 0.0
var spawn_timer: float = 0.0
var active_icicles: Array[Node] = []
@onready var current_scene_root: Node = get_tree().current_scene

func _ready() -> void:
	if current_scene_root == null:
		current_scene_root = get_tree().root
	spawn_timer = initial_spawn_interval

func _process(delta: float) -> void:
	time_elapsed += delta
	
	# Only spawn after spawn_start_time
	if time_elapsed < spawn_start_time:
		return
	
	spawn_timer -= delta
	
	if spawn_timer <= 0.0:
		spawn_icicle()
		spawn_timer = get_current_spawn_interval()

func get_current_spawn_interval() -> float:
	# Calculate how much time has passed since spawning started
	var time_since_start: float = time_elapsed - spawn_start_time
	
	# Exponentially decrease the spawn interval
	var new_interval: float = initial_spawn_interval * exp(-interval_decrease_rate * time_since_start)
	
	# Clamp to minimum interval
	return maxf(new_interval, minimum_spawn_interval)

func spawn_icicle() -> void:
	if active_icicles.size() >= max_icicles:
		return
	
	var icicle: Node2D = icicle_scene.instantiate()
	
	# Spawn around the player at a random angle
	var angle: float = randf_range(0.0, TAU)
	var offset: Vector2 = Vector2.RIGHT.rotated(angle) * spawn_radius
	var spawn_pos: Vector2 = player.global_position + offset
	
	# Add some random variation to the spawn position
	spawn_pos += Vector2.ONE.rotated(randf_range(0.0, TAU)) * randf_range(-50, 50)
	
	icicle.global_position = spawn_pos
	
	# Configure the hazard to fall from the sky
	if icicle is Hazard:
		icicle.direction = Vector2.DOWN
		icicle.speed = randf_range(150.0, 250.0)
		icicle.travel_distance = randf_range(150.0, 250.0)
	
	active_icicles.append(icicle)
	icicle.tree_exited.connect(_on_icicle_removed.bind(icicle))
	
	current_scene_root.add_child(icicle)

func _on_icicle_removed(icicle: Node) -> void:
	active_icicles.erase(icicle)
