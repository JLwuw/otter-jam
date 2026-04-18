class_name Bullet
extends Area2D

enum Team { PLAYER, ENEMY }
var team: Team
var speed: float = 300.0
var direction: Vector2 = Vector2.ZERO
@export var lifetime_seconds: float = 3.0
@export var despawn_when_offscreen: bool = false
@export var rotation_offset_degrees: float = 0.0
@export var lifetime_end_particles: PackedScene
@onready var sprite: Sprite2D = $Sprite2D
var lifetime_remaining: float = 0.0
var pool: Node
var release_requested: bool = false

func _ready() -> void:
	if pool != null:
		deactivate_for_pool()
		return

	activate(team, global_position, direction, speed)

func _physics_process(delta: float) -> void:
	if release_requested:
		return

	if lifetime_seconds > 0.0:
		lifetime_remaining -= delta
		if lifetime_remaining <= 0.0:
			_emit_lifetime_end_particles()
			despawn()
			return

	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if release_requested:
		return

	if team == Team.PLAYER and body.is_in_group("enemies") and body.has_method("take_damage"):
		body.call("take_damage", 1)
		_emit_lifetime_end_particles()
		despawn()

	elif team == Team.ENEMY and body.is_in_group("player") and body.has_method("take_damage"):
		body.call("take_damage", 1)
		_emit_lifetime_end_particles()
		despawn()

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	sprite.visible = true

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	# Bullets are short-lived projectiles; despawning them off-screen avoids wasted draw/update work.
	if despawn_when_offscreen:
		despawn()
		return

	sprite.visible = false

func set_pool(new_pool: Node) -> void:
	pool = new_pool

func activate(new_team: Team, spawn_position: Vector2, spawn_direction: Vector2, spawn_speed: float, spawn_rotation: float = 0.0) -> void:
	release_requested = false
	team = new_team
	global_position = spawn_position
	direction = spawn_direction
	speed = spawn_speed
	rotation = spawn_rotation + deg_to_rad(rotation_offset_degrees)
	lifetime_remaining = lifetime_seconds
	sprite.visible = true
	visible = true
	set_physics_process(true)
	monitoring = true
	monitorable = true

func deactivate_for_pool() -> void:
	release_requested = false
	direction = Vector2.ZERO
	lifetime_remaining = lifetime_seconds
	sprite.visible = false
	visible = false
	set_physics_process(false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func despawn() -> void:
	if release_requested:
		return

	release_requested = true

	if pool != null:
		if pool.has_method("release_bullet"):
			pool.call("release_bullet", self)
		return

	queue_free()

func _emit_lifetime_end_particles() -> void:
	if lifetime_end_particles == null:
		return

	var effect: GPUParticles2D = lifetime_end_particles.instantiate() as GPUParticles2D
	if effect == null:
		return

	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		scene_root = get_tree().root

	effect.top_level = true
	effect.global_position = global_position
	effect.global_rotation = rotation
	effect.emitting = false
	scene_root.add_child(effect)
	effect.restart()
	effect.emitting = true

	if effect.one_shot:
		effect.finished.connect(Callable(effect, "queue_free"), CONNECT_ONE_SHOT)
		return

	var cleanup_delay: float = max(0.1, effect.lifetime + effect.preprocess)
	var cleanup_timer: SceneTreeTimer = get_tree().create_timer(cleanup_delay)
	cleanup_timer.timeout.connect(Callable(self, "_free_effect").bind(effect), CONNECT_ONE_SHOT)


func _free_effect(effect: GPUParticles2D) -> void:
	if effect != null and is_instance_valid(effect):
		effect.queue_free()
