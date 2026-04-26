extends Node

## 简单 JSON 存档。固定 3 个槽位 user://save_{slot}.json。
## 仅存"领域数据"（数值、id），不存 Node/Resource 实例。

const SAVE_DIR := "user://"
const SLOT_COUNT := 3

func slot_path(slot: int) -> String:
	return "%ssave_%d.json" % [SAVE_DIR, slot]

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))

func save_to_slot(slot: int) -> bool:
	var data := {
		"version": 1,
		"timestamp": Time.get_unix_time_from_system(),
		"chapter": GameState.current_chapter,
		"gold": GameState.gold,
		"flags": GameState.flags,
		"player": _serialize_stats(GameState.player),
	}
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f == null:
		push_error("[SaveManager] open for write failed slot=%d" % slot)
		return false
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	return true

func load_from_slot(slot: int) -> bool:
	if not has_save(slot):
		return false
	var f := FileAccess.open(slot_path(slot), FileAccess.READ)
	if f == null:
		return false
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[SaveManager] save file corrupted slot=%d" % slot)
		return false
	var data: Dictionary = parsed
	GameState.current_chapter = int(data.get("chapter", 1))
	GameState.gold = int(data.get("gold", 0))
	GameState.flags = data.get("flags", {})
	_apply_stats(GameState.player, data.get("player", {}))
	GameState.emit_signal("player_changed")
	GameState.emit_signal("gold_changed", GameState.gold)
	return true

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
