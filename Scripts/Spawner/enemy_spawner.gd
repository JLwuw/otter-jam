class_name EnemySpawner
extends Node2D

@export var player: Player
@onready var camera: Camera2D = null
@export var spawn_rect_min: Marker2D
@export var spawn_rect_max: Marker2D
var rink_rect: Rect2

@export_group("Spawn")
@export var base_spawn_interval: float = 6.0
@export var spawn_radius: float = 700
@export_range(0.0, 500.0, 5.0) var spawn_screen_margin: float = 80.0
@export_range(0.0, 2000.0, 10.0) var min_spawn_distance: float = 600.0
@export_range(1, 100, 1) var spawn_position_attempts: int = 24
@export var max_enemy_count: int = 400
@export var forbidden_angle_deg: float = 45.0

@export_group("Scaling")
@export var base_budget: float = 2.0
@export var budget_growth: float = 0.1

var time_elapsed: float = 0
var active_enemies: Array[Node] = []
@onready var current_scene_root: Node = get_tree().current_scene
@onready var spawn_timer: Timer = $Timer
var is_active: bool = true

func _ready() -> void:
	if player == null:
		push_error("EnemySpawner: missing player reference")
		is_active = false
		set_process(false)
		spawn_timer.stop()
		return
	
	if not player.died.is_connected(_on_player_died):
		player.died.connect(_on_player_died)
	
	camera = player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		camera = get_viewport().get_camera_2d()

	if spawn_rect_min == null or spawn_rect_max == null:
		printerr("EnemySpawner: missing SpawnRectMin/SpawnRectMax markers")
		is_active = false
		set_process(false)
		spawn_timer.stop()
		return

	rink_rect = get_rect_from_nodes(spawn_rect_min.global_position, spawn_rect_max.global_position)
	print("EnemySpawner bounds from markers: min=", spawn_rect_min.global_position, " max=", spawn_rect_max.global_position, " size=", rink_rect.size)	

	if rink_rect.size.x <= 1.0 or rink_rect.size.y <= 1.0:
		push_error("EnemySpawner: invalid spawn rectangle size")
		is_active = false
		set_process(false)
		spawn_timer.stop()
		return

	spawn_timer.wait_time = base_spawn_interval
	if current_scene_root == null:
		current_scene_root = get_tree().root


func _draw() -> void:
	draw_rect(rink_rect, Color.GREEN, false, 2.0)

func is_position_in_arena(pos: Vector2) -> bool:
	return rink_rect.has_point(pos)

func validate_spawn_position(pos: Vector2, enemy_name: String = "Enemy") -> void:
	if not is_position_in_arena(pos):
		print("WARNING: %s spawning at %.1f, %.1f which is OUTSIDE arena bounds!" % [enemy_name, pos.x, pos.y])
		print("  Arena bounds: position=%.1f,%.1f  end=%.1f,%.1f  size=%.1f,%.1f" % [
			rink_rect.position.x, rink_rect.position.y,
			rink_rect.end.x, rink_rect.end.y,
			rink_rect.size.x, rink_rect.size.y
		])

func get_rect_from_nodes(a: Vector2, b: Vector2) -> Rect2:
	var min_x: float = minf(a.x, b.x)
	var min_y: float = minf(a.y, b.y)
	var max_x: float = maxf(a.x, b.x)
	var max_y: float = maxf(a.y, b.y)
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))


func _process(delta: float) -> void:
	time_elapsed += delta

func get_current_budget() -> float:
	return base_budget + time_elapsed * budget_growth

func get_camera_rect() -> Rect2:
	if camera == null:
		printerr("EnemySpawner: unable to find camera")
	
	var viewport_size: Vector2 = camera.get_viewport().get_visible_rect().size
	var zoom: Vector2 = camera.zoom
	
	var size: Vector2 = viewport_size / zoom
	var top_left: Vector2 = camera.global_position - size * 0.5
	
	return Rect2(top_left, size)
	
func is_on_screen(pos: Vector2) -> bool:
	var rect: Rect2 = get_camera_rect()
	return rect.has_point(pos)

func push_outside_screen(pos: Vector2, margin: float = 80.0) -> Vector2:
	var rect: Rect2 = get_camera_rect().grow(maxf(0.0, margin))

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
	return edge_point + dir

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
	if player == null:
		return
	if scene == null:
		return
	
	var spawn_pos: Vector2 = _find_spawn_position()
	if not spawn_pos.is_finite():
		print("failed to find spawn position")
		return

	var enemy: Enemy = scene.instantiate()
	enemy.global_position = spawn_pos
	enemy.player = player

	validate_spawn_position(spawn_pos, enemy.name)

	active_enemies.append(enemy)
	enemy.tree_exited.connect(_on_enemy_removed.bind(enemy))
	current_scene_root.add_child(enemy)

	await get_tree().create_timer(0.1).timeout

func _find_spawn_position() -> Vector2:
	var move_dir: Vector2 = player.velocity.normalized()
	
	var base_angle: float = move_dir.angle()
	var half_cone: float = deg_to_rad(forbidden_angle_deg / 2.0)

	var safe_rect: Rect2 = rink_rect.grow(-5.0)
	var min_distance: float = maxf(0.0, min_spawn_distance)
	if safe_rect.size.x <= 0.0 or safe_rect.size.y <= 0.0:
		return Vector2.INF

	for attempt in range(spawn_position_attempts):
		var angle: float
		if randf() < 0.5:
			angle = randf_range(base_angle + half_cone, base_angle + PI)
		else:
			angle = randf_range(base_angle - PI, base_angle - half_cone)

		var offset: Vector2 = Vector2.RIGHT.rotated(angle) * spawn_radius
		var candidate: Vector2 = push_outside_screen(player.global_position + offset, spawn_screen_margin)
		
		# Reject out-of-bounds candidates instead of clamping them toward the player.
		if not safe_rect.has_point(candidate):
			continue
		if candidate.distance_squared_to(player.global_position) < min_distance * min_distance:
			continue
		
		print("Spawn position found in ", attempt, " attempts")
		return candidate

	# Never fall back to an unsafe position when the arena has no valid candidate.
	return Vector2.INF


func _on_timer_timeout() -> void:
	if !is_active:
		set_process(false)
		spawn_timer.stop()
		return
	spawn_with_budget()

func _on_enemy_removed(enemy: Node) -> void:
	active_enemies.erase(enemy)

func _on_player_died() -> void:
	is_active = false
