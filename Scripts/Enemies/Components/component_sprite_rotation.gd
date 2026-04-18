class_name SpriteDirection
extends Node

var owner_body: CharacterBody2D
var sprite: Sprite2D

func _ready() -> void:
	owner_body = get_parent() as CharacterBody2D
	sprite = owner_body.get_node_or_null("Sprite2D") as Sprite2D
	
	if sprite == null:
		push_warning("SpriteDirection: No Sprite2D found on parent")

func _process(_delta: float) -> void:
	if owner_body == null or sprite == null:
		return
	
	# If enemy has velocity, face that direction
	if owner_body.velocity.length() > 0:
		sprite.rotation = owner_body.velocity.angle()
