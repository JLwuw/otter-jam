class_name ComponentBasicShoot
extends Node

signal shot_fired

@export var bullet_scene: PackedScene
@export var fire_rate: float = 1.5
@export var bullet_speed: float = 600
@export_node_path("Node2D") var bullet_spawn_path: NodePath = ^""

var player: Node2D
var owner_body: CharacterBody2D
var shoot_timer: float = 0.0
var has_warned_missing_player: bool = false
var fire_interval: float = INF
@onready var current_scene_root: Node = get_tree().current_scene
var bullet_pool: Node
var bullet_spawn_node: Node2D

func _ready() -> void:
	owner_body = get_parent() as CharacterBody2D
	if fire_rate > 0.0:
		fire_interval = 1.0 / fire_rate
	if current_scene_root == null:
		current_scene_root = get_tree().root
	bullet_pool = current_scene_root.get_node_or_null("BulletPool")
	if owner_body != null and bullet_spawn_path != NodePath(""):
		bullet_spawn_node = owner_body.get_node_or_null(bullet_spawn_path) as Node2D

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

	var spawn_position: Vector2 = owner_body.global_position
	if bullet_spawn_node != null:
		spawn_position = bullet_spawn_node.global_position

	var dir: Vector2 = (player.global_position - spawn_position).normalized()
	if bullet_pool != null and bullet_pool.has_method("get_bullet"):
		bullet_pool.call("get_bullet", Bullet.Team.ENEMY, spawn_position, dir, bullet_speed, dir.angle(), bullet_scene)
		emit_signal("shot_fired")
		return

	var bullet: Bullet = bullet_scene.instantiate()
	bullet.global_position = spawn_position
	bullet.direction = dir
	bullet.team = Bullet.Team.ENEMY
	bullet.speed = bullet_speed
	bullet.rotation = dir.angle()
	current_scene_root.add_child(bullet)
	emit_signal("shot_fired")
