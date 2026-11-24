extends Control

signal closed(after_trade: String)

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const BUTTON_ART := preload("res://scripts/ui/menu_button_art.gd")
const TAB_INACTIVE_PATH := "res://art/ui/shop/tabs_v1/shop_tab_inactive.png"
const TAB_SELECTED_PATH := "res://art/ui/shop/tabs_v1/shop_tab_selected.png"
const MAX_TRADE_QUANTITY := 10
const QUALITY_COLORS := {
	Item.Quality.COMMON: Color("#d8dde2"),
	Item.Quality.UNCOMMON: Color("#55d96b"),
	Item.Quality.RARE: Color("#4aa9ff"),
	Item.Quality.EPIC: Color("#b56cff"),
	Item.Quality.LEGENDARY: Color("#ff9a3c"),
}

@onready var bg: ColorRect = $Bg
@onready var panel: Control = $Panel
@onready var tabs: TabContainer = $Panel/Content/Tabs
@onready var shop_name_label: Label = %ShopName
@onready var greeting_label: Label = %Greeting
@onready var gold_label: Label = %GoldLabel
@onready var buy_list: VBoxContainer = %BuyList
@onready var sell_list: VBoxContainer = %SellList
@onready var buy_tab_button: TextureButton = %BuyTabButton
@onready var sell_tab_button: TextureButton = %SellTabButton
@onready var close_btn: TextureButton = %CloseBtn
@onready var summary_label: Label = %Summary
@onready var last_action_label: Label = %LastAction
@onready var trade_total_label: Label = %TradeTotal
@onready var confirm_trade_button: Button = %ConfirmTradeButton
@onready var confirm_overlay: Control = %TradeConfirmOverlay
@onready var confirm_prompt: Label = %ConfirmPrompt
@onready var cancel_trade_button: Button = %CancelTradeButton
@onready var accept_trade_button: Button = %AcceptTradeButton

var _closing := false
var _shop: ShopDef = null
var _buy_quantities: Dictionary = {}
var _sell_quantities: Dictionary = {}


func _ready() -> void:
	var payload: Dictionary = SceneRouter.get_shop_payload()
	var shop_id: StringName = StringName(payload.get("shop_id", &""))
	_shop = _load_shop(shop_id)
	if _shop == null:
		push_warning("[Shop] shop not found: %s" % shop_id)
		_return_to_field()
		return

	tabs.tabs_visible = false
	shop_name_label.text = _shop.display_name
	greeting_label.text = _shop.greeting
	close_btn.pressed.connect(_on_close)
	buy_tab_button.pressed.connect(_on_buy_tab_pressed)
	sell_tab_button.pressed.connect(_on_sell_tab_pressed)
	confirm_trade_button.pressed.connect(_on_confirm_trade_pressed)
	cancel_trade_button.pressed.connect(_hide_confirmation)
	accept_trade_button.pressed.connect(_on_accept_trade_pressed)
	EventBus.gold_changed.connect(_on_gold_changed)
	Inventory.slots_changed.connect(_on_inventory_changed)

	_apply_visual_style()
	_refresh_all()


func _load_shop(shop_id: StringName) -> ShopDef:
	if String(shop_id).is_empty():
		return null
	var path: String = "res://data/shops/%s.tres" % String(shop_id)
	if not ResourceLoader.exists(path):
		return null
	var resource: Resource = load(path)
	return resource as ShopDef


func _refresh_all() -> void:
	_refresh_gold()
	_refresh_summary()
	_refresh_buy()
	_refresh_sell()
	_refresh_trade_total()
	_update_tab_state()


func _refresh_gold() -> void:
	gold_label.text = "当前金额  %d 金" % GameState.gold


func _refresh_summary() -> void:
	if _shop == null:
		return
	var sellable_count: int = 0
	for entry: Dictionary in Inventory.slots:
		var item: Item = entry.get("item") as Item
		var count: int = int(entry.get("count", 0))
		if item != null and count > 0 and not item.is_key_item():
			sellable_count += count
	summary_label.text = "库存 %d  ·  可出售 %d  ·  回收 %.0f%%" % [
		_shop.stock.size(), sellable_count, _shop.sell_back_ratio * 100.0
	]
	last_action_label.text = "选择数量后统一结算"


func _refresh_buy() -> void:
	_clear_container(buy_list)
	var remaining := maxi(0, GameState.gold - _buy_total())
	for item_id: StringName in _shop.stock:
		var item: Item = Inventory.load_item_by_id(item_id)
		if item == null:
			continue
		var quantity: int = int(_buy_quantities.get(item_id, 0))
		var limit := _buy_limit(item, quantity, remaining)
		buy_list.add_child(_make_table_row(item, item.buy_price, quantity, limit, true))


func _refresh_sell() -> void:
	_clear_container(sell_list)
	var found_item: bool = false
	var seen: Dictionary = {}
	for entry: Dictionary in Inventory.slots:
		var item: Item = entry.get("item") as Item
		if item == null or item.is_key_item() or seen.has(item.item_id):
			continue
		# Sell rows group by template ID; never include an individually upgraded copy.
		if item is Equipment and item.forge_rank > 0:
			continue
		seen[item.item_id] = true
		var owned: int = Inventory.count_of(item.item_id, false)
		if owned <= 0:
			continue
		found_item = true
		var max_quantity: int = mini(MAX_TRADE_QUANTITY, owned)
		var selected: int = mini(int(_sell_quantities.get(item.item_id, 0)), max_quantity)
		_sell_quantities[item.item_id] = selected
		var sell_price: int = int(floor(float(item.sell_price) * _shop.sell_back_ratio))
		sell_list.add_child(_make_table_row(item, sell_price, selected, max_quantity, false))

	if not found_item:
		var empty_label := Label.new()
		empty_label.text = "背包中没有可出售的物品"
		empty_label.custom_minimum_size = Vector2(0, 80)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UI_THEME.style_label(empty_label, 18, UI_THEME.MUTED, false)
		sell_list.add_child(empty_label)


func _make_table_row(
	item: Item,
	unit_price: int,
	quantity: int,
	max_quantity: int,
	is_buy: bool
) -> Control:
	var row_box := VBoxContainer.new()
	row_box.custom_minimum_size = Vector2(0, 82)
	row_box.add_theme_constant_override("separation", 4)

	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 72)
	row.add_theme_constant_override("separation", 18)
	row_box.add_child(row)

	var name_margin := MarginContainer.new()
	name_margin.custom_minimum_size = Vector2(320, 68)
	name_margin.add_theme_constant_override("margin_left", 24)
	row.add_child(name_margin)

	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation", 14)
	name_margin.add_child(identity)
	var icon := TextureRect.new()
	icon.name = "ItemIcon"
	icon.custom_minimum_size = Vector2(50, 50)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(item.icon_path, "Texture2D"):
		icon.texture = load(item.icon_path) as Texture2D
	identity.add_child(icon)

	var name_box := VBoxContainer.new()
	name_box.custom_minimum_size = Vector2(232, 68)
	name_box.add_theme_constant_override("separation", 2)
	identity.add_child(name_box)

	var name_label := Label.new()
	name_label.text = item.display_name
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	name_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UI_THEME.style_label(name_label, 19, QUALITY_COLORS.get(item.quality, Color(0.91, 0.95, 0.96, 1.0)), false)
	name_box.add_child(name_label)

	var price_label := Label.new()
	price_label.text = "%s  ·  单价 %d 金" % [_trade_type(item), unit_price]
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	price_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UI_THEME.style_label(price_label, 14, UI_THEME.GOLD, false)
	name_box.add_child(price_label)

	var description_label := Label.new()
	description_label.text = _shop_item_summary(item)
	description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI_THEME.style_label(description_label, 16, Color(0.72, 0.80, 0.83, 1.0), false)
	row.add_child(description_label)

	var quantity_box := HBoxContainer.new()
	quantity_box.custom_minimum_size = Vector2(230, 68)
	quantity_box.alignment = BoxContainer.ALIGNMENT_CENTER
	quantity_box.add_theme_constant_override("separation", 12)
	row.add_child(quantity_box)

	var item_id: StringName = item.item_id
	var minus_button := Button.new()
	_style_quantity_button(minus_button, "−")
	minus_button.disabled = quantity <= 0
	minus_button.pressed.connect(func() -> void: _change_quantity(item_id, -1, max_quantity, is_buy))
	quantity_box.add_child(minus_button)

	var quantity_label := Label.new()
	quantity_label.custom_minimum_size = Vector2(54, 42)
	quantity_label.text = str(quantity)
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI_THEME.style_label(quantity_label, 20, UI_THEME.GOLD_LIGHT, false)
	quantity_box.add_child(quantity_label)

	var plus_button := Button.new()
	_style_quantity_button(plus_button, "+")
	plus_button.disabled = quantity >= max_quantity
	plus_button.pressed.connect(func() -> void: _change_quantity(item_id, 1, max_quantity, is_buy))
	quantity_box.add_child(plus_button)

	var separator := HSeparator.new()
	separator.modulate = Color(0.30, 0.48, 0.54, 0.72)
	row_box.add_child(separator)
	return row_box


func _trade_type(item: Item) -> String:
	if item is Equipment:
		return "装备·" + ["武器", "头饰", "护甲", "护手", "鞋履", "饰品"][item.slot]
	if item.study_skill_id != &"":
		return "秘籍"
	if item.category == Item.Category.CONSUMABLE:
		return "药品" if item.heal_hp > 0 or item.heal_mp > 0 or item.permanent_growth or item.item_id in [&"antidote_pill", &"clarity_dew", &"bright_eye_powder"] else "消耗品"
	return "材料" if item.category == Item.Category.MATERIAL else "任务物品"

func _shop_item_summary(item: Item) -> String:
	if not item is Equipment:
		return item.description
	var equipment := item as Equipment
	var stats: Array[String] = []
	_append_shop_stat(stats, "攻击", equipment.atk_bonus)
	_append_shop_stat(stats, "防御", equipment.def_bonus + equipment.get_guard_bonus())
	_append_shop_stat(stats, "速度", equipment.speed_bonus)
	_append_shop_stat(stats, "筋骨", equipment.get_strength_bonus())
	_append_shop_stat(stats, "机敏", equipment.get_agility_bonus())
	_append_shop_stat(stats, "内劲", equipment.get_inner_power_bonus())
	_append_shop_stat(stats, "悟性", equipment.get_insight_bonus())
	_append_shop_stat(stats, "生命", equipment.get_vitality_bonus())
	_append_shop_stat(stats, "内力", equipment.get_inner_pool_bonus())
	if equipment.get_crit_chance_bonus() != 0.0:
		stats.append("暴击率 %+d%%" % int(round(equipment.get_crit_chance_bonus() * 100.0)))
	if equipment.get_hit_chance_bonus() != 0.0:
		stats.append("命中率 %+d%%" % int(round(equipment.get_hit_chance_bonus() * 100.0)))
	if equipment.get_weapon_skill_scaling_bonus() != 0:
		stats.append("兵器招式系数 %+d%%" % equipment.get_weapon_skill_scaling_bonus())
	if not equipment.special_effect_description.strip_edges().is_empty():
		stats.append("◆ %s" % equipment.special_effect_description.strip_edges())
	return "  ".join(stats) if not stats.is_empty() else "无额外属性"


func _append_shop_stat(lines: Array[String], label: String, value: int) -> void:
	if value != 0:
		lines.append("%s %+d" % [label, value])


func _change_quantity(item_id: StringName, delta: int, max_quantity: int, is_buy: bool) -> void:
	var quantities: Dictionary = _buy_quantities if is_buy else _sell_quantities
	var current: int = int(quantities.get(item_id, 0))
	if is_buy and delta > 0:
		var item := Inventory.load_item_by_id(item_id)
		if item == null:
			return
		max_quantity = _buy_limit(item, current, maxi(0, GameState.gold - _buy_total()))
	quantities[item_id] = clampi(current + delta, 0, max_quantity)
	if is_buy:
		_refresh_buy()
	else:
		_refresh_sell()
	_refresh_trade_total()


func _buy_limit(item: Item, selected: int, remaining: int) -> int:
	if item.buy_price <= 0:
		return MAX_TRADE_QUANTITY
	@warning_ignore("integer_division")
	return mini(MAX_TRADE_QUANTITY, selected + remaining / item.buy_price)


func _buy_total() -> int:
	var total := 0
	for item_id: StringName in _shop.stock:
		var quantity: int = int(_buy_quantities.get(item_id, 0))
		var item: Item = Inventory.load_item_by_id(item_id)
		if item != null and quantity > 0:
			total += item.buy_price * quantity
	return total


func _trade_total() -> int:
	if tabs.current_tab == 0:
		return _buy_total()
	var total := 0
	for key: Variant in _sell_quantities.keys():
		var item_id := StringName(key)
		var quantity: int = int(_sell_quantities.get(item_id, 0))
		var item: Item = Inventory.load_item_by_id(item_id)
		if item != null and quantity > 0 and Inventory.count_of(item_id, false) >= quantity:
			var price: int = int(floor(float(item.sell_price) * _shop.sell_back_ratio))
			total += price * quantity
	return total


func _refresh_trade_total() -> void:
	var total: int = _trade_total()
	trade_total_label.text = "交易金额：%d 金" % total
	var can_trade: bool = total > 0
	if tabs.current_tab == 0 and total > GameState.gold:
		can_trade = false
		last_action_label.text = "金额不足"
	else:
		last_action_label.text = "选择数量后统一结算"
	confirm_trade_button.disabled = not can_trade


func _on_confirm_trade_pressed() -> void:
	var total: int = _trade_total()
	if total <= 0:
		return
	if tabs.current_tab == 0 and total > GameState.gold:
		last_action_label.text = "金额不足"
		return
	confirm_prompt.text = (
		"是否花 %d 金钱购买所选物品？" % total
		if tabs.current_tab == 0
		else "是否卖掉所选物品获得 %d 金额？" % total
	)
	confirm_overlay.visible = true
	accept_trade_button.grab_focus()


func _on_accept_trade_pressed() -> void:
	if _closing or not confirm_overlay.visible:
		return
	var total: int = _trade_total()
	if total <= 0:
		_hide_confirmation()
		return

	if tabs.current_tab == 0:
		if total > GameState.gold:
			_hide_confirmation()
			_refresh_trade_total()
			return
		for item_id: StringName in _shop.stock:
			var quantity: int = int(_buy_quantities.get(item_id, 0))
			if quantity > 0:
				Inventory.add_item(item_id, quantity)
		GameState.add_gold(-total)
	else:
		var earned := 0
		for key: Variant in _sell_quantities.keys():
			var item_id := StringName(key)
			var quantity: int = int(_sell_quantities.get(item_id, 0))
			var item := Inventory.load_item_by_id(item_id)
			if quantity <= 0 or item == null or item.is_key_item() or not Inventory.remove_item(item_id, quantity, false):
				continue
			earned += int(floor(float(item.sell_price) * _shop.sell_back_ratio)) * quantity
		GameState.add_gold(earned)

	confirm_overlay.visible = false
	_return_to_field("dialog:shop_thanks")


func _on_buy_tab_pressed() -> void:
	tabs.current_tab = 0
	_hide_confirmation()
	_update_tab_state()
	_refresh_trade_total()


func _on_sell_tab_pressed() -> void:
	tabs.current_tab = 1
	_hide_confirmation()
	_update_tab_state()
	_refresh_trade_total()


func _on_inventory_changed() -> void:
	_refresh_sell()
	_refresh_summary()
	_refresh_trade_total()


func _on_gold_changed(_new_gold: int) -> void:
	_refresh_gold()
	_refresh_buy()
	_refresh_trade_total()


func _update_tab_state() -> void:
	_set_shop_tab_selected(buy_tab_button, tabs.current_tab == 0)
	_set_shop_tab_selected(sell_tab_button, tabs.current_tab == 1)


func _apply_visual_style() -> void:
	bg.color = Color(0.015, 0.022, 0.028, 0.76)
	UI_THEME.style_label(shop_name_label, 30, UI_THEME.GOLD_LIGHT)
	UI_THEME.style_label(gold_label, 18, Color(1.0, 0.78, 0.22, 1.0), false)
	UI_THEME.style_label(greeting_label, 15, Color(0.78, 0.86, 0.90, 1.0), false)
	UI_THEME.style_label(summary_label, 15, UI_THEME.JADE, false)
	UI_THEME.style_label(last_action_label, 14, UI_THEME.MUTED, false)
	UI_THEME.style_label(trade_total_label, 19, Color(1.0, 0.78, 0.22, 1.0), false)
	UI_THEME.style_label(confirm_prompt, 22, Color(0.91, 0.95, 0.96, 1.0), false)
	for header: Label in [$Panel/TableHeader/NameHeader, $Panel/TableHeader/DescriptionHeader, $Panel/TableHeader/QuantityHeader]:
		UI_THEME.style_label(header, 18, UI_THEME.GOLD_LIGHT, false)

	tabs.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_setup_shop_tab(buy_tab_button, "买入")
	_setup_shop_tab(sell_tab_button, "卖出")
	for button in [confirm_trade_button, cancel_trade_button, accept_trade_button]:
		BUTTON_ART.style_button(button, "compact", 17)
		var width: float = 148.0 if button == confirm_trade_button else 190.0
		button.custom_minimum_size = Vector2(width, width / BUTTON_ART.aspect("compact"))

	close_btn.tooltip_text = "关闭"
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_update_tab_state()


func _setup_shop_tab(button: TextureButton, caption: String) -> void:
	button.toggle_mode = true
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = caption
	var label := button.get_node_or_null("Caption") as Label
	if label == null:
		label = Label.new()
		label.name = "Caption"
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 19)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.92))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 2)
		button.add_child(label)
	label.text = caption
	button.mouse_entered.connect(_on_shop_tab_hover.bind(button, true))
	button.mouse_exited.connect(_on_shop_tab_hover.bind(button, false))


func _set_shop_tab_selected(button: TextureButton, selected: bool) -> void:
	var texture := load(TAB_SELECTED_PATH if selected else TAB_INACTIVE_PATH) as Texture2D
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.texture_focused = texture
	button.set_pressed_no_signal(selected)
	button.set_meta("shop_tab_selected", selected)
	_update_shop_tab_caption(button, false)


func _on_shop_tab_hover(button: TextureButton, hovered: bool) -> void:
	_update_shop_tab_caption(button, hovered)


func _update_shop_tab_caption(button: TextureButton, hovered: bool) -> void:
	var label := button.get_node_or_null("Caption") as Label
	if label == null:
		return
	var selected := bool(button.get_meta("shop_tab_selected", false))
	label.add_theme_color_override(
		"font_color",
		UI_THEME.GOLD_LIGHT if hovered else (Color(0.70, 0.94, 0.93, 1.0) if selected else Color(0.64, 0.72, 0.75, 1.0))
	)


func _style_quantity_button(button: Button, caption: String) -> void:
	button.text = caption
	button.custom_minimum_size = Vector2(44, 44.0 / BUTTON_ART.aspect("action"))
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	BUTTON_ART.style_button(button, "action", 21)


func _clear_container(container: Container) -> void:
	for child: Node in container.get_children():
		child.queue_free()


func _hide_confirmation() -> void:
	confirm_overlay.visible = false


func _on_close() -> void:
	_return_to_field()


func _return_to_field(after_trade: String = "") -> void:
	if _closing:
		return
	_closing = true
	if closed.has_connections():
		closed.emit(after_trade)
	else:
		# A shop run directly as the current scene has no field underneath it.
		SceneRouter.resume_current_field(after_trade)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if confirm_overlay.visible:
			_hide_confirmation()
		else:
			_return_to_field()
