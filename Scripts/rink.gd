class_name Rink
extends Node2D

@onready var touch_particles_scene: PackedScene = load("res://Scenes/Rink/rink_touch_particles.tscn") as PackedScene
@export var touch_particles_min_speed: float = 120.0

func spawn_touch_particles(world_position: Vector2, normal: Vector2 = Vector2.ZERO, player_speed: float = 0.0) -> void:
	if player_speed < touch_particles_min_speed:
		return

	if touch_particles_scene == null:
		return

	var particles: GPUParticles2D = touch_particles_scene.instantiate() as GPUParticles2D
	if particles == null:
		return

	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		scene_root = get_tree().root

	particles.top_level = true
	particles.global_position = world_position + normal * 2.0
	if normal != Vector2.ZERO:
		particles.global_rotation = normal.angle() + PI * 0.5
	particles.emitting = false
	scene_root.add_child(particles)
	particles.restart()
	particles.emitting = true

	if particles.one_shot:
		particles.finished.connect(Callable(particles, "queue_free"), CONNECT_ONE_SHOT)
		return

	var cleanup_delay: float = max(0.1, particles.lifetime + particles.preprocess)
	var cleanup_timer: SceneTreeTimer = get_tree().create_timer(cleanup_delay)
	cleanup_timer.timeout.connect(Callable(self, "_free_rink_particles").bind(particles), CONNECT_ONE_SHOT)


func _free_rink_particles(particles: GPUParticles2D) -> void:
	if particles != null and is_instance_valid(particles):
		particles.queue_free()
