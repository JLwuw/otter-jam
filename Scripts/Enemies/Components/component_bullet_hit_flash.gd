class_name ComponentBulletHitFlash
extends Node

@export var flash_color: Color = Color(2.0, 2.0, 2.0, 1.0)
@export var flash_duration: float = 0.5

var owner_enemy: Enemy
var visual: CanvasItem
var original_modulate: Color = Color.WHITE
var flash_tween: Tween

func _ready() -> void:
	owner_enemy = _find_owner_enemy()
	if owner_enemy == null:
		push_warning("No owner enemy for Bullet Hit Flash Component")
		return

	if not owner_enemy.is_node_ready():
		await owner_enemy.ready

	visual = _find_visual(owner_enemy)
	if visual == null:
		push_warning("No sprite found for Bullet Hit Flash Component")
		return

	original_modulate = visual.self_modulate
	owner_enemy.damaged.connect(_on_enemy_damaged)

func _on_enemy_damaged(_amount: int) -> void:
	if owner_enemy == null or visual == null:
		return

	if flash_tween != null and flash_tween.is_running():
		flash_tween.kill()

	visual.self_modulate = flash_color
	flash_tween = create_tween()
	flash_tween.tween_property(visual, "self_modulate", original_modulate, flash_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _find_owner_enemy() -> Enemy:
	var current_node: Node = get_parent()
	while current_node != null:
		if current_node is Enemy:
			return current_node as Enemy
		current_node = current_node.get_parent()

	return null


func _find_visual(enemy_node: Enemy) -> CanvasItem:
	if enemy_node == null:
		return null

	var sprite_2d: CanvasItem = enemy_node.get_node_or_null("Sprite2D") as CanvasItem
	if sprite_2d != null:
		return sprite_2d

	var animated_sprite: CanvasItem = enemy_node.get_node_or_null("AnimatedSprite2D") as CanvasItem
	if animated_sprite != null:
		return animated_sprite

	return null