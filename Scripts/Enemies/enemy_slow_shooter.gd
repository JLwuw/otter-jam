class_name EnemySlowShooter
extends Enemy

func _ready() -> void:
	super._ready()
	$"Player Chase Component".player = player
	$"Basic Shoot Component".player = player
