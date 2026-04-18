class_name EnemyDasher
extends Enemy

func _ready() -> void:
	super._ready()
	var dash_component: ComponentDash = $ComponentDash
	dash_component.player = player

func set_enemy_active(is_active: bool) -> void:
	super.set_enemy_active(is_active)
