class_name EnemySlowChaser
extends Enemy

@export var player: Player

func _ready() -> void:
	super._ready()
	$"Player Chase Component".player = player
