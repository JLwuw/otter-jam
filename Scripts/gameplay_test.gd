extends Node2D

var enemy_scenes: Array[PackedScene] = [
	preload("res://Scenes/Enemies/enemy_slow_chaser.tscn"),
	preload("res://Scenes/Enemies/enemy_slow_shooter.tscn")
]

@export var label_update_interval: float = 0.01
var label_update_timer: float = 0.01

@onready var fps_label: Label = $DebugUI/FPSLabel
@onready var score_label: Label = $DebugUI/ScoreLabel
@onready var combo_label: Label = $DebugUI/ComboLabel
@onready var combo_timer_label: Label = $DebugUI/ComboTimerLabel

func _ready() -> void:
	EnemyDB.init(enemy_scenes)

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
	
	
