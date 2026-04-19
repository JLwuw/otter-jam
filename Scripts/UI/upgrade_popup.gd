class_name PopupUpgrade
extends Node2D

@export var duration: float = 1.5
@export var float_distance: float = 100.0
@export var flash_speed: float = 5.0
@export var fade_delay: float = 0.3
@export var fade_in_duration: float = 0.1

var elapsed: float = 0.0
var start_position: Vector2
var target: Node2D
var vertical_offset: float = 0.0


func _ready() -> void:
	start_position = global_position
	if has_node("Label"):
		var label: Label = $Label
		label.self_modulate.a = 0.0


func _process(delta: float) -> void:
	elapsed += delta
	var progress: float = elapsed / duration
	
	# Track player position if we have a target
	var current_base_pos: Vector2 = start_position
	if target != null and is_instance_valid(target):
		current_base_pos = target.global_position
	
	# Move upward from the current position with vertical offset
	var offset_y: float = (float_distance * progress) + 120
	global_position = current_base_pos + Vector2(0, -offset_y + vertical_offset)
	
	# Fade in (quick)
	var fade_in_progress: float = min(1.0, progress / (fade_in_duration / duration))
	var alpha: float = fade_in_progress
	
	# Fade out starting after fade_delay
	var fade_start: float = fade_delay
	var fade_duration: float = duration - fade_delay
	var fade_progress: float = max(0.0, (progress - fade_start) / fade_duration)
	alpha = alpha * (1.0 - fade_progress)
	
	# Flash effect - only during stable phase (before fade_delay)
	if progress < fade_delay:
		var flash: float = (sin(elapsed * flash_speed) + 1.0) * 0.5
		alpha = lerp(alpha * 0.3, alpha, flash)
	
	# Despawn when fully faded
	if alpha <= 0.01:
		queue_free()
		return
	
	if has_node("Label"):
		$Label.self_modulate.a = alpha


func set_target(new_target: Node2D, offset: float = 0.0) -> void:
	target = new_target
	vertical_offset = offset


func set_upgrade_text(upgrade_type: String, amount: int) -> void:
	if has_node("Label"):
		var label: Label = $Label
		label.text = "%s +%s" % [upgrade_type, amount]
