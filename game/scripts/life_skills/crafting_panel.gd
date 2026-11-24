extends Control
## Crafting modal for medicine and smithing.
signal closed
const RECIPES=preload("res://scripts/life_skills/recipes.gd")
const SERVICE=preload("res://scripts/life_skills/crafting_service.gd")
const THEME=preload("res://scripts/ui/wuxia_theme.gd")
const ART := preload("res://scripts/ui/lacquer_ui.gd")
var station: String="medicine"
var tempering_only := false
var stock: Array=[]
var rows: VBoxContainer
var status: Label
var gold_label: Label
var quantities: Dictionary={}
var _confirm: FormalConfirmDialog
var _pending: String=""
var _pending_rank := 0
var station_valid: Callable

static func style_button(button: Button) -> void:
	ART.style_button(button, ART.Shape.CELL if button.text in ["−", "＋"] else ART.Shape.ACTION)
	button.add_theme_font_size_override("font_size",20)
	button.custom_minimum_size=Vector2(48,42)
	button.focus_mode=Control.FOCUS_NONE

func _ready() -> void:
	name = "LacquerCraftingPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim:=ColorRect.new();dim.color=ART.INK_DIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(dim)
	var panel:=Control.new();panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position=Vector2(-600,-390);panel.size=Vector2(1200,780);add_child(panel)
	var art := TextureRect.new()
	panel.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ART.use_frame(art)
	ART.section(panel, Rect2(70, 122, 1060, 605))
	ART.title(panel, ART.Heading.LIFE, Rect2(410, 22, 380, 92))
	var content:=VBoxContainer.new();content.position=Vector2(110,148);content.size=Vector2(980,540)
	content.add_theme_constant_override("separation",14);panel.add_child(content)
	var header:=HBoxContainer.new();content.add_child(header)
	var title:=Label.new();title.text="随身药方 · 战斗用药" if station=="medicine" else "铁匠铺 · 武器升级"
	THEME.style_label(title,30,THEME.GOLD_LIGHT);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(title)
	var close:=Button.new();close.text="返回";style_button(close);close.pressed.connect(close_panel);header.add_child(close)
	var hint:=Label.new();hint.text="优先配制临战增益 · 野外采药 · 战斗中打开背包使用" if station=="medicine" else "+1～+3，每级攻击 +2 · +3 升一品（橙品不变），随机获得 1～2 条效果"
	THEME.style_label(hint,18);content.add_child(hint)
	gold_label=Label.new();THEME.style_label(gold_label,19);content.add_child(gold_label)
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;content.add_child(scroll)
	rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows.add_theme_constant_override("separation",14);scroll.add_child(rows)
	status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size=Vector2(0,48);THEME.style_label(status,20,THEME.JADE);content.add_child(status)
	_confirm=load("res://scenes/ui/formal_confirm_dialog.tscn").instantiate() as FormalConfirmDialog
	add_child(_confirm);_confirm.confirmed.connect(_commit);_confirm.cancelled.connect(func()->void:_pending="")
	refresh()

func refresh() -> void:
	if not is_instance_valid(rows):return
	for child: Node in rows.get_children():rows.remove_child(child);child.queue_free()
	gold_label.text="现有：药草捆 %d · 铁矿石 %d · 金 %d · 背包 %d/%d"%[Inventory.count_of(&"herb_bundle"),Inventory.count_of(&"iron_ore"),GameState.gold,Inventory.slots.size(),Inventory.MAX_SLOTS]
	if station == "blacksmith":
		_add_tempering_rows()
		if tempering_only: return
	else:
		_add_crafting_heading("临战药方 · 店铺不出售")
	for recipe: Dictionary in RECIPES.for_station(station,stock):
		var id: String=String(recipe.id);var quantity: int=int(quantities.get(id,1))
		if station == "medicine" and id == "healing_pill_minor":
			_add_crafting_heading("常备药方 · 恢复与解毒")
		var item: Item=Inventory.load_item_by_id(StringName(recipe.output))
		if item==null:continue
		var box:=VBoxContainer.new();box.add_theme_constant_override("separation",4);rows.add_child(box)
		var line:=HBoxContainer.new();line.add_theme_constant_override("separation",12);box.add_child(line)
		var name_label:=Label.new();name_label.text=item.display_name;name_label.custom_minimum_size=Vector2(190,44)
		THEME.style_label(name_label,24);line.add_child(name_label)
		var cost:=Label.new();var costs: Array[String]=[]
		for material: String in recipe.ingredients:
			var resource: Item=Inventory.load_item_by_id(StringName(material))
			costs.append("%s %d/%d"%[resource.display_name,Inventory.count_of(StringName(material)),int(recipe.ingredients[material])*quantity])
		costs.append("工钱 %d金"%(int(recipe.gold)*quantity))
		cost.text=" · ".join(costs);cost.size_flags_horizontal=Control.SIZE_EXPAND_FILL;THEME.style_label(cost,18);line.add_child(cost)
		var minus:=Button.new();minus.text="−";style_button(minus);minus.disabled=quantity<=1
		minus.pressed.connect(_quantity.bind(id,-1));line.add_child(minus)
		var count:=Label.new();count.text=str(quantity);count.custom_minimum_size.x=30;count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;THEME.style_label(count,22);line.add_child(count)
		var plus:=Button.new();plus.text="＋";style_button(plus);plus.disabled=quantity>=10
		plus.pressed.connect(_quantity.bind(id,1));line.add_child(plus)
		var preview: Dictionary=SERVICE.preview(id,quantity,station,stock)
		var button:=Button.new();button.text="制药" if station=="medicine" else "制造"
		style_button(button);button.disabled=not bool(preview.ok);button.tooltip_text=String(preview.message)
		button.pressed.connect(_ask.bind(id));line.add_child(button)
		var detail:=Label.new();detail.text=item.description+"  "+("" if preview.ok else String(preview.message))
		detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;THEME.style_label(detail,17,THEME.MUTED);box.add_child(detail)

func _quantity(id: String, delta: int) -> void:
	quantities[id]=clampi(int(quantities.get(id,1))+delta,1,10);refresh()

func _ask(id: String) -> void:
	if not station_valid.is_valid() or not station_valid.call():close_panel();return
	var recipe: Dictionary=RECIPES.find(id);var quantity: int=int(quantities.get(id,1))
	var item: Item=Inventory.load_item_by_id(StringName(recipe.output))
	_pending=id
	_pending_rank=0
	_confirm.show_confirm("确认制药" if station=="medicine" else "确认制造","制作 [b]%s ×%d[/b]\n材料按面板数量扣除，工钱 %d金。\n成功后成品放入背包，不自动穿戴。"%[item.display_name,quantity,int(recipe.gold)*quantity],"确认制作","再想想")

func _commit() -> void:
	if _pending.is_empty():return
	if not station_valid.is_valid() or not station_valid.call():close_panel();return
	var id: String=_pending;_pending=""
	if _pending_rank > 0:
		var rank := _pending_rank
		_pending_rank = 0
		var temper_result := SERVICE.temper(id, station, rank)
		status.text = String(temper_result.message)
		refresh()
		return
	var result: Dictionary=SERVICE.craft(id,int(quantities.get(id,1)),station,stock)
	refresh()
	var item: Item=Inventory.load_item_by_id(StringName(result.get("output", "")))
	status.text="已制成 %s ×%d，已放入背包。"%[item.display_name,int(result.output_count)] if result.ok else String(result.message)

func _add_tempering_rows() -> void:
	var number := 0
	for entry: Dictionary in Inventory.slots:
		var weapon := entry.get("item") as Equipment
		if weapon == null or weapon.slot != Equipment.Slot.WEAPON:
			continue
		number += 1
		var id := String(entry.instance_id)
		var preview := SERVICE.preview_temper(id, station)
		var line := HBoxContainer.new()
		rows.add_child(line)
		var label := Label.new()
		var owner := Inventory.get_instance_equipped_character_id(id)
		var member := GameState.get_party_member(owner) if owner != &"" else null
		var location := "背包" if member == null else member.display_name + "已装备"
		var quality := ["白", "绿", "蓝", "紫", "橙"][int(weapon.quality)] as String
		var cost := "铁矿 %d · 工钱 %d 金" % [preview.ore, preview.gold] if preview.has("ore") else "已达 +3"
		label.text = "%d. %s 〔%s品 · %s〕   %s" % [number, weapon.display_name, quality, location, cost]
		label.tooltip_text = weapon.description
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		THEME.style_label(label, 21)
		line.add_child(label)
		var button := Button.new()
		button.text = "升至 +%d" % preview.rank if preview.has("rank") else "已满级"
		style_button(button)
		button.disabled = not preview.ok
		button.tooltip_text = String(preview.message)
		button.pressed.connect(_ask_temper.bind(id))
		line.add_child(button)
	if not tempering_only:
		_add_crafting_heading("基础铁器配方" if number > 0 else "背包没有可升级的武器 · 下方可制造基础铁器")
	elif number == 0:
		_add_crafting_heading("背包没有可升级的武器。")

func _add_crafting_heading(text: String) -> void:
	var heading := Label.new()
	heading.text = text
	THEME.style_label(heading, 20, THEME.JADE)
	rows.add_child(heading)

func _ask_temper(id: String) -> void:
	if not station_valid.is_valid() or not station_valid.call():
		close_panel()
		return
	var preview := SERVICE.preview_temper(id, station)
	var weapon := Inventory.find_slot_by_instance(id).get("item") as Equipment
	if not preview.ok or weapon == null:
		status.text = String(preview.message)
		return
	_pending = id
	_pending_rank = int(preview.rank)
	var extra := ""
	if _pending_rank == 3:
		extra = "\n" + ("橙品不再升品；" if weapon.quality == Item.Quality.LEGENDARY else "品质提升一级；") + "随机生成 1～2 条不同效果，不可重掷。"
	_confirm.show_confirm("确认升级武器", "%s · 升至 +%d（攻击 +2）\n消耗铁矿 %d，工钱 %d 金。%s" % [weapon.display_name, _pending_rank, preview.ore, preview.gold, extra], "确认升级", "再想想")

func close_panel() -> void:
	_pending="";closed.emit();queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _confirm.is_open():_confirm.close_dialog();_pending=""
		else:close_panel()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_I,KEY_E,KEY_C,KEY_K,KEY_J,KEY_M,KEY_TAB]:
		get_viewport().set_input_as_handled()
