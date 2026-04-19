extends StaticBody2D

@export var damage: int = 2
@export var destroy_particles_scene: PackedScene
@export var lifetime: float = 30.0
@export var slow_amount: float = 0.5
@export var slow_duration: float = 0.5

var speed: float = 200.0
var direction: Vector2 = Vector2.DOWN
var travel_distance: float = 200.0
var distance_traveled: float = 0.0
var is_landed: bool = false
var has_hit_player: bool = false
var lifetime_remaining: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var airborne_collision_shape: CollisionShape2D = $AirborneCollisionShape2D
@onready var landed_collision_shape: CollisionShape2D = $LandedCollisionShape2D
@onready var player_detector: Area2D = $PlayerDetector

func _ready() -> void:
	lifetime_remaining = lifetime
	set_process(true)

func _process(delta: float) -> void:
	if lifetime > 0.0 and not is_landed:
		lifetime_remaining -= delta
		if lifetime_remaining <= 0.0:
			_destroy_hazard()
			return

	if not is_landed:
		# Still traveling
		var movement: Vector2 = direction * speed * delta
		position += movement
		distance_traveled += movement.length()
		
		# Check if reached destination
		if distance_traveled >= travel_distance:
			is_landed = true
			_apply_landed_state()

func _apply_landed_state() -> void:
	# If it hit the player, it's already destroyed
	if has_hit_player:
		return
	
	# Otherwise, become a permanent obstacle
	if sprite != null:
		sprite.self_modulate = Color(0.3, 0.6, 1, 1)  # Darker blue for hole/crater
	
	# Disable airborne collision, enable landed (blocking) collision
	if airborne_collision_shape != null:
		airborne_collision_shape.disabled = true
	if landed_collision_shape != null:
		landed_collision_shape.disabled = false
	
	# Disable player detector so it doesn't damage anymore
	if player_detector != null:
		player_detector.queue_free()

func _on_player_detector_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		has_hit_player = true
		if body.has_method("take_damage"):
			body.call("take_damage", damage)
		if body.has_method("apply_slow"):
			body.call("apply_slow", slow_amount, slow_duration)
		# Destroy hazard after hitting player
		_destroy_hazard()

func _destroy_hazard() -> void:
	_spawn_destroy_particles()
	queue_free()

func _spawn_destroy_particles() -> void:
	if destroy_particles_scene == null:
		return

	var instance: Node = destroy_particles_scene.instantiate()
	var parent_node: Node = get_tree().current_scene
	if parent_node == null:
		parent_node = get_parent()
	if parent_node == null:
		return

	parent_node.add_child(instance)

	if instance is Node2D:
		(instance as Node2D).global_position = global_position

	if instance is GPUParticles2D:
		var particles: GPUParticles2D = instance as GPUParticles2D
		particles.one_shot = true
		particles.restart()
		particles.emitting = true
