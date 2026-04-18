class_name Enemy
extends CharacterBody2D

@export var max_health: int = 3
@export var toughness: int = 1
@export var unlock_time: int = 0
@export var player: Player
@export var disable_collision_when_offscreen: bool = true

var current_health: int = 3
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

signal died(toughness: int)

func _ready() -> void:
	current_health = max_health
	set_enemy_active(screen_notifier.is_on_screen())
	died.connect(ScoreManager._on_enemy_died)

func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		die()

func die() -> void:
	emit_signal("died", toughness)
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	set_enemy_active(true)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	set_enemy_active(false)
	
	
func set_enemy_active(is_active: bool) -> void:
	sprite.visible = is_active

	if disable_collision_when_offscreen and collision_shape != null:
		collision_shape.disabled = not is_active
