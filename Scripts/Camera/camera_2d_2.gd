extends Camera2D

@export var follow_inertia: float = 2.0
@export var follow_stiffness: float = 14.0
@export var follow_damping: float = 6.0
@export var follow_velocity_scale: float = 0.35
@export var zoom_lerp_speed: float = 3.0
@export var zoom_in_delay: float = 1.0
@export var speed_for_max_zoom_out: float = 500.0
@export var zoom_in: Vector2 = Vector2(1.2, 1.2)
@export var zoom_out: Vector2 = Vector2(0.7, 0.7)

@export_category("Shake")
@export var shake_strength: float = 20.0
@export var shake_decay: float = 5.0
var current_shake: float = 0.0


var player: CharacterBody2D
var follow_velocity: Vector2 = Vector2.ZERO
var zoom_in_delay_timer: float = 0.0
var last_speed_ratio: float = 0.0

func _ready() -> void:
	player = get_parent() as CharacterBody2D
	top_level = true
	if player != null:
		global_position = player.global_position
	make_current()


func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	apply_shake(delta)

	var speed_ratio: float = 0.0
	if speed_for_max_zoom_out > 0.0:
		speed_ratio = clamp(player.velocity.length() / speed_for_max_zoom_out, 0.0, 1.0)

	if speed_ratio > 0.0:
		last_speed_ratio = speed_ratio
		zoom_in_delay_timer = zoom_in_delay
	else:
		zoom_in_delay_timer = max(0.0, zoom_in_delay_timer - delta)

	var zoom_ratio: float = 0.0
	if zoom_in_delay_timer > 0.0:
		zoom_ratio = last_speed_ratio
	else:
		zoom_ratio = speed_ratio

	var follow_target: Vector2 = player.global_position
	var follow_offset: Vector2 = follow_target - global_position
	var speed_scale: float = lerp(1.0, follow_velocity_scale, speed_ratio)
	follow_velocity += follow_offset * follow_stiffness * speed_scale * delta
	follow_velocity *= exp(-follow_damping * speed_scale * delta)
	global_position += follow_velocity * delta

	var target_zoom: Vector2 = zoom_in.lerp(zoom_out, zoom_ratio)
	var zoom_weight: float = 1.0 - exp(-zoom_lerp_speed * delta)
	zoom = zoom.lerp(target_zoom, zoom_weight)


func apply_shake(delta: float) -> void:
	if current_shake > 0.0:
		current_shake = lerp(current_shake, 0.0, shake_decay * delta)
		
		var new_offset: Vector2 = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * current_shake
		
		new_offset = new_offset.round() # helps avoid subpixel jitter
		
		offset = new_offset
	else:
		offset = Vector2.ZERO
