class_name EnemySlowTank
extends Enemy

func _ready() -> void:
	super._ready()
	$"Wander Component".owner_body = self
	$"Throw Hazard Component".owner_body = self

func set_enemy_active(is_active: bool) -> void:
	super.set_enemy_active(is_active)
	
	$"Throw Hazard Component".set_process(is_active)
		
