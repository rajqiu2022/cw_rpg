extends Node

## 玩家背包 + 装备槽 autoload。
##
## - 物品和装备共用 Item 基类，统一存放在 slots 数组。
## - stackable 物品按 item_id 合并；不可堆叠物品独占一格。
## - 装备穿戴后 *仍占* 一格，由 equipped 字典引用同一 Item。
## - equipped_weapon/equipped_armor 仅保留给旧战斗代码兼容。
##   （这样卸下装备无需"还格子"，逻辑更简单。）
##
## 路径约定：所有 Item .tres 必须放在 res://data/items/<id>.tres 或 res://data/equipment/<id>.tres。
## load_item_by_id() 会按顺序查找。

signal slots_changed
signal equipped_changed(slot: int, item: Equipment)
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
var equipped: Dictionary = {}

## item_id -> 已加载的 Item 缓存
var _item_cache: Dictionary = {}


func _ready() -> void:
	pass


func reset_for_new_game() -> void:
	from_dict({})
	add_item(&"healing_pill_minor", 2)


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


func swap_slots(from_idx: int, to_idx: int) -> bool:
	if from_idx < 0 or from_idx >= slots.size(): return false
	if to_idx < 0 or to_idx >= slots.size(): return false
	if from_idx == to_idx: return false
	var tmp: Dictionary = slots[from_idx]
	slots[from_idx] = slots[to_idx]
	slots[to_idx] = tmp
	emit_signal("slots_changed")
	return true


# --- 使用 ---

func use_item(item_id: StringName, in_battle: bool = false) -> bool:
	if not has_item(item_id, 1):
		return false
	var item := load_item_by_id(item_id)
	if item == null or not item.can_use(in_battle):
		return false
	var player := GameState.player
	if player == null:
		return false

	# 状态解除物品（战斗中）
	var sid := String(item_id)
	match sid:
		"antidote_pill":
			EventBus.status_cured.emit(&"poison")
			_consume_item(item_id, 1)
			EventBus.item_used.emit(item_id)
			return true
		"anti_weak_powder":
			EventBus.status_cured.emit(&"weak")
			_consume_item(item_id, 1)
			EventBus.item_used.emit(item_id)
			return true
		"clarity_dew":
			EventBus.status_cured.emit(&"all")
			_consume_item(item_id, 1)
			EventBus.item_used.emit(item_id)
			return true

	var new_hp: int = min(player.max_hp, player.hp + item.heal_hp)
	var new_mp: int = min(player.max_mp, player.mp + item.heal_mp)
	var changed := new_hp != player.hp or new_mp != player.mp
	if not changed:
		# 回春散同时解中毒
		if sid == "thaw_warm_pill":
			EventBus.status_cured.emit(&"poison")
			_consume_item(item_id, 1)
			EventBus.item_used.emit(item_id)
			return true
		return false

	player.hp = new_hp
	player.mp = new_mp
	_consume_item(item_id, 1)
	EventBus.item_used.emit(item_id)
	GameState.emit_signal("player_changed")
	return true


func _consume_item(item_id: StringName, count: int) -> bool:
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
	return true


# --- 装备 ---

func equip(item_id: StringName) -> bool:
	if not has_item(item_id, 1):
		return false
	var item := load_item_by_id(item_id)
	if not (item is Equipment): return false
	var eq: Equipment = item
	equipped[eq.slot] = eq
	_sync_legacy_equipped(eq.slot)
	EventBus.equipment_changed.emit(eq.slot, item_id)
	emit_signal("equipped_changed", eq.slot, eq)
	emit_signal("slots_changed")
	return true


func unequip(slot: int) -> void:
	equipped.erase(slot)
	_sync_legacy_equipped(slot)
	EventBus.equipment_changed.emit(slot, &"")
	emit_signal("equipped_changed", slot, null)
	emit_signal("slots_changed")


func get_equipped(slot: int) -> Equipment:
	return equipped.get(slot, null)


func get_equipped_id(slot: int) -> StringName:
	var eq := get_equipped(slot)
	return eq.item_id if eq != null else &""


func slot_key(slot: int) -> String:
	match slot:
		Equipment.Slot.WEAPON: return "weapon"
		Equipment.Slot.HEAD: return "head"
		Equipment.Slot.ARMOR: return "armor"
		Equipment.Slot.HANDS: return "hands"
		Equipment.Slot.SHOES: return "shoes"
		Equipment.Slot.ACCESSORY: return "accessory"
		_: return "unknown"


func slot_display_name(slot: int) -> String:
	match slot:
		Equipment.Slot.WEAPON: return "武器"
		Equipment.Slot.HEAD: return "头盔"
		Equipment.Slot.ARMOR: return "护甲"
		Equipment.Slot.HANDS: return "护腕"
		Equipment.Slot.SHOES: return "鞋子"
		Equipment.Slot.ACCESSORY: return "饰品"
		_: return "未知"


func all_slots() -> Array[int]:
	return [
		Equipment.Slot.WEAPON,
		Equipment.Slot.HEAD,
		Equipment.Slot.ARMOR,
		Equipment.Slot.HANDS,
		Equipment.Slot.SHOES,
		Equipment.Slot.ACCESSORY,
	]


func _sync_legacy_equipped(slot: int) -> void:
	if slot == Equipment.Slot.WEAPON:
		equipped_weapon = equipped.get(slot, null)
		emit_signal("weapon_changed", equipped_weapon)
	elif slot == Equipment.Slot.ARMOR:
		equipped_armor = equipped.get(slot, null)
		emit_signal("armor_changed", equipped_armor)


func _sum_equipped_bonus(method_name: StringName) -> int:
	var total := 0
	for eq in equipped.values():
		var e := eq as Equipment
		if e != null and e.has_method(method_name):
			total += int(e.call(method_name))
	return total


func get_atk_bonus() -> int:
	return _sum_equipped_bonus(&"get_attack_bonus")


func get_def_bonus() -> int:
	return _sum_equipped_bonus(&"get_defense_bonus")


func get_speed_bonus() -> int:
	return _sum_equipped_bonus(&"get_speed_bonus")


func get_strength_bonus() -> int:
	return _sum_equipped_bonus(&"get_strength_bonus")


func get_agility_bonus() -> int:
	return _sum_equipped_bonus(&"get_agility_bonus")


func get_inner_power_bonus() -> int:
	return _sum_equipped_bonus(&"get_inner_power_bonus")


func get_insight_bonus() -> int:
	return _sum_equipped_bonus(&"get_insight_bonus")


func get_vitality_bonus() -> int:
	return _sum_equipped_bonus(&"get_vitality_bonus")


func get_inner_pool_bonus() -> int:
	return _sum_equipped_bonus(&"get_inner_pool_bonus")


func get_guard_bonus() -> int:
	return _sum_equipped_bonus(&"get_guard_bonus")


## 查询已装备武器的技能加成。
## 返回 {power: int, crit_mult: float}。
## "all" 门派武器对所有门派生效，但优先级低于专属门派加成（取较大值）。
func get_equipped_skill_bonus(school: String) -> Dictionary:
	var result := {"power": 0, "crit_mult": 0.0}
	if school == "" or school == "generic":
		return result

	for eq in equipped.values():
		var e := eq as Equipment
		if e == null:
			continue
		if e.skill_bonus_school == "":
			continue

		# 同门派加成直接累加
		if e.skill_bonus_school == school:
			result["power"] += e.skill_bonus_power
			result["crit_mult"] += e.skill_bonus_crit_mult

		# "all" 通用加成，取最大值
		elif e.skill_bonus_school == "all":
			result["power"] = max(result["power"], e.skill_bonus_power)
			result["crit_mult"] = max(result["crit_mult"], e.skill_bonus_crit_mult)

	return result


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
	var equipped_out := {}
	for slot in all_slots():
		var eq := get_equipped(slot)
		if eq != null:
			equipped_out[slot_key(slot)] = String(eq.item_id)
	return {
		"slots": out_slots,
		"equipped": equipped_out,
		"weapon_id": String(equipped_weapon.item_id) if equipped_weapon else "",
		"armor_id":  String(equipped_armor.item_id)  if equipped_armor  else "",
	}


func from_dict(d: Dictionary) -> void:
	slots.clear()
	equipped.clear()
	equipped_weapon = null
	equipped_armor = null
	var raw_slots: Array = d.get("slots", [])
	for entry in raw_slots:
		var item_id: StringName = StringName(entry.get("item_id", ""))
		var count: int = int(entry.get("count", 0))
		if String(item_id) == "" or count <= 0: continue
		add_item(item_id, count)
	var raw_equipped: Dictionary = d.get("equipped", {})
	if raw_equipped.is_empty():
		raw_equipped = {
			"weapon": d.get("weapon_id", ""),
			"armor": d.get("armor_id", ""),
		}
	@warning_ignore("untyped_declaration")
	for key in raw_equipped:
		var item_id: StringName = StringName(raw_equipped[key])
		if String(item_id) != "":
			equip(item_id)
	emit_signal("slots_changed")
