class_name BulletPool
extends Node

@export var bullet_scene: PackedScene
@export var initial_size: int = 128
@export var expand_by: int = 32

var available_by_scene: Dictionary[String, Array] = {}
var pending_release: Dictionary[int, bool] = {}
@onready var current_scene_root: Node = get_tree().current_scene
const POOL_PARK_POSITION: Vector2 = Vector2(100000.0, 100000.0)

func _ready() -> void:
	if current_scene_root == null:
		current_scene_root = get_tree().root
	warm_pool(initial_size, bullet_scene)


func warm_pool(count: int, scene_to_pool: PackedScene) -> void:
	if scene_to_pool == null or count <= 0:
		return

	var scene_key: String = _scene_key(scene_to_pool)
	var available: Array = _get_available_bucket(scene_key)

	for _i in range(count):
		var bullet_node: Node = scene_to_pool.instantiate()
		if bullet_node == null:
			continue

		var canvas_item: CanvasItem = bullet_node as CanvasItem
		if canvas_item != null:
			canvas_item.visible = false

		var bullet_2d: Node2D = bullet_node as Node2D
		if bullet_2d != null:
			bullet_2d.global_position = POOL_PARK_POSITION
			bullet_2d.rotation = 0.0

		bullet_node.set_physics_process(false)

		if bullet_node.has_method("set_pool"):
			bullet_node.call("set_pool", self)
		bullet_node.set_meta("pool_scene_key", scene_key)

		add_child(bullet_node)
		if bullet_node.has_method("deactivate_for_pool"):
			bullet_node.call("deactivate_for_pool")

		available.append(bullet_node)

	available_by_scene[scene_key] = available


func get_bullet(team: Bullet.Team, spawn_position: Vector2, spawn_direction: Vector2, spawn_speed: float, spawn_rotation: float = 0.0, bullet_scene_override: PackedScene = null) -> Node:
	var requested_scene: PackedScene = bullet_scene_override
	if requested_scene == null:
		requested_scene = bullet_scene

	if requested_scene == null:
		return null

	var scene_key: String = _scene_key(requested_scene)
	var available: Array = _get_available_bucket(scene_key)
	if available.is_empty():
		warm_pool(expand_by, requested_scene)
		available = _get_available_bucket(scene_key)

	if available.is_empty():
		return null

	var bullet_node: Node = available.pop_back() as Node
	available_by_scene[scene_key] = available
	if bullet_node.has_method("deactivate_for_pool"):
		bullet_node.call("deactivate_for_pool")
	if bullet_node.get_parent() != current_scene_root:
		bullet_node.reparent(current_scene_root, false)

	var bullet_2d: Node2D = bullet_node as Node2D
	if bullet_2d != null:
		bullet_2d.global_position = spawn_position
		bullet_2d.rotation = spawn_rotation

	if bullet_node.has_method("activate"):
		bullet_node.call("activate", team, spawn_position, spawn_direction, spawn_speed, spawn_rotation)

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

	var scene_key: String = ""
	if bullet_node.has_meta("pool_scene_key"):
		scene_key = bullet_node.get_meta("pool_scene_key") as String
	if scene_key.is_empty():
		scene_key = _scene_key(bullet_scene)

	var available: Array = _get_available_bucket(scene_key)

	if bullet_node.has_method("deactivate_for_pool"):
		bullet_node.call("deactivate_for_pool")

	if not available.has(bullet_node):
		available.append(bullet_node)

	available_by_scene[scene_key] = available


func _scene_key(scene: PackedScene) -> String:
	if scene == null:
		return ""

	if not scene.resource_path.is_empty():
		return scene.resource_path

	return "scene_%d" % scene.get_instance_id()


func _get_available_bucket(scene_key: String) -> Array:
	if not available_by_scene.has(scene_key):
		available_by_scene[scene_key] = []

	return available_by_scene[scene_key]
