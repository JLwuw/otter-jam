extends Control

@onready var tutorial_popup: CanvasLayer = $TutorialPopUp
@onready var play_btn: TextureButton = $BtnsCol/PlayBtn
@onready var howto_btn: TextureButton = $BtnsCol/HowtoPlayBtn
@onready var quit_btn: TextureButton = $BtnsCol/QuitBtn
@onready var close_btn: Button = $TutorialPopUp/Box/CloseBtn
@onready var menu_buttons: Array[BaseButton] = [play_btn, howto_btn, quit_btn]
var stick_navigation_ready: bool = true

func _ready() -> void:
	play_btn.pressed.connect(_on_play_pressed)
	howto_btn.pressed.connect(_on_howto_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	tutorial_popup.visible = false
	close_btn.pressed.connect(_on_close_pressed)
	play_btn.grab_focus()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_action_pressed("ui_cancel"):
		if tutorial_popup.visible:
			_on_close_pressed()
		return
	
	if event is InputEventKey and event.is_action_pressed("ui_accept"):
		print("ui_accept")


func _on_play_pressed() -> void:
	AudioController.stop_all_sfx()
	await AudioController.fade_out_music()
	get_tree().change_scene_to_file("res://Scenes/difficulty_screen.tscn")

func _on_howto_pressed() -> void:
	tutorial_popup.visible = true
	close_btn.grab_focus()

func _on_close_pressed() -> void:
	tutorial_popup.visible = false
	play_btn.grab_focus()

func _on_quit_pressed() -> void:
	get_tree().quit()
