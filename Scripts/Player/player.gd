class_name Player
extends CharacterBody2D

@export_category("Movement")
@export var SPEED_CAP: float = 1000
@export var max_speed: float = 500.0
@export var responsiveness: float = 45
@export var acceleration_factor: float = 3
@export var drag: float = 0.5
@export var max_distance: float = 200.0
@export var turn_speed: float = 8.0
@export var rotation_offset_degrees: float = 0.0

var move_direction: Vector2 = Vector2.ZERO
var has_direction: bool = false

@export_category("Health")
@export var max_health: int = 5
@export var invuln_time: float = 0.3
@export var base_fire_rate: float = 0.5

@export_category("Shooting")
@export var bullet_scene: PackedScene = preload("res://Scenes/Bullet/bullet.tscn")
@export var bullet_speed: float = 1000
@export var bullet_spawn_offset: float = 28.0
@export var min_fire_rate: float = 0.8 
@export var max_fire_rate: float = 6
@export var fire_rate_curve: Curve

var shoot_timer: float = 0.0
@onready var current_health: int = max_health
var invuln_timer: float = 0
var max_speed_sq: float = 0.0
var speed_cap_inv: float = 0.0
@onready var current_scene_root: Node = get_tree().current_scene
var bullet_pool: Node

func _ready() -> void:
	max_speed_sq = max_speed * max_speed
	if SPEED_CAP > 0.0:
		speed_cap_inv = 1.0 / SPEED_CAP
	if current_scene_root == null:
		current_scene_root = get_tree().root
	bullet_pool = current_scene_root.get_node_or_null("BulletPool")

# Para progress bar en UI
signal health_changed(current: int, maximum: int)
signal xp_changed(current: int, maximum: int)

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
		var target_rotation: float = move_direction.angle() + deg_to_rad(rotation_offset_degrees)
		rotation = lerp_angle(rotation, target_rotation, turn_speed * delta)
	
	if velocity.length_squared() > max_speed_sq:
		velocity = velocity.normalized() * max_speed 
	
	velocity *= 1.0 / (1.0 + drag * delta) 
	move_and_slide()
	handle_rink_contacts()

func _process(delta: float) -> void:
	update_invuln_timer(delta)
	handle_shooting(delta)

func update_invuln_timer(delta: float) -> void:
	if invuln_timer > 0.0:
		invuln_timer -= delta


func handle_rink_contacts() -> void:
	var collision_count: int = get_slide_collision_count()
	if collision_count <= 0:
		return

	for collision_index in range(collision_count):
		var collision: KinematicCollision2D = get_slide_collision(collision_index)
		if collision == null:
			continue

		var collider: Object = collision.get_collider()
		if collider == null:
			continue

		var rink: Rink = null
		if collider is Rink:
			rink = collider as Rink
		elif collider is Node and (collider as Node).get_parent() is Rink:
			rink = (collider as Node).get_parent() as Rink

		if rink == null:
			continue

		rink.spawn_touch_particles(collision.get_position(), collision.get_normal(), velocity.length())


func handle_shooting(delta: float) -> void:
	shoot_timer -= delta
	if not Input.is_action_pressed("leftClick"):
		return

	if shoot_timer <= 0.0:
		shoot()
		var current_speed: float = velocity.length()
		shoot_timer = calc_shoot_cooldown(current_speed)
	
func calc_shoot_cooldown(current_speed: float) -> float:
	if fire_rate_curve == null:
		return 1.0 / min_fire_rate

	var speed_percent: float = clamp(current_speed * speed_cap_inv, 0.0, 1.0)
	var curve_value: float = fire_rate_curve.sample(speed_percent)
	var current_fire_rate: float = lerp(min_fire_rate, max_fire_rate, curve_value)
	return 1.0 / current_fire_rate
	
func shoot() -> void:
	if bullet_scene == null:
		print("No bullet scene for player")
		return

	var direction: Vector2 = (get_global_mouse_position() - global_position).normalized()
	var rotation_to_mouse: float = (get_global_mouse_position() - global_position).angle()
	var spawn_position: Vector2 = global_position + direction * bullet_spawn_offset
	var effective_bullet_speed: float = bullet_speed + max(0.0, velocity.dot(direction))
	
	if bullet_pool != null and bullet_pool.has_method("get_bullet"):
		bullet_pool.call("get_bullet", Bullet.Team.PLAYER, spawn_position, direction, effective_bullet_speed, rotation_to_mouse, bullet_scene)
		return

	var bullet: Bullet = bullet_scene.instantiate()

	bullet.team = Bullet.Team.PLAYER
	bullet.global_position = spawn_position
	bullet.direction = direction
	bullet.speed = effective_bullet_speed
	bullet.rotation = rotation_to_mouse
	current_scene_root.add_child(bullet)
		
func take_damage(amount: int = 1) -> void:
	if invuln_timer > 0: return
	print("Taking damage!")
	current_health -= amount
	health_changed.emit(current_health, max_health)  # UI
	if current_health <= 0: die()
	invuln_timer = invuln_time
		
func die() -> void:
	print("ggwp")
