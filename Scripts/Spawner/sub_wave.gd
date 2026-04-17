extends Resource
class_name SubWave

@export_group("Spawning")
@export var enemy_scene: PackedScene
@export var count: int = 5
@export var spawn_radius: float = 400.0

@export_group("Timing")
@export var spawn_delay: float = 0.2 # time between each enemy
@export var delay_after: float = 1.0 # wait before next subwave
