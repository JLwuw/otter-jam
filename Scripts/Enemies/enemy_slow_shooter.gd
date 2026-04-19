class_name EnemySlowShooter
extends Enemy

@onready var shoot_component: ComponentBasicShoot = $"Basic Shoot Component"
@onready var body_visual: AnimatedSprite2D = $AnimatedSprite2D
@onready var mouth_visual: AnimatedSprite2D = $mouth
@onready var bullet_spawn_node: Node2D = $"Bullet Spawn"

@export var body_rotation_offset_degrees: float = 0.0
@export var mouth_rotation_offset_degrees: float = 0.0
@export var bullet_spawn_rotation_offset_degrees: float = 0.0

const MOUTH_IDLE_ANIMATION: StringName = &"idle"
const MOUTH_SHOOT_ANIMATION: StringName = &"shoot"

func _ready() -> void:
	super._ready()
	var chase_component: ComponentPlayerChase = $"Player Chase Component"
	chase_component.player = player
	shoot_component.player = player
	shoot_component.shot_fired.connect(_on_shot_fired)

	if mouth_visual != null:
		if mouth_visual.sprite_frames != null and mouth_visual.sprite_frames.has_animation(MOUTH_SHOOT_ANIMATION):
			mouth_visual.sprite_frames.set_animation_loop(MOUTH_SHOOT_ANIMATION, false)
		if mouth_visual.sprite_frames != null and mouth_visual.sprite_frames.has_animation(MOUTH_IDLE_ANIMATION):
			mouth_visual.play(MOUTH_IDLE_ANIMATION)
		mouth_visual.animation_finished.connect(_on_mouth_animation_finished)

	_sync_visual_rotations()


func _process(_delta: float) -> void:
	_sync_visual_rotations()

func set_enemy_active(is_active: bool) -> void:
	super.set_enemy_active(is_active)
	
	if shoot_component != null:
		shoot_component.set_process(is_active)


func _on_shot_fired() -> void:
	if mouth_visual == null:
		return

	if mouth_visual.sprite_frames == null or not mouth_visual.sprite_frames.has_animation(MOUTH_SHOOT_ANIMATION):
		return

	mouth_visual.play(MOUTH_SHOOT_ANIMATION)


func _on_mouth_animation_finished() -> void:
	if mouth_visual == null:
		return

	if mouth_visual.animation == MOUTH_SHOOT_ANIMATION and mouth_visual.sprite_frames != null and mouth_visual.sprite_frames.has_animation(MOUTH_IDLE_ANIMATION):
		mouth_visual.play(MOUTH_IDLE_ANIMATION)


func _sync_visual_rotations() -> void:
	if body_visual == null:
		return

	var base_rotation: float = body_visual.rotation
	if velocity.length() > 0.0:
		base_rotation = velocity.angle()

	body_visual.rotation = base_rotation + deg_to_rad(body_rotation_offset_degrees)

	if mouth_visual != null:
		mouth_visual.rotation = base_rotation + deg_to_rad(mouth_rotation_offset_degrees)

	if bullet_spawn_node != null:
		bullet_spawn_node.rotation = base_rotation + deg_to_rad(bullet_spawn_rotation_offset_degrees)
		
