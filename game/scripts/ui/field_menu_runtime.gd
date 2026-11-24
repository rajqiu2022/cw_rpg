extends Node

const BUTTON_ART := preload("res://scripts/ui/menu_button_art.gd")
const INTERFACE_SUITE := preload("res://scripts/ui/lacquer_interface_suite.gd")
const HUD_BUTTON_SHEET := preload("res://art/ui/field_menu_20261112/field_menu.png")
const HUD_TILE_SIZE := Vector2(504, 150)
const HUD_BUTTON_SPACING := 62.0
const HUD_SCENE := "res://scenes/ui/field_primary_hud.tscn"
const QUEST_SCENE := "res://scenes/ui/quest_panel.tscn"
const REWARD_DETAIL_TIP := preload("res://scripts/ui/quest_reward_detail_tip.gd")
const CHARACTER_SCENE := "res://scenes/ui/character_panel.tscn"
const MENU := [
	["BtnEquipment", "角色", "C"],
	["BtnSkill", "武学", "K"], ["BtnQuest", "任务", "J"],
	["BtnSystem", "系统", "O"],
]

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node.has_method("_on_item_picked_up") and not node.is_node_ready():
		node.ready.connect(_route_pickup_tip.bind(node), CONNECT_ONE_SHOT)
	match node.scene_file_path:
		HUD_SCENE: _style_hud.call_deferred(node)
		QUEST_SCENE: _wire_quest.call_deferred(node)
		CHARACTER_SCENE: _style_inventory_actions.call_deferred(node)
	if node is Control:
		var screen := INTERFACE_SUITE.screen_for(node)
		if screen != &"":
			_skin_interface.call_deferred(node, screen)

func _route_pickup_tip(field: Node) -> void:
	# The field connects its legacy handler in _ready. Replace only that listener.
	var legacy := Callable(field, "_on_item_picked_up")
	if EventBus.item_picked_up.is_connected(legacy):
		EventBus.item_picked_up.disconnect(legacy)
		field.set_meta("uses_reward_pickup_tip", true)

func _skin_interface(node: Control, screen: StringName) -> void:
	INTERFACE_SUITE.apply(node, screen)

func _style_inventory_actions(panel: Control) -> void:
	if not is_instance_valid(panel) or not panel.is_inside_tree():
		return
	for key in ["_inventory_action_button", "_inventory_drop_button"]:
		var button := panel.get(key) as Button
		if button != null:
			BUTTON_ART.style_button(button, "action", 17)
			button.position.y -= 6.0
			button.custom_minimum_size.y = button.size.x / BUTTON_ART.aspect("action")
			button.size.y = button.custom_minimum_size.y

func _style_hud(hud: Control) -> void:
	if not is_instance_valid(hud) or not hud.is_inside_tree():
		return
	for index in MENU.size():
		var spec: Array = MENU[index]
		var button := hud.get_node_or_null(spec[0]) as TextureButton
		if button == null:
			continue
		var row := index + int(index == 3)
		button.position.y = 236 + row * HUD_BUTTON_SPACING
		_style_hud_button(button, row)
		button.tooltip_text = "%s（%s）" % [spec[1], spec[2]]
		if spec[0] == "BtnEquipment":
			button.tooltip_text = "角色与行囊（C）"
		button.show()
	var life_button := TextureButton.new()
	life_button.name = "BtnLifeSkills"
	life_button.position = Vector2(0, HUD_BUTTON_SPACING)
	life_button.tooltip_text = "生活技能"
	_style_hud_button(life_button, 3)
	life_button.pressed.connect(func() -> void: get_parent().open_journal())
	# Follow the existing quest button's slide without introducing a second tween.
	hud.get_node("BtnQuest").add_child(life_button)

func _style_hud_button(button: TextureButton, row: int) -> void:
	var regions: Array[Rect2] = []
	for column in 3:
		regions.append(Rect2(Vector2(4 + column * 512, 68 + row * 192), HUD_TILE_SIZE))
	BUTTON_ART.style_hud(button, HUD_BUTTON_SHEET, regions)
	button.size = Vector2(172, 172.0 / HUD_TILE_SIZE.aspect())

func _wire_quest(quest_panel: Control) -> void:
	if not is_instance_valid(quest_panel) or not quest_panel.is_inside_tree():
		return
	var track := quest_panel.get_node("%TrackBtn") as TextureButton
	var old_tip := quest_panel.get("_reward_detail_tip") as Control
	if is_instance_valid(old_tip):
		var tip := REWARD_DETAIL_TIP.new()
		var tip_parent := old_tip.get_parent()
		tip.position = old_tip.position
		tip.size = old_tip.size
		tip_parent.remove_child(old_tip)
		old_tip.queue_free()
		tip.name = "RewardItemDetailTip"
		tip_parent.add_child(tip)
		quest_panel.set("_reward_detail_tip", tip)
	var main_button := TextureButton.new()
	main_button.name = "ViewMainTarget"
	main_button.position = track.position
	main_button.size = track.size
	quest_panel.call("_setup_texture_button", main_button, "track", "查看追踪", 17)
	for button: TextureButton in [track, main_button]:
		button.mouse_entered.connect(_set_track_caption_hover.bind(button, true))
		button.mouse_exited.connect(_set_track_caption_hover.bind(button, false))
	main_button.hide()
	track.get_parent().add_child(main_button)
	main_button.pressed.connect(_show_main_target.bind(quest_panel))
	var update := _refresh_main_target.bind(quest_panel, track, main_button)
	quest_panel.visibility_changed.connect(update)
	# Selecting a row or changing its status redraws the journal's details.
	var details := quest_panel.get_node("%DetailText") as RichTextLabel
	details.draw.connect(func() -> void: update.call_deferred())
	update.call()

func _set_track_caption_hover(button: TextureButton, hovered: bool) -> void:
	var caption := button.get_node_or_null("Caption") as Label
	if caption != null:
		caption.add_theme_color_override("font_color", Color("#baffef") if hovered else Color("#edf7fa"))

func _refresh_main_target(quest_panel: Control, track: TextureButton, button: TextureButton) -> void:
	if not is_instance_valid(quest_panel) or not quest_panel.is_visible_in_tree():
		return
	var quest := _selected_main(quest_panel)
	track.visible = quest == null and not track.disabled
	button.visible = quest != null
	if quest != null:
		quest_panel.call("_set_caption", button, "查看追踪" if quest == QuestManager.get_current_main_quest() else "查看目标")

func _selected_main(panel: Control) -> QuestDef:
	var qid: StringName = panel.get("_selected_qid")
	if not QuestManager.is_active(qid):
		return null
	var quest := QuestManager.load_def(qid)
	return quest if quest != null and quest.kind == QuestDef.Kind.MAIN else null

func _show_main_target(panel: Control) -> void:
	var quest := _selected_main(panel)
	if quest == null:
		return
	panel.close()
	var target := quest.get_tracker_hint()
	EventBus.toast_requested.emit("%s · %s" % [quest.title, target] if not target.is_empty() else quest.title)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or event.ctrl_pressed or event.alt_pressed or event.meta_pressed or event.shift_pressed:
		return
	var key: Key = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
	if key != KEY_O:
		return
	var field := get_tree().current_scene
	if not is_instance_valid(field) or not field.has_method("get_field_loading_state") or DialogPlayer.is_playing():
		return
	if bool(LoadingManager.get("_transition_active")) or bool(LoadingManager.get("_external_active")):
		return
	var state: Dictionary = field.get_field_loading_state()
	var hud := field.get("_primary_hud") as FieldPrimaryHud
	if state.get("complete") != true or state.get("failed") == true or hud == null:
		return
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return
	var system_layer: CanvasLayer = field.get("_system_ui_canvas_layer")
	var system := system_layer.get_node_or_null("SystemMenu") as Control if system_layer != null else null
	get_viewport().set_input_as_handled()
	if bool(field.get("_system_panel_open")) and (system == null or not system.is_visible_in_tree()):
		return
	if system == null or not system.visible or system.allows_hotkey_close():
		hud.system_pressed.emit()

