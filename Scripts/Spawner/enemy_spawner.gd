class_name EnemySpawner
extends Node2D

@export var player: Player

@export_group("Spawn")
@export var base_spawn_rate: float = 1.0
@export var spawn_radius: float = 600.0

@export_group("Scaling")
@export var base_budget: float = 5.0
@export var budget_growth: float = 0.5

var time_elapsed: float = 0.0
var spawn_timer: float = 0.0

func get_current_budget() -> float:
	return base_budget + time_elapsed * budget_growth


func spawn_with_budget() -> void:
	var budget: float = get_current_budget()
	var available: Array[PackedScene] = EnemyDB.get_available_enemies(time_elapsed)
	
	if available.is_empty():
		return
	
	while budget > 0:
		var valid: Array[PackedScene] = []
		
		for data in available:
			if data["toughness"] <= budget:
				valid.append(data)
		
		if valid.is_empty():
			break
		
		var choice: PackedScene = valid.pick_random()
		
		spawn_enemy(choice["scene"])
		
		budget -= choice["toughness"]


func spawn_enemy(scene: PackedScene) -> void:
	var enemy: Enemy = scene.instantiate()
	
	var angle: float = randf() * TAU
	var offset: Vector2 = Vector2.RIGHT.rotated(angle) * spawn_radius
	
	enemy.global_position = global_position + offset
	enemy.player = player
	
	await get_tree().create_timer(0.1).timeout


func _on_timer_timeout() -> void:
	spawn_with_budget()
