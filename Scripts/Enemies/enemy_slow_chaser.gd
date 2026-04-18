class_name EnemySlowChaser
extends Enemy

func _ready() -> void:
	super._ready()
	var chase_component: ComponentPlayerChase = $"Player Chase Component"
	chase_component.player = player
