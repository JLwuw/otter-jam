class_name Enemy
extends CharacterBody2D

@export var max_health: int = 3
@export var toughness: int = 1
@export var unlock_time: int = 0
@export var player: Player

var current_health: int = 3

signal died(toughness: int)

func _ready() -> void:
	current_health = max_health
	died.connect(ScoreManager._on_enemy_died)

func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		die()

func die() -> void:
	emit_signal("died", toughness)
	queue_free()
