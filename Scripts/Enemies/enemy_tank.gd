class_name EnemySlowTank
extends Enemy

@onready var wander_component: ComponentWander = $"Wander Component"
@onready var throw_component: ComponentThrowHazard = $"Throw Hazard Component"

func _ready() -> void:
	super._ready()

func set_enemy_active(is_active: bool) -> void:
	super.set_enemy_active(is_active)
	
	wander_component.set_active(is_active)
	throw_component.set_process(is_active)
		
