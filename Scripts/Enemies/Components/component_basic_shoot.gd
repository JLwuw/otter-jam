class_name ComponentBasicShoot
extends Node

@export var bullet_scene: PackedScene
@export var fire_rate: float = 1.5
@export var bullet_speed: float = 200

var player: Node2D
var owner_body: CharacterBody2D
var shoot_timer: float = 0.0
var has_warned_missing_player: bool = false
var fire_interval: float = INF
@onready var current_scene_root: Node = get_tree().current_scene
var bullet_pool: Node

func _ready() -> void:
	owner_body = get_parent() as CharacterBody2D
	if fire_rate > 0.0:
		fire_interval = 1.0 / fire_rate
	if current_scene_root == null:
		current_scene_root = get_tree().root
	bullet_pool = current_scene_root.get_node_or_null("BulletPool")

func _process(delta: float) -> void:
	if owner_body == null:
		return

	if player == null:
		if not has_warned_missing_player:
			push_warning("No player found in Basic Shoot Component")
			has_warned_missing_player = true
		return

	has_warned_missing_player = false

	shoot_timer -= delta

	if shoot_timer <= 0.0:
		shoot()
		shoot_timer = fire_interval

func shoot() -> void:
	if bullet_scene == null:
		return

	var dir: Vector2 = (player.global_position - owner_body.global_position).normalized()
	if bullet_pool != null and bullet_pool.has_method("get_bullet"):
		bullet_pool.call("get_bullet", Bullet.Team.ENEMY, owner_body.global_position, dir, bullet_speed, dir.angle(), bullet_scene)
		return

	var bullet: Bullet = bullet_scene.instantiate()
	bullet.global_position = owner_body.global_position
	bullet.direction = dir
	bullet.team = Bullet.Team.ENEMY
	bullet.speed = bullet_speed
	bullet.rotation = dir.angle()
	current_scene_root.add_child(bullet)
