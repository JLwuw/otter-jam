extends CanvasLayer

func _input(event: InputEvent) -> void:
	if visible and get_tree().paused and event.is_action_pressed("ui_cancel"):
		get_parent().toggle_pause()
		get_viewport().set_input_as_handled()
