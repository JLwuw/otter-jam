extends Node

@export var waves: Array[Wave]
@export var player: Node2D

var current_wave_index: int = 0

func _ready() -> void:
	start_waves()

func start_waves() -> void:
	await run_all_waves()
	print("All waves completed!")

func run_all_waves() -> void:
	for wave in waves:
		await run_wave(wave)

func run_wave(wave: Wave) -> void:
	for sub_wave in wave.sub_waves:
		await run_subwave(sub_wave)

func run_subwave(sub_wave: SubWave) -> void:
	for i in sub_wave.count:
		spawn_enemy(sub_wave)
		await get_tree().create_timer(sub_wave.spawn_delay).timeout

	await get_tree().create_timer(sub_wave.delay_after).timeout

func spawn_enemy(sub_wave: SubWave) -> void:
	if sub_wave.enemy_scene == null:
		return

	var enemy: Enemy = sub_wave.enemy_scene.instantiate()

	# Spawn in a circle around player
	var angle: float = randf() * TAU
	var radius: float = sub_wave.spawn_radius

	var offset: Vector2 = Vector2.RIGHT.rotated(angle) * radius
	enemy.global_position = player.global_position + offset

	if enemy.has_variable("player"):
		enemy.player = player

	get_tree().current_scene.add_child(enemy)

func wait_until_enemies_dead() -> void:
	while get_tree().get_nodes_in_group("enemies").size() > 0:
		await get_tree().process_frame
