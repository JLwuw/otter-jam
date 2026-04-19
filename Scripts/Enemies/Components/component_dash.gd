class_name ComponentDash
extends Node

signal dash_started
signal dash_ended

@export_group("Movement")
@export var responsiveness: float = 55
@export var acceleration_factor: float = 30
@export var chase_speed: float = 400.0

@export_group("Dash")
@export var dash_speed: float = 1100.0
@export var dash_cooldown: float = 2.0
@export var dash_duration: float = 0.8
@export var dash_trigger_distance: float = 300.0  # Distance at which to start dashing
@export var prediction_distance: float = 150.0  # How far ahead to predict player movement
@export var drag: float = 0.5
@export var push_force: float = 1000.0  # Force to push other enemies toward player
@export var player_push_force: float = 800.0  # Force to push player
@export var homing_strength: float = 0.2  # How much to steer toward player during dash

var owner_body: CharacterBody2D
var player: Player
var has_warned_missing_player: bool = false
var dash_cooldown_timer: float = 0.0
var dash_active: bool = false
var dash_timer: float = 0.0
var chase_speed_sq: float = 0.0
var dash_hit_player: bool = false  # Track if player was hit during this dash

func _ready() -> void:
	owner_body = get_parent() as CharacterBody2D
	chase_speed_sq = chase_speed * chase_speed
	dash_cooldown_timer = dash_cooldown  # Start ready to dash

func _physics_process(delta: float) -> void:
	if owner_body == null:
		return

	if player == null:
		if not has_warned_missing_player:
			push_warning("No player in Dash Component")
			has_warned_missing_player = true
		return

	has_warned_missing_player = false
	
	# Update dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	
	# Handle active dash
	if dash_active:
		dash_timer -= delta
		if dash_timer <= 0 or dash_hit_player:
			dash_active = false
			dash_hit_player = false
			emit_signal("dash_ended")
		else:
			# Apply homing during dash
			var player_direction: Vector2 = (player.global_position - owner_body.global_position).normalized()
			owner_body.velocity = owner_body.velocity.lerp(player_direction * dash_speed, homing_strength)
	else:
		# Chase the player when not dashing
		chase_player(delta)
		
		# Try to initiate a new dash if cooldown is ready and player is close enough
		if dash_cooldown_timer <= 0:
			var distance_to_player: float = owner_body.global_position.distance_to(player.global_position)
			if distance_to_player < dash_trigger_distance:
				perform_dash()
	
	# Apply drag
	owner_body.velocity *= 1.0 / (1.0 + drag * delta)
	owner_body.move_and_slide()
	
	# If dashing, push any enemies in the way
	if dash_active:
		push_enemies_in_path()

func chase_player(delta: float) -> void:
	var direction: Vector2 = (player.global_position - owner_body.global_position).normalized()
	direction *= acceleration_factor
	var acceleration: Vector2 = owner_body.velocity.lerp(direction, delta * responsiveness)
	owner_body.velocity += delta * acceleration
	
	if owner_body.velocity.length_squared() > chase_speed_sq:
		owner_body.velocity = owner_body.velocity.normalized() * chase_speed

func perform_dash() -> void:
	# Predict where the player is going
	var player_velocity: Vector2 = player.velocity
	var predicted_player_pos: Vector2 = player.global_position + (player_velocity.normalized() * prediction_distance)
	
	# Calculate direction to predicted position
	var dash_direction: Vector2 = (predicted_player_pos - owner_body.global_position).normalized()
	
	# Set dash velocity
	owner_body.velocity = dash_direction * dash_speed
	
	# Start dash
	dash_active = true
	dash_hit_player = false
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	emit_signal("dash_started")


func disable_dash_behavior() -> void:
	var was_dashing: bool = dash_active
	dash_active = false
	dash_hit_player = false
	dash_timer = 0.0
	dash_cooldown_timer = dash_cooldown

	if owner_body != null:
		owner_body.velocity = Vector2.ZERO

	set_process(false)
	set_physics_process(false)

	if was_dashing:
		emit_signal("dash_ended")

func push_enemies_in_path() -> void:
	# Get all slide collisions and push enemies toward the player
	for i in range(owner_body.get_slide_collision_count()):
		var collision := owner_body.get_slide_collision(i)
		var collider := collision.get_collider()
		
		# Check if collider is the player
		if collider == player:
			var push_direction: Vector2 = (player.global_position - owner_body.global_position).normalized()
			
			# Apply push force to player
			if player is CharacterBody2D:
				player.velocity = push_direction * player_push_force
			
			# Stop dashing after hitting player
			dash_hit_player = true
		# Check if collider is an enemy
		else:
			var node_collider: Node = collider as Node
			if node_collider == null or not node_collider.is_in_group("enemies") or node_collider == owner_body:
				continue

			if node_collider is CharacterBody2D:
				var enemy_body: CharacterBody2D = node_collider as CharacterBody2D
				var push_direction: Vector2 = (player.global_position - enemy_body.global_position).normalized()
				enemy_body.velocity = push_direction * push_force
