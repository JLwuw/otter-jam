class_name Enemy
extends CharacterBody2D

@export var max_health: int = 3
@export var toughness: int = 1
@export var unlock_time: int = 0
@export var player: Player
@export var disable_collision_when_offscreen: bool = true
@export var death_free_delay: float = 0.0

var current_health: int = 3
var is_dying: bool = false
@onready var visual_node: CanvasItem = _find_visual_node()
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

signal died(toughness: int)
signal damaged(amount: int)

func _ready() -> void:
	current_health = max_health
	set_enemy_active(screen_notifier.is_on_screen())
	if ScoreManager != null and ScoreManager.has_method("_on_enemy_died"):
		died.connect(Callable(ScoreManager, "_on_enemy_died"))

	if player == null:
		player = _find_player_fallback()

	if player != null and player.has_method("_on_enemy_died"):
		died.connect(Callable(player, "_on_enemy_died"))

func take_damage(amount: int) -> void:
	emit_signal("damaged", amount)
	current_health -= amount
	if current_health <= 0:
		die()

func die() -> void:
	if is_dying:
		return

	is_dying = true
	emit_signal("died", toughness)
	_disable_dash_behavior()
	_disable_all_collisions()
	_disable_gameplay_processing()
	velocity = Vector2.ZERO

	if death_free_delay > 0.0:
		var free_timer: SceneTreeTimer = get_tree().create_timer(death_free_delay)
		free_timer.timeout.connect(Callable(self, "queue_free"), CONNECT_ONE_SHOT)
		return

	queue_free()


func set_death_free_delay_min(delay: float) -> void:
	death_free_delay = max(death_free_delay, delay)

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	set_enemy_active(true)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	set_enemy_active(false)
	
func set_enemy_active(is_active: bool) -> void:
	if visual_node != null:
		visual_node.visible = is_active

	if disable_collision_when_offscreen and collision_shape != null:
		collision_shape.disabled = not is_active


func _find_visual_node() -> CanvasItem:
	var sprite_2d: CanvasItem = get_node_or_null("Sprite2D") as CanvasItem
	if sprite_2d != null:
		return sprite_2d

	var animated_sprite: CanvasItem = get_node_or_null("AnimatedSprite2D") as CanvasItem
	if animated_sprite != null:
		return animated_sprite

	return null


func _find_player_fallback() -> Player:
	var player_from_group: Player = get_tree().get_first_node_in_group("player") as Player
	if player_from_group != null:
		return player_from_group

	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return null

	return scene_root.find_child("Player", true, false) as Player


func _disable_gameplay_processing() -> void:
	_disable_node_processing(self)
	for child: Node in get_children():
		_disable_gameplay_processing_recursive(child)


func _disable_dash_behavior() -> void:
	for child: Node in get_children():
		_disable_dash_behavior_recursive(child)


func _disable_dash_behavior_recursive(node: Node) -> void:
	if node is ComponentDash:
		(node as ComponentDash).disable_dash_behavior()

	for child: Node in node.get_children():
		_disable_dash_behavior_recursive(child)


func _disable_gameplay_processing_recursive(node: Node) -> void:
	# Keep visual playback nodes alive so one-shot death animations can complete.
	if node is AnimatedSprite2D or node is AnimationPlayer:
		return

	_disable_node_processing(node)
	for child: Node in node.get_children():
		_disable_gameplay_processing_recursive(child)


func _disable_node_processing(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	node.set_process_input(false)
	node.set_process_unhandled_input(false)
	node.set_process_unhandled_key_input(false)
	node.set_process_shortcut_input(false)


func _disable_all_collisions() -> void:
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	for child: Node in get_children():
		_disable_collisions_recursive(child)


func _disable_collisions_recursive(node: Node) -> void:
	if node is CollisionShape2D:
		(node as CollisionShape2D).set_deferred("disabled", true)
	elif node is CollisionPolygon2D:
		(node as CollisionPolygon2D).set_deferred("disabled", true)
	elif node is CollisionObject2D:
		var collision_object: CollisionObject2D = node as CollisionObject2D
		collision_object.set_deferred("collision_layer", 0)
		collision_object.set_deferred("collision_mask", 0)

		if collision_object is Area2D:
			var area: Area2D = collision_object as Area2D
			area.set_deferred("monitoring", false)
			area.set_deferred("monitorable", false)

	for child: Node in node.get_children():
		_disable_collisions_recursive(child)
