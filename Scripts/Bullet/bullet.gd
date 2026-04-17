class_name Bullet
extends Area2D

enum Team { PLAYER, ENEMY }
var team: Team
var speed: float = 300.0
var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	if team == Team.PLAYER:
		$Sprite2D.self_modulate = Color(1, 1, 0)
	if team == Team.ENEMY:
		$Sprite2D.self_modulate = Color(1, 0, 0)

	
func _process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if team == Team.PLAYER and body.is_in_group("enemies"):
		body.take_damage(1)
		queue_free()

	elif team == Team.ENEMY and body.is_in_group("player"):
		body.take_damage(1)
		queue_free()
