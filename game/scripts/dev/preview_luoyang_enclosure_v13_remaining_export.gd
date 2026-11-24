extends "res://scripts/dev/preview_luoyang_enclosure_v11_export.gd"
## NEW raw-only three-region composite, optionally binding actual NEW ground.
## Existing V11 five-view evidence/source is never modified or overwritten.

func _initialize() -> void: call_deferred("_remaining_start")
func _remaining_start() -> void:
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"): _finish("Public checkpoint guard unavailable"); return
	bridge.call("set_checkpoint_saves_suspended",true)
	if bridge.call("is_checkpoint_saves_suspended") != true: _finish("Public checkpoint guard not acknowledged"); return
	var region := ""; var tag := ""; var patch_sha := ""; var ground_path := ""; var ground_sha := ""
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for arg: String in args:
		if arg.begins_with("--region="): region = arg.trim_prefix("--region=")
		if arg.begins_with("--preview-run-tag="): tag = arg.trim_prefix("--preview-run-tag=")
		if arg.begins_with("--expected-patch-sha="): patch_sha = arg.trim_prefix("--expected-patch-sha=").to_lower()
		if arg.begins_with("--ground-capture="): ground_path = arg.trim_prefix("--ground-capture=")
		if arg.begins_with("--expected-ground-sha="): ground_sha = arg.trim_prefix("--expected-ground-sha=").to_lower()
	if not "--preview-luoyang-enclosure-v13-export" in args or DisplayServer.get_name() == "headless" or not C.owns_id(StringName(region)) or not tag.is_valid_identifier() or not C._hash(patch_sha) or ground_path.is_empty() != ground_sha.is_empty(): _finish("Explicit unique GPU region preview and frozen actual manifest required"); return
	_output = "res://build/luoyang_enclosure_v13_export_preview/"+tag+"/"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_output)): _finish("Existing preview evidence must be preserved"); return
	var id := StringName(region)
	var patch_path: String = C.ROOT+region+"/art_patch.json"
	if not _track(patch_path,patch_sha) or not _track(C.base_manifest_path(id),C.base_manifest_sha(id)): _finish(_error); return
	var patch_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(patch_path))
	var base_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(C.base_manifest_path(id)))
	if not patch_raw is Dictionary or not base_raw is Dictionary: _finish("Actual patch/base unreadable"); return
	var patch: Dictionary = patch_raw; var baseline: Dictionary = base_raw
	if patch.get("canonical_scene_id") != region or patch.get("status") != "GPU_EXPORTED_REQUIRES_FIELD_VISUAL_QA" or patch.get("base_manifest_sha256") != C.base_manifest_sha(id): _finish("Actual region patch identity differs"); return
	for catalog: Dictionary in [patch.asset_sha256,baseline.asset_sha256]:
		for path: String in catalog:
			if not _track(path,String(catalog[path])): _finish(_error); return
	for path: String in [get_script().resource_path,"res://scripts/dev/preview_luoyang_enclosure_v11_export.gd","res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"]:
		if not _track(path): _finish(_error); return
	var removed: Dictionary = {}
	for oid: String in patch.remove_object_ids: removed[oid] = false
	for object: Dictionary in baseline.objects:
		if removed.has(String(object.id)): removed[String(object.id)] = true
		else: _objects.append(object)
	for oid: String in removed:
		if not removed[oid]: _finish("Removed identity not in frozen BASE"); return
	_objects.append_array(patch.objects)
	_objects.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		var az: int = int(a.get("z_index",0)); var bz: int = int(b.get("z_index",0))
		return az < bz if az != bz else float(a.depth_foot_y) < float(b.depth_foot_y))
	_ground = String(baseline.ground_path)
	if not ground_path.is_empty():
		if not C._hash(ground_sha) or not _track(ground_path,ground_sha): _finish("Frozen actual new ground missing"); return
		var ground_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ground_path))
		if not ground_raw is Dictionary or ground_raw.get("canonical_scene_id") != region or ground_raw.get("status") != "NATIVE_GROUND_GPU_CAPTURE_REQUIRES_VISUAL_FIELD_REVIEW" or ground_raw.get("export_plan_sha256") != patch.export_plan_sha256 or not C._equal_value(ground_raw.get("requested_remove_object_ids"),patch.remove_object_ids): _finish("Actual new ground not bound to exact same region/author removals"); return
		for path: String in ground_raw.asset_sha256:
			if not _track(path,String(ground_raw.asset_sha256[path])): _finish(_error); return
		_ground = String(ground_raw.ground_path)
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output)) != OK: _finish("Unique preview directory failed"); return
	var specs: Array = [{"name":"full_region","rect":Rect2i(0,0,3072,2048)}]
	if region == "ch4_s2_canal_docks": specs.append_array([{"name":"dry_deck_cargo_quay","rect":Rect2i(1520,1100,910,850)},{"name":"water_boat_canal","rect":Rect2i(2190,920,820,1050)}])
	elif region == "ch4_s0_luoyang_gate": specs.append_array([{"name":"west_plot_entrance","rect":Rect2i(140,660,1130,840)},{"name":"east_plot_warehouse_stall","rect":Rect2i(1800,560,1220,1000)}])
	elif region == "ch4_s3_luoyang_market": specs.append_array([{"name":"north_market_roof_margin","rect":Rect2i(750,0,1590,920)},{"name":"south_market_blocks","rect":Rect2i(80,1060,2910,910)}])
	else: specs.append_array([{"name":"west_court_no_old_wall_cast","rect":Rect2i(760,280,660,1510)},{"name":"east_court_no_old_wall_cast","rect":Rect2i(1680,280,720,1510)}])
	for spec: Dictionary in specs:
		if not await _capture(String(spec.name),spec.rect): _finish(_error); return
	_finish("")
