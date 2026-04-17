class_name Enemy
extends CharacterBody2D

@export var max_health: int = 3
@export var toughness: int = 1
@export var unlock_timer: int = 0
@export var player: Player

var current_health: int = 3

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		die()

func die() -> void:
	queue_free()
