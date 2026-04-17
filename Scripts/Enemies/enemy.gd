class_name Enemy
extends CharacterBody2D

@export var max_health: int = 3
var current_health: int

func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")

func take_damage(amount: int = 1) -> void:
	current_health -= amount
	if current_health <= 0:
		die()

func die() -> void:
	queue_free()
