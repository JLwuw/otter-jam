class_name Player
extends CharacterBody2D

@export_category("Movement")
@export var SPEED_CAP: float = 1000
@export var max_speed: float = 500.0
@export var responsiveness: float = 45
@export var acceleration_factor: float = 3
@export var drag: float = 0.5
@export var max_distance: float = 200.0

var move_direction: Vector2 = Vector2.ZERO
var has_direction: bool = false

@export_category("Health")
@export var max_health: int = 5
@export var invuln_time: float = 0.3
@export var base_fire_rate: float = 0.5

@export_category("Shooting")
@export var bullet_scene: PackedScene = preload("res://Scenes/Bullet/bullet.tscn")
@export var bullet_speed: float = 1000
@export var min_fire_rate: float = 0.8 
@export var max_fire_rate: float = 6
@export var fire_rate_curve: Curve

var shoot_timer: float = 0.0
@onready var current_health: int = max_health
var invuln_timer: float = 0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("leftClick"):
		var to_mouse: Vector2 = get_global_mouse_position() - global_position
		
		if to_mouse.length() > 5.0:
			move_direction = to_mouse.normalized()
			has_direction = true

func _physics_process(delta: float) -> void:
	if has_direction:
		var target_velocity: Vector2 = move_direction * max_speed
		var accel: Vector2 = velocity.lerp(target_velocity, responsiveness * delta)
		velocity += accel * acceleration_factor * delta
	
	if velocity.length() > max_speed: 
		velocity = velocity.normalized() * max_speed 
	
	velocity *= 1.0 / (1.0 + drag * delta) 
	move_and_slide()

func _process(delta: float) -> void:
	update_invuln_timer(delta)
	handle_shooting(delta)

func update_invuln_timer(delta: float) -> void:
	if invuln_timer > 0.0:
		invuln_timer -= delta


func handle_shooting(delta: float) -> void:
	shoot_timer -= delta
	if not Input.is_action_pressed("leftClick"):
		return

	if shoot_timer <= 0.0:
		shoot()
		var current_speed: float = velocity.length()
		shoot_timer = calc_shoot_cooldown(current_speed)
	
func calc_shoot_cooldown(current_speed: float) -> float:
	var speed_percent: float = clamp(current_speed / SPEED_CAP, 0.0, 1.0) 	# Normalize speed (0 → 1)
	var curve_value: float = fire_rate_curve.sample(speed_percent)
	var current_fire_rate: float = lerp(min_fire_rate, max_fire_rate, curve_value)
	return 1.0 / current_fire_rate
	
func shoot() -> void:
	if bullet_scene == null:
		print("No bullet scene for player")
		return

	var bullet: Bullet = bullet_scene.instantiate()
	bullet.team = Bullet.Team.PLAYER
	bullet.global_position = global_position
	var direction: Vector2 = (get_global_mouse_position() - global_position).normalized()
	bullet.direction = direction
	bullet.speed = bullet_speed
	
	get_tree().current_scene.add_child(bullet)
		
func take_damage(amount: int = 1) -> void:
	if invuln_timer > 0: return
	print("Taking damage!")
	current_health -= amount
	if current_health <= 0: die()
	invuln_timer = invuln_time
		
func die() -> void:
	print("ggwp")

func apply_slow(slow_amount: float, slow_duration: float) -> void:
	var original_speed: float = max_speed
	max_speed *= (1.0 - slow_amount)
	await get_tree().create_timer(slow_duration).timeout
	max_speed = original_speed
