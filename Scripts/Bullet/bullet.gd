class_name Bullet
extends Area2D

enum Team { PLAYER, ENEMY }
var team: Team
var speed: float = 300.0
var direction: Vector2 = Vector2.ZERO
@export var lifetime_seconds: float = 3.0
@export var despawn_when_offscreen: bool = false
@onready var sprite: Sprite2D = $Sprite2D
var lifetime_remaining: float = 0.0
var pool: BulletPool
var release_requested: bool = false

func _ready() -> void:
	if pool != null:
		deactivate_for_pool()
		return

	activate(team, global_position, direction, speed)

func _physics_process(delta: float) -> void:
	if lifetime_seconds > 0.0:
		lifetime_remaining -= delta
		if lifetime_remaining <= 0.0:
			despawn()
			return

	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if team == Team.PLAYER and body.is_in_group("enemies") and body.has_method("take_damage"):
		body.call("take_damage", 1)
		despawn()

	elif team == Team.ENEMY and body.is_in_group("player") and body.has_method("take_damage"):
		body.call("take_damage", 1)
		despawn()

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	sprite.visible = true

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	# Bullets are short-lived projectiles; despawning them off-screen avoids wasted draw/update work.
	if despawn_when_offscreen:
		despawn()
		return

	sprite.visible = false

func set_pool(new_pool: BulletPool) -> void:
	pool = new_pool

func activate(new_team: Team, spawn_position: Vector2, spawn_direction: Vector2, spawn_speed: float) -> void:
	release_requested = false
	team = new_team
	global_position = spawn_position
	direction = spawn_direction
	speed = spawn_speed
	lifetime_remaining = lifetime_seconds
	_apply_team_color()
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
	if pool != null:
		if release_requested:
			return
		release_requested = true
		pool.release_bullet(self)
		return

	queue_free()

func _apply_team_color() -> void:
	if team == Team.PLAYER:
		sprite.self_modulate = Color(1, 1, 0)
	elif team == Team.ENEMY:
		sprite.self_modulate = Color(1, 0, 0)
