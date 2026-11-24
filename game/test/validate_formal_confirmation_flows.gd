extends SceneTree

const CONFIRM_SCENE := "res://scenes/ui/formal_confirm_dialog.tscn"
const SAVE_SCENE := "res://scenes/ui/save_slot_panel.tscn"
const DEFEAT_SCENE := "res://scenes/result_defeat.tscn"
const CHOICE_SCENE := "res://scenes/ui/formal_choice_menu.tscn"
const QUEST_SCENE := "res://scenes/ui/quest_panel.tscn"
const SKILL_SCENE := "res://scenes/ui/skill_panel.tscn"
const INVENTORY_SCENE := "res://scenes/ui/inventory_panel.tscn"

var _failed := false


func _initialize() -> void:
	var confirm_packed := load(CONFIRM_SCENE) as PackedScene
	_check(confirm_packed != null, "正式确认框场景可加载")
	if confirm_packed != null:
		var dialog := confirm_packed.instantiate() as FormalConfirmDialog
		root.add_child(dialog)
		await process_frame
		_check(not dialog.visible, "确认框默认隐藏")
		dialog.show_confirm("确认测试", "[center]测试内容[/center]", "确认", "取消")
		_check(dialog.visible, "确认操作会显示正式弹层")
		var art := dialog.find_child("ConfirmPanelArt", true, false) as TextureRect
		var confirm_button := dialog.find_child("ConfirmAction", true, false) as Button
		var cancel_button := dialog.find_child("CancelAction", true, false) as Button
		_check(art != null and art.texture != null, "确认框使用正式透明底图")
		_check(confirm_button != null and cancel_button != null and cancel_button.visible, "确认模式有确认与取消按钮")
		_check(confirm_button.get_theme_stylebox("normal") is StyleBoxTexture, "确认按钮使用正式纹理三态")
		dialog.show_notice("提示", "[center]提示内容[/center]")
		_check(not cancel_button.visible and confirm_button.position.x == 240.0, "单按钮提示模式保持居中")
		dialog.queue_free()

	var choice_packed := load(CHOICE_SCENE) as PackedScene
	_check(choice_packed != null, "正式选项菜单场景可加载")
	if choice_packed != null:
		var choice := choice_packed.instantiate() as FormalChoiceMenu
		root.add_child(choice)
		await process_frame
		choice.show_choices("选择测试", [{"id": &"a", "label": "选项一"}, {"id": &"b", "label": "选项二"}], &"a")
		_check(choice.visible and choice.find_child("ChoiceGrid", true, false).get_child_count() == 2, "正式选项菜单按数据创建按钮")
		var first_choice := choice.find_child("ChoiceGrid", true, false).get_child(0) as Button
		_check(first_choice.get_theme_stylebox("normal") is StyleBoxTexture, "正式选项使用通用纹理按钮")
		choice.queue_free()

	var save_packed := load(SAVE_SCENE) as PackedScene
	_check(save_packed != null, "存档面板可加载")
	if save_packed != null:
		var save_panel := save_packed.instantiate() as Control
		root.add_child(save_panel)
		await process_frame
		_check(save_panel.find_child("SaveSlotConfirmation", true, false) is FormalConfirmDialog, "存档面板接入通用正式确认框")
		_check(save_panel.find_child("ConfirmDialog", true, false) == null, "存档面板不再使用原生 ConfirmationDialog")
		_check(save_panel.find_child("NoSaveDialog", true, false) == null, "存档面板不再使用原生 AcceptDialog")
		save_panel.queue_free()

	var defeat_packed := load(DEFEAT_SCENE) as PackedScene
	_check(defeat_packed != null, "失败结算场景可加载")
	if defeat_packed != null:
		var defeat := defeat_packed.instantiate() as Control
		root.add_child(defeat)
		await process_frame
		var back := defeat.find_child("BtnBack", true, false) as Button
		var formal_bg := defeat.find_child("FormalBackground", true, false) as TextureRect
		_check(back != null and back.get_theme_stylebox("normal") is StyleBoxTexture, "失败页返回按钮使用正式纹理")
		_check(formal_bg != null and formal_bg.modulate == Color.WHITE, "失败页正式底图不再压暗")
		defeat.queue_free()

	for scene_info: Dictionary in [
		{"path": QUEST_SCENE, "menu": "ChapterMenu", "native": "PopupMenu", "label": "任务章节"},
		{"path": SKILL_SCENE, "menu": "SchoolChoiceMenu", "native": "OptionButton", "label": "武学流派"},
		{"path": INVENTORY_SCENE, "menu": "ContextMenu", "native": "PopupMenu", "label": "背包右键"},
	]:
		var packed := load(String(scene_info.path)) as PackedScene
		_check(packed != null, "%s界面可加载" % scene_info.label)
		if packed == null:
			continue
		var panel := packed.instantiate() as Control
		root.add_child(panel)
		await process_frame
		_check(panel.find_child(String(scene_info.menu), true, false) is FormalChoiceMenu, "%s使用正式选项菜单" % scene_info.label)
		_check(not _has_native_control(panel, String(scene_info.native)), "%s不再保留系统原生控件" % scene_info.label)
		panel.queue_free()

	print("[FormalConfirmationFlows] %s" % ("FAIL" if _failed else "PASS"))
	quit(1 if _failed else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] ", message)
	else:
		_failed = true
		push_error("[FAIL] " + message)


func _has_native_control(node: Node, class_name_text: String) -> bool:
	if node.get_class() == class_name_text:
		return true
	for child in node.get_children():
		if _has_native_control(child, class_name_text):
			return true
	return false
