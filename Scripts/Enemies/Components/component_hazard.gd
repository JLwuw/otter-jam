class_name Hazard
extends StaticBody2D

@export var damage: int = 3
@export var landed_texture: Texture2D
@export var destroy_particles_scene: PackedScene
@export var lifetime: float = 4.0
@export var pre_landing_scale_curve: Curve
@export var slow_amount: float = 0.65
@export var slow_duration: float = 1
@export var health: int = 15

var speed: float = 200.0
var direction: Vector2 = Vector2.ZERO
var travel_distance: float = 200.0
var distance_traveled: float = 0.0
var is_landed: bool = false
var has_hit: bool = false
var lifetime_remaining: float = 0.0
@onready var sprite: Sprite2D = $Sprite2D as Sprite2D
@onready var airborne_collision_shape: CollisionShape2D = $AirborneCollisionShape2D as CollisionShape2D
@onready var landed_collision_shape: CollisionShape2D = $LandedCollisionShape2D as CollisionShape2D
var airborne_shadow_sprite: Sprite2D
var landed_shadow_sprite: Sprite2D
var original_texture: Texture2D
var base_sprite_scale: Vector2 = Vector2.ONE
var base_shadow_scale: Vector2 = Vector2(0.2, 0.12)
var current_health: int

func _ready() -> void:
	airborne_shadow_sprite = get_node_or_null("AirborneShadowSprite2D") as Sprite2D
	landed_shadow_sprite = get_node_or_null("LandedShadowSprite2D") as Sprite2D

	if sprite != null:
		original_texture = sprite.texture
		base_sprite_scale = sprite.scale
		base_shadow_scale = Vector2(base_sprite_scale.x, base_sprite_scale.y * 0.6)

	if airborne_shadow_sprite == null and sprite != null:
		airborne_shadow_sprite = Sprite2D.new()
		airborne_shadow_sprite.name = "AirborneShadowSprite2D"
		airborne_shadow_sprite.z_index = -2
		airborne_shadow_sprite.position = Vector2(0, 10)
		airborne_shadow_sprite.scale = base_shadow_scale * 0.45
		airborne_shadow_sprite.self_modulate = Color(0, 0, 0, 0.25)
		add_child(airborne_shadow_sprite)

	if landed_shadow_sprite == null and sprite != null:
		landed_shadow_sprite = Sprite2D.new()
		landed_shadow_sprite.name = "LandedShadowSprite2D"
		landed_shadow_sprite.z_index = -1
		landed_shadow_sprite.position = Vector2(0, 8)
		landed_shadow_sprite.scale = base_shadow_scale
		landed_shadow_sprite.self_modulate = Color(0, 0, 0, 0.4)
		add_child(landed_shadow_sprite)

	if airborne_shadow_sprite != null:
		airborne_shadow_sprite.visible = true
		if sprite != null and sprite.texture != null:
			airborne_shadow_sprite.texture = sprite.texture

	if landed_shadow_sprite != null:
		landed_shadow_sprite.visible = false
		if sprite != null and sprite.texture != null:
			landed_shadow_sprite.texture = sprite.texture
	if airborne_collision_shape != null:
		airborne_collision_shape.disabled = false
	if landed_collision_shape != null:
		landed_collision_shape.disabled = true
	lifetime_remaining = lifetime
	current_health = health
	set_process(true)

func _process(delta: float) -> void:
	if lifetime > 0.0:
		lifetime_remaining -= delta
		if lifetime_remaining <= 0.0:
			_destroy_hazard()
			return

	if not is_landed:
		# Still traveling
		var movement: Vector2 = direction * speed * delta
		position += movement
		distance_traveled += movement.length()

		if sprite != null and pre_landing_scale_curve != null and travel_distance > 0.0:
			var progress: float = clamp(distance_traveled / travel_distance, 0.0, 1.0)
			var scale_factor: float = pre_landing_scale_curve.sample_baked(progress)
			sprite.scale = base_sprite_scale * scale_factor
			if airborne_shadow_sprite != null:
				var airborne_shadow_scale_factor: float = lerp(0.45, 1.0, progress)
				airborne_shadow_sprite.scale = base_shadow_scale * airborne_shadow_scale_factor

		if sprite != null and airborne_shadow_sprite != null and sprite.texture != null:
			airborne_shadow_sprite.texture = sprite.texture
		
		# Check if reached destination
		if distance_traveled >= travel_distance:
			is_landed = true
			_apply_landed_state()

func _on_body_entered(body: Node) -> void:
	# Player damage is handled via PlayerDetector.
	return

func _on_player_detector_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		has_hit = true
		if body.has_method("take_damage"):
			body.call("take_damage", damage)
		if body.has_method("apply_slow"):
			body.call("apply_slow", slow_amount, slow_duration)
		# Remove hazard after hitting
		_destroy_hazard()

func _apply_landed_state() -> void:
	if sprite != null:
		sprite.scale = base_sprite_scale
		if landed_texture != null:
			sprite.texture = landed_texture
		elif original_texture != null:
			sprite.texture = original_texture

	if airborne_shadow_sprite != null:
		airborne_shadow_sprite.visible = false

	if landed_shadow_sprite != null:
		landed_shadow_sprite.visible = true
		if sprite != null and sprite.texture != null:
			landed_shadow_sprite.texture = sprite.texture

	if airborne_collision_shape != null:
		airborne_collision_shape.disabled = true
	if landed_collision_shape != null:
		landed_collision_shape.disabled = false

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
		queue_free()

func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		queue_free()
