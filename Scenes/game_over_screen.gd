extends CanvasLayer

@onready var retry_btn: BaseButton = $BtnsCol/RetryBtn
@onready var mainmenu_btn: BaseButton = $BtnsCol/MainMenuBtn

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
		retry_btn.grab_focus()
