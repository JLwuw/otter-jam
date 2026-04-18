class_name Hazard
extends StaticBody2D

@export var damage: int = 8
@export var slow_amount: float = 0.65
@export var slow_duration: float = 1
@export var health: int = 2

var speed: float = 200.0
var direction: Vector2 = Vector2.ZERO
var travel_distance: float = 200.0
var distance_traveled: float = 0.0
var is_landed: bool = false
var has_hit: bool = false
var current_health: int

func _ready() -> void:
	$Sprite2D.self_modulate = Color(0.9, 0.1, 0.1)
	current_health = health
	set_process(true)

func _process(delta: float) -> void:
	if not is_landed:
		# Still traveling
		var movement: Vector2 = direction * speed * delta
		position += movement
		distance_traveled += movement.length()
		
		# Check if reached destination
		if distance_traveled >= travel_distance:
			is_landed = true
			set_process(false)  # Stop processing once landed

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage)
		body.apply_slow(slow_amount, slow_duration)
		# Remove hazard after hitting
		queue_free()

func _on_player_detector_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage)
		body.apply_slow(slow_amount, slow_duration)
		# Remove hazard after hitting
		queue_free()

func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		queue_free()
