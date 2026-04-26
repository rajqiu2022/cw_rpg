extends Control

@onready var btn_new_game: Button = %BtnNewGame
@onready var btn_continue: Button = %BtnContinue
@onready var btn_quit: Button = %BtnQuit
@onready var version_label: Label = %VersionLabel

func _ready() -> void:
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	btn_continue.disabled = not SaveManager.has_save(0)
	version_label.text = "v0.1.0  ·  framework only"

func _on_new_game_pressed() -> void:
	GameState.reset_for_new_game()
	SceneRouter.start_battle("default_thug")

func _on_continue_pressed() -> void:
	if SaveManager.load_from_slot(0):
		SceneRouter.start_battle("default_thug")

func _on_quit_pressed() -> void:
	SceneRouter.quit_game()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		SceneRouter.quit_game()
