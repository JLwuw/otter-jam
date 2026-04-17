extends GPUParticles2D

@export var min_emit_speed: float = 120.0
@export var min_speed_for_direction_update: float = 0.01

var player: CharacterBody2D
var particle_material: ParticleProcessMaterial

func _ready() -> void:
	player = get_parent() as CharacterBody2D
	if process_material is ParticleProcessMaterial:
		particle_material = (process_material as ParticleProcessMaterial).duplicate(true)
		process_material = particle_material


func _process(_delta: float) -> void:
	if particle_material == null or player == null:
		emitting = false
		return

	var speed_sq: float = player.velocity.length_squared()
	var emit_speed_sq: float = min_emit_speed * min_emit_speed
	emitting = speed_sq >= emit_speed_sq
	if not emitting:
		return

	if speed_sq <= min_speed_for_direction_update * min_speed_for_direction_update:
		return

	var opposite_dir: Vector2 = -player.velocity.normalized()
	particle_material.direction = Vector3(opposite_dir.x, opposite_dir.y, 0.0)
