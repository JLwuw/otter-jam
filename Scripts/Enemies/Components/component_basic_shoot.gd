class_name ComponentBasicShoot
extends Node

@export var bullet_scene: PackedScene
@export var fire_rate: float = 1.5

var player: Node2D
var owner_body: CharacterBody2D
var shoot_timer: float = 0.0

func _ready() -> void:
	owner_body = get_parent()
	set_process(true)

func _process(delta: float) -> void:
	if player == null:
		print("No player found in Basic Shoot Component")
		return

	shoot_timer -= delta

	if shoot_timer <= 0.0:
		shoot()
		shoot_timer = 1.0 / fire_rate

func shoot() -> void:
	var bullet: Bullet = bullet_scene.instantiate()
	bullet.global_position = owner_body.global_position

	var dir: Vector2 = (player.global_position - bullet.global_position).normalized()
	bullet.direction = dir
	bullet.team = Bullet.Team.ENEMY

	get_tree().current_scene.add_child(bullet)
