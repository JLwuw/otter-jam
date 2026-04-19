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
@export var move_hold_delay: float = 0.5

var move_direction: Vector2 = Vector2.ZERO
var has_direction: bool = false

@export_category("Health")
@export var max_health: int = 5
@export var invuln_time: float = 0.3
@export var base_fire_rate: float = 0.5

@export_category("Shooting")
@export var bullet_scene: PackedScene = preload("res://Scenes/Bullet/bullet.tscn")
@export var upgrade_popup_scene: PackedScene = preload("res://Scenes/UI/upgrade_popup.tscn")
@export var bullet_speed: float = 1000
@export var bullet_spawn_offset: float = 28.0
@export var muzzle_lateral_offset: float = 10.0
@export var left_muzzle_path: NodePath = NodePath("MuzzleLeft")
@export var right_muzzle_path: NodePath = NodePath("MuzzleRight")
@export var min_fire_rate: float = 0.8 
@export var max_fire_rate: float = 6
@export var min_burst_count: int = 1
@export var max_burst_count: int = 4
@export var burst_start_speed: float = 120.0
@export var burst_shot_interval: float = 0.045
@export var fire_rate_curve: Curve
@export var damage: int = 1


@export_category("Animation")
@export var move_speed_threshold: float = 120.0
@export var idle_speed_threshold: float = 8.0
@export var low_speed_animation: StringName = &"start"
@export var high_speed_animation: StringName = &"walk"
@export var death_animation: StringName = &"death"
@export var gun_idle_animation: StringName = &"idle"
@export var gun_shoot_animation: StringName = &"fire"
@export var gun_shoot_animation_speed: float = 1.6
@export var shoot_anim_hold_time: float = 0.12
@export var gun_aim_turn_speed: float = 14.0
@export var gun_aim_offset_degrees: float = 0.0

@export_category("Leveling")
@export var xp_curve: Curve 
@export var level_cap: int = 10
@export var xp_growth_factor: float = 20
@export var combo_weight: float = 1
@export var enemy_weight: float = 1.5

var current_xp: int = 0
var current_level: int = 0
var xp_for_next_level: int = 0
@onready var upgrade_manager: UpgradeManager = $"Upgrade Manager"

var shoot_timer: float = 0.0
@onready var current_health: int = max_health
var invuln_timer: float = 0
var is_invuln: bool = false
var speed_cap_inv: float = 0.0
@onready var current_scene_root: Node = get_tree().current_scene
var bullet_pool: Node
var left_muzzle: Node2D
var right_muzzle: Node2D
@onready var animated_otter: AnimatedSprite2D = $AnimatedOtter
@onready var animated_gun: AnimatedSprite2D = $AnimatedGun
var shoot_anim_timer: float = 0.0
var move_hold_timer: float = 0.0
var is_firing_burst: bool = false

var is_dead: bool = false
var played_dead_animation: bool = false
var border_hit_cooldown: float = 0.0

# Para UI
signal health_changed(current: int, max: int)
signal damaged
signal xp_changed(current: int, max_xp: int)
signal level_up(level: int)
signal died

func _ready() -> void:
	if SPEED_CAP > 0.0:
		speed_cap_inv = 1.0 / SPEED_CAP
	if current_scene_root == null:
		current_scene_root = get_tree().root
	bullet_pool = current_scene_root.get_node_or_null("BulletPool")
	left_muzzle = get_node_or_null(left_muzzle_path) as Node2D
	right_muzzle = get_node_or_null(right_muzzle_path) as Node2D
	_set_otter_idle_pose()
	_play_if_valid(animated_gun, gun_idle_animation)
	_initialize_leveling()
	xp_changed.emit(current_xp, xp_for_next_level)

func _input(event: InputEvent) -> void:
	if is_dead: return
	
	if event.is_action_pressed("leftClick"):
		_try_shoot_on_click()

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity *= 0.8
		move_and_slide()
		return
	
	if Input.is_action_pressed("leftClick"):
		move_hold_timer += delta
		if move_hold_timer >= move_hold_delay:
			var to_mouse: Vector2 = get_global_mouse_position() - global_position
			if to_mouse.length() > 5.0:
				move_direction = to_mouse.normalized()
				has_direction = true
	else:
		move_hold_timer = 0.0

	if has_direction:
		var target_velocity: Vector2 = move_direction * max_speed
		var accel: Vector2 = velocity.lerp(target_velocity, responsiveness * delta)
		velocity += accel * acceleration_factor * delta
		var target_rotation: float = move_direction.angle() + deg_to_rad(rotation_offset_degrees)
		rotation = lerp_angle(rotation, target_rotation, turn_speed * delta)
	
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed 
	
	velocity *= 1.0 / (1.0 + drag * delta) 
	AudioController.play_player_movement()
	move_and_slide()
	handle_rink_contacts()

func _process(delta: float) -> void:	
	update_animation_state()
	update_invuln_timer(delta)
	
	if !is_dead:
		_update_shoot_cooldown(delta)
		if shoot_anim_timer > 0.0:
			shoot_anim_timer -= delta
		update_gun_aim(delta)
	_update_shoot_cooldown(delta)
	border_hit_cooldown -= delta
	if shoot_anim_timer > 0.0:
		shoot_anim_timer -= delta
	update_animation_state()
	update_gun_aim(delta)

func update_animation_state() -> void:
	if is_dead:
		return

	if animated_otter != null:
		var current_speed: float = velocity.length()
		if current_speed <= idle_speed_threshold:
			_set_otter_idle_pose()
		elif current_speed >= move_speed_threshold:
			_play_if_valid(animated_otter, high_speed_animation)
		else:
			_play_if_valid(animated_otter, low_speed_animation)

	if animated_gun == null:
		return

	if shoot_anim_timer > 0.0:
		animated_gun.speed_scale = gun_shoot_animation_speed
		_play_if_valid(animated_gun, gun_shoot_animation)
	else:
		animated_gun.speed_scale = 1.0
		_play_if_valid(animated_gun, gun_idle_animation)

func _set_otter_idle_pose() -> void:
	if animated_otter == null or animated_otter.sprite_frames == null:
		return
	if not animated_otter.sprite_frames.has_animation(low_speed_animation):
		return
	if animated_otter.animation != low_speed_animation:
		animated_otter.play(low_speed_animation)
	animated_otter.frame = 0
	animated_otter.pause()

func update_gun_aim(delta: float) -> void:
	if animated_gun == null:
		return

	if Input.is_action_pressed("leftClick"):
		var to_mouse: Vector2 = get_global_mouse_position() - animated_gun.global_position
		if to_mouse.length_squared() > 0.001:
			var target_rotation: float = to_mouse.angle() + deg_to_rad(gun_aim_offset_degrees)
			animated_gun.global_rotation = lerp_angle(animated_gun.global_rotation, target_rotation, gun_aim_turn_speed * delta)
	else:
		animated_gun.rotation = lerp_angle(animated_gun.rotation, 0.0, gun_aim_turn_speed * delta)

func _play_if_valid(target: AnimatedSprite2D, animation_name: StringName) -> void:
	if target == null or target.sprite_frames == null:
		return
	if not target.sprite_frames.has_animation(animation_name):
		return
	if target.animation == animation_name and target.is_playing():
		return
	target.play(animation_name)

func update_invuln_timer(delta: float) -> void:
	if invuln_timer > 0.0:
		invuln_timer -= delta
	elif is_invuln:
		is_invuln = false
		set_collision_layer_value(1, true)
		set_collision_mask_value(2, true)
		if animated_otter != null:
			animated_otter.self_modulate = Color(1, 1, 1)


func handle_rink_contacts() -> void:
	var collision_count: int = get_slide_collision_count()
	
	if collision_count <= 0:
		return

	var current_speed: float = velocity.length()

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
		if border_hit_cooldown <= 0.0:
			AudioController.play_border_hit()
			border_hit_cooldown = 0.5
		rink.spawn_touch_particles(collision.get_position(), collision.get_normal(), current_speed)


func _update_shoot_cooldown(delta: float) -> void:
	shoot_timer -= delta

func _try_shoot_on_click() -> void:
	if shoot_timer > 0.0 or is_firing_burst:
		return

	var current_speed: float = velocity.length()
	var burst_count: int = _get_burst_count(current_speed)
	_fire_speed_burst(burst_count)
	shoot_anim_timer = max(shoot_anim_hold_time, burst_shot_interval * max(0, burst_count - 1) + 0.05)
	shoot_timer = calc_shoot_cooldown(current_speed)

func _get_burst_count(current_speed: float) -> int:
	var safe_max_burst: int = max(min_burst_count, max_burst_count)
	if safe_max_burst <= min_burst_count:
		return min_burst_count

	if current_speed <= burst_start_speed:
		return min_burst_count

	var speed_range: float = max(1.0, max_speed - burst_start_speed)
	var speed_percent: float = clamp((current_speed - burst_start_speed) / speed_range, 0.0, 1.0)

	return int(round(lerp(float(min_burst_count), float(safe_max_burst), speed_percent)))

func _fire_speed_burst(burst_count: int) -> void:
	var safe_burst_count: int = max(1, burst_count)
	is_firing_burst = true
	for burst_index in range(safe_burst_count):
		shoot()
		if burst_index < safe_burst_count - 1 and burst_shot_interval > 0.0:
			await get_tree().create_timer(burst_shot_interval).timeout
	is_firing_burst = false
	
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
	var effective_bullet_speed: float = bullet_speed + max(0.0, velocity.dot(direction))
	for spawn_position in _get_bullet_spawn_positions(direction):
		_spawn_bullet(spawn_position, direction, effective_bullet_speed, rotation_to_mouse)
	AudioController.play_shoot()

func _get_bullet_spawn_positions(direction: Vector2) -> Array[Vector2]:
	var positions: Array[Vector2] = []

	if left_muzzle != null and right_muzzle != null:
		positions.append(left_muzzle.global_position)
		positions.append(right_muzzle.global_position)
		return positions

	var forward_position: Vector2 = global_position + direction * bullet_spawn_offset
	var side: Vector2 = direction.orthogonal().normalized() * muzzle_lateral_offset
	positions.append(forward_position - side)
	positions.append(forward_position + side)
	return positions

func _spawn_bullet(spawn_position: Vector2, direction: Vector2, effective_bullet_speed: float, rotation_to_mouse: float) -> void:
	if bullet_pool != null and bullet_pool.has_method("get_bullet"):
		bullet_pool.call("get_bullet", Bullet.Team.PLAYER, spawn_position, direction, effective_bullet_speed, rotation_to_mouse, bullet_scene, damage)
		return

	var bullet: Bullet = bullet_scene.instantiate()
	bullet.team = Bullet.Team.PLAYER
	bullet.global_position = spawn_position
	bullet.direction = direction
	bullet.speed = effective_bullet_speed
	bullet.rotation = rotation_to_mouse
	bullet.damage = damage
	current_scene_root.add_child(bullet)

func take_damage(amount: int = 1) -> void:
	if is_dead:
		return
	
	if invuln_timer > 0: return
	print("Taking damage!")
	current_health -= amount
	health_changed.emit(current_health, max_health)  # UI
	damaged.emit()			# UI
	AudioController.play_health_loss()		
	if current_health <= 0: die()
	invuln_timer = invuln_time
	set_collision_layer_value(1, false)
	set_collision_mask_value(2, false)
	if animated_otter != null:
		animated_otter.self_modulate = Color(1.0, 1.0, 1.0, 0.6)
	is_invuln = true
	$Camera2D.current_shake = 20
		
func die() -> void:
	if is_dead: return
	is_dead = true
	animated_otter.play(death_animation)
	died.emit()
	ScoreManager.is_active = false
	$EnemyDetector.monitorable = false
	$EnemyDetector.monitoring = false
	set_collision_layer_value(1,  false)
	
	print("ggwp")

func apply_slow(slow_amount: float, slow_duration: float) -> void:
	# Store original acceleration on first use
	if not has_meta("original_accel"):
		set_meta("original_accel", acceleration_factor)
		set_meta("current_slow", 0.0)
	
	@warning_ignore("untyped_declaration")
	var original_accel = get_meta("original_accel")
	
	# Only apply if this slow is stronger
	if slow_amount > get_meta("current_slow"):
		velocity *= (1.0 - slow_amount)
		acceleration_factor = original_accel * (1.0 - slow_amount)
		set_meta("current_slow", slow_amount)
		
		await get_tree().create_timer(slow_duration).timeout
		set_meta("current_slow", 0.0)
		acceleration_factor = original_accel

func _on_enemy_detector_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		# Don't take damage during invulnerability
		if invuln_timer > 0:
			return

		var body_script: Script = body.get_script() as Script
		var script_path: String = body_script.resource_path if body_script != null else ""
			
		var damage_amount: int = 1
		
		# Vary damage based on enemy type
		if script_path.contains("enemy_dasher"):
			damage_amount = 2
		elif script_path.contains("enemy_tank"):
			damage_amount = 3
		elif script_path.contains("enemy_slow_shooter"):
			damage_amount = 1
		elif script_path.contains("enemy_slow_chaser"):
			damage_amount = 1
		
		# Only push if NOT a dasher
		if not script_path.contains("enemy_dasher"):
			var body_node: Node2D = body as Node2D
			var push_direction: Vector2 = (global_position - body_node.global_position).normalized()
			var push_force: float = 200.0
			var enemy_push_force: float = 200.0  
			
			# Push player
			velocity = push_direction * push_force
			
			# Push enemy (opposite direction, less force)
			if body is CharacterBody2D:
				var enemy_body: CharacterBody2D = body as CharacterBody2D
				enemy_body.velocity += -push_direction * enemy_push_force
		
		take_damage(damage_amount)

func _initialize_leveling() -> void:
	current_level = 0
	current_xp = 0
	_update_xp_requirement()

func _update_xp_requirement() -> void:
	if xp_curve == null:
		# Fallback: simple quadratic scaling
		xp_for_next_level = int(100 * pow(current_level + 1, 1.5))
	else:
		# Sample curve at normalized level (0 to 1)
		var curve_sample: float = float(current_level) / float(max(1, level_cap))
		var base_xp: float = xp_curve.sample(curve_sample) * 1000.0
		xp_for_next_level = int(base_xp)

func add_xp(amount: int) -> void:
	current_xp += amount
	xp_changed.emit(current_xp, xp_for_next_level)
	
	while current_xp >= xp_for_next_level and current_level < level_cap:
		_level_up()

func _level_up() -> void:
	print("Leveling up!")
	current_xp -= xp_for_next_level
	current_level += 1
	_update_xp_requirement()
	
	xp_changed.emit(current_xp, xp_for_next_level)
	level_up.emit(current_level)
	
	if upgrade_manager != null:
		await get_tree().process_frame  # Let signals propagate first
		var upgrades_offered: Array[Upgrade] = upgrade_manager.get_upgrade_per_level(current_level)
		if upgrades_offered.is_empty():
			print("WARNING: no upgrades available on level up")
		for idx in range(upgrades_offered.size()):
			upgrade_manager.apply_upgrade(upgrades_offered[idx], self, idx)
		
func _on_enemy_died(toughness: int) -> void:
	var xp_gain: int = int(round(xp_growth_factor * (toughness * enemy_weight + ScoreManager.combo * combo_weight)))
	add_xp(xp_gain)

func _spawn_upgrade_popup(upgrade_name: String, amount: int, index: int = 0) -> void:
	if upgrade_popup_scene == null:
		return
	
	var popup: PopupUpgrade = upgrade_popup_scene.instantiate()
	current_scene_root.add_child(popup)
	popup.global_position = global_position
	
	# Stack popups vertically based on index
	var vertical_offset: float = index * -60.0  # Each popup offset 40 pixels down
	if popup.has_method("set_target"):
		popup.set_target(self, vertical_offset)
	
	if popup.has_method("set_upgrade_text"):
		popup.set_upgrade_text(upgrade_name, amount)
	
func upgrade_max_hp(amount: int, index: int = 0) -> void:
	print("Upgrading Max HP!")
	_spawn_upgrade_popup("MAX HP", amount, index)
	max_health += amount
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)	

func upgrade_bullet_speed(amount: int, index: int = 0) -> void:
	print("Upgrading Bullet Speed!")
	_spawn_upgrade_popup("BULLET SPEED", amount, index)
	bullet_speed += amount
	
func upgrade_damage(amount: int, index: int = 0) -> void:
	print("Upgrading Damage!")
	_spawn_upgrade_popup("DAMAGE", amount, index)
	damage += amount

func upgrade_bullet_count(amount: int, index: int = 0) -> void:
	print("Upgrading Bullet Count!")
	_spawn_upgrade_popup("BULLETS", amount, index)
	min_burst_count += amount
	max_burst_count += amount

func upgrade_max_speed(amount: int, index: int = 0) -> void:
	print("Upgrading Max Speed!")
	_spawn_upgrade_popup("MAX SPEED", amount, index)
	max_speed += amount
	
	
