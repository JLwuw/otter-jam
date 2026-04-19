class_name EnemySlowTank
extends Enemy

@export var sprite_rotation_offset_degrees: float = 0.0

@onready var wander_component: ComponentWander = $"Wander Component"
@onready var throw_component: ComponentThrowHazard = $"Throw Hazard Component"
@onready var sprite_rotation_component: SpriteDirection = $"Sprite Rotation Component"

func _ready() -> void:
	if sprite_rotation_component != null:
		sprite_rotation_component.rotation_offset_degrees = sprite_rotation_offset_degrees

	super._ready()

func set_enemy_active(is_active: bool) -> void:
	super.set_enemy_active(is_active)
	
	wander_component.set_active(is_active)
	throw_component.set_process(is_active)
		
