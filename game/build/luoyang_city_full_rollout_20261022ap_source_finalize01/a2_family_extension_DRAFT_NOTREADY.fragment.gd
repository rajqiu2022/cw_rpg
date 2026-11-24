const A2_READY=false
const A2_BINDING="res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/a2_runtime_draft01/a2_binding_DRAFT_NOTREADY.json"
const A2_BINDING_SHA=""
static var _a2_fixed_binding: Dictionary={}
static func _a2_spec() -> Dictionary:
	if not A2_READY or not b()._hash(A2_BINDING_SHA): return {}
	if not _a2_fixed_binding.is_empty(): return _a2_fixed_binding
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(A2_BINDING)
	if b().bytes_sha(bytes)!=A2_BINDING_SHA: return {}
	var value: Variant=JSON.parse_string(bytes.get_string_from_utf8())
	if not value is Dictionary or value.get("status")!="ROOT_FIXED_A2_ARTISAN_NATIVE_AND_ART_BINDING" or value.get("ready")!=true or value.get("scene_id")!=String(IDS[0]): return {}
	for key: String in ["child","parent"]:
		if not value.get(key) is Dictionary: return {}
		for suffix: String in ["scene.res","layout.res","packet.bin","walk.png"]:
			var leaf: Dictionary=value[key].get(suffix,{})
			if not leaf.get("path") is String or ".." in leaf.path or not leaf.path.begins_with("res://") or not b()._hash(leaf.get("sha256")): return {}
	for key: String in ["publisher_report","root_art_admission"]:
		var leaf: Dictionary=value.get(key,{})
		if not leaf.get("path") is String or not leaf.path.begins_with("res://build/") or ".." in leaf.path or not b()._hash(leaf.get("sha256")) or FileAccess.get_sha256(leaf.path)!=leaf.sha256: return {}
	var report: Variant=JSON.parse_string(FileAccess.get_file_as_string(value.publisher_report.path))
	var art: Variant=JSON.parse_string(FileAccess.get_file_as_string(value.root_art_admission.path))
	if not report is Dictionary or report.get("passed")!=true or report.get("published")!=true or not art is Dictionary or art.get("approved_by_root")!=true: return {}
	if art.get("publisher_report",{}).get("path")!=value.publisher_report.path or art.get("publisher_report",{}).get("sha256")!=value.publisher_report.sha256: return {}
	for suffix: String in value.child:
		if report.get("artifacts",{}).get(value.child[suffix].path)!=value.child[suffix].sha256: return {}
	if not value.get("source_sha256") is Dictionary or not value.get("local_domains_xywh") is Array or value.local_domains_xywh.size()!=8: return {}
	_a2_fixed_binding=value
	return _a2_fixed_binding
static func _a2_declared(data: Dictionary) -> bool: return data.has("a2_artisan_successor")
static func _a2_header_matches(data: Dictionary) -> bool:
	if not _a2_declared(data): return true
	var spec: Dictionary=_a2_spec()
	if spec.is_empty(): return false
	var declaration: Variant=data.get("a2_artisan_successor")
	if not declaration is Dictionary or declaration.size()!=2 or declaration.get("binding_path")!=A2_BINDING or declaration.get("binding_sha256")!=A2_BINDING_SHA or data.source_sha256.get(A2_BINDING)!=A2_BINDING_SHA: return false
	for path: String in spec.source_sha256:
		if not b()._hash(spec.source_sha256[path]) or data.source_sha256.get(path)!=spec.source_sha256[path]: return false
	for suffix: String in spec.child:
		if data.source_sha256.get(spec.child[suffix].path)!=spec.child[suffix].sha256: return false
	return true
static func _a2_artifact_path(data: Dictionary,id: StringName,suffix: String) -> String:
	if id==IDS[0] and _a2_declared(data):
		var spec: Dictionary=_a2_spec()
		return String(spec.child[suffix].path) if not spec.is_empty() and spec.child.has(suffix) else ""
	return ROOT+String(id)+"/"+suffix
static func _a2_packet_inverse(raw: Dictionary,data: Dictionary) -> bool:
	if not _a2_header_matches(data): return false
	var spec: Dictionary=_a2_spec()
	if spec.is_empty() or not raw.has("a2_finite_proof"): return false
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(spec.parent["packet.bin"].path)
	if b().bytes_sha(bytes)!=spec.parent["packet.bin"].sha256: return false
	var parent: Variant=bytes_to_var(bytes)
	if not parent is Dictionary or not b()._plain(parent) or parent.get("kind")!="AP_SOURCE_BOUND_NEW_ORDINARY_QUARTER" or parent.get("scene_id")!=String(IDS[0]) or parent.has("a2_finite_proof"): return false
	if raw.get("kind")!=parent.kind or raw.get("scene_id")!=parent.scene_id or raw.get("parent_packet_sha256")!=spec.parent["packet.bin"].sha256: return false
	if not raw.get("solids") is Array or raw.solids.size()!=27 or not parent.get("solids") is Array or parent.solids.size()!=33: return false
	for key: String in ["scene_storage","layout_storage"]:
		if not raw.get(key) is Dictionary or not raw[key].get("fields") is Dictionary or not parent.get(key) is Dictionary or not parent[key].get("fields") is Dictionary: return false
	for key: String in ["visual_objects","blockers"]:
		if not raw.layout_storage.fields.get(key) is Dictionary: return false
	var before: Dictionary={};var after: Dictionary={};var changed: Array=[]
	for row: Dictionary in parent.solids:
		if before.has(row.id): return false
		before[row.id]=row
	for row: Dictionary in raw.solids:
		if after.has(row.id) or not before.has(row.id): return false
		after[row.id]=row
	for id: String in before:
		if after.has(id) and b().equal(before[id],after[id]): continue
		if id not in spec.allowed_changed_solid_ids: return false
		changed.append(id)
	if changed.size()!=7 or after.get("ap_cloth_rack_v2_hull_0",{}).is_empty(): return false
	for id: String in changed:
		if id!="ap_cloth_rack_v2_hull_0" and after.has(id): return false
	var inverse_scene: Dictionary=raw.scene_storage.duplicate(true)
	inverse_scene.fields["metadata/luoyang_full_city_AP"]=parent.scene_storage.fields["metadata/luoyang_full_city_AP"]
	var inverse_layout: Dictionary=raw.layout_storage.duplicate(true)
	for key: String in ["visual_objects","blockers","walkable_mask_path"]: inverse_layout.fields[key]=parent.layout_storage.fields[key]
	if not b().equal(inverse_scene,parent.scene_storage) or not b().equal(inverse_layout,parent.layout_storage): return false
	if raw.layout_storage.fields.visual_objects.get("array_values",[]).size()!=132 or raw.layout_storage.fields.blockers.get("array_values",[]).size()!=27: return false
	if raw.layout_storage.fields.walkable_mask_path!=spec.child["walk.png"].path or raw.get("author_sha256")!=spec.author.sha256 or raw.get("author_path")!=spec.author.path: return false
	if not raw.get("walk_bytes") is PackedByteArray or raw.walk_bytes.size()!=3072*2048*4 or not parent.get("walk_bytes") is PackedByteArray or parent.walk_bytes.size()!=raw.walk_bytes.size(): return false
	if b().bytes_sha(parent.walk_bytes)!=spec.parent_rgba_sha256 or b().bytes_sha(raw.walk_bytes)!=raw.mask_sha256: return false
	var inverse_mask: PackedByteArray=raw.walk_bytes.duplicate();var visited: Dictionary={}
	for bounds: Array in spec.local_domains_xywh:
		if bounds.size()!=4: return false
		var area:=Rect2i(int(bounds[0]),int(bounds[1]),int(bounds[2]),int(bounds[3]))
		if not Rect2i(0,0,3072,2048).encloses(area): return false
		for y: int in range(area.position.y,area.end.y):
			for x: int in range(area.position.x,area.end.x):
				var pixel: int=y*3072+x
				if visited.has(pixel): continue
				visited[pixel]=true
				for channel: int in 4: inverse_mask[pixel*4+channel]=parent.walk_bytes[pixel*4+channel]
	if inverse_mask!=parent.walk_bytes: return false
	var inverse: Dictionary=raw.duplicate(true);inverse.erase("a2_finite_proof")
	for key: String in ["author_path","author_sha256","scene_storage","layout_storage","solids","mask_sha256","walk_bytes","geometry","parent_packet_sha256","parent_whole_inverse","local_mask_inverse"]: inverse[key]=parent[key]
	return b().equal(inverse,parent)
static func a2_source_bound_scene(scene: SceneScript) -> bool:
	return A2_READY and scene!=null and scene.scene_id==IDS[0] and _a2_declared(manifest()) and matches(scene)
