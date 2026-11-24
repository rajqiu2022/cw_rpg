extends RefCounted
## NPC-row presentation only, after the unchanged h office projection.
## Never writes Scene, C record, geometry, movement, flags, quests or catalog.
const SELF := "res://scripts/city/luoyang_docks_roles_20261019ad.gd"
const INDEX := "res://scripts/city/luoyang_docks_roles_index_20261019ad.gd"
const MANIFEST := "res://data/luoyang_docks_roles_20261019ad/manifest.json"
const CITY := &"ch4_s2_canal_docks"
const FLAG := "--luoyang-docks-roles-20261019ad"
const CROWD := "res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd"
const OFFICE := "res://scripts/city/luoyang_docks_office_roles_20261016h.gd"
const HARBOUR := "res://scripts/city/luoyang_harbour_life_runtime_20261016.gd"
const ROLE_IDS := ["harbour_life_docks_rope_carrier", "harbour_life_docks_southern_carrier", "harbour_life_docks_west_carrier", "harbour_life_docks_store_attendant", "harbour_life_docks_rope_seller"]
const MOVING_IDS := ["harbour_life_docks_rope_carrier", "harbour_life_docks_southern_carrier", "harbour_life_docks_west_carrier"]
const VISUAL_KEYS := ["sprite_path", "walk_sprite_path", "portrait_path", "invert_patrol_facing"]
const ART_ROOT := "res://art/characters/luoyang_docks_roles_20261019ad/"
const PORTRAIT_ROOT := "res://art/characters/portraits/luoyang_docks_roles_20261019ad/"
const DIALOG_ROOT := "luoyang_docks_roles_20261019ad/"

static func _fail(error: String) -> Dictionary: return {"ok": false, "error": error}
static func _hash(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for c: String in value:
		if c not in "0123456789abcdef": return false
	return true
static func _wire(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value, "\t", true, true))
static func _equal(a: Variant, b: Variant) -> bool:
	return load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")._equal_value(_wire(a), _wire(b))
static func requested(id: StringName) -> bool:
	if id != CITY or OS.has_feature("web"): return false
	if FLAG in OS.get_cmdline_user_args(): return true
	var authority: Variant = load(INDEX)
	return authority is GDScript and authority.resource_path == INDEX and authority.formal_enabled() == true
static func _manifest() -> Dictionary:
	var authority: Variant = load(INDEX)
	if not authority is GDScript or authority.resource_path != INDEX: return {}
	var expected: Variant = authority.manifest_sha256()
	if not _hash(expected) or FileAccess.get_sha256(MANIFEST) != expected: return {}
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	return raw if raw is Dictionary else {}
static func _asset_names(id: String) -> Dictionary:
	var family: String = "strong_carrier" if id in MOVING_IDS else ("store_attendant" if id == ROLE_IDS[3] else "rope_seller")
	return {"sprite_path": ART_ROOT + "npc_docks_" + family + "_idle_down_1f_v1_runtime.png", "walk_sprite_path": ART_ROOT + "npc_docks_strong_carrier_walk_right_4f_v1_runtime.png" if id in MOVING_IDS else "", "portrait_path": PORTRAIT_ROOT + "portrait_docks_" + family + "_v1.png"}
static func _presentation_patch(id: String) -> Dictionary:
	var patch: Dictionary = _asset_names(id)
	# New authored sheet faces screen-right. This changes mirroring only, not sin/route.
	if id in MOVING_IDS: patch["invert_patrol_facing"] = false
	return patch
static func _dialog_id(id: String) -> String:
	if id in [ROLE_IDS[0], ROLE_IDS[1]]: return DIALOG_ROOT + "carrier_daily"
	if id == ROLE_IDS[2]: return DIALOG_ROOT + "west_porter_daily"
	return DIALOG_ROOT + ("store_attendant_daily" if id == ROLE_IDS[3] else "rope_seller_daily")
static func readiness() -> Dictionary:
	var spec: Dictionary = _manifest()
	if spec.get("schema_version") != 1 or spec.get("status") != "READY_SOURCE_BOUND_DOCKS_ROLES" or spec.get("scene_id") != String(CITY): return _fail("DOCKS_ROLES_MANIFEST_NOT_READY")
	if not spec.get("roles") is Array or spec.roles.is_empty() or spec.roles.size() > ROLE_IDS.size() or not spec.get("source_sha256") is Dictionary or spec.source_sha256.is_empty(): return _fail("DOCKS_ROLES_MANIFEST_DOMAIN")
	for path: Variant in spec.source_sha256:
		if not path is String or not path.begins_with("res://") or ".." in path or path in [SELF, INDEX, MANIFEST] or not _hash(spec.source_sha256[path]) or FileAccess.get_sha256(path) != spec.source_sha256[path]: return _fail("DOCKS_ROLES_SOURCE_CHANGED")
	for path: String in [CROWD, OFFICE]:
		if not spec.source_sha256.has(path): return _fail("DOCKS_ROLES_PARENT_SOURCE_MISSING")
	var seen: Dictionary = {}
	for role: Variant in spec.roles:
		if not role is Dictionary or role.size() != 3 or not role.get("npc_id") is String or not role.get("patch") is Dictionary or not role.get("ambient_dialog") is String: return _fail("DOCKS_ROLES_ROLE_DOMAIN")
		var id: String = role.npc_id
		if id not in ROLE_IDS or seen.has(id): return _fail("DOCKS_ROLES_UNKNOWN_OR_DUPLICATE")
		seen[id] = true
		var names: Dictionary = _asset_names(id)
		if not _equal(role.patch, _presentation_patch(id)): return _fail("DOCKS_ROLES_ASSET_IDENTITY_OR_WALK_PAIR")
		for path: String in names.values():
			if not path.is_empty() and not spec.source_sha256.has(path): return _fail("DOCKS_ROLES_ASSET_NOT_SOURCE_BOUND")
		if not role.ambient_dialog.is_empty():
			if role.ambient_dialog != _dialog_id(id) or not spec.source_sha256.has("res://data/dialogs/" + role.ambient_dialog + ".tres"): return _fail("DOCKS_ROLES_AMBIENT_DIALOG_NOT_BOUND")
	return {"ok": true, "spec": spec, "role_ids": seen.keys()}
static func source_paths() -> Dictionary:
	# This also describes the disabled candidate, once its manifest is frozen.
	var paths: Dictionary = {SELF: true, INDEX: true, MANIFEST: true}
	var ready: Dictionary = readiness()
	if ready.get("ok") != true: return paths
	for path: String in ready.spec.source_sha256: paths[path] = true
	return paths
static func _parent(scene: SceneScript) -> Dictionary:
	var harbour: Variant = load(HARBOUR)
	if scene == null or scene.scene_id != CITY or not harbour.bound(scene): return _fail("DOCKS_ROLES_NATIVE_OWNER")
	var crowd: Variant = load(CROWD)
	var office: Variant = load(OFFICE)
	return office.project_npcs(scene, crowd.project(CITY))
static func compose_exact(original: Array, parent: Array, spec: Dictionary) -> Dictionary:
	# Pure value plan only. Runtime authority/readiness/Scene ownership lives in project().
	if original.size() != 10 or not _equal(original, parent): return _fail("DOCKS_ROLES_EXACT_POST_OFFICE_PARENT_CHANGED")
	if not spec.get("roles") is Array or spec.roles.is_empty() or spec.roles.size() > ROLE_IDS.size(): return _fail("DOCKS_ROLES_PARTIAL_PLAN_DOMAIN")
	var out: Array = original.duplicate(true)
	var seen: Dictionary = {}
	for row: Variant in out:
		if not row is Dictionary or not row.get("npc_id") is String or seen.has(row.npc_id): return _fail("DOCKS_ROLES_PARENT_DUPLICATE_OR_TYPE")
		seen[row.npc_id] = true
	var changed: Array[String] = []
	for raw_role: Variant in spec.roles:
		if not raw_role is Dictionary or raw_role.size() != 3 or not raw_role.get("npc_id") is String or not raw_role.get("patch") is Dictionary or not raw_role.get("ambient_dialog") is String: return _fail("DOCKS_ROLES_PARTIAL_ROLE_DOMAIN")
		var role: Dictionary = raw_role
		var id: String = String(role.get("npc_id", ""))
		if id not in ROLE_IDS or id in changed or not seen.has(id) or not role.get("patch") is Dictionary or not _equal(role.patch, _presentation_patch(id)): return _fail("DOCKS_ROLES_INVALID_PARTIAL_PLAN")
		var index: int = -1
		for i: int in out.size():
			if out[i].npc_id == id: index = i
		if index < 0: return _fail("DOCKS_ROLES_EXACT_ID_MISSING")
		var before: Dictionary = original[index]
		var row: Dictionary = out[index]
		if before.get("harbour_life_ground_anchored") != true or before.get("scale") != 1.0 or before.get("movement_mode") != ("patrol" if id in MOVING_IDS else "idle"): return _fail("DOCKS_ROLES_ORIGINAL_CALIBRATION_OR_MOVEMENT_CHANGED")
		for key: String in VISUAL_KEYS:
			if role.patch.has(key): row[key] = role.patch[key]
		var dialog: String = String(role.get("ambient_dialog", ""))
		if not dialog.is_empty():
			if dialog != _dialog_id(id) or not String(before.get("dialog_id", "")).is_empty() or not String(before.get("interaction_action", "")).is_empty() or not before.get("dialog_variants", []).is_empty(): return _fail("DOCKS_ROLES_WOULD_OVERRIDE_PRIMARY")
			row.dialog_id = dialog
		# Exact non-visual inverse, including key presence rather than empty-key substitution.
		var inverse: Dictionary = row.duplicate(true)
		for key: String in VISUAL_KEYS + ["dialog_id"]:
			if before.has(key): inverse[key] = before[key]
			else: inverse.erase(key)
		if not _equal(inverse, before): return _fail("DOCKS_ROLES_NON_VISUAL_MUTATION")
		changed.append(id)
	return {"ok": true, "npcs": out, "changed_ids": changed, "geometry_modified": false, "movement_modified": false, "native_body_px": Vector2(22.4, 28.8)}
static func project(scene: SceneScript, original: Array) -> Dictionary:
	if scene == null: return _fail("DOCKS_ROLES_SCENE_NULL")
	if not requested(scene.scene_id): return {"ok": true, "npcs": original.duplicate(true), "matched": false}
	var ready: Dictionary = readiness()
	if ready.get("ok") != true: return ready
	var parent: Dictionary = _parent(scene)
	if parent.get("ok") != true: return parent
	var result: Dictionary = compose_exact(original, parent.npcs, ready.spec)
	if result.get("ok") == true: result["matched"] = true
	return result
