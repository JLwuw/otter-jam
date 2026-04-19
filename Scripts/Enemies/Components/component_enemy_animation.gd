class_name ComponentEnemyAnimation
extends Node

@export_node_path("AnimatedSprite2D") var animated_sprite_path: NodePath = ^"AnimatedSprite2D"
@export_node_path("AnimationPlayer") var animation_player_path: NodePath = ^"AnimationPlayer"
@export var walk_animation_name: StringName = &"walk"
@export var death_animation_name: StringName = &"death"
@export var lock_walk_to_velocity: bool = true
@export var minimum_walk_speed: float = 1.0
@export var death_free_delay: float = 0.35

var owner_enemy: Enemy
var animated_sprite: AnimatedSprite2D
var animation_player: AnimationPlayer
var is_dying: bool = false
var override_animation: StringName = &""

func _ready() -> void:
	owner_enemy = _find_owner_enemy()
	if owner_enemy == null:
		return

	animated_sprite = owner_enemy.get_node_or_null(animated_sprite_path) as AnimatedSprite2D
	animation_player = owner_enemy.get_node_or_null(animation_player_path) as AnimationPlayer
	owner_enemy.died.connect(_on_enemy_died)

	if lock_walk_to_velocity:
		set_process(true)
		_update_walk_animation()
	else:
		_play_walk_animation()

func _process(_delta: float) -> void:
	if owner_enemy == null or is_dying:
		return

	if override_animation != StringName(""):
		_play_animation(override_animation)
		return

	if lock_walk_to_velocity:
		_update_walk_animation()

func _on_enemy_died(_toughness: int) -> void:
	is_dying = true
	_play_death_animation()

func _update_walk_animation() -> void:
	if owner_enemy.velocity.length() < minimum_walk_speed:
		_stop_walk_animation()
		return

	_play_walk_animation()

func _play_walk_animation() -> void:
	_play_animation(walk_animation_name)

func _stop_walk_animation() -> void:
	if animated_sprite != null and animated_sprite.animation == walk_animation_name and animated_sprite.is_playing():
		animated_sprite.stop()

func _play_death_animation() -> void:
	var resolved_delay: float = max(0.0, death_free_delay)

	if animation_player != null and animation_player.has_animation(death_animation_name):
		var clip: Animation = animation_player.get_animation(death_animation_name)
		if clip != null:
			if clip.loop_mode != Animation.LOOP_NONE:
				clip.loop_mode = Animation.LOOP_NONE
			resolved_delay = max(resolved_delay, clip.length)
		animation_player.play(death_animation_name)

	if animated_sprite != null and _has_sprite_animation(death_animation_name):
		if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.get_animation_loop(death_animation_name):
			animated_sprite.sprite_frames.set_animation_loop(death_animation_name, false)
		resolved_delay = max(resolved_delay, _get_sprite_animation_length(death_animation_name))
		animated_sprite.play(death_animation_name)

	if owner_enemy != null:
		owner_enemy.set_death_free_delay_min(resolved_delay)


func set_animation_override(animation_name: StringName) -> void:
	override_animation = animation_name
	if override_animation != StringName(""):
		_play_animation(override_animation)


func clear_animation_override() -> void:
	override_animation = StringName("")
	if lock_walk_to_velocity:
		_update_walk_animation()
	else:
		_play_walk_animation()


func _play_animation(animation_name: StringName) -> void:
	if animation_name == StringName(""):
		return

	if animation_player != null and animation_player.has_animation(animation_name):
		if animation_player.current_animation != animation_name:
			animation_player.play(animation_name)

	if animated_sprite != null and _has_sprite_animation(animation_name):
		if animated_sprite.animation != animation_name or not animated_sprite.is_playing():
			animated_sprite.play(animation_name)

func _has_sprite_animation(animation_name: StringName) -> bool:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return false

	return animated_sprite.sprite_frames.has_animation(animation_name)

func _get_sprite_animation_length(animation_name: StringName) -> float:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return 0.0

	var frames: SpriteFrames = animated_sprite.sprite_frames
	if not frames.has_animation(animation_name):
		return 0.0

	var frame_count: int = frames.get_frame_count(animation_name)
	var fps: float = frames.get_animation_speed(animation_name)
	if frame_count <= 0 or fps <= 0.0:
		return 0.0

	return frame_count / fps

func _find_owner_enemy() -> Enemy:
	var current_node: Node = get_parent()
	while current_node != null:
		if current_node is Enemy:
			return current_node as Enemy
		current_node = current_node.get_parent()

	return null
