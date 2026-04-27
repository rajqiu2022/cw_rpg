extends Control

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

@onready var shop_name_label: Label = %ShopName
@onready var greeting_label: Label = %Greeting
@onready var gold_label: Label = %GoldLabel
@onready var buy_list: VBoxContainer = %BuyList
@onready var sell_list: VBoxContainer = %SellList
@onready var close_btn: Button = %CloseBtn

var _shop: ShopDef = null


func _ready() -> void:
	var payload: Dictionary = SceneRouter.get_shop_payload()
	var sid: StringName = payload.get("shop_id", &"")
	_shop = _load_shop(sid)
	if _shop == null:
		push_warning("[Shop] shop not found: %s, return to field" % sid)
		_return_to_field()
		return

	shop_name_label.text = _shop.display_name
	greeting_label.text = _shop.greeting
	close_btn.pressed.connect(_on_close)
	EventBus.gold_changed.connect(_on_gold_changed)
	Inventory.slots_changed.connect(_refresh_sell)

	_refresh_gold()
	_refresh_buy()
	_refresh_sell()


# --- 加载与渲染 ---

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
	# 金额变化时买入按钮的可用状态可能要变
	_refresh_buy()


func _refresh_buy() -> void:
	for c in buy_list.get_children():
		c.queue_free()

	for iid in _shop.stock:
		var item: Item = Inventory.load_item_by_id(iid)
		if item == null:
			continue
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 44)
		row.add_theme_constant_override("separation", 12)

		var name_lbl := Label.new()
		name_lbl.text = "%s   ¥%d" % [item.display_name, item.buy_price]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", 18)
		row.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = item.description
		desc_lbl.modulate = Color(0.75, 0.75, 0.75)
		desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_lbl.add_theme_font_size_override("font_size", 14)
		row.add_child(desc_lbl)

		var btn := Button.new()
		btn.text = "买入"
		btn.disabled = (GameState.gold < item.buy_price)
		btn.custom_minimum_size = Vector2(80, 40)
		var captured_id: StringName = iid
		btn.pressed.connect(func(): _on_buy(captured_id))
		row.add_child(btn)

		buy_list.add_child(row)


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
		# 即使 sell_price=0 也允许卖（拿 0 金）—— UI 标灰提示就行
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 44)
		row.add_theme_constant_override("separation", 12)

		var name_lbl := Label.new()
		name_lbl.text = "%s ×%d   卖 ¥%d/件" % [it.display_name, cnt, sell_each]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", 18)
		row.add_child(name_lbl)

		var btn := Button.new()
		btn.text = "卖出"
		btn.custom_minimum_size = Vector2(80, 40)
		var captured_iid: StringName = it.item_id
		var captured_price: int = sell_each
		btn.pressed.connect(func(): _on_sell(captured_iid, captured_price))
		row.add_child(btn)

		sell_list.add_child(row)

	if not any_sellable:
		var lab := Label.new()
		lab.text = "（背包空空如也）"
		lab.modulate = Color(0.7, 0.7, 0.7)
		lab.add_theme_font_size_override("font_size", 16)
		sell_list.add_child(lab)


# --- 按钮回调 ---

func _on_buy(item_id: StringName) -> void:
	var item: Item = Inventory.load_item_by_id(item_id)
	if item == null:
		return
	if GameState.gold < item.buy_price:
		return
	GameState.add_gold(-item.buy_price)
	Inventory.add_item(item_id, 1)
	print("[Shop] bought: %s @ ¥%d (left ¥%d)" % [item_id, item.buy_price, GameState.gold])


func _on_sell(item_id: StringName, price_each: int) -> void:
	if not Inventory.has_item(item_id, 1):
		return
	# 卖装备时若正穿着，先卸下，避免 stat 计算引用已售物品
	if Inventory.equipped_weapon != null and Inventory.equipped_weapon.item_id == item_id:
		Inventory.unequip(Equipment.Slot.WEAPON)
	if Inventory.equipped_armor != null and Inventory.equipped_armor.item_id == item_id:
		Inventory.unequip(Equipment.Slot.ARMOR)
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
	SceneRouter.go_field(sid)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_return_to_field()
