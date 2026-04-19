class_name ComponentEnemyDeathImpact
extends Node

@export var death_particles_scene: PackedScene = preload("res://Scenes/Enemies/death.tscn")
@export var enable_hit_stop: bool = false
@export var hit_stop_duration: float = 0.1

var owner_enemy: Enemy
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("../AnimatedSprite2D") as AnimatedSprite2D

func _ready() -> void:
	owner_enemy = _find_owner_enemy()
	if owner_enemy == null:
		push_warning("No owner enemy for Enemy Death Impact Component")
		return

	owner_enemy.died.connect(_on_enemy_died)

func _on_enemy_died(_toughness: int) -> void:
	if not is_inside_tree():
		return

	var tween: Tween = create_tween()
	
	if animated_sprite != null:
		animated_sprite.modulate = Color(1, 1, 1) # reset
	
	tween.tween_property(
		animated_sprite, 
		"modulate", 
		Color(1, 0.4, 0.4), 
		0.1
	)
	
	_emit_death_particles()
	_trigger_hit_stop()

func _emit_death_particles() -> void:
	if death_particles_scene == null or owner_enemy == null:
		return
	if not is_inside_tree():
		return

	var effect: Node = death_particles_scene.instantiate()
	if effect == null:
		return

	var tree: SceneTree = get_tree()

	var scene_root: Node = tree.current_scene
	if scene_root == null:
		scene_root = tree.root

	var particles_root: GPUParticles2D = effect as GPUParticles2D
	if particles_root != null:
		particles_root.top_level = true
		particles_root.global_position = owner_enemy.global_position
		particles_root.one_shot = true
		particles_root.emitting = false

	scene_root.add_child(effect)
	if particles_root != null:
		_restart_particle_nodes(effect)
		particles_root.finished.connect(Callable(particles_root, "queue_free"), CONNECT_ONE_SHOT)

func _restart_particle_nodes(node: Node) -> void:
	if node is GPUParticles2D:
		var particles: GPUParticles2D = node as GPUParticles2D
		particles.emitting = false
		particles.restart()
		particles.emitting = true

	for child: Node in node.get_children():
		_restart_particle_nodes(child)

func _trigger_hit_stop() -> void:
	if not enable_hit_stop or hit_stop_duration <= 0.0:
		return
	if not is_inside_tree():
		return

	var tree: SceneTree = get_tree()

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
