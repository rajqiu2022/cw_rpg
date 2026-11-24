extends Node

var _checked := 0
var _failed := 0


func _ready() -> void:
	await _validate_skill_resources()
	await _validate_shop_buttons()
	print("[SkillShopUI] checked=%d failed=%d" % [_checked, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _validate_skill_resources() -> void:
	var packed := load("res://scenes/ui/skill_panel.tscn") as PackedScene
	_check(packed != null, "skill panel scene loads")
	if packed == null:
		return
	var panel := packed.instantiate()
	add_child(panel)
	await get_tree().process_frame
	panel.call("open")
	await get_tree().process_frame
	var panel_bg := panel.get_node("PanelBg") as TextureRect
	var cropped_bg := panel_bg.texture as AtlasTexture if panel_bg != null else null
	_check(cropped_bg != null, "skill panel crops the baked outer black gutter")
	if cropped_bg != null:
		_check(cropped_bg.region == Rect2(15, 15, 1506, 994), "skill panel keeps the inner frame at native coordinates")
		_check(panel_bg.size == Vector2(1506, 994), "cropped skill panel background is not stretched back over the gutter")
	var total := panel.get("_runtime_total_resource_label") as Label
	var available := panel.get("_runtime_available_resource_label") as Label
	_check(total != null and available != null, "skill resource labels exist")
	if total != null and available != null:
		_check(total.position == Vector2(1278, 72) and total.size == Vector2(166, 40), "total training points are centered in the upper resource bar")
		_check(available.position == Vector2(1278, 124) and available.size == Vector2(166, 40), "available training points are centered in the lower resource bar")
		_check(total.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and total.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "total training points use two-axis centering")
		_check(available.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and available.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "available training points use two-axis centering")
	await _validate_skill_effect_text(panel)
	panel.queue_free()
	await get_tree().process_frame


func _validate_skill_effect_text(panel: Node) -> void:
	var heal: Skill = load("res://data/skills/qinghe_returning_breath.tres")
	var guard: Skill = load("res://data/skills/qinghe_jade_guard.tres")
	var legendary: Skill = load("res://data/skills/huashan_jianduan_qianshan.tres")
	var skills: Array[Skill] = [heal, guard, legendary]
	panel.set("_skills", skills)
	panel.set("_runtime_selected_id", heal.skill_id)
	panel.call("_runtime_show_selected")
	var value_label := panel.get("_runtime_power_label") as Label
	var detail := panel.get("_runtime_detail") as RichTextLabel
	_check(value_label != null and value_label.text.contains("治疗"), "healing skill shows healing instead of damage")
	_check(detail != null and detail.text.contains("预计治疗") and not detail.text.contains("预计伤害"), "healing detail uses independent effect_value preview")
	panel.set("_runtime_selected_id", guard.skill_id)
	panel.call("_runtime_show_selected")
	_check(detail.text.contains("固定效果 16") and not detail.text.contains("预计伤害"), "buff detail does not enter damage formula")
	var legendary_row := panel.call("_runtime_make_row", legendary) as Button
	_check(legendary_row != null and not legendary_row.text.contains("[橙]"), "skill row does not spell out the quality color")
	_check(legendary_row != null and legendary_row.get_theme_color("font_color") == Color("e6a14f"), "skill row still distinguishes legendary quality by color")
	panel.set("_runtime_selected_id", legendary.skill_id)
	panel.call("_runtime_show_selected")
	_check(detail != null and not detail.text.contains("橙品质") and detail.text.contains("[color=#e6a14f]◆[/color]"), "skill detail uses a color marker without a quality-color label")
	if legendary_row != null:
		legendary_row.queue_free()


func _validate_shop_buttons() -> void:
	SceneRouter.set("_shop_payload", {"shop_id": &"linxi_apothecary"})
	var packed := load("res://scenes/shop.tscn") as PackedScene
	_check(packed != null, "shop scene loads")
	if packed == null:
		return
	var shop := packed.instantiate()
	add_child(shop)
	await get_tree().process_frame
	var tabs: Array[TextureButton] = [
		shop.get_node("Panel/BuyTabButton") as TextureButton,
		shop.get_node("Panel/SellTabButton") as TextureButton,
	]
	for tab: TextureButton in tabs:
		_check(tab != null, "shop tab exists as a TextureButton")
		if tab == null:
			continue
		_check(tab.texture_normal != null and tab.texture_normal.resource_path.ends_with("shop_tab_%s.png" % ("selected" if tab.button_pressed else "inactive")), "%s uses the correct selected/inactive tab base" % tab.name)
		_check(tab.texture_hover == tab.texture_normal, "%s hover keeps the tab base and changes text only" % tab.name)
		_check(tab.size.x >= 290.0 and tab.size.y >= 90.0, "%s covers the authored tab slot with a readable proportion" % tab.name)
		var caption := tab.get_node_or_null("Caption") as Label
		_check(caption != null and not caption.text.is_empty(), "%s owns a dynamic caption" % tab.name)
	_check(tabs[0].button_pressed and not tabs[1].button_pressed, "buy tab is selected on initial shop page")
	shop.call("_on_sell_tab_pressed")
	_check(not tabs[0].button_pressed and tabs[1].button_pressed, "sell tab selection follows the active page")
	_check(tabs[0].texture_normal.resource_path.ends_with("shop_tab_inactive.png") and tabs[1].texture_normal.resource_path.ends_with("shop_tab_selected.png"), "tab bases swap when the page changes")
	var buttons: Array[Button] = [
		shop.get_node("Panel/ConfirmTradeButton") as Button,
	]
	for button: Button in buttons:
		_check(button != null, "shop action button exists")
		if button == null:
			continue
		var normal := button.get_theme_stylebox("normal") as StyleBoxTexture
		var hover := button.get_theme_stylebox("hover") as StyleBoxTexture
		var pressed := button.get_theme_stylebox("pressed") as StyleBoxTexture
		_check(normal != null and normal.texture.resource_path.ends_with("shop_rect_normal.png"), "%s uses the reviewed shop normal frame" % button.name)
		_check(hover != null and hover.texture.resource_path.ends_with("shop_rect_hover.png"), "%s uses the reviewed shop hover frame" % button.name)
		_check(pressed != null and pressed.texture.resource_path.ends_with("shop_rect_pressed.png"), "%s uses the reviewed shop pressed frame" % button.name)
	_check(buttons[0].size.x >= 220.0 and buttons[0].size.y >= 54.0, "confirm button keeps the formal action-button family without squeezing text")
	var first_name_margin := shop.get_node_or_null("Panel/TradeScroll/TradeRows/ItemRow0/NameMargin") as MarginContainer
	if first_name_margin != null:
		_check(first_name_margin.get_theme_constant("margin_left") >= 24, "shop item names have left breathing room")
	shop.queue_free()
	await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	_checked += 1
	if condition:
		return
	_failed += 1
	push_error("[SkillShopUI] %s" % message)
