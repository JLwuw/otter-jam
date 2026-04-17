extends Node

var enemy_data: Array[PackedScene] = []

func init(enemy_scenes: Array[PackedScene]) -> void:
	enemy_data.clear()
	
	for scene in enemy_scenes:
		var enemy: Enemy = scene.instantiate()
		
		if not enemy.has_variable("toughness"):
			continue
		
		
		enemy_data.append({
			"scene": scene,
			"toughness": enemy.toughness,
			"unlock_time": enemy.unlock_time
		})
		
		enemy.queue_free()

func get_available_enemies(time_elapsed: float) -> Array:
	var available: Array = []
	
	for data in enemy_data:
		if time_elapsed >= data["unlock_time"]:
			available.append(data)
	
	return available
