extends RefCounted
## Separate new-quarter population. Does not alter the frozen old-city module.
## Caller owns actual author placement audit, native publishing and activation.
const SELF := "res://build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people_execution.gd"
const PREDECESSOR := "res://build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people.gd"
const PREDECESSOR_SHA := "dfdc530a1c020dbcc93b7a8c09118de59284d0774cfda4f258370ee4f0a9b2a7"
const EXEC_AUTHORITY := "res://scripts/city/luoyang_execution_authority_20261022ap.gd"
const DATA := "res://build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people.json"
const DATA_SHA := "74759592d13ae8dade98e8b44daed34d62ca0acd00387b1ee654d9d300609b9b"
const SIZE := Vector2(3072, 2048)
const IDS := ["luoyang_artisan_residential_20261022ap", "luoyang_riverside_garden_20261022ap"]

static func _fail(error: String) -> Dictionary: return {"ok": false, "error": error}

static func _pair(value: Variant) -> bool:
	if not value is Array or value.size() != 2: return false
	for scalar: Variant in value:
		if (not scalar is int and not scalar is float) or not is_finite(float(scalar)): return false
	return true

static func _v(value: Array) -> Vector2: return Vector2(float(value[0]), float(value[1]))


static func _source_matches(path: String, historical_sha: String) -> bool:
	if FileAccess.get_sha256(path) == historical_sha: return true
	# Only closed-set canonical executable sources may have an exact approved
	# successor. Data, dialogues, art, imports and proof leaves remain immutable.
	if not path.begins_with("res://scripts/") or not path.ends_with(".gd") or not FileAccess.file_exists(EXEC_AUTHORITY): return false
	var authority: Variant = load(EXEC_AUTHORITY)
	return authority is GDScript and authority.resource_path == EXEC_AUTHORITY and path in authority.OWNED and authority.approved(path, historical_sha) == true

static func _execution_paths() -> Dictionary:
	if not FileAccess.file_exists(EXEC_AUTHORITY): return {}
	var authority: Variant = load(EXEC_AUTHORITY)
	if not authority is GDScript or authority.resource_path != EXEC_AUTHORITY: return {}
	var paths: Variant = authority.source_paths()
	return paths if paths is Dictionary and paths.has(EXEC_AUTHORITY) else {}

static func readiness() -> Dictionary:
	if FileAccess.get_sha256(PREDECESSOR) != PREDECESSOR_SHA: return _fail("AP_NPC_EXECUTION_PREDECESSOR_CHANGED")
	if DATA_SHA.length() != 64 or FileAccess.get_sha256(DATA) != DATA_SHA: return _fail("AP_QUARTER_PEOPLE_DATA_CHANGED")
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	if not raw is Dictionary or raw.get("schema_version") != 1 or raw.get("status") != "SOURCE_BOUND_NEW_PEOPLE_PENDING_NATIVE_GEOMETRY" or not _pair(raw.get("world_size")) or _v(raw.world_size) != SIZE or not raw.get("people") is Array or raw.people.size() != 8 or not raw.get("families") is Dictionary or raw.families.size() != 4 or not raw.get("source_sha256") is Dictionary: return _fail("AP_QUARTER_PEOPLE_DATA_DOMAIN")
	for path: String in raw.source_sha256:
		var expected: Variant = raw.source_sha256[path]
		if not path.begins_with("res://") or ".." in path or not expected is String or expected.length() != 64 or not _source_matches(path, String(expected)): return _fail("AP_QUARTER_PEOPLE_SOURCE_CHANGED:" + path)
	var seen: Dictionary = {}; var names_by_scene: Dictionary = {}
	for row: Variant in raw.people:
		if not row is Dictionary or not row.get("npc_id") is String or not String(row.npc_id).begins_with("ap_quarter_life_") or seen.has(row.npc_id) or not row.get("scene_id") is String or row.scene_id not in IDS or not _pair(row.get("foot_px")) or not _pair(row.get("approach_px")) or not row.get("npc_name") is String or row.npc_name == "" or not raw.families.has(row.get("family")) or not row.get("daily_lines") is Array or row.daily_lines.size() != 2: return _fail("AP_QUARTER_PEOPLE_ROW_DOMAIN")
		seen[row.npc_id] = true
		if not Rect2(Vector2(17, 12), SIZE - Vector2(34, 24)).has_point(_v(row.foot_px)) or _v(row.approach_px) != _v(row.foot_px) + Vector2(0, 48): return _fail("AP_QUARTER_PEOPLE_COORDINATE_CONTRACT")
		if not names_by_scene.has(row.scene_id): names_by_scene[row.scene_id] = {}
		if names_by_scene[row.scene_id].has(row.family): return _fail("AP_QUARTER_PEOPLE_SAME_SCREEN_FAMILY_REPEAT")
		names_by_scene[row.scene_id][row.family] = true
		for line: Variant in row.daily_lines:
			if not line is String or line.length() < 12 or line.length() > 60: return _fail("AP_QUARTER_PEOPLE_SHORT_AUTHORED_LINE")
	for id: String in IDS:
		if not names_by_scene.has(id) or names_by_scene[id].size() != 4: return _fail("AP_QUARTER_PEOPLE_FOUR_PER_SCENE_REQUIRED")
	for key: String in raw.families:
		var family: Dictionary = raw.families[key]
		for field: String in ["sprite_path", "portrait_path"]:
			if not family.get(field) is String or not raw.source_sha256.has(family[field]): return _fail("AP_QUARTER_PEOPLE_FAMILY_NOT_BOUND")
		if family.get("idle_frames") != 4 or family.get("walk_sprite_path") != "": return _fail("AP_QUARTER_PEOPLE_STATIC_REAL_IDLE_ONLY")
	return {"ok": true, "data": raw}

static func source_paths() -> Dictionary:
	var ready: Dictionary = readiness()
	if ready.get("ok") != true: return {}
	var paths: Dictionary = {SELF: true, DATA: true, PREDECESSOR: true}
	for path: String in ready.data.source_sha256: paths[path] = true
	var execution_paths: Dictionary = _execution_paths()
	if execution_paths.is_empty(): return {}
	paths.merge(execution_paths)
	return paths

static func defs_exact(scene_id: StringName, data: Dictionary) -> Dictionary:
	if String(scene_id) not in IDS or not data.get("people") is Array or not data.get("families") is Dictionary: return _fail("AP_QUARTER_PEOPLE_UNKNOWN_SCENE")
	var npcs: Array = []; var approaches: Array = []
	for row: Dictionary in data.people:
		if row.scene_id != String(scene_id): continue
		var family: Dictionary = data.families[row.family]
		npcs.append({"npc_id": row.npc_id, "npc_name": row.npc_name, "pos": _v(row.foot_px) / SIZE, "sprite_path": family.sprite_path, "walk_sprite_path": "", "portrait_path": family.portrait_path, "scale": 1.0, "movement_mode": "idle", "patrol_axis": Vector2.RIGHT, "patrol_distance": 0.0, "patrol_speed": 22.0, "idle_frame_seconds": 0.28, "walk_frame_seconds": 0.12, "dialog_id": "", "interaction_action": "", "dialog_variants": [], "district_life_ground_anchored": true})
		approaches.append({"npc_id": row.npc_id, "foot_px": _v(row.foot_px), "approach_px": _v(row.approach_px), "route_required": true})
	if npcs.size() != 4: return _fail("AP_QUARTER_PEOPLE_INCOMPLETE_SCENE")
	return {"ok": true, "npcs": npcs, "approaches": approaches, "native_geometry_validation_pending": true}

static func defs(scene_id: StringName) -> Dictionary:
	var ready: Dictionary = readiness()
	if ready.get("ok") != true: return ready
	return defs_exact(scene_id, ready.data)

static func daily_handles_exact(scene_id: StringName, npc_id: String, data: Dictionary) -> bool:
	for row: Dictionary in data.get("people", []):
		if row.npc_id == npc_id and row.scene_id == String(scene_id): return true
	return false

static func daily_handles(scene_id: StringName, npc_id: String) -> bool:
	var ready: Dictionary = readiness()
	return ready.get("ok") == true and daily_handles_exact(scene_id, npc_id, ready.data)

static func validate_daily_identity_exact(scene_id: StringName, row: Dictionary, data: Dictionary) -> Dictionary:
	var projected: Dictionary = defs_exact(scene_id, data)
	if projected.get("ok") != true: return projected
	for expected: Dictionary in projected.npcs:
		if expected.npc_id != String(row.get("npc_id", "")): continue
		if row.get("npc_name", "") != expected.npc_name or row.get("dialog_id", "") != "" or row.get("interaction_action", "") != "" or row.get("dialog_variants", []) != []: return _fail("AP_QUARTER_PEOPLE_PRIMARY_OR_IDENTITY_CHANGED")
		return {"ok": true, "matched": true}
	return {"ok": true, "matched": false}

static func build_daily_menu(scene_id: StringName, npc_id: String, npc_name: String) -> Dictionary:
	var ready: Dictionary = readiness()
	if ready.get("ok") != true: return ready
	var selected: Dictionary = {}
	for row: Dictionary in ready.data.people:
		if row.npc_id == npc_id and row.scene_id == String(scene_id): selected = row
	if selected.is_empty() or npc_name != selected.npc_name: return _fail("AP_QUARTER_PEOPLE_DIALOG_IDENTITY")
	var script := DialogScript.new()
	script.dialog_id = StringName("luoyang_quarter_daily_" + npc_id)
	var menu := DialogNode.new(); menu.node_id = &"menu"; menu.speaker = npc_name; menu.text = "聊聊日常"; menu.voice_emotion = "normal"
	menu.choices.assign([{"text": "聊聊日常", "next": "start"}, {"text": "告辞", "next": "end"}])
	var first := DialogNode.new(); first.node_id = &"start"; first.speaker = npc_name; first.text = selected.daily_lines[0]; first.voice_emotion = "normal"; first.on_end = "next:reply"
	var reply := DialogNode.new(); reply.node_id = &"reply"; reply.speaker = npc_name; reply.text = selected.daily_lines[1]; reply.voice_emotion = "normal"; reply.on_end = "end"
	script.nodes.assign([menu, first, reply]); script.entry_node_id = menu.node_id
	return {"ok": true, "script": script, "secondary_daily_only": true, "zero_state_or_reward_effects": true, "new_voice": false}
