class_name EnemySlowTank
extends Enemy

func _ready() -> void:
	super._ready()
	$"Wander Component".owner_body = self
	$"Throw Hazard Component".owner_body = self
