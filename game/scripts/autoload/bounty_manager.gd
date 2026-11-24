extends Node

## 城市通缉榜、追捕目标迁移与结算的单一状态源。

const BOUNTY_DIR := "res://data/bounties/"
const STATUS_AVAILABLE := &"available"
const STATUS_ACTIVE := &"active"
const STATUS_CAPTURED := &"captured"

var _definitions: Dictionary = {}
var _states: Dictionary = {}


func _ready() -> void:
	_reload_definitions()


func reset_for_new_game() -> void:
	_states.clear()


func _reload_definitions() -> void:
	_definitions.clear()
	# ResourceLoader lists original resource names even if an export remaps them.
	for filename: String in ResourceLoader.list_directory(BOUNTY_DIR):
		if not filename.ends_with(".tres"):
			continue
		var loaded := load(BOUNTY_DIR + filename) as BountyDef
		if loaded != null and String(loaded.bounty_id) != "":
			_definitions[String(loaded.bounty_id)] = loaded


func get_definition(bounty_id: StringName) -> BountyDef:
	return _definitions.get(String(bounty_id)) as BountyDef


func get_board_entries(city_id: StringName) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for raw_def: Variant in _definitions.values():
		var def := raw_def as BountyDef
		if def == null or def.board_city != city_id:
			continue
		var state := _state_for(def.bounty_id)
		var location := _location_for(def, int(state.get("location_index", -1)))
		entries.append({
			"bounty_id": def.bounty_id,
			"display_name": def.display_name,
			"title": def.title,
			"description": def.description,
			"level_text": "%d～%d级" % [def.recommended_min_level, def.recommended_max_level],
			"reward_text": def.reward_summary(),
			"status": StringName(state.get("status", STATUS_AVAILABLE)),
			"location_label": String(location.get("label", "接榜后由驿卒指明踪迹")),
			"escape_count": int(state.get("escape_count", 0)),
		})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var da := get_definition(StringName(a.get("bounty_id", &"")))
		var db := get_definition(StringName(b.get("bounty_id", &"")))
		return da.recommended_min_level < db.recommended_min_level
	)
	return entries


func accept_bounty(bounty_id: StringName) -> Dictionary:
	var def := get_definition(bounty_id)
	if def == null:
		return {"ok": false, "message": "这张榜文已经撤下。"}
	var state := _state_for(bounty_id)
	var status := StringName(state.get("status", STATUS_AVAILABLE))
	if status == STATUS_CAPTURED:
		return {"ok": false, "message": "%s已归案。" % def.display_name}
	if status == STATUS_ACTIVE:
		return {"ok": false, "message": "此案已接，目标现藏于%s。" % _active_location_label(def, state)}
	state["status"] = STATUS_ACTIVE
	state["location_index"] = _pick_location_index(def, -1)
	state["accepted_at"] = Time.get_unix_time_from_system()
	_states[String(bounty_id)] = state
	var message := "已揭榜：%s\n线报指向%s。" % [def.display_name, _active_location_label(def, state)]
	EventBus.toast_requested.emit(message)
	return {"ok": true, "message": message, "location_label": _active_location_label(def, state)}


func get_scene_npcs(scene_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key: String in _states:
		var state: Dictionary = _states[key]
		if StringName(state.get("status", STATUS_AVAILABLE)) != STATUS_ACTIVE:
			continue
		var def := get_definition(StringName(key))
		if def == null:
			continue
		var location := _location_for(def, int(state.get("location_index", -1)))
		if StringName(location.get("scene_id", &"")) != scene_id:
			continue
		result.append({
			"npc_id": "bounty_%s" % key,
			"npc_name": "%s · 在逃" % def.display_name,
			"pos": location.get("pos", Vector2(0.65, 0.55)),
			"sprite_path": def.field_sprite_path,
			"scale": def.field_sprite_scale,
			"interaction_action": "bounty_battle:%s" % key,
		})
	return result


func start_bounty(bounty_id: StringName) -> bool:
	var def := get_definition(bounty_id)
	var state := _state_for(bounty_id)
	if def == null or StringName(state.get("status", STATUS_AVAILABLE)) != STATUS_ACTIVE:
		return false
	SceneRouter.start_bounty_encounter(bounty_id, def.enemy_ids)
	return true


func resolve_victory(bounty_id: StringName) -> Dictionary:
	var def := get_definition(bounty_id)
	var state := _state_for(bounty_id)
	if def == null or StringName(state.get("status", STATUS_AVAILABLE)) != STATUS_ACTIVE:
		return {}
	state["status"] = STATUS_CAPTURED
	state["completion_count"] = int(state.get("completion_count", 0)) + 1
	_states[String(bounty_id)] = state
	GameState.add_reputation(def.reward_reputation)
	GameState.add_training_points(def.reward_training)
	GameState.add_gold(def.reward_gold)
	var member_lines: PackedStringArray = []
	for member: CharacterStats in GameState.party:
		if member == null:
			continue
		var before := member.level
		member.gain_exp(def.reward_exp)
		member_lines.append("%s 额外经验 +%d%s" % [member.display_name, def.reward_exp, "，升至%d级" % member.level if member.level > before else ""])
	for reward: Dictionary in def.reward_items:
		Inventory.add_item(StringName(reward.get("item_id", &"")), maxi(1, int(reward.get("count", 1))))
	GameState.player_changed.emit()
	GameState.party_changed.emit()
	return {
		"title": "缉捕归案 · %s" % def.display_name,
		"summary": "%s\n%s" % [def.reward_summary(), "\n".join(member_lines)],
	}


func record_defeat(bounty_id: StringName) -> Dictionary:
	var def := get_definition(bounty_id)
	var state := _state_for(bounty_id)
	if def == null or StringName(state.get("status", STATUS_AVAILABLE)) != STATUS_ACTIVE:
		return {}
	var previous := int(state.get("location_index", -1))
	state["location_index"] = _pick_location_index(def, previous)
	state["escape_count"] = int(state.get("escape_count", 0)) + 1
	_states[String(bounty_id)] = state
	return {
		"message": "%s趁乱逃走。官差重查线报后，发现其已转移至%s。" % [def.display_name, _active_location_label(def, state)],
		"location_label": _active_location_label(def, state),
	}


func to_dict() -> Dictionary:
	return {"states": _states.duplicate(true)}


func from_dict(raw: Variant) -> void:
	_states.clear()
	if raw is Dictionary:
		var saved_states: Variant = (raw as Dictionary).get("states", {})
		if saved_states is Dictionary:
			_states = (saved_states as Dictionary).duplicate(true)


func _state_for(bounty_id: StringName) -> Dictionary:
	var key := String(bounty_id)
	if not _states.has(key):
		_states[key] = {
			"status": STATUS_AVAILABLE,
			"location_index": -1,
			"escape_count": 0,
			"completion_count": 0,
		}
	return (_states[key] as Dictionary).duplicate(true)


func _location_for(def: BountyDef, index: int) -> Dictionary:
	if def == null or def.locations.is_empty() or index < 0:
		return {}
	return def.locations[index % def.locations.size()]


func _active_location_label(def: BountyDef, state: Dictionary) -> String:
	return String(_location_for(def, int(state.get("location_index", -1))).get("label", "未知去处"))


func _pick_location_index(def: BountyDef, previous: int) -> int:
	if def.locations.is_empty():
		return -1
	if def.locations.size() == 1:
		return 0
	var next := randi_range(0, def.locations.size() - 2)
	if next >= previous:
		next += 1
	return next

