class_name EnemySlowShooter
extends Enemy

@export_group("Combat")
@export var player: Player

func _ready() -> void:
	$"Slow Chase Component".player = player
	$"Basic Shoot Component".player = player
