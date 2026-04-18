class_name EnemySpawner
extends Node2D

@export var player: Player
@onready var camera: Camera2D = player.get_node("Camera2D")

@export_group("Spawn")
@export var base_spawn_interval: float = 6.0
@export var spawn_radius: float = 600
@export var max_enemy_count: int = 400
@export var forbidden_angle_deg: float = 45.0

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

func get_camera_rect() -> Rect2:
	var viewport_size: Vector2 = camera.get_viewport().get_visible_rect().size
	var zoom: Vector2 = camera.zoom
	
	var size: Vector2 = viewport_size / zoom
	var top_left: Vector2 = camera.global_position - size * 0.5
	
	return Rect2(top_left, size)
	
func is_on_screen(pos: Vector2) -> bool:
	var rect: Rect2 = get_camera_rect()
	return rect.has_point(pos)

func get_closest_point_on_rect(rect: Rect2, point: Vector2) -> Vector2:
	return Vector2(
		clamp(point.x, rect.position.x, rect.end.x),
		clamp(point.y, rect.position.y, rect.end.y)
	)

func push_outside_screen(pos: Vector2, margin: float = 20.0) -> Vector2:
	var rect: Rect2 = get_camera_rect()

	if not rect.has_point(pos):
		return pos
	
	var center: Vector2 = rect.position + rect.size * 0.5
	var dir: Vector2 = (pos - center).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT.rotated(randf_range(0.0, TAU))

	var tx: float = INF
	var ty: float = INF
	if absf(dir.x) > 0.0001:
		tx = (rect.size.x * 0.5) / absf(dir.x)
	if absf(dir.y) > 0.0001:
		ty = (rect.size.y * 0.5) / absf(dir.y)

	var t: float = minf(tx, ty)
	var edge_point: Vector2 = center + dir * t
	return edge_point + dir * margin

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
	var move_dir: Vector2 = player.velocity.normalized()
	
	var base_angle: float = move_dir.angle()
	var half_cone: float = deg_to_rad(forbidden_angle_deg / 2.0)

	var angle: float

	if randf() < 0.5:
		angle = randf_range(base_angle + half_cone, base_angle + PI)
	else:
		angle = randf_range(base_angle - PI, base_angle - half_cone)
	
	var offset: Vector2 = Vector2.RIGHT.rotated(angle) * spawn_radius
	
	var spawn_pos: Vector2 = player.global_position + offset
	spawn_pos = push_outside_screen(spawn_pos)

	enemy.global_position = spawn_pos
	enemy.player = player
	
	active_enemies.append(enemy)
	enemy.tree_exited.connect(_on_enemy_removed.bind(enemy))

	current_scene_root.add_child(enemy)
	await get_tree().create_timer(0.1).timeout


func _on_timer_timeout() -> void:
	spawn_with_budget()

func _on_enemy_removed(enemy: Node) -> void:
	active_enemies.erase(enemy)
