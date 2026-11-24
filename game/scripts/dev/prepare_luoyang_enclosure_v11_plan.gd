extends SceneTree
## Plan conversion only. No GPU, import, Field, publication or activation.
const C = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const AUTHOR = preload("res://scripts/dev/luoyang_yamen_complete_walls_v11_preview.gd")
const AUTHOR_PATH := "res://scripts/dev/luoyang_yamen_complete_walls_v11_preview.gd"
const AUTHOR_SHA := "8f01167354e6fa3274b463f11180e23441874144f923b0fd25611117b865fd67"
const RECORD_PATH := "res://art/maps/luoyang_enclosure_v11/source/v11b_generation_record.json"
const RECORD_SHA := "061ea0f7afb77c91f5fae2db32baf46e8c5c026aea8b858d78012a238d827357"
const ID := &"ch4_s1_luoyang_yamen"
const REMOVED := ["court_wall_960_780", "court_wall_960_940", "court_wall_960_1360", "court_wall_960_1520", "court_wall_960_1680", "court_wall_2110_780", "court_wall_2110_940", "court_wall_2110_1360", "court_wall_2110_1520", "court_wall_2110_1680", "court_southwest_wing", "court_southeast_wing", "south_court_gate"]

func _initialize() -> void: call_deferred("_prepare_plan")
func _prepare_plan() -> void:
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"): _finish("Public checkpoint suspension unavailable"); return
	bridge.call("set_checkpoint_saves_suspended", true)
	if bridge.call("is_checkpoint_saves_suspended") != true: _finish("Public checkpoint suspension not acknowledged"); return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not "--prepare-luoyang-enclosure-v11-plan" in args or "--activate" in args or "--publish-candidate" in args: _finish("Explicit plan preparation only"); return
	var path: String = C.ROOT + String(ID) + "/export_plan.json"
	if FileAccess.file_exists(path): _finish("Existing authoring plan must be preserved; choose NEW revision"); return
	if FileAccess.get_sha256(AUTHOR_PATH) != AUTHOR_SHA or FileAccess.get_sha256(RECORD_PATH) != RECORD_SHA or FileAccess.get_sha256(C.base_manifest_path(ID)) != C.base_manifest_sha(ID): _finish("Pinned author/helper/provenance/base bytes changed"); return
	var source: AUTHOR = AUTHOR.new()
	if not source.prepare(): _finish(source.error); return
	var catalog: Dictionary = source.source_catalog()
	catalog[AUTHOR_PATH] = AUTHOR_SHA; catalog[RECORD_PATH] = RECORD_SHA
	catalog[get_script().resource_path] = FileAccess.get_sha256(get_script().resource_path)
	for asset: String in catalog:
		if FileAccess.get_sha256(asset) != catalog[asset]: source.release(); _finish("Copied source differs from actual original: " + asset); return
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(C.base_manifest_path(ID)))
	if not raw is Dictionary or not raw.get("objects") is Array: source.release(); _finish("Frozen base author record invalid"); return
	var baseline: Dictionary = raw
	var found: Dictionary = {}
	var retained: Array[String] = []
	for object: Dictionary in baseline.objects:
		if String(object.id) in REMOVED: found[String(object.id)] = true
		else: retained.append(String(object.id))
	if found.size() != REMOVED.size(): source.release(); _finish("Exact thirteen original wall/gate replacements missing"); return
	var records: Array = source.author_records()
	var ids: Dictionary = {}
	var pieces := 0
	for author: Dictionary in records:
		if ids.has(String(author.id)) or String(author.id) in retained or not C._object_solids_valid(author): source.release(); _finish("Author group ID/solid invalid"); return
		ids[String(author.id)] = true; pieces += author.pieces.size()
	if records.size() != 11 or pieces != 13 or not ids.has("south_court_gate"): source.release(); _finish("Exact eleven real Y-groups/thirteen UV pieces required"); return
	var observed: Dictionary = source.authoring_observations()
	if observed.get("original_short_run_not_claimed_complete") != true or observed.get("old_v9_front_not_under_drawn") != true or observed.get("central_gate_source_uv_preserved") != true or observed.get("open_ground_y") != [940, 1200]: source.release(); _finish("Modular run/old-wall removal/ground passage declaration differs"); return
	var plan := {"schema_version": 1, "canonical_scene_id": String(ID), "status": "ROOT_APPROVED_AUTHORING_REQUIRES_GPU_FIELD_VISUAL", "base_manifest_path": C.base_manifest_path(ID), "base_manifest_sha256": C.base_manifest_sha(ID), "remove_object_ids": REMOVED, "source_catalog": catalog, "objects": records, "authoring_observations": observed, "retained_object_ids": retained, "original_gameplay_slots_unchanged": true, "original_routes_unchanged": true, "alpha_bbox_is_not_physical_foot": true, "source_bitmap_modified": false, "generated_complete_run_claim": false, "production_approved": false, "field_approved": false, "visual_approved": false}
	source.release()
	for asset: String in catalog:
		if FileAccess.get_sha256(asset) != catalog[asset]: _finish("Source changed during plan preparation"); return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir())) != OK: _finish("Independent plan directory creation failed"); return
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null: _finish("Plan write failed"); return
	file.store_string(JSON.stringify(plan, "\t", false)); file.flush()
	var error: Error = file.get_error(); file.close()
	if error != OK: _finish("Plan write/flush failed"); return
	print("LUOYANG_V11_AUTHOR_PLAN_ONLY_NOT_GPU_FIELD_APPROVED " + path + " SHA=" + FileAccess.get_sha256(path))
	_finish("")
func _finish(error: String) -> void:
	if not error.is_empty(): push_error(error)
	quit(0 if error.is_empty() else 1)
