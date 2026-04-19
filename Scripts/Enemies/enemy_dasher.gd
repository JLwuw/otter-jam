class_name EnemyDasher
extends Enemy

@onready var dash_component: ComponentDash = $"Dash Component"
@onready var player_chase_component: ComponentPlayerChase = $"Player Chase Component"
@onready var animation_component: ComponentEnemyAnimation = $"Enemy Animation Component"
@export var dash_animation_name: StringName = &"dash"

func _ready() -> void:
	super._ready()
	dash_component.player = player
	player_chase_component.player = player
	dash_component.dash_started.connect(_on_dash_started)
	dash_component.dash_ended.connect(_on_dash_ended)

func set_enemy_active(is_active: bool) -> void:
	super.set_enemy_active(is_active)
	
	if dash_component == null or player_chase_component == null:
		return
	
	if !is_active:
		dash_component.set_physics_process(false)
		player_chase_component.set_physics_process(true)
		dash_component.dash_timer = dash_component.dash_cooldown
		
	else:
		dash_component.set_physics_process(true)
		player_chase_component.set_physics_process(false)
		dash_component.dash_timer = dash_component.dash_cooldown


func _on_dash_started() -> void:
	if animation_component != null:
		animation_component.set_animation_override(dash_animation_name)


func _on_dash_ended() -> void:
	if animation_component != null:
		animation_component.clear_animation_override()
	
	
