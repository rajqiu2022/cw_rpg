extends Control

@onready var reward_label: Label = %RewardLabel
@onready var btn_continue: Button = %BtnContinue
@onready var btn_save: Button = %BtnSave

func _ready() -> void:
	var payload := SceneRouter.get_battle_payload()
	var gold := int(payload.get("gold", 0))
	var exp := int(payload.get("exp", 0))
	reward_label.text = "获得金钱  %d 两\n获得经验  %d 点" % [gold, exp]
	btn_continue.pressed.connect(func(): SceneRouter.go_main_menu())
	btn_save.pressed.connect(_on_save_pressed)

func _on_save_pressed() -> void:
	if SaveManager.save_to_slot(0):
		btn_save.text = "已存档 ✓"
		btn_save.disabled = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_confirm"):
		SceneRouter.go_main_menu()
