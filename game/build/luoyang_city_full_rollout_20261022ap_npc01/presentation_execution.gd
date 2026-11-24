extends RefCounted
## AP terminal row projection. No Scene, body, route, quest, save or catalog writes.
## compose_exact is pure; project/readiness only read frozen author/source files.
const SELF := "res://build/luoyang_city_full_rollout_20261022ap_npc01/presentation_execution.gd"
const PREDECESSOR := "res://build/luoyang_city_full_rollout_20261022ap_npc01/presentation.gd"
const PREDECESSOR_SHA := "1c1a43ecfc26f370a703790aacc77b692e0ee7f2ecac745821a5bd473a5bada7"
const EXEC_AUTHORITY := "res://scripts/city/luoyang_execution_authority_20261022ap.gd"
const AUTHOR := "res://build/luoyang_city_full_rollout_20261022ap_npc01/author.json"
const AUTHOR_SHA := "d51fa9ffce334601ecad4d114b39db78b24bbc71fef99ab3cfb10b5189720ed2"
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
	if not _sha(AUTHOR_SHA) or FileAccess.get_sha256(AUTHOR) != AUTHOR_SHA:
		return _fail("AP_NPC_AUTHOR_CHANGED")
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(AUTHOR))
	if not raw is Dictionary or raw.get("schema_version") != 1 or raw.get("status") != "READY_CURRENT_SOURCE_NPC_PRESENTATION_AND_SECONDARY_DAILY":
		return _fail("AP_NPC_AUTHOR_DOMAIN")
	if not raw.get("visual_rows") is Array or raw.visual_rows.size() != 7 or not raw.get("daily_rows") is Array or raw.daily_rows.size() != 12 or not raw.get("source_sha256") is Dictionary or raw.source_sha256.is_empty():
		return _fail("AP_NPC_AUTHOR_INCOMPLETE")
	for path: Variant in raw.source_sha256:
		if not _path(path) or not _sha(raw.source_sha256[path]) or not _source_matches(path, String(raw.source_sha256[path])):
			return _fail("AP_NPC_SOURCE_CHANGED:" + str(path))
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

static func source_paths() -> Dictionary:
	var ready: Dictionary = readiness()
	if ready.get("ok") != true: return {}
	var paths: Dictionary = {SELF: true, AUTHOR: true, PREDECESSOR: true}
	for path: String in ready.author.source_sha256: paths[path] = true
	var execution_paths: Dictionary = _execution_paths()
	if execution_paths.is_empty(): return {}
	paths.merge(execution_paths)
	return paths

static func identity_mapping() -> Dictionary:
	var ready: Dictionary = readiness()
	if ready.get("ok") != true: return ready
	return {"ok": true, "visual_rows": ready.author.visual_rows.duplicate(true), "daily_rows": ready.author.daily_rows.duplicate(true), "moving_military_unchanged": ready.author.moving_military_unchanged.duplicate(true)}

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

static func project(scene_id: StringName, rows: Array) -> Dictionary:
	var ready: Dictionary = readiness()
	if ready.get("ok") != true: return ready
	return compose_exact(scene_id, rows, ready.author)

static func daily_topics(scene_id: StringName, npc_id: String) -> Array:
	var ready: Dictionary = readiness()
	if ready.get("ok") != true: return []
	return daily_topics_exact(scene_id, npc_id, ready.author)

static func daily_topics_exact(scene_id: StringName, npc_id: String, author: Dictionary) -> Array:
	if not author.get("daily_rows") is Array: return []
	for row: Dictionary in author.daily_rows:
		if row.npc_id == npc_id and row.scene_id == String(scene_id):
			return [{"kind": "secondary_daily_life", "label": "聊聊日常", "dialog_id": row.dialog_id, "dialog_path": row.dialog_path}]
	return []

static func daily_handles(scene_id: StringName, npc_id: String) -> bool:
	return not daily_topics(scene_id, npc_id).is_empty()

static func validate_daily_identity(scene_id: StringName, row: Dictionary) -> Dictionary:
	var ready: Dictionary = readiness()
	if ready.get("ok") != true: return ready
	return validate_daily_identity_exact(scene_id, row, ready.author)

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

static func build_daily_menu(scene_id: StringName, npc_id: String, npc_name: String) -> Dictionary:
	var ready: Dictionary = readiness()
	if ready.get("ok") != true: return ready
	var selected: Dictionary = {}
	for row: Dictionary in ready.author.daily_rows:
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
