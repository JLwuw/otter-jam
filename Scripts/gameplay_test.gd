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

# Debug UI
@onready var fps_label: Label = $DebugUI/FPSLabel
@onready var score_label: Label = $DebugUI/ScoreLabel
@onready var combo_label: Label = $DebugUI/ComboLabel
@onready var level_label: Label = $DebugUI/LevelLabel
@onready var xp_label: Label = $DebugUI/XPLabel
@onready var xp_required_label: Label = $DebugUI/XPRequieredLabel

# UI
@onready var life_bar: TextureProgressBar = $UI/RootUI/PlayerInfo/BarsCol/LifeBar
@onready var xp_bar: TextureProgressBar = $UI/RootUI/PlayerInfo/BarsCol/XPBar
@onready var life_lbl: Label = $UI/RootUI/PlayerInfo/CounterCol/LifeLbl
@onready var xp_lbl: Label = $UI/RootUI/PlayerInfo/CounterCol/XPLbl
@onready var lvl_label: Label = $UI/RootUI/PlayerInfo/LvlCol/LvlNum
@onready var speed_label: Label = $UI/RootUI/Speedometer/SpeedLabel
@onready var speed_bar: TextureProgressBar = $UI/RootUI/Speedometer/SpeedBar
@onready var combo_meter_label: Label = $UI/RootUI/ComboMeter/ComboLabel
@onready var combo_timer_bar: ProgressBar = $UI/RootUI/ComboMeter/ComboTimerBar
var shake_intensity: float = 0.0			# No modificar porfa
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var shake_target: Control = null  # ← nuevo
@onready var speedometer_node: Control = $UI/RootUI/Speedometer

# Game Over Screen
@onready var game_over_screen: CanvasLayer = $GameOverScreen
@onready var game_over_score_label: Label = $GameOverScreen/ScoreLabel

# Pause Screen
@onready var pause_menu: CanvasLayer = $PauseMenu

@onready var player: Player = $Player as Player
@onready var speed_fx_rect: ColorRect = $SpeedFX/SpeedFXRect
var speed_fx_material: ShaderMaterial
var speed_fx_strength: float = 0.0

func _ready() -> void:
	AudioController.stop_music()
	AudioController.play_music()
	EnemyDB.init(enemy_scenes)
	ScoreManager.is_active = true
	
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
		
	life_lbl.text = "%d/%d" % [player.current_health, player.max_health]
	xp_lbl.text = "%d/%d" % [player.current_xp, player.xp_for_next_level]
	
	player.level_up.connect(_on_player_level_up)
	lvl_label.text = str(player.current_level)
	
	player.damaged.connect(_on_player_damaged)
	
	game_over_screen.hide()
	$GameOverScreen/BtnsCol/RetryBtn.pressed.connect(_on_play_again_pressed)
	player.died.connect(_on_player_died)
	$GameOverScreen/BtnsCol/MainMenuBtn.pressed.connect(_on_main_menu_pressed)
	
	pause_menu.hide()
	$PauseMenu/BtnsCol/ContinueBtn.pressed.connect(toggle_pause)
	$PauseMenu/BtnsCol/RestartBtn.pressed.connect(_on_play_again_pressed)
	$PauseMenu/BtnsCol/MainMenuBtn.pressed.connect(_on_main_menu_pressed)
	
	if speed_bar != null:
		speed_bar.max_value = player.max_speed
		
	combo_timer_bar.max_value = ScoreManager.COMBO_DURATION
	combo_timer_bar.value = 0.0

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
	
	var combo: int = ScoreManager.is_active
	combo_label.text = "Combo: %.0f" % combo
	combo_meter_label.text = "x%d" % combo  			# UI
	
	var level: int = player.current_level
	level_label.text = "Level: %.0f" % level
	
	var xp: int = player.current_xp
	xp_label.text = "XP: %.0f" % xp
	
	var requiered_xp: int = player.xp_for_next_level
	xp_required_label.text = "XP Required: %0.f" % requiered_xp

	update_speed_fx(delta)
	
	update_speedometer()
	
	process_shake(delta)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC por defecto
		toggle_pause()
		
func toggle_pause() -> void:
	var paused: bool = not get_tree().paused
	get_tree().paused = paused
	if paused:
		pause_menu.show()
	else:
		pause_menu.hide()

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
	life_bar.max_value = max_health
	life_bar.value = current
	life_lbl.text = "%d/%d" % [current, max_health]
	
func _on_player_damaged() -> void:
	start_shake($UI/RootUI/PlayerInfo, 0.4, 6.0)
	
func _on_player_xp_changed(current: int, max_xp: int) -> void:
	xp_bar.value = current
	xp_bar.max_value = max_xp
	xp_lbl.text = "%d/%d" % [current, max_xp]
	
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
				

func _on_player_died() -> void:
	game_over_score_label.text = "Score: %d" % ScoreManager.get_final_score()
	await get_tree().create_timer(1.5).timeout
	game_over_screen.show()

	var overlay: ColorRect = $GameOverScreen/Overlay
	var tween: Tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.92, 0.92)

func _on_play_again_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/difficulty_screen.tscn")  # ajusta el path
	
func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")
