extends Node

## 玩家背包 + 装备槽 autoload。
##
## - 物品和装备共用 Item 基类，统一存放在 slots 数组。
## - stackable 物品按 item_id 合并；不可堆叠物品独占一格。
## - 装备穿戴后 *仍占* 一格，由 equipped_weapon/equipped_armor 引用同一 Item。
##   （这样卸下装备无需"还格子"，逻辑更简单。）
##
## 路径约定：所有 Item .tres 必须放在 res://data/items/<id>.tres 或 res://data/equipment/<id>.tres。
## load_item_by_id() 会按顺序查找。

signal slots_changed
signal weapon_changed(item: Item)
signal armor_changed(item: Item)

const MAX_SLOTS := 30
const ITEM_SEARCH_DIRS := [
	"res://data/items/",
	"res://data/equipment/",
]

## 每个元素：{"item": Item, "count": int}
var slots: Array[Dictionary] = []

var equipped_weapon: Equipment = null
var equipped_armor: Equipment = null

## item_id -> 已加载的 Item 缓存
var _item_cache: Dictionary = {}


func _ready() -> void:
	pass


# --- 加载与查询 ---

func load_item_by_id(item_id: StringName) -> Item:
	if _item_cache.has(item_id):
		return _item_cache[item_id]
	for dir in ITEM_SEARCH_DIRS:
		var path := "%s%s.tres" % [dir, String(item_id)]
		if ResourceLoader.exists(path):
			var res: Resource = load(path)
			if res is Item:
				_item_cache[item_id] = res
				return res
	push_warning("[Inventory] item not found: %s" % item_id)
	return null


func count_of(item_id: StringName) -> int:
	var total := 0
	for s in slots:
		var it: Item = s.get("item")
		if it != null and it.item_id == item_id:
			total += int(s.get("count", 0))
	return total


func has_item(item_id: StringName, n: int = 1) -> bool:
	return count_of(item_id) >= n


# --- 增删 ---

func add_item(item_id: StringName, count: int = 1) -> bool:
	if count <= 0: return false
	var item := load_item_by_id(item_id)
	if item == null: return false

	var remaining := count

	if item.stackable:
		for s in slots:
			if remaining <= 0: break
			var it: Item = s.get("item")
			if it != null and it.item_id == item_id:
				var c: int = s.get("count", 0)
				var space: int = item.max_stack - c
				if space > 0:
					var put: int = min(space, remaining)
					s["count"] = c + put
					remaining -= put

	while remaining > 0 and slots.size() < MAX_SLOTS:
		var put_now: int = min(item.max_stack if item.stackable else 1, remaining)
		slots.append({"item": item, "count": put_now})
		remaining -= put_now

	emit_signal("slots_changed")
	EventBus.item_picked_up.emit(item_id, count - remaining)

	if remaining > 0:
		push_warning("[Inventory] inventory full, %d x %s discarded" % [remaining, item_id])
		return false
	return true


func remove_item(item_id: StringName, count: int = 1) -> bool:
	if count <= 0: return false
	if count_of(item_id) < count: return false

	var remaining := count
	for i in range(slots.size() - 1, -1, -1):
		if remaining <= 0: break
		var s: Dictionary = slots[i]
		var it: Item = s.get("item")
		if it != null and it.item_id == item_id:
			var c: int = s.get("count", 0)
			var take: int = min(c, remaining)
			s["count"] = c - take
			remaining -= take
			if s["count"] <= 0:
				slots.remove_at(i)

	emit_signal("slots_changed")
	EventBus.item_dropped.emit(item_id, count)
	return true


# --- 装备 ---

func equip(item_id: StringName) -> bool:
	var item := load_item_by_id(item_id)
	if not (item is Equipment): return false
	var eq: Equipment = item
	match eq.slot:
		Equipment.Slot.WEAPON:
			equipped_weapon = eq
			EventBus.equipment_changed.emit(eq.slot, item_id)
			emit_signal("weapon_changed", eq)
		Equipment.Slot.ARMOR:
			equipped_armor = eq
			EventBus.equipment_changed.emit(eq.slot, item_id)
			emit_signal("armor_changed", eq)
	return true


func unequip(slot: int) -> void:
	match slot:
		Equipment.Slot.WEAPON:
			equipped_weapon = null
			EventBus.equipment_changed.emit(slot, &"")
			emit_signal("weapon_changed", null)
		Equipment.Slot.ARMOR:
			equipped_armor = null
			EventBus.equipment_changed.emit(slot, &"")
			emit_signal("armor_changed", null)


func get_atk_bonus() -> int:
	var b := 0
	if equipped_weapon: b += equipped_weapon.atk_bonus
	if equipped_armor:  b += equipped_armor.atk_bonus
	return b


func get_def_bonus() -> int:
	var b := 0
	if equipped_weapon: b += equipped_weapon.def_bonus
	if equipped_armor:  b += equipped_armor.def_bonus
	return b


func get_speed_bonus() -> int:
	var b := 0
	if equipped_weapon: b += equipped_weapon.speed_bonus
	if equipped_armor:  b += equipped_armor.speed_bonus
	return b


# --- 序列化（给 SaveManager 用）---

func to_dict() -> Dictionary:
	var out_slots: Array = []
	for s in slots:
		var it: Item = s.get("item")
		if it == null: continue
		out_slots.append({
			"item_id": String(it.item_id),
			"count": int(s.get("count", 0)),
		})
	return {
		"slots": out_slots,
		"weapon_id": String(equipped_weapon.item_id) if equipped_weapon else "",
		"armor_id":  String(equipped_armor.item_id)  if equipped_armor  else "",
	}


func from_dict(d: Dictionary) -> void:
	slots.clear()
	equipped_weapon = null
	equipped_armor = null
	var raw_slots: Array = d.get("slots", [])
	for entry in raw_slots:
		var item_id := StringName(entry.get("item_id", ""))
		var count: int = int(entry.get("count", 0))
		if String(item_id) == "" or count <= 0: continue
		add_item(item_id, count)
	var w_id := StringName(d.get("weapon_id", ""))
	if String(w_id) != "":
		equip(w_id)
	var a_id := StringName(d.get("armor_id", ""))
	if String(a_id) != "":
		equip(a_id)
