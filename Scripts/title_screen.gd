extends Control


func _ready() -> void:
	$BtnsCol/PlayBtn.pressed.connect(_on_play_pressed)
	$BtnsCol/QuitBtn.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/gameplay_test.tscn")

func _on_howtoplay_pressed() -> void:
	pass # lo que necesites

func _on_quit_pressed() -> void:
	get_tree().quit()
