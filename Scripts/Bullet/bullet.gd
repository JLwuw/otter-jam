class_name Bullet
extends Area2D

@export var speed: float = 300.0
var direction: Vector2 = Vector2.ZERO
	
func _process(delta: float) -> void:
	position += direction * speed * delta



func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage()
