extends Node2D

var enemy_scenes: Array[PackedScene] = [
	preload("res://Scenes/Enemies/enemy_slow_chaser.tscn"),
	preload("res://Scenes/Enemies/enemy_slow_shooter.tscn")
]

@export var fps_update_interval: float = 0.01
@onready var fps_label: Label = $DebugUI/FPSLabel
var fps_update_timer: float = 0.01

func _ready() -> void:
	EnemyDB.init(enemy_scenes)

func _process(delta: float) -> void:
	if fps_label == null:
		return

	fps_update_timer -= delta
	if fps_update_timer > 0.0:
		return

	fps_update_timer = fps_update_interval
	var fps: float = Engine.get_frames_per_second()
	fps_label.text = "FPS: %.0f" % fps
