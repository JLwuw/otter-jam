class_name Rink
extends Node2D

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var touch_particles_scene: PackedScene = load("res://Scenes/Rink/rink_touch_particles.tscn") as PackedScene
@export var touch_particles_min_speed: float = 120.0
@onready var particle_cooldown_timer: Timer = $ParticleCooldown

func spawn_touch_particles(world_position: Vector2, normal: Vector2 = Vector2.ZERO, player_speed: float = 0.0) -> void:
	if not particle_cooldown_timer:
		printerr("Rink Timer no longer with us")
		return
	
	if not particle_cooldown_timer.is_stopped():
		return
		
	if player_speed < touch_particles_min_speed:
		return

	if touch_particles_scene == null:
		return

	var particles: GPUParticles2D = touch_particles_scene.instantiate() as GPUParticles2D
	if particles == null:
		return
	
	if not particles.one_shot:
		printerr("Bullet lifetime end particles should be one-shot")
		return

	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		scene_root = get_tree().root

	particles.top_level = true
	particles.global_position = world_position + normal * 2.0
	if normal != Vector2.ZERO:
		particles.global_rotation = normal.angle() + PI * 0.5
	scene_root.add_child(particles)
	
	particles.finished.connect(
		Callable(particles, "queue_free"),
		CONNECT_ONE_SHOT
	)

	particles.restart()
	
	particle_cooldown_timer.start()


func _free_rink_particles(particles: GPUParticles2D) -> void:
	if particles != null and is_instance_valid(particles):
		particles.queue_free()
