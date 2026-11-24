extends SceneTree
## ROOT only. Add physical enclosure to the frozen AL83 native parent.
const M=preload("res://build/luoyang_estate_courtyard_20261021an_system01/enclosure_candidate.gd")
const HELPER="res://build/luoyang_estate_courtyard_20261021an_system01/enclosure_candidate.gd"
const E=preload("res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd")
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const HERE="res://build/luoyang_estate_courtyard_20261021an_system01/"
const AUTHOR=HERE+"author_READY.json"
const AUTHOR_SHA="PENDING"
const PARENT="res://build/luoyang_estate_courtyard_20261021al_system01/revision2/native_candidate/"
const PROOF="res://build/luoyang_estate_courtyard_20261021al_system01/revision2/actual/16096/result.json"
const PROOF_SHA="c4a66219fb29e784f3c3bf4a8e3185627765853e9943e6f7dfc70b70a361a20d"
const OUTPUT=HERE+"native_candidate/"
const WALK=HERE+"publication_assets/walk_candidate.png"
const FUTURE_WALK="res://data/maps/luoyang_estate_courtyard_20261021am/walk.png"
var error: String=""
var pins: Dictionary={}
func _initialize() -> void: call_deferred("_run")
func need(ok: bool,label: String) -> bool:
	if not ok and error.is_empty(): error=label;push_error("AM_ENCLOSURE "+label)
	return ok
func track(path: String,wanted: String="") -> bool:
	var hash: String=FileAccess.get_sha256(path)
	if not need(path.begins_with("res://") and ".." not in path and hash.length()==64 and (wanted.is_empty() or hash==wanted) and (not pins.has(path) or pins[path]==hash),"SOURCE:"+path): return false
	pins[path]=hash;return true
func write_json(path: String,data: Dictionary) -> bool:
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(data,"\t",true,true));file.close();return true
func publish() -> Dictionary:
	if not need(OS.get_cmdline_user_args().is_empty() and AUTHOR_SHA.length()==64,"READY_REQUIRED_NO_UNKNOWN_ARGS"): return {}
	if not track(AUTHOR,AUTHOR_SHA) or not track(PROOF,PROOF_SHA): return {}
	var a: Dictionary=E.json(AUTHOR);var proof: Dictionary=E.json(PROOF)
	if not need(M.valid(a) and proof.get("passed")==true and proof.get("source_first")==proof.get("source_final") and proof.get("sprites")==83 and proof.get("all20rect_mask_routes_portals_unchanged")==true,"EXACT_AL_ACTUAL_AND_ADMITTED_AUTHOR"): return {}
	for path: String in proof.source_first:
		if not track(path,proof.source_first[path]): return {}
	for path: String in proof.artifacts:
		if not track(path,proof.artifacts[path]): return {}
	for path: String in a.source_sha256:
		if not track(path,a.source_sha256[path]): return {}
	if not track(HELPER) or not track(get_script().resource_path): return {}
	var parent: Variant=bytes_to_var(FileAccess.get_file_as_bytes(PARENT+"packet.bin"))
	var scene:=ResourceLoader.load(PARENT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(parent is Dictionary and scene!=null and B.equal(B.storage(scene),parent.scene_storage) and B.equal(B.storage(scene.map_layout),parent.layout_storage) and parent.rectangular_solids.size()==20 and scene.map_layout.visual_objects.size()==83,"AL83_AK20_COMPLETE_NATIVE_PACKET_PARENT"): return {}
	var delta: Dictionary=M.geometry(a,scene)
	if not need(not delta.is_empty(),"ACTUAL_SOURCE_A1_GROUND_ANCHOR_AND_ENTITIES"): return {}
	var mask: Image=M.mask_after(parent.walk_bytes,delta.solids)
	if not need(mask!=null,"ADD_ONLY_MASK"): return {}
	# Undo just the new closed-rectangle pixels from the exact parent bytes.
	# Full byte equality proves that no off-rectangle water/route was reopened.
	var old_mask:=Image.create_from_data(3072,2048,false,Image.FORMAT_RGBA8,parent.walk_bytes)
	var inverse_mask: Image=mask.duplicate()
	for row: Dictionary in delta.solids:
		var box: Rect2=E.rect(row.rect_px)
		for y: int in range(ceili(box.position.y),floori(box.end.y)+1):
			for x: int in range(ceili(box.position.x),floori(box.end.x)+1):
				if not need(mask.get_pixel(x,y)==Color(0,0,0,1),"NEW_RECT_PIXEL_BLACK"): return {}
				inverse_mask.set_pixel(x,y,old_mask.get_pixel(x,y))
	if not need(inverse_mask.get_data()==parent.walk_bytes,"FULL_MASK_INVERSE_ONLY_NEW_RECTANGLES"): return {}
	var audit: Dictionary=M.audit(a,parent,scene,delta,mask)
	if not need(audit.get("passed")==true,"AFFECTED_OLD_ROUTES_AND_NEW_BYPASSES87517"): return {"geometry":audit}
	var old_rows: Array[Dictionary]=scene.map_layout.visual_objects.duplicate(true);var old_blocks: Array[Dictionary]=scene.map_layout.blockers.duplicate(true);var old_path: String=scene.map_layout.walkable_mask_path
	var rows: Array[Dictionary]=old_rows.duplicate(true);rows.append_array(delta.visual)
	var blocks: Array[Dictionary]=old_blocks.duplicate(true)
	for solid: Dictionary in delta.solids:
		var box: Rect2=E.rect(solid.rect_px)
		blocks.append({"id":solid.id,"pos":box.get_center()/M.SIZE,"size":box.size/M.SIZE,"walkability_margin":0.0})
	scene.map_layout.visual_objects=rows;scene.map_layout.blockers=blocks;scene.map_layout.walkable_mask_path=FUTURE_WALK
	var storage: Dictionary={"scene":B.storage(scene),"layout":B.storage(scene.map_layout)}
	scene.map_layout.visual_objects=old_rows;scene.map_layout.blockers=old_blocks;scene.map_layout.walkable_mask_path=old_path
	if not need(B.equal(B.storage(scene),parent.scene_storage) and B.equal(B.storage(scene.map_layout),parent.layout_storage),"WHOLE_TYPED_NATIVE_INVERSE_ONLY_THREE_LAYOUT_FIELDS"): return {}
	scene.map_layout.visual_objects=rows;scene.map_layout.blockers=blocks;scene.map_layout.walkable_mask_path=FUTURE_WALK
	var packet: Dictionary=parent.duplicate(true)
	packet.scene_storage=storage.scene;packet.layout_storage=storage.layout;packet.rectangular_solids=audit.all_solids;packet.walk_bytes=mask.get_data();packet.mask_sha256=B.bytes_sha(packet.walk_bytes);packet.geometry=audit
	packet.enclosure_successor_AM={"author_path":AUTHOR,"author_sha256":AUTHOR_SHA,"parent_packet":PARENT+"packet.bin","parent_packet_sha256":proof.artifacts[PARENT+"packet.bin"],"parent_actual":PROOF,"parent_actual_sha256":PROOF_SHA,"all83_visual_and20_rect_prefix_exact":true,"new_routes":a.new_routes,"no_old_full_route_rerun":true,"formal_enabled":false}
	var inverse: Dictionary=packet.duplicate(true)
	for key: String in ["scene_storage","layout_storage","rectangular_solids","walk_bytes","mask_sha256","geometry"]: inverse[key]=parent[key]
	inverse.erase("enclosure_successor_AM")
	if not need(B._plain(packet) and B.equal(inverse,parent),"WHOLE_PARENT_PACKET_INVERSE"): return {}
	if not need(not DirAccess.dir_exists_absolute(OUTPUT) and not FileAccess.file_exists(WALK) and DirAccess.make_dir_recursive_absolute(OUTPUT)==OK and DirAccess.make_dir_recursive_absolute(WALK.get_base_dir())==OK,"NEW_OUTPUTS_ONLY"): return {}
	if not need(mask.save_png(WALK)==OK,"NEW_WALK_CANDIDATE_ONLY"): return {}
	var image: Image=Image.load_from_file(WALK)
	if image!=null: image.convert(Image.FORMAT_RGBA8)
	if not need(image!=null and image.get_data()==packet.walk_bytes,"WALK_RGBA_READBACK"): return {}
	if not need(ResourceSaver.save(scene.map_layout,OUTPUT+"layout.res")==OK,"NATIVE_LAYOUT"): return {}
	scene.map_layout=ResourceLoader.load(OUTPUT+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not need(scene.map_layout!=null and ResourceSaver.save(scene,OUTPUT+"scene.res")==OK,"NATIVE_SCENE"): return {}
	var file:=FileAccess.open(OUTPUT+"packet.bin",FileAccess.WRITE)
	if not need(file!=null,"PACKET_NEW"): return {}
	file.store_buffer(var_to_bytes(packet));file.close()
	var readback:=ResourceLoader.load(OUTPUT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(readback!=null and B.equal(B.storage(readback),storage.scene) and B.equal(B.storage(readback.map_layout),storage.layout) and B.equal(bytes_to_var(FileAccess.get_file_as_bytes(OUTPUT+"packet.bin")),packet),"ALL_NATIVE_PACKET_READBACK"): return {}
	var artifacts: Dictionary={}
	for name: String in ["scene.res","layout.res","packet.bin"]: artifacts[OUTPUT+name]=FileAccess.get_sha256(OUTPUT+name)
	return {"published":true,"artifacts":artifacts,"geometry":audit,"whole_parent_inverse":true,"visual_rows":rows.size(),"physical_rectangles":blocks.size(),"walk_candidate":{"path":WALK,"sha256":FileAccess.get_sha256(WALK),"rgba_sha256":packet.mask_sha256,"future_path":FUTURE_WALK,"not_imported_or_promoted":true},"scope":"AM_RECTANGULAR_ENCLOSURE_NATIVE_CANDIDATE_FIELD_AND_PORTAL_CHECK_STILL_REQUIRED"}
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);var began: int=Time.get_ticks_msec()
	var result: Dictionary=publish();var final: Dictionary={}
	for path: String in pins:
		final[path]=FileAccess.get_sha256(path);need(final[path]==pins[path],"SOURCE_FINAL:"+path)
	need(Time.get_ticks_msec()-began<60000,"FIXED60S_BUDGET")
	result.merge({"passed":error.is_empty() and result.get("published")==true,"error":error,"source_first":pins,"source_final":final,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":60000},true)
	var path: String=HERE+"geometry/"+str(OS.get_process_id())+"/result.json";var ok: bool=write_json(path,result)
	print(JSON.stringify({"path":path,"passed":ok and result.passed,"error":error}));quit(0 if ok and result.passed else 1)
