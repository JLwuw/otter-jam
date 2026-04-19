extends Area2D

@export var marker_min_path: NodePath = NodePath("../SpawnRectMin")
@export var marker_max_path: NodePath = NodePath("../SpawnRectMax")
@export var extra_margin: float = 64.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_exited.connect(_on_body_exited)
	_configure_from_markers()

func _configure_from_markers() -> void:
	var marker_min: Node2D = get_node_or_null(marker_min_path) as Node2D
	var marker_max: Node2D = get_node_or_null(marker_max_path) as Node2D
	if marker_min == null or marker_max == null:
		push_error("ArenaKillZone: missing SpawnRectMin/SpawnRectMax markers")
		queue_free()
		return

	var min_x: float = minf(marker_min.global_position.x, marker_max.global_position.x)
	var min_y: float = minf(marker_min.global_position.y, marker_max.global_position.y)
	var max_x: float = maxf(marker_min.global_position.x, marker_max.global_position.x)
	var max_y: float = maxf(marker_min.global_position.y, marker_max.global_position.y)
	var bounds: Rect2 = Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y)).grow(extra_margin)

	global_position = bounds.position + bounds.size * 0.5
	if collision_shape == null:
		return

	var rectangle_shape: RectangleShape2D = collision_shape.shape as RectangleShape2D
	if rectangle_shape == null:
		rectangle_shape = RectangleShape2D.new()
		collision_shape.shape = rectangle_shape

	rectangle_shape.size = bounds.size

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("enemies"):
		return

	if body.has_method("despawn"):
		body.call_deferred("despawn")
		return

	if body.has_method("die"):
		body.call_deferred("die")
		return

	if body.has_method("queue_free"):
		body.call_deferred("queue_free")