class_name EquipmentPanel
extends Control
## 装备面板 — 底图含标签，只叠数据

signal closed

@onready var _close_btn: TextureButton = $Container/BtnClose
@onready var _panel_bg: TextureRect = $Container/PanelBg

const SLOT_POSITIONS := [
	Vector2(130, 290),  # 武器
	Vector2(170, 70),   # 头部
	Vector2(170, 180),  # 衣甲
	Vector2(90, 350),   # 手套
	Vector2(170, 470),  # 鞋子
	Vector2(240, 110),  # 饰品
]
const SLOT_SIZE := Vector2(80, 70)

@onready var _attr_labels: Array[Label] = [
	$Container/AttrGroup/Attr_筋骨, $Container/AttrGroup/Attr_机敏, $Container/AttrGroup/Attr_内劲, $Container/AttrGroup/Attr_悟性,
	$Container/AttrGroup/Attr_生命, $Container/AttrGroup/Attr_内力, $Container/AttrGroup/Attr_攻击, $Container/AttrGroup/Attr_防御, $Container/AttrGroup/Attr_速度,
]
var _slot_labels: Array[Label] = []


func open() -> void:
	visible = true
	_refresh()


func _on_close() -> void:
	close()
	emit_signal("closed")

func close() -> void:
	visible = false


func _ready() -> void:
	_close_btn.pressed.connect(_on_close)
	_close_btn.texture_normal = load("res://art/ui/inventory/buttons/btn_x_normal.png")
	_close_btn.texture_hover = load("res://art/ui/inventory/buttons/btn_x_hover.png")
	_close_btn.texture_pressed = load("res://art/ui/inventory/buttons/btn_x_pressed.png")
	_create_slot_overlays()
	Inventory.slots_changed.connect(_refresh)
	GameState.player_changed.connect(_refresh)


func _create_slot_overlays() -> void:
	for i in 6:
		var lbl := Label.new()
		lbl.position = SLOT_POSITIONS[i]
		lbl.size = SLOT_SIZE
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.clip_text = true
		add_child(lbl)
		_slot_labels.append(lbl)




func _refresh() -> void:
	# Equipment slot labels
	for i in 6:
		var eq: Equipment = Inventory.get_equipped(i)
		if i < _slot_labels.size() and _slot_labels[i] != null:
			_slot_labels[i].text = eq.display_name if eq else ""
	
	# Attribute values
	var p: CharacterStats = GameState.player
	if p == null: return
	
	var texts := [
		str(p.strength + Inventory.get_strength_bonus()),
		str(p.agility + Inventory.get_agility_bonus()),
		str(p.inner_power + Inventory.get_inner_power_bonus()),
		str(p.insight + Inventory.get_insight_bonus()),
		"%d/%d" % [p.hp, p.max_hp + Inventory.get_vitality_bonus() * 8],
		"%d/%d" % [p.mp, p.max_mp + Inventory.get_inner_pool_bonus() * 6],
		str(p.attack + Inventory.get_atk_bonus()),
		str(p.defense + Inventory.get_def_bonus()),
		str(p.speed + Inventory.get_speed_bonus()),
	]
	for i in _attr_labels.size():
		if i < texts.size() and i < _attr_labels.size() and _attr_labels[i] != null:
			_attr_labels[i].text = texts[i]
