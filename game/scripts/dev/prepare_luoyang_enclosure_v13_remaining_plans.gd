extends SceneTree
## NEW three-region author conversion; no GPU/Field/candidate/formal writes.
const C = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const STREET = preload("res://scripts/dev/luoyang_gate_market_street_blocks_v13_preview.gd")
const STREET_PATH := "res://scripts/dev/luoyang_gate_market_street_blocks_v13_preview.gd"
const STREET_SHA := "2572239a85dad5fa1d04c3ca15ed9ae6e752fadb931d26ad5524307eb39f5674"
const NATIVE_CAPTURE := "res://art/maps/luoyang_enclosure_v11/ch4_s2_canal_docks/native_v12/root_native_docks_v12_01/native_capture.json"
const NATIVE_SHA := "967acaa0dcec425957db27ca482fb507569e307cadeadf624518fc9286e2b524"
const FROZEN_EXPORT := "res://scripts/dev/export_luoyang_enclosure_v11_candidate.gd"
const FROZEN_EXPORT_SHA := "7493ecc658d5548c687e3f0d0da041d71e9f8c318215bee7f9f3491f0ba60ea9"
const REGIONS := ["ch4_s0_luoyang_gate","ch4_s2_canal_docks","ch4_s3_luoyang_market"]
var failure := ""

func _initialize() -> void: call_deferred("_prepare_remaining")
func _prepare_remaining() -> void:
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"): _finish("Public checkpoint suspension unavailable"); return
	bridge.call("set_checkpoint_saves_suspended",true)
	if bridge.call("is_checkpoint_saves_suspended") != true: _finish("Checkpoint suspension not acknowledged"); return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var region := ""
	for arg: String in args:
		if arg.begins_with("--region="): region = arg.trim_prefix("--region=")
	if not "--prepare-luoyang-enclosure-v13-plan" in args or region not in REGIONS or "--activate" in args or "--publish-candidate" in args: _finish("Explicit one-region author conversion only"); return
	var path: String = C.ROOT + region + "/export_plan.json"
	if FileAccess.file_exists(path): _finish("Existing author plan must remain immutable"); return
	var base_path: String = C.base_manifest_path(StringName(region))
	if FileAccess.get_sha256(base_path) != C.base_manifest_sha(StringName(region)): _finish("Original region BASE changed"); return
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(base_path))
	if not raw is Dictionary: _finish("Original region author record unreadable"); return
	var baseline: Dictionary = raw
	var catalog: Dictionary = {get_script().resource_path:FileAccess.get_sha256(get_script().resource_path),FROZEN_EXPORT:FROZEN_EXPORT_SHA}
	var author_records: Array = []; var remove: Array = []; var observed: Dictionary = {}
	if region == "ch4_s2_canal_docks":
		if not _native_plan(author_records,remove,catalog,observed): _finish(failure); return
	else:
		if FileAccess.get_sha256(STREET_PATH) != STREET_SHA: _finish("Approved current street helper changed"); return
		var street: STREET = STREET.new()
		if not street.prepare(region): _finish(street.error); return
		for asset: String in street.source_catalog(): catalog[asset] = street.source_catalog()[asset]
		catalog[STREET_PATH] = STREET_SHA; catalog[STREET.MODULE_SEM] = STREET.MODULE_SEM_SHA
		# Gate reuses a frozen market source footprint, so bind that original
		# author record independently as well as the four PNG/module semantics.
		for id: String in [STREET.GATE,STREET.MARKET]: catalog[STREET.BASE_ROOT+id+"/art_contract.json"] = STREET.BASE_SHA[id]
		author_records = street.author_records(region); remove = street.remove_object_ids(region)
		observed = street.authoring_observations()
		var context: Dictionary = street.protected_context()
		if not C._equal_value(context.routes,baseline.routes) or not C._equal_value(context.gameplay_slots,baseline.gameplay_slots): street.release(); _finish("Protected routes/gameplay context changed"); return
		if not street.error.is_empty(): var reason: String = street.error; street.release(); _finish(reason); return
		street.release()
	var removed: Dictionary = {}; var retained: Array[String] = []; var ids: Dictionary = {}
	for oid: String in remove:
		if removed.has(oid): _finish("Duplicate removed identity"); return
		removed[oid] = false
	for object: Dictionary in baseline.objects:
		if removed.has(String(object.id)): removed[String(object.id)] = true
		else: retained.append(String(object.id))
	for oid: String in removed:
		if not removed[oid]: _finish("Exact original object replacement missing: " + oid); return
	for object: Dictionary in author_records:
		if ids.has(String(object.id)) or String(object.id) in retained or not C._object_solids_valid(object) or not object.get("pieces") is Array or object.pieces.is_empty(): _finish("New author identity/foot/solid invalid"); return
		var roles: Dictionary = object.duplicate(true)
		roles.ghost_occlusion = object.get("ghost_occlusion",true)
		if not C._object_render_role_valid(StringName(region),roles): _finish("Invalid explicit author ghost/support/sort role"); return
		ids[String(object.id)] = true
	var count: int = 6 if region in [STREET.GATE,"ch4_s2_canal_docks"] else 5
	if author_records.size() != count: _finish("Exact region author group count differs"); return
	for asset: String in catalog:
		if FileAccess.get_sha256(asset) != catalog[asset]: _finish("Author source/copy bytes differ: " + asset); return
	var plan := {"schema_version":1,"canonical_scene_id":region,"status":"ROOT_APPROVED_AUTHORING_REQUIRES_GPU_FIELD_VISUAL","base_manifest_path":base_path,"base_manifest_sha256":C.base_manifest_sha(StringName(region)),"remove_object_ids":remove,"source_catalog":catalog,"objects":author_records,"authoring_observations":observed,"retained_object_ids":retained,"original_gameplay_slots_unchanged":true,"original_routes_unchanged":true,"alpha_bbox_is_not_physical_foot":true,"source_bitmap_modified":false,"additional_walk_support":false,"production_approved":false,"field_approved":false,"visual_approved":false}
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir())) != OK: _finish("Independent plan directory failed"); return
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if file == null: _finish("Independent plan write failed"); return
	file.store_string(JSON.stringify(plan,"\t",false)); file.flush()
	var status: Error = file.get_error(); file.close()
	if status != OK: _finish("Plan write/flush failed"); return
	print("LUOYANG_V13_AUTHOR_PLAN_ONLY " + path + " SHA=" + FileAccess.get_sha256(path))
	_finish("")

func _native_plan(records: Array, remove: Array, catalog: Dictionary, observed: Dictionary) -> bool:
	if FileAccess.get_sha256(NATIVE_CAPTURE) != NATIVE_SHA: failure = "Actual395 capture changed"; return false
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(NATIVE_CAPTURE))
	if not raw is Dictionary or raw.get("status") != "NATIVE_GPU_CAPTURE_REQUIRES_VISUAL_FIELD_REVIEW" or raw.get("canonical_scene_id") != "ch4_s2_canal_docks" or not raw.get("objects") is Array or raw.objects.size() != 2 or not raw.get("existing_cargo_records") is Array or raw.existing_cargo_records.size() != 4: failure = "Actual native/cargo record schema differs"; return false
	catalog[NATIVE_CAPTURE] = NATIVE_SHA
	for asset: String in raw.source_catalog: catalog[asset] = raw.source_catalog[asset]
	for asset: String in raw.asset_sha256: catalog[asset] = raw.asset_sha256[asset]
	for native: Dictionary in raw.objects:
		var size: Vector2 = C._vec(native.source_size_px)
		var record := {"id":native.id,"world_foot_px":native.world_foot_px,"physical_center_px":native.physical_center_px,"depth_foot_y":native.world_foot_px[1],"collision_size_px":[0,0],"solid_polygons_px":[],"blocking":false,"ghost_occlusion":false,"walk_support":false,"role":native.role,"source_kind":"actual_native_gpu_capture","actual_native_capture_path":NATIVE_CAPTURE,"actual_native_capture_sha256":NATIVE_SHA,"original_native_record":native.duplicate(true),"pieces":[{"source":native.texture,"uv_polygon_px":[[0,0],[size.x,0],[size.x,size.y],[0,size.y]],"origin_px":native.world_origin_px,"scale":1.}],"foot_authority":"Exact actual camera projection of authored local anchor0; crop includes anchor, not inferred alpha bottom"}
		if native.role == "ground_overlay": record.z_index = -2; record.sort_by_feet = false
		elif native.role == "water_decoration": record.sort_by_feet = true; record.interaction_required = false
		else: failure = "Unexpected actual native role"; return false
		records.append(record); remove.append(String(native.id))
	for cargo: Dictionary in raw.existing_cargo_records:
		var size: Vector2 = C._vec(cargo.source_size_px)
		records.append({"id":cargo.id,"world_foot_px":cargo.world_foot_px,"physical_center_px":cargo.world_foot_px,"collision_size_px":[0,0],"solid_polygons_px":cargo.solid_polygons_px,"blocking":true,"pieces":[{"source":cargo.source,"uv_polygon_px":[[0,0],[size.x,0],[size.x,size.y],[0,size.y]],"origin_px":cargo.origin_px,"scale":cargo.scale}],"foot_authority":"Original detailed cargo source manual foot257,459 and independent4-vertex ground; existing story id retained","original_cargo_record":cargo.duplicate(true)})
		remove.append(String(cargo.id))
	observed.merge({"actual_native_capture_path":NATIVE_CAPTURE,"actual_native_capture_sha256":NATIVE_SHA,"scope":"Actual deck/boat and original detailed cargo6 replacement groups; not approved final art/Field","additional_walk_support":false,"water_sort":"Explicit mooring footY, noninteractive/nonblocking/ghostfalse","native_material":"Project original procedural timber and grey canvas, not CC0 scan; root noted simple-model appearance","currentframe_alpha_and_legal_actor_domain":"PENDING independent Field proof"})
	return true

func _finish(reason: String) -> void:
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or bridge.call("is_checkpoint_saves_suspended") != true: reason = "Checkpoint suspension lost; " + reason
	if not reason.is_empty(): push_error(reason)
	quit(0 if reason.is_empty() else 1)
