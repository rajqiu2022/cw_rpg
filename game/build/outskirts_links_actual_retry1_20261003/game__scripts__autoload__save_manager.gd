extends Node

## JSON 存档管理（M7）。
## - 5 个槽位：0..4
## - 仅存领域数据（数值、id），不存 Node/Resource 实例
## - 提供槽位元数据读取，供主菜单展示

const SAVE_DIR := "user://"
const SLOT_COUNT := 5
const SAVE_VERSION := 14
const FIELD_ID_MIGRATIONS := {
	"ch1_s3_zhuwei_forest": "ch2_s3_forest_ambush",
}

var active_slot: int = 0


func clamp_slot(slot: int) -> int:
	return clamp(slot, 0, SLOT_COUNT - 1)


func slot_path(slot: int) -> String:
	return "%ssave_%d.json" % [SAVE_DIR, clamp_slot(slot)]


func slot_backup_path(slot: int) -> String:
	return "%ssave_%d.json.bak" % [SAVE_DIR, clamp_slot(slot)]


func has_save(slot: int) -> bool:
	if slot < 0 or slot >= SLOT_COUNT:
		return false
	return FileAccess.file_exists(slot_path(slot)) or FileAccess.file_exists(slot_backup_path(slot))


func save_to_slot(slot: int) -> bool:
	slot = clamp_slot(slot)
	active_slot = slot
	var data := {
		"version": SAVE_VERSION,
		"slot": slot,
		"timestamp": Time.get_unix_time_from_system(),
		"chapter": GameState.current_chapter,
		"player_faction": String(GameState.player_faction),
		"skill_mastery": GameState.skill_mastery,
		"pending_skill_unlocks": GameState.pending_skill_unlocks.map(func(skill_id: StringName) -> String: return String(skill_id)),
		"training_points_total": GameState.training_points_total,
		"training_points_available": GameState.training_points_available,
		"reputation": GameState.reputation,
		"sparring_records": GameState.get_sparring_records_save_data(),
		"gold": GameState.gold,
		"flags": GameState.flags,
		"player": _serialize_stats(GameState.player),
		"party": GameState.party.map(func(member: CharacterStats) -> Dictionary: return _serialize_stats(member)),
		"inventory": Inventory.to_dict(),
		"quests": QuestManager.to_dict(),
		"bounties": BountyManager.to_dict(),
		"investigation": InvestigationState.to_dict(),
		"weather": WeatherManager.to_dict(),
		"current_field": String(SceneRouter.get_current_field_id()),
		"navigation": SceneRouter.get_navigation_state(),
		"audio_volumes": AudioManager.get_volumes(),
	}
	return _write_slot_atomic(slot, JSON.stringify(data, "  "))


func load_from_slot(slot: int, world_map_upgrade_target: StringName = &"") -> bool:
	# Candidate QA explicitly opts in. After canonical v14 activation, normal
	# menu loads automatically migrate navigation; save schema stays version 14.
	slot = clamp_slot(slot)
	if not has_save(slot):
		return false
	var data := _read_slot_data(slot)
	if data.is_empty():
		return false
	var saved_navigation: Variant = data.get("navigation", {})
	var selected_world: StringName = world_map_upgrade_target if world_map_upgrade_target != &"" else SceneRouter.WORLD_MAP_SCENE
	if saved_navigation is Dictionary and not SceneRouter.navigation_coordinate_version_supported(saved_navigation, selected_world): return false
	var prepared_v15_navigation: Dictionary = {}
	var v15_target: StringName = SceneRouter.WORLD_MAP_V15_SCENE if world_map_upgrade_target == SceneRouter.WORLD_MAP_V15_SCENE else SceneRouter.WORLD_MAP_SCENE
	if world_map_upgrade_target == SceneRouter.WORLD_MAP_V15_SCENE or (world_map_upgrade_target == &"" and SceneRouter.WORLD_V15.formal_version() == 15):
		var navigation: Variant = data.get("navigation", {})
		prepared_v15_navigation = SceneRouter.prepare_v15_navigation(navigation if navigation is Dictionary else {}, migrate_field_id(StringName(data.get("current_field", SceneRouter.START_FIELD_SCENE))), v15_target)
		if prepared_v15_navigation.is_empty(): return false

	active_slot = slot
	GameState.current_chapter = int(data.get("chapter", 1))
	GameState.player_faction = StringName(data.get("player_faction", GameState.flags.get("player_faction", "")))
	GameState.skill_mastery = data.get("skill_mastery", {})
	GameState.pending_skill_unlocks.clear()
	for skill_id: Variant in data.get("pending_skill_unlocks", []):
		GameState.pending_skill_unlocks.append(StringName(skill_id))
	GameState.training_points_total = maxi(0, int(data.get("training_points_total", 0)))
	GameState.training_points_available = clampi(int(data.get("training_points_available", GameState.training_points_total)), 0, GameState.training_points_total)
	GameState.reputation = maxi(0, int(data.get("reputation", 0)))
	GameState.restore_sparring_records(data.get("sparring_records", {}))
	GameState.gold = int(data.get("gold", 0))
	GameState.flags = data.get("flags", {})
	var saved_version := int(data.get("version", 0))
	_apply_stats(GameState.player, data.get("player", {}), saved_version)
	var saved_party: Array = data.get("party", [])
	GameState.restore_party(saved_party)
	for raw_member: Variant in saved_party:
		if raw_member is Dictionary:
			var member_id := StringName((raw_member as Dictionary).get("character_id", ""))
			var member := GameState.get_party_member(member_id)
			if member != null:
				_apply_stats(member, raw_member, saved_version)
	GameState.reconcile_progression_rewards()
	GameState.reconcile_equipped_internal_arts()
	GameState.call_deferred("_reconcile_pending_skills")
	Inventory.from_dict(data.get("inventory", {}))
	QuestManager.from_dict(data.get("quests", {}))
	BountyManager.from_dict(data.get("bounties", {}))
	var investigation_data: Variant = data.get("investigation", {})
	InvestigationState.from_dict(investigation_data if investigation_data is Dictionary else {})
	var weather_data: Variant = data.get("weather", {})
	WeatherManager.from_dict(weather_data if weather_data is Dictionary else {})
	var navigation_data: Variant = data.get("navigation", {})
	if not prepared_v15_navigation.is_empty():
		SceneRouter.commit_v15_navigation(prepared_v15_navigation)
	else:
		SceneRouter.restore_navigation_state(
			navigation_data if navigation_data is Dictionary else {},
			migrate_field_id(StringName(data.get("current_field", SceneRouter.START_FIELD_SCENE))),
			world_map_upgrade_target
		)
	AudioManager.set_volumes(data.get("audio_volumes", {}))
	GameState.emit_signal("player_changed")
	GameState.emit_signal("party_changed")
	GameState.emit_signal("gold_changed", GameState.gold)
	EventBus.training_points_changed.emit(GameState.training_points_total, GameState.training_points_available)
	EventBus.reputation_changed.emit(GameState.reputation, GameState.get_reputation_title())
	return true


func get_save_field_id(slot: int, world_map_upgrade_target: StringName = &"") -> StringName:
	## 仅查看存档应返回哪个场景，不应用整个存档。
	var data := _read_slot_data(slot)
	if data.is_empty():
		return &""
	var saved_field := migrate_field_id(StringName(data.get("current_field", SceneRouter.START_FIELD_SCENE)))
	if world_map_upgrade_target == SceneRouter.WORLD_MAP_V15_SCENE and SceneRouter.is_world_map_scene(saved_field):
		return SceneRouter.WORLD_MAP_V15_SCENE
	if world_map_upgrade_target == &"" and SceneRouter.WORLD_V15.formal_version() == 15 and SceneRouter.is_world_map_scene(saved_field):
		return SceneRouter.WORLD_MAP_SCENE
	if world_map_upgrade_target == SceneRouter.WORLD_MAP_V14_SCENE and SceneRouter.is_world_map_scene(saved_field):
		return SceneRouter.WORLD_MAP_V14_SCENE
	if world_map_upgrade_target == &"" and SceneRouter.WORLD_V14.formal_version() == 14 and SceneRouter.is_world_map_scene(saved_field):
		return SceneRouter.WORLD_MAP_SCENE
	if world_map_upgrade_target == SceneRouter.WORLD_MAP_STAGING_SCENE and saved_field == SceneRouter.WORLD_MAP_SCENE:
		return SceneRouter.WORLD_MAP_STAGING_SCENE
	return saved_field


func migrate_field_id(scene_id: StringName) -> StringName:
	var migrated: String = String(FIELD_ID_MIGRATIONS.get(String(scene_id), String(scene_id)))
	if migrated == "" or not ResourceLoader.exists("res://data/scenes/%s.tres" % migrated):
		var chapter: int = clampi(GameState.current_chapter, 1, 4)
		var entry: StringName = SceneRouter.get_chapter_entry(chapter)
		return entry if String(entry) != "" else SceneRouter.START_FIELD_SCENE
	return StringName(migrated)


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
		"reputation": int(data.get("reputation", 0)),
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
	var parsed := _read_json_file(slot_path(slot))
	if not parsed.is_empty():
		return parsed
	parsed = _read_json_file(slot_backup_path(slot))
	if not parsed.is_empty():
		push_warning("[SaveManager] recovered slot=%d from backup" % slot)
	return parsed


func _read_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[SaveManager] save file corrupted: %s" % path)
		return {}
	return parsed


func _write_slot_atomic(slot: int, payload: String) -> bool:
	var final_path := slot_path(slot)
	var backup_path := slot_backup_path(slot)
	var temp_path := "%s.tmp" % final_path
	var f := FileAccess.open(temp_path, FileAccess.WRITE)
	if f == null:
		push_error("[SaveManager] open temp file for write failed slot=%d" % slot)
		return false
	f.store_string(payload)
	f.flush()
	f.close()

	var final_abs := ProjectSettings.globalize_path(final_path)
	var backup_abs := ProjectSettings.globalize_path(backup_path)
	var temp_abs := ProjectSettings.globalize_path(temp_path)
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_abs)
	if FileAccess.file_exists(final_path):
		var backup_err := DirAccess.rename_absolute(final_abs, backup_abs)
		if backup_err != OK:
			push_warning("[SaveManager] could not rotate backup slot=%d error=%d" % [slot, backup_err])
	var commit_err := DirAccess.rename_absolute(temp_abs, final_abs)
	if commit_err == OK:
		return true

	# Some virtual filesystems cannot atomically rename. Preserve compatibility
	# with them by falling back to a direct write after the temp payload is safe.
	var fallback := FileAccess.open(final_path, FileAccess.WRITE)
	if fallback == null:
		push_error("[SaveManager] commit failed slot=%d error=%d" % [slot, commit_err])
		return false
	fallback.store_string(payload)
	fallback.flush()
	fallback.close()
	DirAccess.remove_absolute(temp_abs)
	return true


func _serialize_stats(s: CharacterStats) -> Dictionary:
	if s == null:
		return {}
	return {
		"character_id": s.character_id,
		"display_name": s.display_name,
		"portrait_path": s.portrait_path,
		"role_title": s.role_title,
		"origin": s.origin,
		"biography": s.biography,
		"weapon_specialty": String(s.weapon_specialty),
		"fixed_martial_arts": s.fixed_martial_arts,
		"equipped_internal_art": String(s.equipped_internal_art),
		"battle_actor_path": s.battle_actor_path,
		"battle_sprite_root": s.battle_sprite_root,
		"battle_sprite_prefix": s.battle_sprite_prefix,
		"battle_actor_scale": s.battle_actor_scale,
		"level": s.level,
		"exp": s.exp,
		"skills": s.skills.map(func(skill_id: StringName) -> String: return String(skill_id)),
		"hp": s.hp, "max_hp": s.max_hp,
		"mp": s.mp, "max_mp": s.max_mp,
		"permanent_resource_bonuses": s.permanent_resource_bonuses.duplicate(true),
		"attack": s.attack, "defense": s.defense, "speed": s.speed,
		"strength": s.strength,
		"agility": s.agility,
		"inner_power": s.inner_power,
		"insight": s.insight,
		"vitality": s.vitality,
		"inner_pool": s.inner_pool,
		"guard": s.guard,
	}


func _apply_stats(s: CharacterStats, d: Dictionary, saved_version: int = SAVE_VERSION) -> void:
	if s == null or d.is_empty():
		return
	s.level = int(d.get("level", s.level))
	s.display_name = String(d.get("display_name", s.display_name))
	s.portrait_path = String(d.get("portrait_path", s.portrait_path))
	s.equipped_internal_art = StringName(d.get("equipped_internal_art", ""))
	s.exp = int(d.get("exp", 0))
	if d.has("skills") and d.skills is Array:
		s.skills.clear()
		for skill_id in d.skills:
			s.skills.append(StringName(skill_id))
	s.max_hp = int(d.get("max_hp", s.max_hp))
	s.hp = int(d.get("hp", s.hp))
	s.max_mp = int(d.get("max_mp", s.max_mp))
	s.mp = int(d.get("mp", s.mp))
	s.attack = int(d.get("attack", s.attack))
	s.defense = int(d.get("defense", s.defense))
	s.speed = int(d.get("speed", s.speed))
	# Clear the previous slot's ledger even when this save predates the field.
	s.restore_permanent_resource_bonuses(d.get("permanent_resource_bonuses", {}))

	var has_core := d.has("strength") and d.has("agility") and d.has("inner_power") and d.has("insight") and d.has("vitality") and d.has("inner_pool") and d.has("guard")
	if has_core:
		s.strength = int(d.get("strength", s.strength))
		s.agility = int(d.get("agility", s.agility))
		s.inner_power = int(d.get("inner_power", s.inner_power))
		s.insight = int(d.get("insight", s.insight))
		s.vitality = int(d.get("vitality", s.vitality))
		s.inner_pool = int(d.get("inner_pool", s.inner_pool))
		s.guard = int(d.get("guard", s.guard))
		if saved_version <= 12 and not d.has("permanent_resource_bonuses"):
			s.preserve_legacy_saved_capacities(int(d.get("max_hp", 0)), int(d.get("max_mp", 0)))
		s.refresh_derived_stats(false)
	else:
		s.infer_core_attributes_from_legacy()
