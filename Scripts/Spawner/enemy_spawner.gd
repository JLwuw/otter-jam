class_name EnemySpawner
extends Node2D

@export var player: Player
@onready var camera: Camera2D = null
@export var rink: Rink
@export var spawn_rect_min_path: NodePath = NodePath("SpawnRectMin")
@export var spawn_rect_max_path: NodePath = NodePath("SpawnRectMax")
@export var allow_rink_fallback: bool = false
var rink_rect: Rect2

@export_group("Spawn")
@export var base_spawn_interval: float = 6.0
@export var spawn_radius: float = 700
@export var max_enemy_count: int = 400
@export var forbidden_angle_deg: float = 45.0

@export_group("Scaling")
@export var base_budget: float = 2.0
@export var budget_growth: float = 0.1

var time_elapsed: float = 0
var active_enemies: Array[Node] = []
@onready var current_scene_root: Node = get_tree().current_scene
@onready var spawn_timer: Timer = $Timer
@onready var spawn_rect_min_node: Node2D = get_node_or_null(spawn_rect_min_path) as Node2D
@onready var spawn_rect_max_node: Node2D = get_node_or_null(spawn_rect_max_path) as Node2D
var is_active: bool = true

func _ready() -> void:
	if player == null:
		player = get_parent().get_node_or_null("Player") as Player
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

	var parent_spawn_rect_min: Node2D = get_parent().get_node_or_null("SpawnRectMin") as Node2D
	var parent_spawn_rect_max: Node2D = get_parent().get_node_or_null("SpawnRectMax") as Node2D
	if parent_spawn_rect_min != null and parent_spawn_rect_max != null:
		spawn_rect_min_node = parent_spawn_rect_min
		spawn_rect_max_node = parent_spawn_rect_max

	if spawn_rect_min_node == null:
		spawn_rect_min_node = get_parent().get_node_or_null("SpawnRectMin") as Node2D
	if spawn_rect_max_node == null:
		spawn_rect_max_node = get_parent().get_node_or_null("SpawnRectMax") as Node2D
	
	if spawn_rect_min_node != null and spawn_rect_max_node != null:
		rink_rect = get_rect_from_nodes(spawn_rect_min_node.global_position, spawn_rect_max_node.global_position)
		print("EnemySpawner bounds from markers: min=", spawn_rect_min_node.global_position, " max=", spawn_rect_max_node.global_position, " size=", rink_rect.size)
	else:
		if not allow_rink_fallback:
			push_error("EnemySpawner: missing SpawnRectMin/SpawnRectMax markers")
			is_active = false
			set_process(false)
			spawn_timer.stop()
			return

		if rink == null:
			rink = get_parent().get_node_or_null("Rink") as Rink
		if rink == null:
			push_error("EnemySpawner: missing spawn rect nodes and rink reference")
			is_active = false
			set_process(false)
			spawn_timer.stop()
			return
		
		var rink_tilemap: TileMapLayer = rink.get_node_or_null("TileMapLayer") as TileMapLayer
		if rink_tilemap == null:
			push_error("EnemySpawner: missing spawn rect nodes and Rink TileMapLayer")
			is_active = false
			set_process(false)
			spawn_timer.stop()
			return
		
		rink_rect = get_tilemap_world_rect(rink_tilemap)
		push_warning("EnemySpawner: using rink tilemap bounds fallback; assign SpawnRectMin and SpawnRectMax")

	if rink_rect.size.x <= 1.0 or rink_rect.size.y <= 1.0:
		push_error("EnemySpawner: invalid spawn rectangle size")
		is_active = false
		set_process(false)
		spawn_timer.stop()
		return

	spawn_timer.wait_time = base_spawn_interval
	if current_scene_root == null:
		current_scene_root = get_tree().root
		
#func _draw() -> void:
	#draw_rect(rink_rect, Color.GREEN, false, 2.0)

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

func get_tilemap_world_rect(tilemap: TileMapLayer) -> Rect2:
	var used_rect: Rect2i = tilemap.get_used_rect()
	
	var top_left: Vector2 = tilemap.to_global(tilemap.map_to_local(used_rect.position))
	var bottom_right: Vector2 = tilemap.to_global(
		tilemap.map_to_local(used_rect.position + used_rect.size)
	)
	
	top_left.x += 120
	top_left.y += 80
	
	bottom_right.x -= 40
	bottom_right.y -= 40
	
	var rect: Rect2 = Rect2(top_left, bottom_right - top_left)
	return rect.grow(-50.0)

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
		var fallback_center: Vector2 = player.global_position if player != null else global_position
		return Rect2(fallback_center - Vector2(640, 360), Vector2(1280, 720))
	
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
	if player == null:
		return
	if scene == null:
		return
	
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
	spawn_pos = clamp_to_arena(spawn_pos, rink_rect)

	enemy.global_position = spawn_pos
	enemy.player = player
	
	# Validate spawn position
	validate_spawn_position(spawn_pos, enemy.name)
	
	# Ensure enemy collider is set up before adding to scene
	if enemy.has_node("CollisionShape2D"):
		var collision_shape: CollisionShape2D = enemy.get_node("CollisionShape2D") as CollisionShape2D
		if collision_shape != null and collision_shape.shape != null:
			var shape_size: float = 0.0
			if collision_shape.shape is CircleShape2D:
				shape_size = (collision_shape.shape as CircleShape2D).radius
			elif collision_shape.shape is RectangleShape2D:
				shape_size = (collision_shape.shape as RectangleShape2D).size.length() * 0.5
			
			# Re-clamp with collision shape taken into account
			if shape_size > 0:
				var tight_rect: Rect2 = rink_rect.grow(-shape_size)
				spawn_pos = Vector2(
					clamp(spawn_pos.x, tight_rect.position.x, tight_rect.end.x),
					clamp(spawn_pos.y, tight_rect.position.y, tight_rect.end.y)
				)
				enemy.global_position = spawn_pos
	
	active_enemies.append(enemy)
	enemy.tree_exited.connect(_on_enemy_removed.bind(enemy))

	current_scene_root.add_child(enemy)
	
	# Wait a frame for the enemy to initialize, then validate position again
	await get_tree().process_frame
	if enemy != null and is_instance_valid(enemy):
		if not is_position_in_arena(enemy.global_position):
			# Enemy somehow moved outside - force it back in
			var corrected_pos: Vector2 = clamp_to_arena(enemy.global_position, rink_rect)
			enemy.global_position = corrected_pos
			print("Enemy was outside arena after spawn, repositioned to: %.1f, %.1f" % [corrected_pos.x, corrected_pos.y])
	
	await get_tree().create_timer(0.1).timeout

func clamp_to_arena(pos: Vector2, rect: Rect2) -> Vector2:
	# Ensure the position is strictly within bounds with a small safety margin
	var safety_margin: float = 5.0
	var safe_rect: Rect2 = rect.grow(-safety_margin)
	
	# Make sure safe_rect is valid before clamping
	if safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
		# Fallback if rect is too small - just use the original rect
		return Vector2(
			clamp(pos.x, rect.position.x, rect.end.x),
			clamp(pos.y, rect.position.y, rect.end.y)
		)
	
	return Vector2(
		clamp(pos.x, safe_rect.position.x, safe_rect.end.x),
		clamp(pos.y, safe_rect.position.y, safe_rect.end.y)
	)

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
