extends Control

@onready var tutorial_popup: CanvasLayer = $TutorialPopUp
@onready var howto_btn: Button = $BtnsCol/HowtoPlayBtn
@onready var close_btn: Button = $TutorialPopUp/Box/CloseBtn

func _ready() -> void:
	$BtnsCol/PlayBtn.pressed.connect(_on_play_pressed)
	$BtnsCol/QuitBtn.pressed.connect(_on_quit_pressed)

	tutorial_popup.visible = false
	howto_btn.pressed.connect(_on_howto_pressed)
	close_btn.pressed.connect(_on_close_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/difficulty_screen.tscn")

func _on_howto_pressed() -> void:
	tutorial_popup.visible = true

func _on_close_pressed() -> void:
	tutorial_popup.visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()
