class_name BulletSpawner
extends Node2D

@export var bullet_scene: PackedScene = preload("res://Scenes/Bullet/bullet.tscn")
@export var spawn_rate: float = 0.5

var timer: float = 0.0

func _process(delta: float) -> void:
	timer += delta
	if timer >= spawn_rate:
		spawn_bullet()
		timer = 0.0

func spawn_bullet() -> void:
	var bullet: Bullet = bullet_scene.instantiate()
	
	var spawn_pos := global_position
	bullet.global_position = spawn_pos

	var dir := Vector2(randf(), randf())
	bullet.direction = dir
	bullet.team = Bullet.Team.ENEMY
	
	add_child(bullet)
