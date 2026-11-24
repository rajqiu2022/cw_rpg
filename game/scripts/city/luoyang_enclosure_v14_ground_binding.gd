extends RefCounted
## Small independently SHA-bound native ground sidecar reader. No publishing,
## synthetic shadow proxies, support/mask mutation or inferred caster geometry.
const BASE = preload("res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd")
const SOURCE = preload("res://scripts/dev/luoyang_modular_v3_source.gd")
const DOMAIN = preload("res://scripts/dev/luoyang_ground_v14_serialized_domain.gd")

static func _reject(reason: String) -> Dictionary: return {"error":reason}
static func read(binding: Dictionary, id: StringName, prefix: String, base_record: Dictionary, plan: Dictionary, plan_sha: String, cpu_context: RefCounted = null) -> Dictionary:
	var path: Variant = binding.get("path")
	var sha: Variant = binding.get("sha256")
	if not path is String or not path.begins_with(prefix+"ground_v14/") or not path.ends_with("/ground_capture.json") or ".." in path or not BASE._hash(sha) or FileAccess.get_sha256(path) != sha: return _reject("Ground native capture path/SHA is PENDING or changed")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary: return _reject("Malformed native ground capture")
	var record: Dictionary = parsed
	var base_path: String = BASE.ROOT+String(id)+"/art_contract.json"
	if record.get("canonical_scene_id") != String(id) or record.get("status") != "NATIVE_GROUND_GPU_CAPTURE_REQUIRES_VISUAL_FIELD_REVIEW" or record.get("base_manifest_path") != base_path or record.get("base_manifest_sha256") != BASE.MANIFEST_SHAS[String(id)] or record.get("export_plan_path") != prefix+"export_plan.json" or record.get("export_plan_sha256") != plan_sha or not BASE._equal_value(record.get("requested_remove_object_ids"),plan.get("remove_object_ids")): return _reject("Native ground bound to wrong original/region/author removal")
	for key: String in ["actual_on_off_repeat_exact","original_support_paving_material_arrays_unchanged","original_vertex_contact_dirt_unchanged"]:
		if record.get(key) != true: return _reject("Native ground capture must preserve original geometry/material/contact and actual repeats")
	for key: String in ["png_wall_proxy_casters","navigation_or_height_changed","production_approved","visual_approved","field_approved"]:
		if record.get(key) != false: return _reject("Native ground cannot grant proxy/support/approval credit")
	if not BASE._equal_value(record.get("capture_camera"),base_record.get("capture_camera")): return _reject("Native ground camera/light differs from original")
	var catalog: Variant = record.get("asset_sha256")
	if not catalog is Dictionary or catalog.is_empty(): return _reject("Ground complete original/new native catalog missing")
	if cpu_context != null and (cpu_context.get_script() != BASE.CPU_WORKSPACE or not base_record.get("asset_sha256") is Dictionary or not cpu_context.matches_input(id, BASE.ROOT+String(id)+"/", base_record, base_record.asset_sha256)): return _reject("Unbound/cancelled live native ground source receipt")
	for asset: Variant in catalog:
		if not asset is String or not asset.begins_with("res://") or ".." in asset or not BASE._hash(catalog[asset]) or (FileAccess.get_sha256(asset) if cpu_context == null else cpu_context.source_sha(id, asset)) != catalog[asset]: return _reject("Changed frozen native ground source/output: "+str(asset))
	for asset: String in base_record.asset_sha256:
		if catalog.get(asset) != base_record.asset_sha256[asset]: return _reject("Ground native capture omitted/changed old support/paving/material source")
	for asset: String in plan.source_catalog:
		if catalog.get(asset) != plan.source_catalog[asset]: return _reject("Ground native capture omitted actual new source/mesh")
	var removed: Array[String] = []; var retained: Array[String] = []; var added: Array[String] = []
	for old: Dictionary in base_record.objects:
		if not old.has("native_transform"): continue
		if String(old.id) in plan.remove_object_ids: removed.append(String(old.id))
		else: retained.append(String(old.id))
	for authored: Dictionary in plan.objects:
		if authored.get("source_kind") == "actual_native_gpu_capture": added.append(String(authored.id))
	if not BASE._equal_value(record.get("removed_old_caster_ids"),removed) or not BASE._equal_value(record.get("added_native_caster_ids"),added) or not record.get("retained_or_new_casters") is Array or record.retained_or_new_casters.size() != retained.size()+added.size(): return _reject("Ground removed/retained/new actual caster set changed")
	var ids: Array[String] = []; ids.append_array(retained); ids.append_array(added)
	for index: int in ids.size():
		var caster: Variant = record.retained_or_new_casters[index]
		if not caster is Dictionary or caster.get("id") != ids[index] or caster.get("actual_saved_mesh_only") != true or caster.get("added395") != (ids[index] in added) or not catalog.has(caster.get("native_mesh_path")) or catalog[caster.native_mesh_path] != caster.get("native_mesh_sha256"): return _reject("Ground caster identity/native mesh binding changed")
		var expected_mesh := ""; var expected_pose: Transform3D
		if ids[index] in retained:
			var old: Dictionary = {}
			for value: Dictionary in base_record.objects:
				if String(value.id) == ids[index]: old = value; break
			var meta_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(String(old.get("metadata_path",""))))
			if not meta_raw is Dictionary or not old.get("native_transform") is Dictionary: return _reject("Original caster native metadata/pose missing")
			expected_mesh = String(meta_raw.get("native_mesh_path",""))
			var pose: Dictionary = old.native_transform; var cols: Array = pose.basis_columns
			expected_pose = Transform3D(Basis(_v3(cols[0]),_v3(cols[1]),_v3(cols[2])),_v3(pose.origin))
		else:
			var authored: Dictionary = {}
			for value: Dictionary in plan.objects:
				if String(value.id) == ids[index]: authored = value; break
			var native: Variant = authored.get("original_native_record")
			if not native is Dictionary or not BASE._equal_value(native.get("draw_transform"),DOMAIN.stored({"basis_columns":[[1.,0.,0.],[0.,1.,0.],[0.,0.,1.]],"origin_m":[0.,0.,0.]})) or not BASE._equal_value(native.get("local_ground_anchor_m"),DOMAIN.stored([0.,0.,0.])): return _reject("Actual395 caster must retain original identity/G0 anchor")
			expected_mesh = String(native.get("native_mesh_path",""))
			expected_pose = Transform3D(Basis.IDENTITY,SOURCE.point3(BASE._vec(authored.world_foot_px)))
		var expected: Variant = DOMAIN.stored({"basis_columns":[_array(expected_pose.basis.x),_array(expected_pose.basis.y),_array(expected_pose.basis.z)],"origin_m":_array(expected_pose.origin)})
		if caster.native_mesh_path != expected_mesh or not BASE._equal_value(caster.get("basis_columns"),expected.basis_columns) or not BASE._equal_value(caster.get("origin_m"),expected.origin_m): return _reject("Ground caster changed original mesh/basis/origin pose")
	var floor_path: Variant = record.get("ground_path")
	if not floor_path is String or floor_path != path.get_base_dir()+"/floor.png" or not catalog.has(floor_path) or not BASE._png_size(floor_path,Vector2i(BASE.SIZE)) or not ResourceLoader.exists(floor_path): return _reject("Native ground independent3072x2048 PNG missing/unimported")
	var source: Image = Image.load_from_file(floor_path)
	var texture: Texture2D = ResourceLoader.load(floor_path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var imported: Image = texture.get_image() if texture != null else null
	if source == null or imported == null or (imported.is_compressed() and imported.decompress() != OK): return _reject("Native ground original/import PNG unreadable")
	source.convert(Image.FORMAT_RGBA8); imported.convert(Image.FORMAT_RGBA8)
	if source.get_size() != imported.get_size() or source.get_data() != imported.get_data().slice(0,source.get_width()*source.get_height()*4): return _reject("Native ground imported pixels differ from actual captured PNG")
	return {"ground_path":floor_path,"ground_capture_path":path,"ground_capture_sha256":sha,"asset_sha256":catalog.duplicate(true)}

static func _v3(raw: Array) -> Vector3: return Vector3(raw[0],raw[1],raw[2])
static func _array(value: Vector3) -> Array: return [value.x,value.y,value.z]
