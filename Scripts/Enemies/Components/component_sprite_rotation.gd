class_name SpriteDirection
extends Node

@export var rotation_offset_degrees: float = 0.0

var owner_body: CharacterBody2D
var visual: Node2D

func _ready() -> void:
	owner_body = get_parent() as CharacterBody2D
	visual = _find_visual(owner_body)
	
	if visual == null:
		push_warning("SpriteDirection: No Sprite2D or AnimatedSprite2D found on parent")

func _process(_delta: float) -> void:
	if owner_body == null or visual == null:
		return
	
	# If enemy has velocity, face that direction
	if owner_body.velocity.length() > 0:
		visual.rotation = owner_body.velocity.angle() + deg_to_rad(rotation_offset_degrees)


func _find_visual(owner_node: CharacterBody2D) -> Node2D:
	if owner_node == null:
		return null

	var sprite_2d: Node2D = owner_node.get_node_or_null("Sprite2D") as Node2D
	if sprite_2d != null:
		return sprite_2d

	var animated_sprite: Node2D = owner_node.get_node_or_null("AnimatedSprite2D") as Node2D
	if animated_sprite != null:
		return animated_sprite

	return null
