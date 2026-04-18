class_name EnemySlowShooter
extends Enemy

var 	shoot_component: ComponentBasicShoot 

func _ready() -> void:
	super._ready()
	var chase_component: ComponentPlayerChase = get_node_or_null("Player Chase Component")
	shoot_component = get_node_or_null("Basic Shoot Component")
	chase_component.player = player
	shoot_component.player = player

func set_enemy_active(is_active: bool) -> void:
	super.set_enemy_active(is_active)
		
	if shoot_component == null:
		print("Shoot component not found on", name)
		return
	
	shoot_component.set_process(is_active)
		
