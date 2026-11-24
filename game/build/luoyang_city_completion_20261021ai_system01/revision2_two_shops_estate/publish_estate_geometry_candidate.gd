extends SceneTree
## ROOT only: one new ordinary dry-court native candidate, no Field/C setup.
const E=preload("res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd")
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const REPORT="res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/geometry/"
const WALK="res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/publication_assets/estate_walk_candidate.png"
const LIMIT_MS=60000
var pins: Dictionary={}
var error: String=""
var began: int=0
func _initialize() -> void: call_deferred("_run")
func need(ok: bool,label: String) -> bool:
	if not ok and error.is_empty(): error=label;push_error("AI_ESTATE "+label)
	return ok
func track(path: String,expected: String="") -> bool:
	var sha: String=FileAccess.get_sha256(path)
	if not need(path.begins_with("res://") and ".." not in path and sha.length()==64 and (expected.is_empty() or expected==sha) and (not pins.has(path) or pins[path]==sha),"EXACT_SOURCE:"+path): return false
	pins[path]=sha;return true
func write_json(path: String,data: Dictionary) -> bool:
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var f:=FileAccess.open(path,FileAccess.WRITE)
	if f==null: return false
	f.store_string(JSON.stringify(data,"\t",true,true));f.close();return true
func alpha_proof(scene: SceneScript) -> Dictionary:
	var boxes: Dictionary={}
	for row: Dictionary in scene.map_layout.visual_objects:
		if not row.get("sort_by_feet",false): continue
		var image: Image=Image.load_from_file(row.texture)
		if image==null: return {"passed":false,"error":"ACTUAL_PROP_IMAGE"}
		image.convert(Image.FORMAT_RGBA8)
		var used: Rect2i=image.get_used_rect()
		var size: Vector2=row.render_size_px;var origin: Vector2=row.pos*E.SIZE-size*.5
		var box:=Rect2(origin+Vector2(used.position)*size/Vector2(image.get_size()),Vector2(used.size)*size/Vector2(image.get_size()))
		if not used.has_area() or not Rect2(Vector2.ZERO,E.SIZE).encloses(box): return {"passed":false,"error":"ACTUAL_ALPHA_DOMAIN"}
		boxes[String(row.id)]=box
	for first: String in boxes:
		for last: String in boxes:
			if first==last: continue
			var box: Rect2=boxes[first]
			if box.intersects(boxes[last],true): return {"passed":false,"error":"PROP_ALPHA_INTERSECTION","pair":[first,last]}
	return {"passed":boxes.size()==5,"full_alpha_boxes":var_to_str(boxes),"alpha_threshold":0,"no_cropped_or_thresholded_assets":true}
func publish() -> Dictionary:
	if not need(OS.get_cmdline_user_args().is_empty(),"NO_UNKNOWN_FLAGS"): return {}
	var a: Dictionary=E.author()
	if not need(not a.is_empty(),"PINNED_AUTHOR_AND_13_ASSET_LEAVES"): return {}
	for path: String in [E.AUTHOR,"res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd",get_script().resource_path,"res://scripts/city/luoyang_precomputed_bundle_20261018r.gd","res://scripts/domain/scene_script.gd","res://scripts/domain/walkable_map_layout.gd"]:
		if not track(path): return {}
	for path: String in a.source_sha256:
		if not track(path,a.source_sha256[path]): return {}
	var solids: Array[Dictionary]=E.blockers(a)
	var mask: Image=E.mask(a,solids)
	if not need(solids.size()==6 and mask!=null,"SIX_REAL_RECT_BLOCKERS_AND_NATIVE_MASK"): return {}
	var geometry: Dictionary=E.audit(a,mask,solids)
	if not need(geometry.get("passed")==true,"EVERY_ROUTE_FULL_875_PLUS17"): return {"geometry":geometry}
	var scene: SceneScript=E.scene(a,solids)
	if not need(scene!=null and scene.actor_positions_are_feet and scene.map_layout.visual_objects.size()==13 and scene.map_layout.blockers.size()==6 and scene.map_layout.portals.size()==2 and scene.npcs.is_empty(),"EXACT_ORDINARY_SCENE_SCHEMA"): return {}
	var alpha: Dictionary=alpha_proof(scene)
	if not need(alpha.get("passed")==true,"FIVE_COMPLETE_ALPHA_PROP_ENVELOPES"): return {"geometry":geometry,"alpha":alpha}
	if not need(not DirAccess.dir_exists_absolute(E.ROOT) and not FileAccess.file_exists(WALK),"NEW_OUTPUTS_ONLY"): return {}
	if not need(DirAccess.make_dir_recursive_absolute(E.ROOT)==OK and DirAccess.make_dir_recursive_absolute(WALK.get_base_dir())==OK,"NEW_OUTPUT_DIRS"): return {}
	if not need(mask.save_png(WALK)==OK,"BUILD_MASK_CANDIDATE_WRITE"): return {}
	var mask_read: Image=Image.load_from_file(WALK)
	if mask_read!=null: mask_read.convert(Image.FORMAT_RGBA8)
	if not need(mask_read!=null and mask_read.get_data()==mask.get_data(),"NATIVE_MASK_RGBA_READBACK"): return {}
	var storage: Dictionary={"scene":B.storage(scene),"layout":B.storage(scene.map_layout)}
	if not need(ResourceSaver.save(scene.map_layout,E.ROOT+"layout.res")==OK,"NATIVE_LAYOUT_WRITE"): return {}
	scene.map_layout=ResourceLoader.load(E.ROOT+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not need(scene.map_layout!=null and ResourceSaver.save(scene,E.ROOT+"scene.res")==OK,"NATIVE_SCENE_WRITE"): return {}
	var readback:=ResourceLoader.load(E.ROOT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(readback!=null and B.equal(B.storage(readback),storage.scene) and B.equal(B.storage(readback.map_layout),storage.layout),"ENTIRE_NATIVE_STORAGE_READBACK"): return {}
	var packet: Dictionary={"kind":"AI_NEW_DRY_ESTATE_ORDINARY_NATIVE_CANDIDATE","scene_id":String(E.ID),"author_path":E.AUTHOR,"author_sha256":E.AUTHOR_SHA,"rectangular_solids":solids,"mask_sha256":B.bytes_sha(mask.get_data()),"walk_bytes":mask.get_data(),"scene_storage":storage.scene,"layout_storage":storage.layout,"geometry":geometry,"alpha":alpha}
	if not need(B._plain(packet),"SAFE_PLAIN_PACKET"): return {}
	var f:=FileAccess.open(E.ROOT+"packet.bin",FileAccess.WRITE)
	if not need(f!=null,"PACKET_WRITE"): return {}
	f.store_buffer(var_to_bytes(packet));f.close()
	if not need(B.equal(bytes_to_var(FileAccess.get_file_as_bytes(E.ROOT+"packet.bin")),packet),"ENTIRE_PACKET_READBACK"): return {}
	var artifacts: Dictionary={}
	for name: String in ["scene.res","layout.res","packet.bin"]: artifacts[E.ROOT+name]=FileAccess.get_sha256(E.ROOT+name)
	return {"published":true,"artifacts":artifacts,"geometry":geometry,"alpha":alpha,"walk_candidate":{"path":WALK,"sha256":FileAccess.get_sha256(WALK),"rgba_sha256":packet.mask_sha256,"future_canonical_path":E.ROOT+"walk.png","native_size":[3072,2048],"not_imported_or_promoted":true},"scope":"ONE_NEW_ORDINARY_DRY_ESTATE_GEOMETRY_NOT_FIELD_OR_CONNECTED_WORLD","missing":["Market25 child and its lane portal","three room-return successor including mansion city change","source admission manifest/index and route adapter","pavilion/water/complete garden art and NPCs","Field ghost/occlusion/door/body actual checks"]}
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	began=Time.get_ticks_msec()
	var report: Dictionary=publish()
	var final: Dictionary={}
	for path: String in pins:
		final[path]=FileAccess.get_sha256(path);need(final[path]==pins[path],"SOURCE_FINAL:"+path)
	need(Time.get_ticks_msec()-began<LIMIT_MS,"FIXED_60S_BUDGET")
	report.merge({"passed":error.is_empty() and report.get("published")==true,"error":error,"source_first":pins,"source_final":final,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":LIMIT_MS,"no_C_or_Field_or_other_city_prepare":true},true)
	var path: String=REPORT+str(OS.get_process_id())+"/result.json"
	var ok: bool=write_json(path,report)
	print(JSON.stringify({"path":path,"passed":ok and report.passed,"error":error}));quit(0 if ok and report.passed else 1)
