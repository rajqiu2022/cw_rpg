extends SceneTree
## ROOT-only one incremental architecture geometry publication. No Field setup.
const A=preload("res://build/luoyang_estate_courtyard_20261021ak_system01/architecture_candidate.gd")
const HELPER_PATH="res://build/luoyang_estate_courtyard_20261021ak_system01/architecture_candidate.gd"
const E=preload("res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd")
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const HERE="res://build/luoyang_estate_courtyard_20261021ak_system01/"
const AUTHOR=HERE+"author_READY.json"
const AUTHOR_SHA="c21097071d8a13ee9e427309a9203fe74ae28250eb36d067c2a101e08185de55"
const GEOMETRY="res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/geometry/114084/result.json"
const GEOMETRY_SHA="91c95216c2e422fa7389ef291683dd25fe1d499acd369d80b941367be5bb88af"
const VISUAL="res://build/luoyang_city_completion_20261021ai_system01/revision3_ground_visual_only/results/116964/result.json"
const VISUAL_SHA="40e3387d1525b3ebf259fbf7555b8f91e7f555d9a0afa6328000b975e7cf3005"
const PARENT="res://build/luoyang_city_completion_20261021ai_system01/revision3_ground_visual_only/native_candidate/"
const OUTPUT=HERE+"native_candidate/"
const FUTURE_WALK="res://data/maps/luoyang_estate_courtyard_20261021ak/walk.png"
const WALK=HERE+"publication_assets/walk_candidate.png"
var error: String=""
var pins: Dictionary={}
var began: int=0
func _initialize() -> void: call_deferred("_run")
func need(ok: bool,label: String) -> bool:
	if not ok and error.is_empty(): error=label;push_error("AK_ARCHITECTURE "+label)
	return ok
func track(path: String,expected: String="") -> bool:
	var hash: String=FileAccess.get_sha256(path)
	if not need(path.begins_with("res://") and ".." not in path and hash.length()==64 and (expected.is_empty() or hash==expected) and (not pins.has(path) or pins[path]==hash),"EXACT_SOURCE:"+path): return false
	pins[path]=hash;return true
func json_new(path: String,data: Dictionary) -> bool:
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(data,"\t",true,true));file.close();return true
func publish() -> Dictionary:
	if not need(OS.get_cmdline_user_args().is_empty() and AUTHOR_SHA.length()==64,"READY_AUTHOR_REQUIRED_NO_UNKNOWN_ARGS"): return {}
	if not track(AUTHOR,AUTHOR_SHA) or not track(GEOMETRY,GEOMETRY_SHA) or not track(VISUAL,VISUAL_SHA): return {}
	var geometry: Dictionary=E.json(GEOMETRY);var visual: Dictionary=E.json(VISUAL);var a: Dictionary=E.json(AUTHOR)
	if not need(geometry.get("passed")==true and visual.get("passed")==true and geometry.get("source_first")==geometry.get("source_final") and visual.get("source_first")==visual.get("source_final") and A.author_valid(a),"FROZEN_ACTUAL_PARENTS_AND_EXPLICIT_ART_AUTHOR"): return {}
	for report: Dictionary in [geometry,visual]:
		for path: String in report.source_first:
			if not track(path,report.source_first[path]): return {}
		for path: String in report.artifacts:
			if not track(path,report.artifacts[path]): return {}
	for path: String in [get_script().resource_path,HELPER_PATH]:
		if not track(path): return {}
	for path: String in a.source_sha256:
		if not track(path,a.source_sha256[path]): return {}
	var parent: Variant=bytes_to_var(FileAccess.get_file_as_bytes(PARENT+"packet.bin"))
	var scene:=ResourceLoader.load(PARENT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(parent is Dictionary and B._plain(parent) and scene!=null and B.equal(B.storage(scene),parent.scene_storage) and B.equal(B.storage(scene.map_layout),parent.layout_storage) and parent.rectangular_solids.size()==6 and parent.geometry.samples==2226 and scene.map_layout.visual_objects.size()==57,"EXACT_ACTUAL_VISUAL57_GEOMETRY6_PARENT"): return {}
	var parent_author: Dictionary=E.author();var delta: Dictionary=A.geometry(a)
	if not need(not parent_author.is_empty() and not delta.is_empty(),"ACTUAL_A1_IMAGES_AND_SOURCE_RECTANGULAR_SOLIDS"): return {}
	var trees: Dictionary=A.tree_delta(a,parent_author,parent)
	if not need(not trees.is_empty(),"EXACT_NW_NE_TREE_VISUAL_AND24X18_ENTITY_SUCCESSOR"): return {}
	var mask: Image=A.clone_mask(parent.walk_bytes,trees,delta.solids)
	if not need(mask!=null,"ONLY_TWO_OLD_TREE_RECT_RECOVERY_AND_NEW_BLACK_DELTA_MASK"): return {}
	var audit: Dictionary=A.audit(a,parent_author,parent,delta,trees,mask)
	if not need(audit.get("passed")==true,"INCREMENTAL_AND_NEW_ROUTES_FULL875_PLUS17"): return {"geometry":audit}
	var old_visual: Array[Dictionary]=scene.map_layout.visual_objects.duplicate(true)
	var old_blocks: Array[Dictionary]=scene.map_layout.blockers.duplicate(true)
	var old_portals: Array[Dictionary]=scene.map_layout.portals.duplicate(true)
	var old_mask_path: String=scene.map_layout.walkable_mask_path
	var rows: Array[Dictionary]=old_visual.duplicate(true);var moved_tree_rows: int=0
	for i: int in rows.size():
		var row: Dictionary=rows[i]
		if not trees.visuals.has(row.id): continue
		var next: Dictionary=trees.visuals[row.id]
		var left: Dictionary=row.duplicate(true);var right: Dictionary=next.duplicate(true)
		for key: String in ["pos","depth_sort_foot_y"]: left.erase(key);right.erase(key)
		if not need(B.equal(left,right),"TREE_TEXTURE_RENDER_AND_ALL_NON_FOOT_VALUES_UNCHANGED"): return {}
		rows[i]=next.duplicate(true);moved_tree_rows+=1
	if not need(moved_tree_rows==2,"ONLY_TWO_TREE_VISUAL_ROWS_MOVED"): return {}
	rows.append_array(delta.visual)
	var blocks: Array[Dictionary]=old_blocks.duplicate(true)
	var moved_tree_blocks: int=0
	for row: Dictionary in blocks:
		for tree: Dictionary in trees.new_tree_rects:
			if row.id!=tree.id: continue
			var box: Rect2=E.rect(tree.rect_px)
			row.pos=box.get_center()/E.SIZE;row.size=box.size/E.SIZE;moved_tree_blocks+=1
	if not need(moved_tree_blocks==2,"ONLY_TWO_TREE_NATIVE_BLOCKERS_MOVED"): return {}
	for solid: Dictionary in delta.solids:
		var box: Rect2=E.rect(solid.rect_px)
		blocks.append({"id":solid.id,"pos":box.get_center()/E.SIZE,"size":box.size/E.SIZE,"walkability_margin":0.0})
	var portals: Array[Dictionary]=old_portals.duplicate(true);var moved: int=0
	for row: Dictionary in portals:
		if row.id!=a.portal_move.id: continue
		if not need(row.target_scene==String(E.ROOM) and row.pos==E.uv(a.portal_move.old_foot),"EXACT_OLD_MANSION_ROOM_PORTAL"): return {}
		row.pos=E.uv(a.portal_move.new_foot);moved+=1
	if not need(moved==1,"ONLY_EXISTING_MANSION_PORTAL_MOVED_TO_MAIN_HALL"): return {}
	scene.map_layout.visual_objects=rows;scene.map_layout.blockers=blocks;scene.map_layout.portals=portals;scene.map_layout.walkable_mask_path=FUTURE_WALK
	var storage: Dictionary={"scene":B.storage(scene),"layout":B.storage(scene.map_layout)}
	scene.map_layout.visual_objects=old_visual;scene.map_layout.blockers=old_blocks;scene.map_layout.portals=old_portals;scene.map_layout.walkable_mask_path=old_mask_path
	if not need(B.equal(B.storage(scene),parent.scene_storage) and B.equal(B.storage(scene.map_layout),parent.layout_storage),"ENTIRE_NATIVE_PARENT_INVERSE_ONLY_DECLARED4_LAYOUT_FIELDS"): return {}
	scene.map_layout.visual_objects=rows;scene.map_layout.blockers=blocks;scene.map_layout.portals=portals;scene.map_layout.walkable_mask_path=FUTURE_WALK
	var packet: Dictionary=parent.duplicate(true)
	packet.scene_storage=storage.scene;packet.layout_storage=storage.layout;packet.rectangular_solids=audit.all_solids;packet.walk_bytes=mask.get_data();packet.mask_sha256=B.bytes_sha(packet.walk_bytes);packet.geometry=audit
	packet.architecture_successor={"author_path":AUTHOR,"author_sha256":AUTHOR_SHA,"parent_packet":PARENT+"packet.bin","parent_sha256":visual.artifacts[PARENT+"packet.bin"],"inherited_geometry_receipt":GEOMETRY,"inherited_geometry_sha256":GEOMETRY_SHA,"parent_visual_receipt":VISUAL,"parent_visual_sha256":VISUAL_SHA,"new_components":5,"two_named_tree_visual_and24x18_rects_moved":a.tree_moves,"other_four_solids_and55_visual_rows_unchanged":true,"only_portal_pos_moved":a.portal_move,"replaced_old_route_ids":a.replace_old_route_ids,"new_routes":a.new_routes,"old2226_not_full_rerun":true,"formal_enabled":false,"new_component_texture_credit":"raw_candidate_ImageTexture_preview_not_formal_import"}
	var inverse: Dictionary=packet.duplicate(true)
	for key: String in ["scene_storage","layout_storage","rectangular_solids","walk_bytes","mask_sha256","geometry"]: inverse[key]=parent[key]
	inverse.erase("architecture_successor")
	if not need(B._plain(packet) and B.equal(inverse,parent),"ENTIRE_PARENT_PACKET_INVERSE"): return {}
	if not need(not DirAccess.dir_exists_absolute(OUTPUT) and not FileAccess.file_exists(WALK) and DirAccess.make_dir_recursive_absolute(OUTPUT)==OK and DirAccess.make_dir_recursive_absolute(WALK.get_base_dir())==OK,"NEW_OUTPUTS_ONLY"): return {}
	if not need(mask.save_png(WALK)==OK,"NEW_BUILD_MASK_ONLY"): return {}
	var read_mask: Image=Image.load_from_file(WALK)
	if read_mask!=null: read_mask.convert(Image.FORMAT_RGBA8)
	if not need(read_mask!=null and read_mask.get_data()==mask.get_data(),"MASK_FULL_RGBA_READBACK"): return {}
	if not need(ResourceSaver.save(scene.map_layout,OUTPUT+"layout.res")==OK,"NEW_NATIVE_LAYOUT"): return {}
	scene.map_layout=ResourceLoader.load(OUTPUT+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not need(scene.map_layout!=null and ResourceSaver.save(scene,OUTPUT+"scene.res")==OK,"NEW_NATIVE_SCENE"): return {}
	var file:=FileAccess.open(OUTPUT+"packet.bin",FileAccess.WRITE)
	if not need(file!=null,"NEW_PACKET"): return {}
	file.store_buffer(var_to_bytes(packet));file.close()
	var readback:=ResourceLoader.load(OUTPUT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(readback!=null and B.equal(B.storage(readback),storage.scene) and B.equal(B.storage(readback.map_layout),storage.layout) and B.equal(bytes_to_var(FileAccess.get_file_as_bytes(OUTPUT+"packet.bin")),packet),"NATIVE_AND_PACKET_FULL_STORAGE_READBACK"): return {}
	var artifacts: Dictionary={}
	for name: String in ["scene.res","layout.res","packet.bin"]: artifacts[OUTPUT+name]=FileAccess.get_sha256(OUTPUT+name)
	return {"published":true,"artifacts":artifacts,"geometry":audit,"parent_inverse":true,"visual_rows":rows.size(),"physical_rectangles":blocks.size(),"walk_candidate":{"path":WALK,"sha256":FileAccess.get_sha256(WALK),"rgba_sha256":packet.mask_sha256,"future_path":FUTURE_WALK,"not_imported_or_promoted":true},"scope":"NEW_ARCHITECTURE_NATIVE_CANDIDATE_NOT_FIELD_CONNECTED_WORLD_OR_COMPLETE_GARDEN"}
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);began=Time.get_ticks_msec()
	var result: Dictionary=publish();var final: Dictionary={}
	for path: String in pins:
		final[path]=FileAccess.get_sha256(path);need(final[path]==pins[path],"SOURCE_FINAL:"+path)
	need(Time.get_ticks_msec()-began<60000,"FIXED60S_BUDGET")
	result.merge({"passed":error.is_empty() and result.get("published")==true,"error":error,"source_first":pins,"source_final":final,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":60000,"no_Field_C_Router_GS_or_old_geometry_execution":true},true)
	var report: String=HERE+"geometry/"+str(OS.get_process_id())+"/result.json"
	var ok: bool=json_new(report,result)
	print(JSON.stringify({"path":report,"passed":ok and result.passed,"error":error}));quit(0 if ok and result.passed else 1)
