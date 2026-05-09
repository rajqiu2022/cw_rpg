extends Control

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const ATTR_ICON_ATLAS_PATH := "res://art/ui/cold_wuxia/v1/ui_cold_wuxia_attribute_icons_v1.png"
const ATTR_ICON_REGIONS := {
	"筋骨": Rect2(37, 55, 203, 204),
	"机敏": Rect2(290, 55, 201, 204),
	"内劲": Rect2(544, 55, 200, 204),
	"悟性": Rect2(794, 55, 195, 203),
	"生命": Rect2(1033, 55, 197, 204),
	"内力": Rect2(1281, 55, 196, 204),
	"防御": Rect2(38, 293, 202, 207),
}

## 商店 UI（M4）。
##
## 进入：SceneRouter.go_shop(shop_id) 通过 `_shop_payload.shop_id` 携带商店 id。
## 渲染：从 `res://data/shops/<id>.tres` 加载 ShopDef，按 stock 列出可买物品；
##       按 Inventory.slots 列出可卖物品（KEY_ITEM 不允许卖）。
##
## 价格规则：
##   - 玩家买入 = item.buy_price
##   - 玩家卖出实收 = floor(item.sell_price × shop.sell_back_ratio)
##
## 关闭：返回 SceneRouter._current_field_id（进 shop 前不会被覆写）。

@onready var bg: ColorRect = $Bg
@onready var panel: PanelContainer = $Panel
@onready var tabs: TabContainer = $Panel/Body/Tabs
@onready var shop_name_label: Label = %ShopName
@onready var greeting_label: Label = %Greeting
@onready var gold_label: Label = %GoldLabel
@onready var buy_list: VBoxContainer = %BuyList
@onready var sell_list: VBoxContainer = %SellList
@onready var close_btn: Button = %CloseBtn

var _shop: ShopDef = null
var _attr_icon_atlas: Texture2D = null


func _ready() -> void:
	var payload: Dictionary = SceneRouter.get_shop_payload()
	var sid: StringName = payload.get("shop_id", &"")
	_shop = _load_shop(sid)
	if _shop == null:
		push_warning("[Shop] shop not found: %s, return to field" % sid)
		_return_to_field()
		return

	_build_formal_layout()
	shop_name_label.text = _shop.display_name
	greeting_label.text = _shop.greeting
	close_btn.pressed.connect(_on_close)
	EventBus.gold_changed.connect(_on_gold_changed)
	Inventory.slots_changed.connect(_refresh_sell)
	if ResourceLoader.exists(ATTR_ICON_ATLAS_PATH):
		_attr_icon_atlas = load(ATTR_ICON_ATLAS_PATH)
	_apply_visual_style()

	_refresh_gold()
	_refresh_buy()
	_refresh_sell()


# --- 加载与渲染 ---

func _build_formal_layout() -> void:
	var body: VBoxContainer = get_node_or_null("Panel/Body") as VBoxContainer
	if body == null:
		return
	if body.get_node_or_null("ShopInfoBar") == null:
		var info_bar := HBoxContainer.new()
		info_bar.name = "ShopInfoBar"
		info_bar.add_theme_constant_override("separation", 12)
		body.add_child(info_bar)
		body.move_child(info_bar, 2)
		_summary_label = Label.new()
		_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_summary_label.text = "库存 0 · 可回收 0"
		UI_THEME.style_label(_summary_label, 16, UI_THEME.JADE, false)
		info_bar.add_child(_summary_label)
		_last_action_label = Label.new()
		_last_action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_last_action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_last_action_label.text = "请择物交易"
		UI_THEME.style_label(_last_action_label, 16, UI_THEME.MUTED, false)
		info_bar.add_child(_last_action_label)
	else:
		var existing_bar: HBoxContainer = body.get_node_or_null("ShopInfoBar") as HBoxContainer
		if existing_bar != null and existing_bar.get_child_count() >= 2:
			_summary_label = existing_bar.get_child(0) as Label
			_last_action_label = existing_bar.get_child(1) as Label


func _load_shop(sid: StringName) -> ShopDef:
	if String(sid) == "":
		return null
	var path := "res://data/shops/%s.tres" % String(sid)
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	return res if res is ShopDef else null


func _refresh_gold() -> void:
	gold_label.text = "金 %d" % GameState.gold
	_refresh_summary()
	# 金额变化时买入按钮的可用状态可能要变
	_refresh_buy()


func _refresh_buy() -> void:
	for c in buy_list.get_children():
		c.queue_free()

	for iid in _shop.stock:
		var item: Item = Inventory.load_item_by_id(iid)
		if item == null:
			continue
		var row_panel := PanelContainer.new()
		row_panel.custom_minimum_size = Vector2(0, 62)
		row_panel.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.040, 0.060, 0.078, 0.86), Color(0.20, 0.32, 0.40, 0.84), 10, 1))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row_panel.add_child(row)

		var icon := _make_item_icon(_icon_key_for_item(item), 34)
		if icon != null:
			row.add_child(icon)

		var name_lbl := Label.new()
		name_lbl.text = "%s   ¥%d" % [item.display_name, item.buy_price]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UI_THEME.style_label(name_lbl, 18, UI_THEME.GOLD_LIGHT, false)
		row.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = item.description
		desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI_THEME.style_label(desc_lbl, 14, Color(0.68, 0.78, 0.82, 1.0), false)
		row.add_child(desc_lbl)

		var btn := Button.new()
		btn.text = "买入"
		btn.disabled = (GameState.gold < item.buy_price)
		btn.custom_minimum_size = Vector2(92, 42)
		UI_THEME.style_button(btn, 16, UI_THEME.JADE)
		var captured_id: StringName = iid
		btn.pressed.connect(func(): _on_buy(captured_id))
		row.add_child(btn)

		buy_list.add_child(row_panel)


func _refresh_sell() -> void:
	for c in sell_list.get_children():
		c.queue_free()

	var any_sellable := false
	# 拷贝 slots，避免按钮回调修改 slots 时迭代崩
	var snapshot: Array[Dictionary] = []
	for s in Inventory.slots:
		snapshot.append(s)

	for s in snapshot:
		var it: Item = s.get("item")
		var cnt: int = int(s.get("count", 0))
		if it == null or cnt <= 0 or it.is_key_item():
			continue
		any_sellable = true

		var sell_each: int = int(floor(float(it.sell_price) * _shop.sell_back_ratio))
		var row_panel := PanelContainer.new()
		row_panel.custom_minimum_size = Vector2(0, 78)
		row_panel.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.050, 0.072, 0.084, 0.90), Color(0.30, 0.42, 0.50, 0.88), 10, 1))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row_panel.add_child(row)

		var icon := _make_item_icon(_icon_key_for_item(it), 38)
		if icon != null:
			row.add_child(icon)

		var name_lbl := Label.new()
		name_lbl.text = "%s ×%d   卖 ¥%d/件" % [it.display_name, cnt, sell_each]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UI_THEME.style_label(name_lbl, 18, UI_THEME.GOLD_LIGHT, false)
		row.add_child(name_lbl)

		var btn := Button.new()
		btn.text = "卖出"
		btn.custom_minimum_size = Vector2(92, 42)
		UI_THEME.style_button(btn, 16, UI_THEME.BLUE_STEEL)
		var captured_iid: StringName = it.item_id
		var captured_price: int = sell_each
		btn.pressed.connect(func(): _on_sell(captured_iid, captured_price))
		row.add_child(btn)

		sell_list.add_child(row_panel)

	if not any_sellable:
		var lab := Label.new()
		lab.text = "（背包空空如也）"
		UI_THEME.style_label(lab, 16, UI_THEME.MUTED, false)
		sell_list.add_child(lab)


func _apply_visual_style() -> void:
	if bg != null:
		bg.color = Color(0.020, 0.026, 0.036, 0.94)
	if panel != null:
		panel.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.040, 0.060, 0.075, 0.96), UI_THEME.GOLD, 18, 3))
	UI_THEME.style_label(shop_name_label, 30, UI_THEME.GOLD_LIGHT)
	UI_THEME.style_label(gold_label, 24, UI_THEME.GOLD, false)
	UI_THEME.style_label(greeting_label, 17, Color(0.78, 0.86, 0.90, 1.0), false)
	if tabs != null:
		tabs.add_theme_font_size_override("font_size", 20)
		tabs.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.026, 0.038, 0.050, 0.82), Color(0.18, 0.30, 0.38, 0.86), 10, 1))
	UI_THEME.style_button(close_btn, 18, UI_THEME.CRIMSON)


func _refresh_summary() -> void:
	if _summary_label == null or _shop == null:
		return
	var sellable_count := 0
	for entry in Inventory.slots:
		var it: Item = entry.get("item")
		var count: int = int(entry.get("count", 0))
		if it != null and count > 0 and not it.is_key_item():
			sellable_count += count
	_summary_label.text = "库存 %d · 可回收 %d · 回收 %.0f%%" % [_shop.stock.size(), sellable_count, _shop.sell_back_ratio * 100.0]


func _icon_key_for_item(item: Item) -> String:
	if item is Equipment:
		return "防御"
	if item.is_key_item():
		return "悟性"
	if item.category == Item.Category.MATERIAL:
		return "内力"
	if item.category == Item.Category.CONSUMABLE:
		if item.heal_hp > 0:
			return "生命"
		if item.heal_mp > 0:
			return "内劲"
		return "机敏"
	return "筋骨"


func _make_item_icon(icon_key: String, icon_size: int = 34) -> TextureRect:
	if _attr_icon_atlas == null:
		return null
	var region: Rect2 = ATTR_ICON_REGIONS.get(icon_key, Rect2())
	if region.size.x <= 0 or region.size.y <= 0:
		return null
	var tex := AtlasTexture.new()
	tex.atlas = _attr_icon_atlas
	tex.region = region
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = tex
	icon.tooltip_text = icon_key
	return icon


# --- 按钮回调 ---

func _on_buy(item_id: StringName) -> void:
	var item: Item = Inventory.load_item_by_id(item_id)
	if item == null:
		return
	if GameState.gold < item.buy_price:
		return
	GameState.add_gold(-item.buy_price)
	Inventory.add_item(item_id, 1)
	if _last_action_label != null:
		_last_action_label.text = "买入：%s  -%d 金" % [item.display_name, item.buy_price]
	_refresh_summary()
	print("[Shop] bought: %s @ ¥%d (left ¥%d)" % [item_id, item.buy_price, GameState.gold])


func _on_sell(item_id: StringName, price_each: int) -> void:
	if not Inventory.has_item(item_id, 1):
		return
	# 卖装备时若正穿着，先卸下，避免 stat 计算引用已售物品。
	for slot in Inventory.all_slots():
		if Inventory.get_equipped_id(slot) == item_id:
			Inventory.unequip(slot)
	Inventory.remove_item(item_id, 1)
	GameState.add_gold(price_each)
	print("[Shop] sold: %s @ +¥%d (gold ¥%d)" % [item_id, price_each, GameState.gold])


func _on_close() -> void:
	_return_to_field()


func _on_gold_changed(_n: int) -> void:
	_refresh_gold()


# --- helpers ---

func _return_to_field() -> void:
	var sid: StringName = SceneRouter.get_current_field_id()
	if String(sid) == "":
		sid = &"ch1_s1_road"
	SceneRouter.go_field_smart(sid)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_return_to_field()
