extends Node2D

@export_category("Speed FX")
@export var speed_fx_max_speed: float = 750.0
@export var speed_fx_start_ratio: float = 0.45
@export var speed_fx_lerp_speed: float = 6.0

@onready var player: Player = $Player as Player
var speed_fx_rect: ColorRect
var speed_fx_material: ShaderMaterial
var speed_fx_strength: float = 0.0

func _ready() -> void:
	speed_fx_rect = get_node_or_null("SpeedFX/SpeedFXRect") as ColorRect
	AudioController.stop_all_sfx()
	AudioController.play_menu_music()
	if speed_fx_rect != null and speed_fx_rect.material is ShaderMaterial:
		speed_fx_material = speed_fx_rect.material as ShaderMaterial

func _process(delta: float) -> void:
	update_speed_fx(delta)

func update_speed_fx(delta: float) -> void:
	if speed_fx_material == null or player == null:
		return

	var speed_ratio: float = 0.0
	if speed_fx_max_speed > 0.0:
		speed_ratio = clamp(player.velocity.length() / speed_fx_max_speed, 0.0, 1.0)

	var target_strength: float = 0.0
	if speed_ratio > speed_fx_start_ratio:
		var t: float = inverse_lerp(speed_fx_start_ratio, 1.0, speed_ratio)
		target_strength = t * t

	var follow_weight: float = min(1.0, speed_fx_lerp_speed * delta)
	speed_fx_strength = lerp(speed_fx_strength, target_strength, follow_weight)
	speed_fx_material.set_shader_parameter("strength", speed_fx_strength)

	var vel_len_sq: float = player.velocity.length_squared()
	if vel_len_sq > 0.001:
		speed_fx_material.set_shader_parameter("velocity_dir", player.velocity.normalized())

func select_difficulty(difficulty: String) -> void:
	match difficulty:
		#"easy":
			#GameSettings.difficulty = "easy"	# ajusta a tu sistema
		#"normal":
			#GameSettings.difficulty = "normal"
		#"hard":
			#GameSettings.difficulty = "hard"
			
		"easy":							# PLACEHOLDERS !!
			print("set to easy")
		"normal":
			print("set to normal")
		"hard":
			print("set to hard")
	AudioController.stop_all_sfx()
	await AudioController.fade_out_music()
	get_tree().change_scene_to_file("res://Scenes/gameplay_test.tscn")


func _on_easy_zone_body_entered(body: Node2D) -> void:
	if body is Player:
		select_difficulty("easy")

func _on_normal_zone_body_entered(body: Node2D) -> void:
	if body is Player:
		select_difficulty("normal")

func _on_hard_zone_body_entered(body: Node2D) -> void:
	if body is Player:
		select_difficulty("hard")
