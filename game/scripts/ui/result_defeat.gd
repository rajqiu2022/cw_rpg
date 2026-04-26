extends Control

@onready var btn_back: Button = %BtnBack

func _ready() -> void:
	btn_back.pressed.connect(func(): SceneRouter.go_main_menu())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_confirm"):
		SceneRouter.go_main_menu()
