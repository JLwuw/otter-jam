extends Camera2D

@export var follow_inertia: float = 8.0
@export var zoom_lerp_speed: float = 6.0
@export var speed_for_max_zoom_out: float = 700.0
@export var zoom_in: Vector2 = Vector2(1.15, 1.15)
@export var zoom_out: Vector2 = Vector2(0.8, 0.8)

var player: CharacterBody2D

func _ready() -> void:
	player = get_parent() as CharacterBody2D
	top_level = true
	if player != null:
		global_position = player.global_position
	make_current()


func _physics_process(delta: float) -> void:
	if player == null:
		return

	var follow_weight: float = 1.0 - exp(-follow_inertia * delta)
	global_position = global_position.lerp(player.global_position, follow_weight)

	var speed_ratio: float = 0.0
	if speed_for_max_zoom_out > 0.0:
		speed_ratio = clamp(player.velocity.length() / speed_for_max_zoom_out, 0.0, 1.0)
	var target_zoom: Vector2 = zoom_in.lerp(zoom_out, speed_ratio)
	var zoom_weight: float = 1.0 - exp(-zoom_lerp_speed * delta)
	zoom = zoom.lerp(target_zoom, zoom_weight)
