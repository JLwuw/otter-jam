class_name EnemySlowChaser
extends Enemy

func _ready() -> void:
	super._ready()
	var chase_component: ComponentPlayerChase = get_node_or_null("Player Chase Component")
	chase_component.player = player

func set_enemy_active(is_active: bool) -> void:
	super.set_enemy_active(is_active)
