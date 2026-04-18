class_name EnemySlowShooter
extends Enemy

func _ready() -> void:
	super._ready()
	var chase_component: ComponentPlayerChase = $"Player Chase Component"
	var shoot_component: ComponentBasicShoot = $"Basic Shoot Component"
	chase_component.player = player
	shoot_component.player = player
