extends Node

enum Difficulty {
	EASY,
	MEDIUM,
	HARD
}

var score: float = 0
var elapsed_time: float = 0.0
var combo: int = 0
var combo_timer: float = 0.0
var is_active: bool = false
var difficulty_selected: Difficulty = Difficulty.EASY

const TOUGHNESS_MULT: float = 5.0
const TIME_MULT: float = 0.1
const COMBO_DURATION: float = 3.0

func _process(delta: float) -> void:
	if not is_active: return
	elapsed_time += delta
	if combo > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo = 0

func _on_enemy_died(toughness: int) -> void:
	if not is_active: return
	combo += 1
	combo_timer = COMBO_DURATION
	
	var final_points: float = toughness * combo * TOUGHNESS_MULT
	score += final_points

func get_final_score() -> int:
	return int(round(score + elapsed_time * TIME_MULT))
	

func reset() -> void:
	score = 0
	elapsed_time = 0
	combo = 0
	combo_timer = 0
