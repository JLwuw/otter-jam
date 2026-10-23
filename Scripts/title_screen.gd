extends Control

@onready var tutorial_popup: CanvasLayer = $TutorialPopUp
@onready var howto_btn: TextureButton = $BtnsCol/HowtoPlayBtn
@onready var close_btn: Button = $TutorialPopUp/Box/CloseBtn
@onready var menu_buttons: Array[BaseButton] = [$BtnsCol/PlayBtn, howto_btn, $BtnsCol/QuitBtn]
var focused_menu_index: int = 0
var stick_navigation_ready: bool = true

func _ready() -> void:
	$BtnsCol/PlayBtn.pressed.connect(_on_play_pressed)
	$BtnsCol/QuitBtn.pressed.connect(_on_quit_pressed)

	tutorial_popup.visible = false
	howto_btn.pressed.connect(_on_howto_pressed)
	close_btn.pressed.connect(_on_close_pressed)
	$BtnsCol/PlayBtn.grab_focus()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_action_pressed("ui_cancel"):
		if tutorial_popup.visible:
			_on_close_pressed()
		return

	if event is InputEventJoypadButton and event.pressed:
		var button_event: InputEventJoypadButton = event as InputEventJoypadButton
		if tutorial_popup.visible:
			if button_event.button_index == JOY_BUTTON_B:
				_on_close_pressed()
			elif button_event.button_index == JOY_BUTTON_A:
				close_btn.emit_signal("pressed")
			return

		if button_event.button_index == JOY_BUTTON_DPAD_UP:
			_move_menu_focus(-1)
		elif button_event.button_index == JOY_BUTTON_DPAD_DOWN:
			_move_menu_focus(1)
		elif button_event.button_index == JOY_BUTTON_A:
			menu_buttons[focused_menu_index].emit_signal("pressed")
	elif event is InputEventJoypadMotion:
		if tutorial_popup.visible:
			return
		var motion_event: InputEventJoypadMotion = event as InputEventJoypadMotion
		if motion_event.axis == JOY_AXIS_LEFT_Y:
			if absf(motion_event.axis_value) < 0.5:
				stick_navigation_ready = true
			elif not stick_navigation_ready:
				return
			elif motion_event.axis_value <= -0.5:
				_move_menu_focus(-1)
				stick_navigation_ready = false
			elif motion_event.axis_value >= 0.5:
				_move_menu_focus(1)
				stick_navigation_ready = false

func _move_menu_focus(direction: int) -> void:
	focused_menu_index = posmod(focused_menu_index + direction, menu_buttons.size())
	menu_buttons[focused_menu_index].grab_focus()

func _on_play_pressed() -> void:
	AudioController.stop_all_sfx()
	await AudioController.fade_out_music()
	get_tree().change_scene_to_file("res://Scenes/difficulty_screen.tscn")

func _on_howto_pressed() -> void:
	tutorial_popup.visible = true
	close_btn.grab_focus()

func _on_close_pressed() -> void:
	tutorial_popup.visible = false
	$BtnsCol/HowtoPlayBtn.grab_focus()

func _on_quit_pressed() -> void:
	get_tree().quit()
