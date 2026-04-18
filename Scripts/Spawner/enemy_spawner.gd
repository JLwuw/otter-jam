class_name EnemySpawner
extends Node2D

@export var player: Player

@export_group("Spawn")
@export var base_spawn_interval: float = 6.0
@export var spawn_radius: float = 20.0
@export var max_enemy_count: int = 5

@export_group("Scaling")
@export var base_budget: float = 2.0
@export var budget_growth: float = 0.1

var time_elapsed: float = 0
var active_enemies: Array[Node] = []
@onready var current_scene_root: Node = get_tree().current_scene
@onready var spawn_timer: Timer = $Timer

func _ready() -> void:
	spawn_timer.wait_time = base_spawn_interval
	if current_scene_root == null:
		current_scene_root = get_tree().root

func _process(delta: float) -> void:
	time_elapsed += delta

func get_current_budget() -> float:
	return base_budget + time_elapsed * budget_growth


func spawn_with_budget() -> void:
	if active_enemies.size() >= max_enemy_count:
		return
	
	var budget: float = get_current_budget()
	var available_enemies: Array[EnemyData] = EnemyDB.get_available_enemies(time_elapsed)
	
	if available_enemies.is_empty():
		print("No enemies found in DB")
		return
	
	while budget > 0:
		var choice: EnemyData = pick_affordable_enemy(available_enemies, budget)
		if choice == null:
			break
		
		await spawn_enemy(choice.scene)
		
		if active_enemies.size() >= max_enemy_count:
			return
			
		spawn_enemy(choice.scene)
		budget -= choice.toughness


func pick_affordable_enemy(available_enemies: Array[EnemyData], budget: float) -> EnemyData:
	var choice: EnemyData = null
	var valid_count: int = 0

	for enemy in available_enemies:
		if enemy.toughness <= budget:
			valid_count += 1
			if randi() % valid_count == 0:
				choice = enemy

	return choice

func spawn_enemy(scene: PackedScene) -> void:
	var enemy: Enemy = scene.instantiate()
	
	var angle: float = randf() * TAU
	var offset: Vector2 = Vector2.RIGHT.rotated(angle) * spawn_radius
	
	enemy.global_position = global_position + offset
	enemy.player = player
	
	active_enemies.append(enemy)
	enemy.tree_exited.connect(_on_enemy_removed.bind(enemy))

	current_scene_root.add_child(enemy)
	await get_tree().create_timer(0.1).timeout


func _on_timer_timeout() -> void:
	spawn_with_budget()

func _on_enemy_removed(enemy: Node) -> void:
	active_enemies.erase(enemy)
