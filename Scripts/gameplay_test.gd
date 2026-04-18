extends Node2D

var enemy_scenes: Array[PackedScene] = [
	preload("res://Scenes/Enemies/enemy_slow_chaser.tscn"),
	preload("res://Scenes/Enemies/enemy_slow_shooter.tscn")
]

func _ready() -> void:
	EnemyDB.init(enemy_scenes)
