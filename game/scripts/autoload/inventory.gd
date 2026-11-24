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

## 每个元素：{"item": Item, "count": int, "instance_id": String}
## 不可堆叠物品使用独立 instance_id；同种装备也不会共享穿戴状态。
var slots: Array[Dictionary] = []

var equipped_weapon: Equipment = null
var equipped_armor: Equipment = null
var equipped: Dictionary = {}
var equipped_instance_ids: Dictionary = {}
var equipped_by_character: Dictionary = {}
var equipped_instance_ids_by_character: Dictionary = {}
var _next_instance_serial: int = 1

## item_id -> 已加载的 Item 缓存
var _item_cache: Dictionary = {}


func _ready() -> void:
	pass


func reset_for_new_game() -> void:
	from_dict({})
	add_item(&"healing_pill_minor", 2)
	add_item(&"inner_breath_pill", 2)


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


func count_of(item_id: StringName, include_tempered: bool = true) -> int:
	var total := 0
	for s in slots:
		var it: Item = s.get("item")
		if it != null and it.item_id == item_id and (include_tempered or not it is Equipment or it.forge_rank == 0):
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
		var instance_id: String = "" if item.stackable else _new_instance_id(item_id)
		slots.append({"item": item, "count": put_now, "instance_id": instance_id})
		remaining -= put_now

	emit_signal("slots_changed")
	EventBus.item_picked_up.emit(item_id, count - remaining)

	if remaining > 0:
		push_warning("[Inventory] inventory full, %d x %s discarded" % [remaining, item_id])
		return false
	return true


func remove_item(item_id: StringName, count: int = 1, include_tempered: bool = true) -> bool:
	if count <= 0: return false
	if count_of(item_id, include_tempered) < count: return false

	var remaining: int = count
	# 优先移除未装备的副本，出售多余同款装备时不会把身上的那件脱掉。
	for remove_equipped: bool in [false, true]:
		for i: int in range(slots.size() - 1, -1, -1):
			if remaining <= 0:
				break
			var s: Dictionary = slots[i]
			var it: Item = s.get("item")
			if it == null or it.item_id != item_id:
				continue
			if not include_tempered and it is Equipment and it.forge_rank > 0:
				continue
			var instance_id: String = String(s.get("instance_id", ""))
			var is_equipped_copy: bool = instance_id != "" and is_instance_equipped(instance_id)
			if is_equipped_copy != remove_equipped:
				continue
			var c: int = int(s.get("count", 0))
			var take: int = mini(c, remaining)
			s["count"] = c - take
			remaining -= take
			if int(s["count"]) <= 0:
				_remove_slot_at(i)

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
	return use_item_for(&"protagonist", item_id, in_battle)


func use_item_for(character_id: StringName, item_id: StringName, in_battle: bool = false) -> bool:
	if not has_item(item_id, 1):
		return false
	var item := load_item_by_id(item_id)
	if item == null or not item.can_use(in_battle):
		return false
	var player: CharacterStats = GameState.get_party_member(character_id)
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

	# 永久属性加成物品（使用后增加上限）
	if sid == "linxi_jiu":
		if not _consume_item(item_id, 1):
			return false
		player.add_permanent_resource_bonus(&"item:linxi_jiu", 100, 50)
		player.hp = mini(player.max_hp, player.hp + 100)
		player.mp = mini(player.max_mp, player.mp + 50)
		EventBus.item_used.emit(item_id)
		GameState.emit_signal("player_changed")
		GameState.emit_signal("party_changed")
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
	for s: Dictionary in slots:
		var item: Item = s.get("item")
		if item != null and item.item_id == item_id and item is Equipment:
			var instance_id: String = String(s.get("instance_id", ""))
			if instance_id != "" and not is_instance_equipped(instance_id):
				return equip_instance(instance_id)
	return false


func equip_instance(instance_id: String) -> bool:
	return equip_instance_for(&"protagonist", instance_id)


func grant_recruit_equipment(character_id: StringName, item_id: StringName) -> bool:
	var member := GameState.get_party_member(character_id)
	var equipment := load_item_by_id(item_id) as Equipment
	if member == null or equipment == null or get_equipped_for(character_id, equipment.slot) != null:
		return false
	var instance_id := _new_instance_id(item_id)
	slots.append({"item": equipment, "count": 1, "instance_id": instance_id, "recruit_gear": true})
	if equip_instance_for(character_id, instance_id):
		return true
	slots.pop_back()
	return false


func equip_instance_for(character_id: StringName, instance_id: String) -> bool:
	var slot_entry: Dictionary = find_slot_by_instance(instance_id)
	var item: Item = slot_entry.get("item")
	if not (item is Equipment):
		return false
	var eq: Equipment = item
	var cid := String(character_id)
	if cid.is_empty():
		cid = "protagonist"
	var member := GameState.get_party_member(StringName(cid))
	if member != null and member.fixed_martial_arts and eq.slot == Equipment.Slot.WEAPON and member.weapon_specialty != &"" and _weapon_type_for_equipment(eq) != member.weapon_specialty:
		return false
	# An equipment instance may only be worn by one party member.  Switching the
	# selected character must not silently steal gear from another companion;
	# the owner has to unequip it first.
	var current_owner := get_instance_equipped_character_id(instance_id)
	if current_owner != &"" and String(current_owner) != cid:
		return false
	_unequip_instance_everywhere(instance_id)
	var char_equipped: Dictionary = _equipment_for(cid)
	var char_instances: Dictionary = _equipment_instances_for(cid)
	char_equipped[eq.slot] = eq
	char_instances[eq.slot] = instance_id
	equipped_by_character[cid] = char_equipped
	equipped_instance_ids_by_character[cid] = char_instances
	_sync_protagonist_aliases()
	if cid == "protagonist":
		_sync_legacy_equipped(eq.slot)
	EventBus.equipment_changed.emit(eq.slot, eq.item_id)
	emit_signal("equipped_changed", eq.slot, eq)
	emit_signal("slots_changed")
	return true


func unequip(slot: int) -> void:
	unequip_for(&"protagonist", slot)


func unequip_for(character_id: StringName, slot: int) -> void:
	var cid := String(character_id)
	var char_equipped: Dictionary = _equipment_for(cid)
	var char_instances: Dictionary = _equipment_instances_for(cid)
	char_equipped.erase(slot)
	char_instances.erase(slot)
	equipped_by_character[cid] = char_equipped
	equipped_instance_ids_by_character[cid] = char_instances
	_sync_protagonist_aliases()
	if cid == "protagonist":
		_sync_legacy_equipped(slot)
	EventBus.equipment_changed.emit(slot, &"")
	emit_signal("equipped_changed", slot, null)
	emit_signal("slots_changed")


func get_equipped(slot: int) -> Equipment:
	return get_equipped_for(&"protagonist", slot)


func get_equipped_for(character_id: StringName, slot: int) -> Equipment:
	return _equipment_for(String(character_id)).get(slot, null)


func get_equipped_id(slot: int) -> StringName:
	var eq := get_equipped(slot)
	return eq.item_id if eq != null else &""


func get_equipped_instance_id(slot: int) -> String:
	return get_equipped_instance_id_for(&"protagonist", slot)


func get_equipped_instance_id_for(character_id: StringName, slot: int) -> String:
	return String(_equipment_instances_for(String(character_id)).get(slot, ""))


func is_instance_equipped(instance_id: String) -> bool:
	if instance_id == "":
		return false
	for by_slot: Variant in equipped_instance_ids_by_character.values():
		if by_slot is Dictionary and (by_slot as Dictionary).values().has(instance_id):
			return true
	return false


func get_instance_equipped_character_id(instance_id: String) -> StringName:
	if instance_id.is_empty():
		return &""
	for raw_character_id: Variant in equipped_instance_ids_by_character.keys():
		var by_slot: Variant = equipped_instance_ids_by_character.get(raw_character_id, {})
		if by_slot is Dictionary and (by_slot as Dictionary).values().has(instance_id):
			return StringName(String(raw_character_id))
	return &""


func find_slot_by_instance(instance_id: String) -> Dictionary:
	if instance_id == "":
		return {}
	for s: Dictionary in slots:
		if String(s.get("instance_id", "")) == instance_id:
			return s
	return {}


func remove_instance(instance_id: String) -> bool:
	for i: int in range(slots.size() - 1, -1, -1):
		if String(slots[i].get("instance_id", "")) == instance_id:
			var item: Item = slots[i].get("item")
			_remove_slot_at(i)
			emit_signal("slots_changed")
			if item != null:
				EventBus.item_dropped.emit(item.item_id, 1)
			return true
	return false


func _remove_slot_at(index: int) -> void:
	if index < 0 or index >= slots.size():
		return
	var instance_id: String = String(slots[index].get("instance_id", ""))
	if instance_id != "":
		_unequip_instance_everywhere(instance_id)
	slots.remove_at(index)


func _new_instance_id(item_id: StringName) -> String:
	var candidate: String = ""
	while candidate == "" or not find_slot_by_instance(candidate).is_empty():
		candidate = "%s#%d" % [String(item_id), _next_instance_serial]
		_next_instance_serial += 1
	return candidate


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


func _weapon_type_for_equipment(equipment: Equipment) -> StringName:
	if equipment == null:
		return &""
	if equipment.weapon_type != &"":
		return Equipment.normalize_weapon_type(equipment.weapon_type)
	var item_id := String(equipment.item_id).to_lower()
	if "staff" in item_id or "stick" in item_id:
		return &"staff"
	if "sword" in item_id:
		return &"sword"
	if "blade" in item_id or "axe" in item_id:
		return &"blade"
	return &""


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
	return _sum_equipped_bonus_for(&"protagonist", method_name)


func _sum_equipped_bonus_for(character_id: StringName, method_name: StringName) -> int:
	var total := 0
	for eq in _equipment_for(String(character_id)).values():
		var e := eq as Equipment
		if e != null and e.has_method(method_name):
			total += int(e.call(method_name))
	return total


func _sum_equipped_float_bonus_for(character_id: StringName, method_name: StringName) -> float:
	var total := 0.0
	for eq in _equipment_for(String(character_id)).values():
		var e := eq as Equipment
		if e != null and e.has_method(method_name):
			total += float(e.call(method_name))
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


func get_crit_chance_bonus() -> float:
	return _sum_equipped_float_bonus_for(&"protagonist", &"get_crit_chance_bonus")


func get_atk_bonus_for(character_id: StringName) -> int:
	return _sum_equipped_bonus_for(character_id, &"get_attack_bonus")


func get_def_bonus_for(character_id: StringName) -> int:
	return _sum_equipped_bonus_for(character_id, &"get_defense_bonus")


func get_speed_bonus_for(character_id: StringName) -> int:
	return _sum_equipped_bonus_for(character_id, &"get_speed_bonus")


func get_crit_chance_bonus_for(character_id: StringName) -> float:
	return _sum_equipped_float_bonus_for(character_id, &"get_crit_chance_bonus")


func get_hit_chance_bonus_for(character_id: StringName) -> float:
	return _sum_equipped_float_bonus_for(character_id, &"get_hit_chance_bonus")


func get_attribute_bonus_for(character_id: StringName, method_name: StringName) -> int:
	return _sum_equipped_bonus_for(character_id, method_name)


## 查询已装备武器的技能加成。
## 返回 {scaling: int, crit_mult: float}。
## "all" 门派武器对所有门派生效，但优先级低于专属门派加成（取较大值）。
func get_equipped_skill_bonus(school: String, weapon_style: StringName = &"") -> Dictionary:
	return get_equipped_skill_bonus_for(&"protagonist", school, weapon_style)


func get_equipped_skill_bonus_for(character_id: StringName, school: String, weapon_style: StringName = &"") -> Dictionary:
	var result := {"scaling": 0, "school_scaling": 0, "weapon_scaling": 0, "crit_mult": 0.0}

	for eq in _equipment_for(String(character_id)).values():
		var e := eq as Equipment
		if e == null:
			continue
		if e.get_weapon_skill_scaling_bonus() > 0 and _weapon_style_matches(e.get_martial_style(), weapon_style):
			result["weapon_scaling"] += e.get_weapon_skill_scaling_bonus()

		# 同门派加成直接累加
		if school != "" and school != "generic" and e.skill_bonus_school == school:
			result["school_scaling"] += e.get_skill_scaling_bonus()
			result["crit_mult"] += e.skill_bonus_crit_mult

		# "all" 通用加成，取最大值
		elif school != "" and e.skill_bonus_school == "all":
			result["school_scaling"] = max(result["school_scaling"], e.get_skill_scaling_bonus())
			result["crit_mult"] = max(result["crit_mult"], e.skill_bonus_crit_mult)

	result["scaling"] = int(result["school_scaling"]) + int(result["weapon_scaling"])
	return result


func _weapon_style_matches(equipment_type: StringName, skill_style: StringName) -> bool:
	equipment_type = Equipment.normalize_weapon_type(equipment_type)
	skill_style = Equipment.normalize_weapon_type(skill_style)
	if skill_style == &"any":
		return true
	if skill_style == &"":
		return false
	if skill_style == &"blade":
		return equipment_type == &"blade"
	if skill_style == &"hidden":
		return equipment_type == &"hidden" or equipment_type == &"ring" or equipment_type == &"dagger"
	return equipment_type == skill_style


func _equipment_for(character_id: String) -> Dictionary:
	var cid := character_id if not character_id.is_empty() else "protagonist"
	if not equipped_by_character.has(cid):
		equipped_by_character[cid] = {}
	return equipped_by_character[cid]


func _equipment_instances_for(character_id: String) -> Dictionary:
	var cid := character_id if not character_id.is_empty() else "protagonist"
	if not equipped_instance_ids_by_character.has(cid):
		equipped_instance_ids_by_character[cid] = {}
	return equipped_instance_ids_by_character[cid]


func _sync_protagonist_aliases() -> void:
	equipped = _equipment_for("protagonist")
	equipped_instance_ids = _equipment_instances_for("protagonist")


func _unequip_instance_everywhere(instance_id: String) -> void:
	if instance_id.is_empty():
		return
	for cid: Variant in equipped_instance_ids_by_character.keys():
		var char_instances: Dictionary = equipped_instance_ids_by_character[cid]
		for slot: Variant in char_instances.keys():
			if String(char_instances[slot]) == instance_id:
				var char_equipped: Dictionary = _equipment_for(String(cid))
				char_instances.erase(slot)
				char_equipped.erase(slot)
				equipped_instance_ids_by_character[cid] = char_instances
				equipped_by_character[cid] = char_equipped
	_sync_protagonist_aliases()


# --- 序列化（给 SaveManager 用）---

func commit_weapon_temper(next_slots: Array, weapon: Equipment, instance_id: String, gold_after: int) -> void:
	var owner := get_instance_equipped_character_id(instance_id)
	slots.assign(next_slots)
	GameState.gold = gold_after
	if owner != &"":
		_equipment_for(String(owner))[Equipment.Slot.WEAPON] = weapon
		_sync_protagonist_aliases()
		if owner == &"protagonist":
			_sync_legacy_equipped(Equipment.Slot.WEAPON)
		EventBus.equipment_changed.emit(Equipment.Slot.WEAPON, weapon.item_id)
		equipped_changed.emit(Equipment.Slot.WEAPON, weapon)
	slots_changed.emit()
	GameState.gold_changed.emit(GameState.gold)
	EventBus.gold_changed.emit(GameState.gold)


func to_dict() -> Dictionary:
	var out_slots: Array = []
	for s in slots:
		var it: Item = s.get("item")
		if it == null: continue
		var saved := {
			"item_id": String(it.item_id),
			"count": int(s.get("count", 0)),
			"instance_id": String(s.get("instance_id", "")),
		}
		if it is Equipment and it.forge_rank > 0:
			saved["forge_rank"] = it.forge_rank
			saved["forge_affixes"] = it.forge_affixes.duplicate()
		if bool(s.get("recruit_gear", false)):
			saved["recruit_gear"] = true
		out_slots.append(saved)
	var equipped_out := {}
	for slot in all_slots():
		var eq := get_equipped(slot)
		if eq != null:
			equipped_out[slot_key(slot)] = {
				"item_id": String(eq.item_id),
				"instance_id": get_equipped_instance_id(slot),
			}
	var all_equipped_out: Dictionary = {}
	for cid: Variant in equipped_by_character.keys():
		var per_character: Dictionary = {}
		for slot: int in all_slots():
			var eq := get_equipped_for(StringName(cid), slot)
			if eq != null:
				per_character[slot_key(slot)] = {
					"item_id": String(eq.item_id),
					"instance_id": get_equipped_instance_id_for(StringName(cid), slot),
				}
		all_equipped_out[String(cid)] = per_character
	return {
		"slots": out_slots,
		"equipped": equipped_out,
		"equipped_by_character": all_equipped_out,
		"weapon_id": String(equipped_weapon.item_id) if equipped_weapon else "",
		"armor_id":  String(equipped_armor.item_id)  if equipped_armor  else "",
	}


func from_dict(d: Dictionary) -> void:
	slots.clear()
	equipped.clear()
	equipped_instance_ids.clear()
	equipped_by_character.clear()
	equipped_instance_ids_by_character.clear()
	_next_instance_serial = 1
	equipped_weapon = null
	equipped_armor = null
	var raw_slots: Array = d.get("slots", [])
	var remaining_standard_slots := MAX_SLOTS
	for entry in raw_slots:
		var item_id: StringName = StringName(entry.get("item_id", ""))
		var count: int = int(entry.get("count", 0))
		if String(item_id) == "" or count <= 0: continue
		var item: Item = load_item_by_id(item_id)
		if item == null:
			continue
		if item.stackable:
			if remaining_standard_slots > 0:
				_append_loaded_slot(item, count, "")
				remaining_standard_slots -= 1
		else:
			var recruit_gear := item is Equipment and bool(entry.get("recruit_gear", false))
			var copies := 1 if recruit_gear else mini(count, remaining_standard_slots)
			for copy_index: int in copies:
				var saved_instance_id: String = String(entry.get("instance_id", "")) if copy_index == 0 else ""
				var physical: Item = item
				if item is Equipment and copy_index == 0 and entry.has("forge_rank"):
					physical = preload("res://scripts/life_skills/weapon_tempering.gd").make_weapon(item, int(entry.forge_rank), entry.get("forge_affixes", []))
				_append_loaded_slot(physical, 1, saved_instance_id, recruit_gear)
			if not recruit_gear:
				remaining_standard_slots -= copies
	var raw_all_equipped: Dictionary = d.get("equipped_by_character", {})
	if not raw_all_equipped.is_empty():
		for cid: Variant in raw_all_equipped.keys():
			_restore_character_equipment(StringName(cid), raw_all_equipped[cid])
		_sync_protagonist_aliases()
		emit_signal("slots_changed")
		return
	var raw_equipped: Dictionary = d.get("equipped", {})
	if raw_equipped.is_empty():
		raw_equipped = {
			"weapon": d.get("weapon_id", ""),
			"armor": d.get("armor_id", ""),
		}
	for key: Variant in raw_equipped:
		var equipped_data: Variant = raw_equipped[key]
		var item_id: StringName = &""
		var instance_id: String = ""
		if equipped_data is Dictionary:
			var equipped_dict: Dictionary = equipped_data
			item_id = StringName(equipped_dict.get("item_id", ""))
			instance_id = String(equipped_dict.get("instance_id", ""))
		else:
			item_id = StringName(equipped_data)
		if instance_id != "" and equip_instance(instance_id):
			continue
		if String(item_id) != "":
			equip(item_id)
	emit_signal("slots_changed")


func _restore_character_equipment(character_id: StringName, raw_equipped: Variant) -> void:
	if not (raw_equipped is Dictionary):
		return
	var slot_map: Dictionary = raw_equipped
	for key: Variant in slot_map:
		var equipped_data: Variant = slot_map[key]
		var item_id: StringName = &""
		var instance_id: String = ""
		if equipped_data is Dictionary:
			item_id = StringName((equipped_data as Dictionary).get("item_id", ""))
			instance_id = String((equipped_data as Dictionary).get("instance_id", ""))
		else:
			item_id = StringName(equipped_data)
		if not instance_id.is_empty() and equip_instance_for(character_id, instance_id):
			continue
		if item_id != &"":
			for entry: Dictionary in slots:
				var item: Item = entry.get("item")
				var candidate_id := String(entry.get("instance_id", ""))
				if item != null and item.item_id == item_id and not is_instance_equipped(candidate_id):
					equip_instance_for(character_id, candidate_id)
					break


func _append_loaded_slot(item: Item, count: int, saved_instance_id: String, recruit_gear := false) -> void:
	var instance_id: String = saved_instance_id
	if not item.stackable and (instance_id == "" or not find_slot_by_instance(instance_id).is_empty()):
		instance_id = _new_instance_id(item.item_id)
	var entry := {"item": item, "count": count, "instance_id": instance_id}
	if recruit_gear:
		entry["recruit_gear"] = true
	slots.append(entry)
