extends RefCounted
## ROOT only after AM geometry and isolated media admission. No re-raster.
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const E=preload("res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd")
const PARENT="res://build/luoyang_estate_courtyard_20261021am_system01/native_candidate/"
const OUTPUT="res://data/maps/luoyang_estate_courtyard_20261021am/"
const ART_PREFIX="res://art/modules/luoyang_estate_components_20261021am/"
static func publish(spec: Dictionary,track: Callable) -> Dictionary:
	if not track.is_valid() or not spec.get("geometry_report") is String or not B._hash(spec.get("geometry_report_sha256")) or not track.call(spec.geometry_report,spec.geometry_report_sha256): return {"ok":false,"error":"AM_FORMAL_EXACT_GEOMETRY_RECEIPT"}
	var proof: Dictionary=E.json(spec.geometry_report)
	if proof.get("passed")!=true or proof.get("whole_parent_inverse")!=true or proof.get("source_first")!=proof.get("source_final") or not spec.get("include_peony_beds") is bool or not spec.get("media_aliases") is Array or spec.media_aliases.size()!=(4 if spec.include_peony_beds else 3) or not spec.get("import_proofs") is Array: return {"ok":false,"error":"AM_FORMAL_EXACT_ADMITTED_MEDIA_SUBSET_AND_NATIVE"}
	for path: String in proof.artifacts:
		if not track.call(path,String(proof.artifacts[path])): return {"ok":false,"error":"AM_FORMAL_GEOMETRY_NATIVE_CHANGED"}
	var original: Variant=bytes_to_var(FileAccess.get_file_as_bytes(PARENT+"packet.bin"))
	var scene:=ResourceLoader.load(PARENT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not original is Dictionary or scene==null or not B.equal(B.storage(scene),original.scene_storage) or not B.equal(B.storage(scene.map_layout),original.layout_storage) or scene.map_layout.walkable_mask_path!=OUTPUT+"walk.png": return {"ok":false,"error":"AM_FORMAL_PARENT_WHOLE_STORAGE"}
	var imported: Dictionary={}
	for row: Dictionary in spec.import_proofs:
		if not track.call(row.path,String(row.sha256)): return {"ok":false,"error":"AM_FORMAL_IMPORT_RECEIPT"}
		var report: Dictionary=E.json(row.path)
		if report.get("passed")!=true or not report.get("failures") is Array or not report.failures.is_empty() or report.get("source_first")!=report.get("source_final"): return {"ok":false,"error":"AM_FORMAL_IMPORT_NOT_PASSED"}
		for media: Dictionary in report.get("rows",[]):
			if imported.has(media.texture) or media.get("full_rgba_exact")!=true or media.get("params23")!=true or media.get("zero_mipmaps")!=true or media.get("detect3d_compress_to")!=0: return {"ok":false,"error":"AM_FORMAL_UNIQUE_RGBA23_MIP0_DETECT0"}
			for pair: Array in [[media.texture,media.source_sha256],[media.import_path,media.import_sha256],[media.compiled_path,media.compiled_sha256]]:
				if not track.call(String(pair[0]),String(pair[1])): return {"ok":false,"error":"AM_FORMAL_MEDIA_TRIPLE"}
			imported[media.texture]=media
	var aliases: Dictionary={};var targets: Dictionary={}
	for row: Dictionary in spec.media_aliases:
		if not row.get("old_path") is String or not row.get("new_path") is String or not row.new_path.begins_with(ART_PREFIX) or aliases.has(row.old_path) or targets.has(row.new_path) or not imported.has(row.new_path) or not B._hash(row.get("sha256")) or not track.call(row.old_path,row.sha256) or not track.call(row.new_path,row.sha256) or imported[row.new_path].source_sha256!=row.sha256: return {"ok":false,"error":"AM_FORMAL_EXACT_BYTE_IDENTICAL_MEDIA_ALIAS"}
		aliases[row.old_path]=row.new_path;targets[row.new_path]=true
	var old_rows: Array[Dictionary]=scene.map_layout.visual_objects.duplicate(true);var old_name: String=scene.display_name;var rows: Array[Dictionary]=old_rows.duplicate(true);var changed: Array=[]
	for i: int in rows.size():
		if not aliases.has(rows[i].get("texture")): continue
		changed.append({"index":i,"id":rows[i].id,"old_texture":rows[i].texture,"new_texture":aliases[rows[i].texture]});rows[i].texture=aliases[rows[i].texture]
	if changed.size()!=(7 if spec.include_peony_beds else 5): return {"ok":false,"error":"AM_FORMAL_ONLY_FIVE_ARCHITECTURE_AND_OPTIONAL_TWO_BED_TEXTURE_ALIASES"}
	var walk: Image=Image.load_from_file(OUTPUT+"walk.png")
	if walk!=null: walk.convert(Image.FORMAT_RGBA8)
	if walk==null or walk.get_data()!=original.walk_bytes or not imported.has(OUTPUT+"walk.png"): return {"ok":false,"error":"AM_FORMAL_PROMOTED_WALK_EXACT_RGBA"}
	for name: String in ["scene.res","layout.res","packet.bin","manifest.json"]:
		if FileAccess.file_exists(OUTPUT+name): return {"ok":false,"error":"AM_FORMAL_NEW_OUTPUT_ONLY"}
	if DirAccess.make_dir_recursive_absolute(OUTPUT)!=OK: return {"ok":false,"error":"AM_FORMAL_NEW_DIRECTORY"}
	scene.map_layout.visual_objects=rows;scene.display_name="洛阳 · 宅园"
	var storage: Dictionary={"scene":B.storage(scene),"layout":B.storage(scene.map_layout)}
	scene.map_layout.visual_objects=old_rows;scene.display_name=old_name
	if not B.equal(B.storage(scene),original.scene_storage) or not B.equal(B.storage(scene.map_layout),original.layout_storage): return {"ok":false,"error":"AM_FORMAL_WHOLE_NATIVE_ALIAS_AND_LABEL_INVERSE"}
	scene.map_layout.visual_objects=rows;scene.display_name="洛阳 · 宅园"
	if ResourceSaver.save(scene.map_layout,OUTPUT+"layout.res")!=OK: return {"ok":false,"error":"AM_FORMAL_LAYOUT_SAVE"}
	scene.map_layout=ResourceLoader.load(OUTPUT+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if scene.map_layout==null or ResourceSaver.save(scene,OUTPUT+"scene.res")!=OK: return {"ok":false,"error":"AM_FORMAL_SCENE_SAVE"}
	var packet: Dictionary=original.duplicate(true);packet.scene_storage=storage.scene;packet.layout_storage=storage.layout
	packet.formal_path_successor_AM={"parent_packet":PARENT+"packet.bin","parent_sha256":proof.artifacts[PARENT+"packet.bin"],"unchanged_geometry_and_walk":true,"exact_byte_identical_texture_aliases":changed,"display_label_only":"洛阳 · 宅园"}
	var inverse: Dictionary=packet.duplicate(true);inverse.scene_storage=original.scene_storage;inverse.layout_storage=original.layout_storage;inverse.erase("formal_path_successor_AM")
	if not B._plain(packet) or not B.equal(inverse,original): return {"ok":false,"error":"AM_FORMAL_PACKET_WHOLE_INVERSE"}
	var file:=FileAccess.open(OUTPUT+"packet.bin",FileAccess.WRITE)
	if file==null: return {"ok":false,"error":"AM_FORMAL_PACKET_SAVE"}
	file.store_buffer(var_to_bytes(packet));file.close()
	var readback:=ResourceLoader.load(OUTPUT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if readback==null or readback.map_layout.resource_path!=OUTPUT+"layout.res" or not B.equal(B.storage(readback),storage.scene) or not B.equal(B.storage(readback.map_layout),storage.layout) or not B.equal(bytes_to_var(FileAccess.get_file_as_bytes(OUTPUT+"packet.bin")),packet): return {"ok":false,"error":"AM_FORMAL_COMPLETE_STORAGE_AND_NEW_PATH_READBACK"}
	var outputs: Dictionary={}
	for name: String in ["scene.res","layout.res","packet.bin"]: outputs[OUTPUT+name]=FileAccess.get_sha256(OUTPUT+name)
	return {"ok":true,"artifacts":outputs,"packet_whole_inverse":true,"scene_layout_whole_inverse":true,"texture_alias_count":changed.size(),"body_mask_portals_routes_unchanged":true,"geometry_rerun":false,"not_yet_formal_admitted":true}
