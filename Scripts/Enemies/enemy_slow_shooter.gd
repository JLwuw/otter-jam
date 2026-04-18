class_name EnemySlowShooter
extends Enemy

@onready var shoot_component: ComponentBasicShoot = $"Basic Shoot Component"

func _ready() -> void:
	super._ready()
	var chase_component: ComponentPlayerChase = $"Player Chase Component"
	chase_component.player = player
	shoot_component.player = player

func set_enemy_active(is_active: bool) -> void:
	super.set_enemy_active(is_active)
	
	shoot_component.set_process(is_active)
		
