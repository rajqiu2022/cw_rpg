extends RefCounted
## Explicit static-only successor: four real stills over five existing people.
## The failed/not-ready six-identity animation proposal remains separate.
## No catalog, scene, route, body, name, primary, quest, flag or save mutation.
const SELF := "res://scripts/city/luoyang_military_static_presentation_20261019y.gd"
const INDEX := "res://scripts/city/luoyang_military_static_presentation_index_20261019y.gd"
const MANIFEST := "res://data/luoyang_military_static_presentation_20261019y/manifest.json"
const MANIFEST_SHA := "306c01323d8afbaa330e5a6ffec9a1d971321ae12c6bbf75e623f5c59a54b582"
const FLAG := "--luoyang-military-static-presentation-20261019y"
const GUARD_IDLE := "res://art/characters/street_expansion_v1/npc_escort_guard_idle_down_4f_v2_runtime.png"
const GUARD_WALK := "res://art/characters/street_expansion_v2/npc_escort_guard_walk_right_8f_v1_runtime.png"
const EXAMINER := "res://art/characters/street_expansion_v1/npc_wulin_examiner_idle_down_4f.png"
const GATE := "ch4_s0_luoyang_gate"
const YAMEN := "ch4_s1_luoyang_yamen"
const DOCKS := "ch4_s2_canal_docks"
const MARKET := "ch4_s3_luoyang_market"
const SCENES := [GATE, YAMEN, DOCKS]
const STYLES := ["young_gate", "old_soldier", "sergeant", "commander"]
const VISUAL_KEYS := ["sprite_path", "walk_sprite_path", "portrait_path"]
const LEGACY_CALIBRATED_FAMILIES := ["npc_zhuwei_gate_guard_", "npc_zhuwei_inn_waiter_", "npc_escort_guard_", "npc_linxi_martial_hall_master_"]
const MILITARY := {
	"luoyang_gate_sergeant": {"scene": GATE, "style": "sergeant", "moving": false},
	"harbour_life_gate_check_assistant": {"scene": GATE, "style": "young_gate", "moving": false},
	"canal_old_soldier": {"scene": DOCKS, "style": "old_soldier", "moving": false},
	"spar_yamen_captain": {"scene": YAMEN, "style": "commander", "moving": false},
	"district_life_yamen_guard": {"scene": YAMEN, "style": "young_gate", "moving": false},
}
const DEFERRED_UNCHANGED_IDS := ["harbour_life_gate_patrol_west", "harbour_life_gate_patrol_east", "harbour_life_docks_quay_patrol", "district_life_market_patrol", "district_life_yamen_west_patrol", "spar_yamen_patrol", "spar_luoyang_patrol"]

static func _fail(error: String) -> Dictionary:
	return {"ok": false, "error": error}

static func enabled() -> bool:
	if FLAG in OS.get_cmdline_user_args(): return true
	var authority: Variant = load(INDEX)
	return authority is GDScript and authority.resource_path == INDEX and authority.formal_enabled() == true

static func requested(scene_id: StringName) -> bool:
	return enabled() and String(scene_id) in SCENES

static func _integer(value: Variant, exact: int) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value)) and float(value) == exact

static func _resource_path(value: Variant) -> bool:
	return value is String and String(value).begins_with("res://") and not String(value).contains("..")

static func _legacy_calibrated_path(path: String) -> bool:
	for family: String in LEGACY_CALIBRATED_FAMILIES:
		if path.get_file().begins_with(family): return true
	return false

static func _texture_proof(data: Dictionary, path: String, frames: int) -> bool:
	if not _resource_path(path) or not data.texture_proofs.has(path): return false
	var proof: Variant = data.texture_proofs[path]
	if not proof is Dictionary or proof.get("full_rgba_exact") != true or proof.get("params23") != true: return false
	var size: Variant = proof.get("size_px")
	if not size is Array or size.size() != 2: return false
	if frames > 0:
		if not _integer(size[0], 160 * frames) or not _integer(size[1], 160) or not _integer(proof.get("frames"), frames): return false
	else:
		if not _integer(size[0], 512) and not _integer(size[0], 1024): return false
		if size[0] != size[1]: return false
	var imported: Variant = proof.get("import_path")
	var compiled: Variant = proof.get("compiled_path")
	if imported != path + ".import" or not _resource_path(compiled) or not String(compiled).begins_with("res://.godot/imported/") or not String(compiled).ends_with(".ctex"): return false
	return data.source_sha256.has(path) and data.source_sha256.has(imported) and data.source_sha256.has(compiled)

static func readiness() -> Dictionary:
	if MANIFEST_SHA.length() != 64 or FileAccess.get_sha256(MANIFEST) != MANIFEST_SHA: return _fail("MILITARY_Y_MANIFEST_NOT_FROZEN")
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not data is Dictionary or not _integer(data.get("schema_version"), 1) or data.get("status") != "READY_SOURCE_BOUND_FOUR_STATIC_MILITARY_PRESENTATION": return _fail("MILITARY_Y_MANIFEST_NOT_READY")
	if not data.get("styles") is Dictionary or data.styles.size() != STYLES.size() or not data.get("texture_proofs") is Dictionary or not data.get("source_sha256") is Dictionary or data.source_sha256.is_empty(): return _fail("MILITARY_Y_COMPLETE_ART_SET_REQUIRED")
	var idles: Dictionary = {}; var used: Dictionary = {}
	for style: String in STYLES:
		var row: Variant = data.styles.get(style)
		if not row is Dictionary or not row.get("idle_path") is String or not row.get("walk_path") is String or not row.get("portrait_path") is String or not _integer(row.get("idle_frames"), 1): return _fail("MILITARY_Y_STYLE_FIELDS:" + style)
		var idle: String = row.idle_path
		if idles.has(idle) or not _texture_proof(data, idle, 1): return _fail("MILITARY_Y_DISTINCT_IDLE_OR_PROOF:" + style)
		# The target ordinary sergeant/old soldier used adult calibration;
		# the original examiner-based captain did not. Crowd's existing Field
		# ground marker forces calibration independently of filenames. Preserve
		# these exact branches with asset naming, not a new global NPC switch.
		if style in ["old_soldier", "sergeant"] and not _legacy_calibrated_path(idle): return _fail("MILITARY_Y_LEGACY_CALIBRATION_PREFIX_REQUIRED:" + style)
		if style == "commander" and _legacy_calibrated_path(idle): return _fail("MILITARY_Y_CAPTAIN_MUST_KEEP_ORIGINAL_NONCALIBRATED_BRANCH")
		idles[idle] = true; used[idle] = true
		var walk: String = row.walk_path
		if walk != "" or not _integer(row.get("walk_frames"), 0): return _fail("MILITARY_Y_STATIC_ROLE_HAS_FOREIGN_WALK:" + style)
		var portrait: String = row.portrait_path
		if portrait != "":
			if not _texture_proof(data, portrait, 0): return _fail("MILITARY_Y_PORTRAIT_PROOF:" + style)
			used[portrait] = true
	# Gate's existing approved catalog portrait must not silently defeat a new
	# row portrait. Keep it untouched in this batch rather than altering catalog.
	if data.styles.sergeant.portrait_path != "": return _fail("MILITARY_Y_KEEP_APPROVED_SERGEANT_CATALOG_PORTRAIT")
	if used.size() != data.texture_proofs.size(): return _fail("MILITARY_Y_UNUSED_TEXTURE_PROOF")
	for path: Variant in data.source_sha256:
		var sha: Variant = data.source_sha256[path]
		if not _resource_path(path) or not sha is String or String(sha).length() != 64 or FileAccess.get_sha256(path) != sha: return _fail("MILITARY_Y_SOURCE_CHANGED:" + str(path))
	return {"ok": true, "data": data}

static func source_paths() -> Dictionary:
	var paths: Dictionary = {SELF: true, INDEX: true, MANIFEST: true}
	# Disabled candidate sources are still explicit leaves. Missing art is not
	# silently loaded from another character; enabling fails closed in project.
	if MANIFEST_SHA.length() != 64 or FileAccess.get_sha256(MANIFEST) != MANIFEST_SHA: return paths
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not data is Dictionary or not data.get("source_sha256") is Dictionary: return paths
	for path: Variant in data.source_sha256:
		if not _resource_path(path): return {}
		paths[path] = true
	return paths

static func _nonvisual(row: Dictionary) -> Dictionary:
	var value: Dictionary = row.duplicate(true)
	for key: String in VISUAL_KEYS: value.erase(key)
	return value

static func project(scene_id: StringName, rows: Array) -> Dictionary:
	if not requested(scene_id): return {"ok": true, "matched": false, "npcs": rows.duplicate(true), "changed_ids": []}
	var ready: Dictionary = readiness()
	if ready.get("ok") != true: return ready
	var output: Array = []; var seen: Dictionary = {}; var changed: Array[String] = []
	for raw: Variant in rows:
		if not raw is Dictionary: return _fail("MILITARY_Y_NPC_ROW_TYPE")
		var original: Dictionary = raw
		var id: String = String(original.get("npc_id", ""))
		var next: Dictionary = original.duplicate(true)
		if MILITARY.has(id):
			if seen.has(id): return _fail("MILITARY_Y_DUPLICATE_ID:" + id)
			seen[id] = true
			var spec: Dictionary = MILITARY[id]
			if spec.scene != String(scene_id): return _fail("MILITARY_Y_WRONG_SCENE:" + id)
			var old_idle: String = EXAMINER if id == "spar_yamen_captain" else GUARD_IDLE
			var old_walk: String = GUARD_WALK if spec.moving else ""
			if original.get("sprite_path", "") != old_idle or original.get("walk_sprite_path", "") != old_walk or original.get("movement_mode", "idle") != ("patrol" if spec.moving else "idle"): return _fail("MILITARY_Y_ORIGINAL_VISUAL_OR_MOVEMENT_CHANGED:" + id)
			var style: Dictionary = ready.data.styles[spec.style]
			next["sprite_path"] = String(style.idle_path)
			# This successor changes no walk field at all. All seven deferred
			# patrol/canonical people retain their complete old rows unchanged.
			if String(style.portrait_path) != "": next["portrait_path"] = String(style.portrait_path)
			if _nonvisual(next) != _nonvisual(original): return _fail("MILITARY_Y_NONVISUAL_MUTATION:" + id)
			changed.append(id)
		output.append(next)
	return {"ok": true, "matched": not changed.is_empty(), "npcs": output, "changed_ids": changed, "presentation_only": true, "native_physics_and_task_primary_unchanged": true}
