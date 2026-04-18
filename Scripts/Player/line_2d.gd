extends Line2D

@export var length: int = 120

@onready var parent_node: Node2D = get_parent() as Node2D
var offset: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	offset = position
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
	add_point(point, 0)
	if get_point_count() > length:
		remove_point(get_point_count() - 1)
