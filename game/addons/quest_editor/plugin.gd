@tool
extends EditorPlugin

## Quest Editor 插件入口。
## 在 Godot 编辑器底部面板注册 "Quest Editor" 标签，
## 实例化 QuestEditorPanel 作为主界面。

var _panel: Control = null


func _enter_tree() -> void:
	_panel = preload("res://addons/quest_editor/quest_editor_panel.tscn").instantiate()
	add_control_to_bottom_panel(_panel, "📋 Quest Editor")


func _exit_tree() -> void:
	if _panel != null:
		remove_control_from_bottom_panel(_panel)
		_panel.queue_free()
		_panel = null
