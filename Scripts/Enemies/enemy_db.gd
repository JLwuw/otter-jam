extends Node

var enemy_data_list: Array[EnemyData] = []

func init(enemy_scenes: Array[PackedScene]) -> void:
	enemy_data_list.clear()
	
	for scene in enemy_scenes:
		var enemy: Enemy = scene.instantiate()
		var enemy_data: EnemyData = EnemyData.new(
			scene,
			enemy.toughness,
			enemy.unlock_time
		)
		enemy_data_list.append(enemy_data)
		enemy.queue_free()

func get_available_enemies(time_elapsed: float) -> Array[EnemyData]:
	var available: Array[EnemyData] = []
	
	for enemy in enemy_data_list:
		if time_elapsed >= enemy.unlock_time:
			available.append(enemy)
	
	return available
