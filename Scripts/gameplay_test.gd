extends Node2D

var enemy_scenes: Array[PackedScene] = [
	preload("res://Scenes/Enemies/enemy_slow_chaser.tscn"),
	preload("res://Scenes/Enemies/enemy_slow_shooter.tscn"),
	preload("res://Scenes/Enemies/enemy_tank.tscn"),
	preload("res://Scenes/Enemies/enemy_dasher.tscn")
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
@onready var level_label: Label = $DebugUI/LevelLabel
@onready var xp_label: Label = $DebugUI/XPLabel
@onready var xp_required_label: Label = $DebugUI/XPRequieredLabel

@onready var life_bar: TextureProgressBar = $UI/RootUI/PlayerInfo/BarsCol/LifeBar
@onready var xp_bar: TextureProgressBar = $UI/RootUI/PlayerInfo/BarsCol/XPBar
@onready var lvl_label: Label = $UI/RootUI/PlayerInfo/VBoxContainer/LvlNum
@onready var speed_label: Label = $UI/RootUI/Speedometer/SpeedLabel
@onready var speed_bar: TextureProgressBar = $UI/RootUI/Speedometer/SpeedBar
var shake_intensity: float = 0.0			# No modificar porfa
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var shake_target: Control = null  # ← nuevo
@onready var speedometer_node: Control = $UI/RootUI/Speedometer

@onready var player: Player = $Player as Player
@onready var speed_fx_rect: ColorRect = $SpeedFX/SpeedFXRect
var speed_fx_material: ShaderMaterial
var speed_fx_strength: float = 0.0

func _ready() -> void:
	EnemyDB.init(enemy_scenes)
	if player != null:
		player.health_changed.connect(_on_player_health_changed)

	## UI
	if player != null:
		life_bar.max_value = player.max_health
		life_bar.value = player.current_health
	
	if player != null:
		player.xp_changed.connect(_on_player_xp_changed)
		xp_bar.max_value = player.xp_for_next_level
		xp_bar.value = player.current_xp
	
	player.level_up.connect(_on_player_level_up)
	lvl_label.text = str(player.current_level)
	
	player.damaged.connect(_on_player_damaged)
	
	if speed_bar != null:
		speed_bar.max_value = player.max_speed
		
	## FX
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
	
	var level: int = player.current_level
	level_label.text = "Level: %.0f" % level
	
	var xp: int = player.current_xp
	xp_label.text = "XP: %.0f" % xp
	
	var requiered_xp: int = player.xp_for_next_level
	xp_required_label.text = "XP Required: %0.f" % requiered_xp

	update_speed_fx(delta)
	
	update_speedometer()
	
	process_shake(delta)

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
func _on_player_health_changed(current: int, max_health: int) -> void:
	life_bar.value = current
	life_bar.max_value = max_health
	
func _on_player_damaged() -> void:
	start_shake($UI/RootUI/PlayerInfo, 0.4, 6.0)
	
func _on_player_xp_changed(current: int, max_xp: int) -> void:
	xp_bar.value = current
	xp_bar.max_value = max_xp
	
func _on_player_level_up(level: int) -> void:
	lvl_label.text = str(level)
	
func start_shake(target: Control, duration: float, intensity: float) -> void:
	shake_target = target
	shake_duration = duration
	shake_intensity = intensity
	shake_timer = duration
	if not shake_target.has_meta("original_position"):
		shake_target.set_meta("original_position", shake_target.position)

func process_shake(delta: float) -> void:
	if shake_target == null:
		return

	var original_pos: Vector2 = shake_target.get_meta("original_position")

	if shake_timer > 0:
		shake_timer -= delta
		var shake_offset: Vector2 = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_target.position = shake_target.position.lerp(original_pos + shake_offset, 0.3)
	else:
		shake_target.position = shake_target.position.lerp(original_pos, 0.1)

func update_speedometer() -> void:
	if player != null and speed_label != null:
		var current_speed: float = player.velocity.length()
		var speed_kmh: float = current_speed * 3.6 /10

		speed_label.text = "%.0f" % speed_kmh
		speed_bar.value = current_speed

		# Detectar velocidad máxima y activar shake
		if current_speed >= speed_fx_max_speed * 0.95:  # 95% del máximo
			if shake_timer <= 0:  # Evitar activar shake constantemente
				start_shake(speedometer_node, 0.3, 5.0)  # duración, intensidad
				
