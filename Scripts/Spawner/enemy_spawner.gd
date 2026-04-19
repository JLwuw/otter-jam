class_name EnemySpawner
extends Node2D

@export var player: Player
@onready var camera: Camera2D = player.get_node("Camera2D")
@export var rink: Rink
var rink_rect: Rect2

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
	var rink_tilemap: TileMapLayer = rink.get_node("TileMapLayer")
	rink_rect = get_tilemap_world_rect(rink_tilemap)
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
	spawn_with_budget()

func _on_enemy_removed(enemy: Node) -> void:
	active_enemies.erase(enemy)
