extends RefCounted
## REGION_27D pure presentation/daily business. Not a legacy Field owner.
## Fixed original tables retain all rows; no EXEC_AUTHORITY/source_paths/prepare.
const SELF="res://build/luoyang_city_rectification_20261027d_system01/presentation_definition.gd"
const CONTRACT="res://build/luoyang_city_rectification_20261027d_system01/presentation_definition_contract01_BUILD.json"
const CONTRACT_SHA="4e33336f401ed3f13046a3e5ce6f18e5665097d07890858524dd45be129b4b4d"
const AUTHOR="res://build/luoyang_city_full_rollout_20261022ap_npc01/author.json"
const AUTHOR_SHA="d51fa9ffce334601ecad4d114b39db78b24bbc71fef99ab3cfb10b5189720ed2"
const AP_PREDECESSOR="res://build/luoyang_city_full_rollout_20261022ap_npc01/presentation.gd"
const AP_PREDECESSOR_SHA="1c1a43ecfc26f370a703790aacc77b692e0ee7f2ecac745821a5bd473a5bada7"
const PEOPLE_DATA="res://build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people.json"
const PEOPLE_DATA_SHA="74759592d13ae8dade98e8b44daed34d62ca0acd00387b1ee654d9d300609b9b"
const PEOPLE_PREDECESSOR="res://build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people.gd"
const PEOPLE_PREDECESSOR_SHA="dfdc530a1c020dbcc93b7a8c09118de59284d0774cfda4f258370ee4f0a9b2a7"
const PEOPLE_IDS=["luoyang_artisan_residential_20261022ap","luoyang_riverside_garden_20261022ap"]
const SIZE=Vector2(3072,2048)
const VISUAL_KEYS := ["sprite_path", "portrait_path"]
const EMPTY_ARRAY_EFFECTS := ["choices", "give_items", "set_flags", "learn_skills", "add_evidence", "verify_evidence", "add_testimonies", "verify_testimonies", "faction_trust_changes", "companion_trust_changes", "bond_events", "city_outcomes", "method_flags"]
static func _fail(error: String) -> Dictionary:
	return {"ok": false, "error": error}

static func _path(value: Variant) -> bool:
	return value is String and value.begins_with("res://") and not value.contains("..")

static func _sha(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for c: String in value:
		if c not in "0123456789abcdef": return false
	return true

static func _pair(value: Variant) -> bool:
	if not value is Array or value.size() != 2: return false
	for scalar: Variant in value:
		if (not scalar is int and not scalar is float) or not is_finite(float(scalar)): return false
	return true

static func _v(value: Array) -> Vector2: return Vector2(float(value[0]), float(value[1]))

static func _definition() -> Dictionary:
	if FileAccess.get_sha256(CONTRACT)!=CONTRACT_SHA: return {}
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(CONTRACT))
	return raw if raw is Dictionary and raw.get("schema")=="REGION_27D_PRESENTATION_BUSINESS_DEFINITION_V1" and raw.get("status")=="FIXED_PURE_BUSINESS_NOT_LEGACY_FIELD_AUTHORITY" and raw.get("source_sha256") is Dictionary else {}
static func source_declarations() -> Dictionary:
	var definition: Dictionary=_definition()
	if definition.is_empty(): return {}
	var out: Dictionary=definition.source_sha256.duplicate(true)
	out[CONTRACT]=CONTRACT_SHA
	return out
static func dependency_paths() -> Array[String]:
	var out: Array[String]=[SELF]
	for path: String in source_declarations(): out.append(path)
	return out
static func readiness() -> Dictionary:
	var definition: Dictionary=_definition()
	if definition.is_empty(): return _fail("REGION_PRESENTATION_DEFINITION")
	for path: String in definition.source_sha256:
		var pin: Variant=definition.source_sha256[path]
		if not _path(path) or not _sha(pin) or FileAccess.get_sha256(path)!=pin: return _fail("REGION_PRESENTATION_BUSINESS_SOURCE:"+path)
	var presentation: Dictionary=_presentation_schema()
	if presentation.get("ok")!=true: return presentation
	var people: Dictionary=_people_schema()
	if people.get("ok")!=true: return people
	return {"ok":true,"author":presentation.author,"data":people.data,"definition_sources":source_declarations(),"legacy_owner_authority":false}
static func _presentation_schema() -> Dictionary:
	if FileAccess.get_sha256(AP_PREDECESSOR) != AP_PREDECESSOR_SHA: return _fail("AP_NPC_EXECUTION_AP_PREDECESSOR_CHANGED")
	if not _sha(AUTHOR_SHA) or FileAccess.get_sha256(AUTHOR) != AUTHOR_SHA:
		return _fail("AP_NPC_AUTHOR_CHANGED")
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(AUTHOR))
	if not raw is Dictionary or raw.get("schema_version") != 1 or raw.get("status") != "READY_CURRENT_SOURCE_NPC_PRESENTATION_AND_SECONDARY_DAILY":
		return _fail("AP_NPC_AUTHOR_DOMAIN")
	if not raw.get("visual_rows") is Array or raw.visual_rows.size() != 7 or not raw.get("daily_rows") is Array or raw.daily_rows.size() != 12 or not raw.get("source_sha256") is Dictionary or raw.source_sha256.is_empty():
		return _fail("AP_NPC_AUTHOR_INCOMPLETE")
	var visual_ids: Dictionary = {}; var daily_ids: Dictionary = {}
	for row: Variant in raw.visual_rows:
		if not row is Dictionary or not row.get("npc_id") is String or visual_ids.has(row.npc_id) or not row.get("scene_id") is String or not row.get("patch") is Dictionary or not row.get("expected") is Dictionary:
			return _fail("AP_NPC_VISUAL_ROW_DOMAIN")
		visual_ids[row.npc_id] = true
		if row.expected.get("movement_mode") != "idle" or row.expected.get("walk_sprite_path") != "": return _fail("AP_NPC_STATIC_ONLY_REQUIRED")
		for key: Variant in row.patch:
			if key not in VISUAL_KEYS or not _path(row.patch[key]) or not raw.source_sha256.has(row.patch[key]): return _fail("AP_NPC_VISUAL_PATCH_NOT_BOUND")
	for row: Variant in raw.daily_rows:
		if not row is Dictionary or not row.get("npc_id") is String or daily_ids.has(row.npc_id) or not row.get("scene_id") is String or not _path(row.get("dialog_path")) or not raw.source_sha256.has(row.dialog_path): return _fail("AP_NPC_DAILY_ROW_DOMAIN")
		if row.npc_id in raw.excluded_culture_ids or row.npc_id in raw.excluded_ad_role_ids: return _fail("AP_NPC_DAILY_EXISTING_TOPIC_COLLISION")
		daily_ids[row.npc_id] = true
	return {"ok": true, "author": raw}

static func _people_schema() -> Dictionary:
	if FileAccess.get_sha256(PEOPLE_PREDECESSOR) != PEOPLE_PREDECESSOR_SHA: return _fail("AP_NPC_EXECUTION_PEOPLE_PREDECESSOR_CHANGED")
	if PEOPLE_DATA_SHA.length() != 64 or FileAccess.get_sha256(PEOPLE_DATA) != PEOPLE_DATA_SHA: return _fail("AP_QUARTER_PEOPLE_DATA_CHANGED")
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PEOPLE_DATA))
	if not raw is Dictionary or raw.get("schema_version") != 1 or raw.get("status") != "SOURCE_BOUND_NEW_PEOPLE_PENDING_NATIVE_GEOMETRY" or not _pair(raw.get("world_size")) or _v(raw.world_size) != SIZE or not raw.get("people") is Array or raw.people.size() != 8 or not raw.get("families") is Dictionary or raw.families.size() != 4 or not raw.get("source_sha256") is Dictionary: return _fail("AP_QUARTER_PEOPLE_DATA_DOMAIN")
	var seen: Dictionary = {}; var names_by_scene: Dictionary = {}
	for row: Variant in raw.people:
		if not row is Dictionary or not row.get("npc_id") is String or not String(row.npc_id).begins_with("ap_quarter_life_") or seen.has(row.npc_id) or not row.get("scene_id") is String or row.scene_id not in PEOPLE_IDS or not _pair(row.get("foot_px")) or not _pair(row.get("approach_px")) or not row.get("npc_name") is String or row.npc_name == "" or not raw.families.has(row.get("family")) or not row.get("daily_lines") is Array or row.daily_lines.size() != 2: return _fail("AP_QUARTER_PEOPLE_ROW_DOMAIN")
		seen[row.npc_id] = true
		if not Rect2(Vector2(17, 12), SIZE - Vector2(34, 24)).has_point(_v(row.foot_px)) or _v(row.approach_px) != _v(row.foot_px) + Vector2(0, 48): return _fail("AP_QUARTER_PEOPLE_COORDINATE_CONTRACT")
		if not names_by_scene.has(row.scene_id): names_by_scene[row.scene_id] = {}
		if names_by_scene[row.scene_id].has(row.family): return _fail("AP_QUARTER_PEOPLE_SAME_SCREEN_FAMILY_REPEAT")
		names_by_scene[row.scene_id][row.family] = true
		for line: Variant in row.daily_lines:
			if not line is String or line.length() < 12 or line.length() > 60: return _fail("AP_QUARTER_PEOPLE_SHORT_AUTHORED_LINE")
	for id: String in PEOPLE_IDS:
		if not names_by_scene.has(id) or names_by_scene[id].size() != 4: return _fail("AP_QUARTER_PEOPLE_FOUR_PER_SCENE_REQUIRED")
	for key: String in raw.families:
		var family: Dictionary = raw.families[key]
		for field: String in ["sprite_path", "portrait_path"]:
			if not family.get(field) is String or not raw.source_sha256.has(family[field]): return _fail("AP_QUARTER_PEOPLE_FAMILY_NOT_BOUND")
		if family.get("idle_frames") != 4 or family.get("walk_sprite_path") != "": return _fail("AP_QUARTER_PEOPLE_STATIC_REAL_IDLE_ONLY")
	return {"ok": true, "data": raw}

static func compose_exact(scene_id: StringName, rows: Array, author: Dictionary) -> Dictionary:
	if not author.get("visual_rows") is Array: return _fail("AP_NPC_PURE_AUTHOR_MISSING")
	var specs: Dictionary = {}
	for spec: Dictionary in author.visual_rows: specs[String(spec.npc_id)] = spec
	var out: Array = []; var seen: Dictionary = {}; var changed: Array[String] = []
	for raw: Variant in rows:
		if not raw is Dictionary: return _fail("AP_NPC_ROW_NOT_DICTIONARY")
		var row: Dictionary = raw; var next: Dictionary = row.duplicate(true)
		var id: String = String(row.get("npc_id", ""))
		if seen.has(id): return _fail("AP_NPC_DUPLICATE_INPUT_ID:" + id)
		seen[id] = true
		if specs.has(id):
			var spec: Dictionary = specs[id]
			if spec.scene_id != String(scene_id): return _fail("AP_NPC_WRONG_SCENE:" + id)
			for key: String in spec.expected:
				var fallback: Variant = "idle" if key == "movement_mode" else ""
				if row.get(key, fallback) != spec.expected[key]: return _fail("AP_NPC_PARENT_IDENTITY_CHANGED:" + id + ":" + key)
			for key: String in spec.patch:
				if key not in VISUAL_KEYS: return _fail("AP_NPC_NONVISUAL_PATCH:" + id)
				next[key] = spec.patch[key]
			var restored: Dictionary = next.duplicate(true)
			for key: String in spec.patch:
				if row.has(key): restored[key] = row[key]
				else: restored.erase(key)
			if restored != row: return _fail("AP_NPC_NONVISUAL_MUTATION:" + id)
			changed.append(id)
		out.append(next)
	return {"ok": true, "matched": not changed.is_empty(), "npcs": out, "changed_ids": changed, "presentation_only": true, "geometry_movement_primary_culture_rewards_save_unchanged": true}

static func daily_topics_exact(scene_id: StringName, npc_id: String, author: Dictionary) -> Array:
	if not author.get("daily_rows") is Array: return []
	for row: Dictionary in author.daily_rows:
		if row.npc_id == npc_id and row.scene_id == String(scene_id):
			return [{"kind": "secondary_daily_life", "label": "聊聊日常", "dialog_id": row.dialog_id, "dialog_path": row.dialog_path}]
	return []

static func validate_daily_identity_exact(scene_id: StringName, row: Dictionary, author: Dictionary) -> Dictionary:
	if not author.get("daily_rows") is Array: return _fail("AP_NPC_PURE_DAILY_AUTHOR_MISSING")
	for spec: Dictionary in author.daily_rows:
		if spec.npc_id != String(row.get("npc_id", "")): continue
		if spec.scene_id != String(scene_id) or spec.npc_name != String(row.get("npc_name", "")): return _fail("AP_NPC_DAILY_PARENT_IDENTITY_CHANGED")
		var variants: Variant = row.get("dialog_variants", [])
		if row.get("dialog_id", "") != "" or row.get("interaction_action", "") != "" or not variants is Array or not variants.is_empty(): return _fail("AP_NPC_DAILY_MUST_NOT_REPLACE_PRIMARY")
		return {"ok": true, "matched": true}
	return {"ok": true, "matched": false}

static func _safe_daily_node(node: DialogNode) -> bool:
	if node == null or node.give_gold != 0 or node.weather_id != &"" or node.accept_quest != &"" or node.complete_quest != &"": return false
	for key: String in EMPTY_ARRAY_EFFECTS:
		var value: Variant = node.get(key)
		if not value is Array or not value.is_empty(): return false
	return true

static func defs_exact(scene_id: StringName, data: Dictionary) -> Dictionary:
	if String(scene_id) not in PEOPLE_IDS or not data.get("people") is Array or not data.get("families") is Dictionary: return _fail("AP_QUARTER_PEOPLE_UNKNOWN_SCENE")
	var npcs: Array = []; var approaches: Array = []
	for row: Dictionary in data.people:
		if row.scene_id != String(scene_id): continue
		var family: Dictionary = data.families[row.family]
		npcs.append({"npc_id": row.npc_id, "npc_name": row.npc_name, "pos": _v(row.foot_px) / SIZE, "sprite_path": family.sprite_path, "walk_sprite_path": "", "portrait_path": family.portrait_path, "scale": 1.0, "movement_mode": "idle", "patrol_axis": Vector2.RIGHT, "patrol_distance": 0.0, "patrol_speed": 22.0, "idle_frame_seconds": 0.28, "walk_frame_seconds": 0.12, "dialog_id": "", "interaction_action": "", "dialog_variants": [], "district_life_ground_anchored": true})
		approaches.append({"npc_id": row.npc_id, "foot_px": _v(row.foot_px), "approach_px": _v(row.approach_px), "route_required": true})
	if npcs.size() != 4: return _fail("AP_QUARTER_PEOPLE_INCOMPLETE_SCENE")
	return {"ok": true, "npcs": npcs, "approaches": approaches, "native_geometry_validation_pending": true}

static func people_daily_handles_exact(scene_id: StringName, npc_id: String, data: Dictionary) -> bool:
	for row: Dictionary in data.get("people", []):
		if row.npc_id == npc_id and row.scene_id == String(scene_id): return true
	return false

static func validate_people_identity_exact(scene_id: StringName, row: Dictionary, data: Dictionary) -> Dictionary:
	var projected: Dictionary = defs_exact(scene_id, data)
	if projected.get("ok") != true: return projected
	for expected: Dictionary in projected.npcs:
		if expected.npc_id != String(row.get("npc_id", "")): continue
		if row.get("npc_name", "") != expected.npc_name or row.get("dialog_id", "") != "" or row.get("interaction_action", "") != "" or row.get("dialog_variants", []) != []: return _fail("AP_QUARTER_PEOPLE_PRIMARY_OR_IDENTITY_CHANGED")
		return {"ok": true, "matched": true}
	return {"ok": true, "matched": false}

static func build_presentation_daily_menu_exact(scene_id: StringName, npc_id: String, npc_name: String, author: Dictionary) -> Dictionary:
	var selected: Dictionary = {}
	for row: Dictionary in author.daily_rows:
		if row.npc_id == npc_id and row.scene_id == String(scene_id): selected = row
	if selected.is_empty() or npc_name != selected.npc_name: return _fail("AP_NPC_DAILY_IDENTITY_OR_SCENE")
	var original: DialogScript = ResourceLoader.load(selected.dialog_path) as DialogScript
	if original == null or String(original.dialog_id) != selected.dialog_id or original.entry_node_id != &"start" or original.nodes.size() != 2: return _fail("AP_NPC_DAILY_RESOURCE_DOMAIN")
	var first: DialogNode = original.find_node_by_id(&"start")
	var second: DialogNode = original.find_node_by_id(&"reply")
	if not _safe_daily_node(first) or not _safe_daily_node(second) or first.speaker != npc_name or second.speaker != npc_name or first.on_end != "next:reply" or second.on_end != "end": return _fail("AP_NPC_DAILY_NOT_ZERO_EFFECT_TWO_LINES")
	# Clone authored lines, never mutate the cached resource or global dialog player.
	# Keep authored dialog_id so existing voice lookup semantics are not fabricated.
	var script: DialogScript = original.duplicate(true) as DialogScript
	var menu := DialogNode.new()
	menu.node_id = &"ap_daily_menu"; menu.speaker = npc_name; menu.text = "聊聊日常"; menu.voice_emotion = "normal"
	menu.choices.assign([{"text": "聊聊日常", "next": "start"}, {"text": "告辞", "next": "end"}])
	script.nodes.push_front(menu); script.entry_node_id = menu.node_id
	return {"ok": true, "script": script, "secondary_daily_only": true, "authored_text_nodes": 2, "new_voice_or_portrait": false, "preserve_primary_and_culture": true}

static func build_people_daily_menu_exact(scene_id: StringName, npc_id: String, npc_name: String, data: Dictionary) -> Dictionary:
	var selected: Dictionary = {}
	for row: Dictionary in data.people:
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

static func daily_handles_exact(scene_id: StringName,npc_id: String,ready: Dictionary) -> bool:
	return ready.get("ok")==true and (people_daily_handles_exact(scene_id,npc_id,ready.data) or not daily_topics_exact(scene_id,npc_id,ready.author).is_empty())
static func daily_menu_exact(scene_id: StringName,npc_id: String,npc_name: String,ready: Dictionary) -> Dictionary:
	if ready.get("ok")!=true: return _fail("REGION_DAILY_DEFINITION_NOT_READY")
	if people_daily_handles_exact(scene_id,npc_id,ready.data): return build_people_daily_menu_exact(scene_id,npc_id,npc_name,ready.data)
	return build_presentation_daily_menu_exact(scene_id,npc_id,npc_name,ready.author)
