class_name EnemyData
extends Resource

var scene: PackedScene
var toughness: int
var unlock_time: int

func _init(_scene: PackedScene, _toughness: int, _unlock_time: int) -> void:
	scene = _scene
	toughness = _toughness
	unlock_time = _unlock_time
