class_name ComponentEnemyDeathImpact
extends Node

@export var death_particles_scene: PackedScene = preload("res://Scenes/Enemies/death.tscn")
@export var enable_hit_stop: bool = false
@export var hit_stop_duration: float = 0.1

var owner_enemy: Enemy

func _ready() -> void:
	owner_enemy = _find_owner_enemy()
	if owner_enemy == null:
		push_warning("No owner enemy for Enemy Death Impact Component")
		return

	owner_enemy.died.connect(_on_enemy_died)

func _on_enemy_died(_toughness: int) -> void:
	_emit_death_particles()
	_trigger_hit_stop()

func _emit_death_particles() -> void:
	if death_particles_scene == null or owner_enemy == null:
		return

	var effect: GPUParticles2D = death_particles_scene.instantiate() as GPUParticles2D
	if effect == null:
		return

	var tree: SceneTree = get_tree()
	if tree == null:
		return

	var scene_root: Node = tree.current_scene
	if scene_root == null:
		scene_root = tree.root

	effect.top_level = true
	effect.global_position = owner_enemy.global_position
	effect.one_shot = true
	effect.emitting = false
	scene_root.add_child(effect)
	effect.restart()
	effect.emitting = true
	effect.finished.connect(Callable(effect, "queue_free"), CONNECT_ONE_SHOT)

func _trigger_hit_stop() -> void:
	if not enable_hit_stop or hit_stop_duration <= 0.0:
		return

	var tree: SceneTree = get_tree()
	if tree == null:
		return

	if tree.paused or tree.has_meta("enemy_death_hit_stop_active"):
		return

	tree.set_meta("enemy_death_hit_stop_active", true)
	tree.paused = true

	var timer: SceneTreeTimer = tree.create_timer(hit_stop_duration, true, false, true)
	timer.timeout.connect(Callable(tree, "set").bind("paused", false), CONNECT_ONE_SHOT)
	timer.timeout.connect(Callable(tree, "remove_meta").bind("enemy_death_hit_stop_active"), CONNECT_ONE_SHOT)

func _find_owner_enemy() -> Enemy:
	var current_node: Node = get_parent()
	while current_node != null:
		if current_node is Enemy:
			return current_node as Enemy
		current_node = current_node.get_parent()

	return null
