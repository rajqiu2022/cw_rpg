extends Node

## JSON 存档管理（M7）。
## - 5 个槽位：0..4
## - 仅存领域数据（数值、id），不存 Node/Resource 实例
## - 提供槽位元数据读取，供主菜单展示

const SAVE_DIR := "user://"
const SLOT_COUNT := 5

var active_slot: int = 0


func clamp_slot(slot: int) -> int:
	return clamp(slot, 0, SLOT_COUNT - 1)


func slot_path(slot: int) -> String:
	return "%ssave_%d.json" % [SAVE_DIR, clamp_slot(slot)]


func has_save(slot: int) -> bool:
	if slot < 0 or slot >= SLOT_COUNT:
		return false
	return FileAccess.file_exists(slot_path(slot))


func save_to_slot(slot: int) -> bool:
	slot = clamp_slot(slot)
	active_slot = slot
	var data := {
		"version": 4,
		"slot": slot,
		"timestamp": Time.get_unix_time_from_system(),
		"chapter": GameState.current_chapter,
		"gold": GameState.gold,
		"flags": GameState.flags,
		"player": _serialize_stats(GameState.player),
		"inventory": Inventory.to_dict(),
		"quests": QuestManager.to_dict(),
		"current_field": String(SceneRouter.get_current_field_id()),
	}
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f == null:
		push_error("[SaveManager] open for write failed slot=%d" % slot)
		return false
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	return true


func load_from_slot(slot: int) -> bool:
	slot = clamp_slot(slot)
	if not has_save(slot):
		return false
	var data := _read_slot_data(slot)
	if data.is_empty():
		return false

	active_slot = slot
	GameState.current_chapter = int(data.get("chapter", 1))
	GameState.gold = int(data.get("gold", 0))
	GameState.flags = data.get("flags", {})
	_apply_stats(GameState.player, data.get("player", {}))
	Inventory.from_dict(data.get("inventory", {}))
	QuestManager.from_dict(data.get("quests", {}))
	GameState.emit_signal("player_changed")
	GameState.emit_signal("gold_changed", GameState.gold)
	return true


func get_save_field_id(slot: int) -> StringName:
	## 仅查看存档应返回哪个场景，不应用整个存档。
	var data := _read_slot_data(slot)
	if data.is_empty():
		return &""
	return StringName(data.get("current_field", "ch1_s1_road"))


func get_slot_meta(slot: int) -> Dictionary:
	var data := _read_slot_data(slot)
	if data.is_empty():
		return {
			"exists": false,
			"slot": clamp_slot(slot),
		}
	return {
		"exists": true,
		"slot": clamp_slot(slot),
		"version": int(data.get("version", 0)),
		"timestamp": int(data.get("timestamp", 0)),
		"chapter": int(data.get("chapter", 1)),
		"gold": int(data.get("gold", 0)),
		"field": String(data.get("current_field", "")),
	}


func format_timestamp(ts: int) -> String:
	if ts <= 0:
		return "--"
	var d := Time.get_datetime_dict_from_unix_time(ts)
	return "%04d-%02d-%02d %02d:%02d" % [
		int(d.get("year", 0)),
		int(d.get("month", 0)),
		int(d.get("day", 0)),
		int(d.get("hour", 0)),
		int(d.get("minute", 0)),
	]


func _read_slot_data(slot: int) -> Dictionary:
	slot = clamp_slot(slot)
	if not has_save(slot):
		return {}
	var f := FileAccess.open(slot_path(slot), FileAccess.READ)
	if f == null:
		return {}
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[SaveManager] save file corrupted slot=%d" % slot)
		return {}
	return parsed


func _serialize_stats(s: CharacterStats) -> Dictionary:
	if s == null:
		return {}
	return {
		"character_id": s.character_id,
		"display_name": s.display_name,
		"level": s.level,
		"hp": s.hp, "max_hp": s.max_hp,
		"mp": s.mp, "max_mp": s.max_mp,
		"attack": s.attack, "defense": s.defense, "speed": s.speed,
		"strength": s.strength,
		"agility": s.agility,
		"inner_power": s.inner_power,
		"insight": s.insight,
		"vitality": s.vitality,
		"inner_pool": s.inner_pool,
		"guard": s.guard,
	}


func _apply_stats(s: CharacterStats, d: Dictionary) -> void:
	if s == null or d.is_empty():
		return
	s.level = int(d.get("level", s.level))
	s.max_hp = int(d.get("max_hp", s.max_hp))
	s.hp = int(d.get("hp", s.hp))
	s.max_mp = int(d.get("max_mp", s.max_mp))
	s.mp = int(d.get("mp", s.mp))
	s.attack = int(d.get("attack", s.attack))
	s.defense = int(d.get("defense", s.defense))
	s.speed = int(d.get("speed", s.speed))

	var has_core := d.has("strength") and d.has("agility") and d.has("inner_power") and d.has("insight") and d.has("vitality") and d.has("inner_pool") and d.has("guard")
	if has_core:
		s.strength = int(d.get("strength", s.strength))
		s.agility = int(d.get("agility", s.agility))
		s.inner_power = int(d.get("inner_power", s.inner_power))
		s.insight = int(d.get("insight", s.insight))
		s.vitality = int(d.get("vitality", s.vitality))
		s.inner_pool = int(d.get("inner_pool", s.inner_pool))
		s.guard = int(d.get("guard", s.guard))
		s.refresh_derived_stats(false)
	else:
		s.infer_core_attributes_from_legacy()
