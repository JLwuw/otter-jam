class_name EnemySlowChaser
extends Enemy

func _ready() -> void:
	super._ready()
	$"Player Chase Component".player = player
