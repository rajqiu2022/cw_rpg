extends Node


func _ready() -> void:
	call_deferred("_enter_main_menu")


func _enter_main_menu() -> void:
	LoadingManager.transition_to("res://scenes/main_menu.tscn", &"startup", {"title": "江湖初醒"})

