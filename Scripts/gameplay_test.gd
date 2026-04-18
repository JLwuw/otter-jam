extends Node2D

var enemy_scenes: Array[PackedScene] = [
	preload("res://Scenes/Enemies/enemy_slow_chaser.tscn"),
	preload("res://Scenes/Enemies/enemy_slow_shooter.tscn"),
	preload("res://Scenes/Enemies/enemy_tank.tscn")
]

@export var label_update_interval: float = 0.01
@export_category("Speed FX")
@export var speed_fx_max_speed: float = 750.0
@export var speed_fx_start_ratio: float = 0.45
@export var speed_fx_lerp_speed: float = 6.0
var label_update_timer: float = 0.01

@onready var fps_label: Label = $DebugUI/FPSLabel
@onready var score_label: Label = $DebugUI/ScoreLabel
@onready var combo_label: Label = $DebugUI/ComboLabel
@onready var combo_timer_label: Label = $DebugUI/ComboTimerLabel
@onready var life_bar: TextureProgressBar = $UI/RootUI/PlayerInfo/BarsCol/LifeBar
@onready var speed_label: Label = $UI/RootUI/Speedometer/SpeedLabel
@onready var player: Player = $Player as Player
@onready var speed_fx_rect: ColorRect = $SpeedFX/SpeedFXRect
var speed_fx_material: ShaderMaterial
var speed_fx_strength: float = 0.0

func _ready() -> void:
	EnemyDB.init(enemy_scenes)
	if player != null:
		player.health_changed.connect(_on_player_health_changed)

	if player != null:
		life_bar.max_value = player.max_health
		life_bar.value = player.current_health

	if speed_fx_rect != null and speed_fx_rect.material is ShaderMaterial:
		speed_fx_material = speed_fx_rect.material as ShaderMaterial

func _process(delta: float) -> void:
	if fps_label == null:
		return

	label_update_timer -= delta
	if label_update_timer > 0.0:
		return

	label_update_timer = label_update_interval
	var fps: float = Engine.get_frames_per_second()
	fps_label.text = "FPS: %.0f" % fps
	
	var score: int = ScoreManager.get_final_score()
	score_label.text = "Score: %.0f" % score
	
	var combo: int = ScoreManager.combo
	combo_label.text = "Combo: %.0f" % combo
	
	var combo_timer: float = ScoreManager.combo_timer
	combo_timer_label.text = "Combo Timer: %.0f" % combo_timer

	update_speed_fx(delta)
	
	update_speed_label()


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
	
# UI
func _on_player_health_changed(current: int, maximum: int) -> void:
	life_bar.max_value = maximum
	life_bar.value = current
	
func update_speed_label() -> void:
	# Actualizar velocímetro
	if player != null and speed_label != null:
		var current_speed: float = player.velocity.length()

		# Convertir a km/h y corregir
		var speed_kmh: float = current_speed * 3.6 /10

		# Actualizar label
		speed_label.text = "%.0f" % speed_kmh
