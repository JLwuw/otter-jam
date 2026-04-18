class_name BulletPool
extends Node

@export var bullet_scene: PackedScene
@export var initial_size: int = 128
@export var expand_by: int = 32

var available: Array[Node] = []
var pending_release: Dictionary = {}
@onready var current_scene_root: Node = get_tree().current_scene

func _ready() -> void:
	if current_scene_root == null:
		current_scene_root = get_tree().root
	warm_pool(initial_size)


func warm_pool(count: int) -> void:
	if bullet_scene == null or count <= 0:
		return

	for _i in range(count):
		var bullet_node: Node = bullet_scene.instantiate()
		if bullet_node == null:
			continue

		if bullet_node.has_method("set_pool"):
			bullet_node.call("set_pool", self)

		add_child(bullet_node)
		if bullet_node.has_method("deactivate_for_pool"):
			bullet_node.call("deactivate_for_pool")

		available.append(bullet_node)


func get_bullet(team: Bullet.Team, spawn_position: Vector2, spawn_direction: Vector2, spawn_speed: float) -> Node:
	if available.is_empty():
		warm_pool(expand_by)

	if available.is_empty():
		return null

	var bullet_node: Node = available.pop_back()
	if bullet_node.get_parent() != current_scene_root:
		bullet_node.reparent(current_scene_root)

	if bullet_node.has_method("activate"):
		bullet_node.call("activate", team, spawn_position, spawn_direction, spawn_speed)

	return bullet_node


func release_bullet(bullet_node: Node) -> void:
	if bullet_node == null:
		return

	var instance_id: int = bullet_node.get_instance_id()
	if pending_release.has(instance_id):
		return

	pending_release[instance_id] = true
	call_deferred("_release_bullet_deferred", bullet_node, instance_id)


func _release_bullet_deferred(bullet_node: Node, instance_id: int) -> void:
	pending_release.erase(instance_id)
	if bullet_node == null or not is_instance_valid(bullet_node):
		return

	if bullet_node.has_method("deactivate_for_pool"):
		bullet_node.call("deactivate_for_pool")

	if bullet_node.get_parent() != self:
		bullet_node.reparent(self)

	if not available.has(bullet_node):
		available.append(bullet_node)
