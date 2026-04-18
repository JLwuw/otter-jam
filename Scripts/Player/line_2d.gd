extends Line2D

@export var length: int = 120
@export var min_point_distance: float = 3.0

@onready var parent_node: Node2D = get_parent() as Node2D
var offset: Vector2 = Vector2.ZERO
var min_point_distance_sq: float = 0.0
var last_point: Vector2 = Vector2.ZERO
var has_last_point: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	offset = position
	min_point_distance_sq = min_point_distance * min_point_distance
	if get_point_count() > 0:
		offset += get_point_position(0)
		clear_points()
	top_level  = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if parent_node == null:
		return

	# Keep using the node's authored local position within the player scene.
	var point: Vector2 = parent_node.to_global(offset)
	if has_last_point and point.distance_squared_to(last_point) < min_point_distance_sq:
		return

	last_point = point
	has_last_point = true
	add_point(point, 0)
	var point_count: int = get_point_count()
	if point_count > length:
		remove_point(point_count - 1)
