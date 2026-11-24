extends SceneTree
## ROOT-only exact wall successor. Original 83 visuals/20 bodies and six
## admitted shoulder/bed entities stay unchanged; no old full-route rerun.
const E=preload("res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd")
const A=preload("res://build/luoyang_estate_courtyard_20261021ak_system01/architecture_candidate.gd")
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const HERE="res://build/luoyang_estate_courtyard_20261021an_system01/"
const ROOT2=HERE+"revision2_native_walls/"
const PARENT=HERE+"native_candidate/"
const REPORT=HERE+"geometry/120540/result.json"
const REPORT_SHA="e5cdbd812293266d16c4b2a4357eb308bf7ca9467cb824b3cc2316847d219625"
const ART="res://build/luoyang_estate_courtyard_20261021an_art01/"
const OLD_ART=ART+"native_perimeter_wall_successor.json"
const OLD_SHA="2a4bc3beaab04f31c8e205e78042046288171204c51a65be75a65269a7b21ada"
const FINAL_ART=ART+"final_gate_material_horizontal_wall_author.json"
const FINAL_SHA="22376bd31c59eabb0fd3c3df7db7adaebd906a99005ec8811b948e0889f07eb8"
const POSTSCRIPT=ART+"final_gate_material_horizontal_wall_author_postscript2.json"
const POSTSCRIPT_SHA="46474ea486848689aaf4fcb861303d90485c64c5200f0f9499226fb849886a44"
const OUTPUT=ROOT2+"native_candidate/"
const WALK=ROOT2+"publication_assets/walk_candidate.png"
const SIZE=Vector2(3072,2048)
var pins: Dictionary={}
var error: String=""
func _initialize() -> void: call_deferred("_run")
func need(ok: bool,label: String) -> bool:
	if not ok and error.is_empty(): error=label;push_error("AN_WALL_DELTA "+label)
	return ok
func track(path: String,expected: String="") -> bool:
	var sha: String=FileAccess.get_sha256(path)
	if not need(path.begins_with("res://") and ".." not in path and sha.length()==64 and (expected.is_empty() or sha==expected.to_lower()) and (not pins.has(path) or pins[path]==sha),"SOURCE:"+path): return false
	pins[path]=sha;return true
func write_json(path: String,value: Dictionary) -> bool:
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(value,"\t",true,true));file.close();return true
func pixels(rect: Rect2) -> Rect2i:
	var start:=Vector2i(ceili(rect.position.x),ceili(rect.position.y))
	return Rect2i(start,Vector2i(floori(rect.end.x),floori(rect.end.y))-start+Vector2i.ONE)
func body_join(left: Dictionary,right: Dictionary) -> bool:
	var area: float=E.rect(left.rect_px).intersection(E.rect(right.rect_px)).get_area()
	if area<=0: return true
	var pair: Array=[left.id,right.id]
	for approved: Array in [
		["estate_an3_north_west_plinth_join_solid_0","estate_ak_main_hall_solid_0",11.0],
		["estate_an3_north_east_plinth_join_solid_0","estate_ak_main_hall_solid_1",9.0],
		["estate_an3_southwest_gate_jamb_fill_solid_0","estate_gate_jamb_0",0.0],
		["estate_an3_southeast_gate_jamb_fill_solid_0","estate_gate_jamb_1",0.0],
		["estate_an3_north_west_0a_solid_0","estate_an2_west_side_0_solid_0",0.0],
		["estate_an3_north_east_2b_solid_0","estate_an2_east_side_0_solid_0",0.0]
	]:
		if pair in [[approved[0],approved[1]],[approved[1],approved[0]]]: return area<=float(approved[2])
	# Only exact consecutive longitudinal modules may touch at their shared
	# source-derived ground edge. Numeric float32 contact must remain subpixel.
	for side: String in ["west","east"]:
		for i: int in 3:
			var ids: Array=["estate_an2_"+side+"_side_"+str(i)+"_solid_0","estate_an2_"+side+"_side_"+str(i+1)+"_solid_0"]
			if pair in [ids,[ids[1],ids[0]]]: return area<.1
	return false
func run_delta() -> Dictionary:
	if not need(OS.get_cmdline_user_args().is_empty(),"NO_ARGS") or not track(REPORT,REPORT_SHA) or not track(OLD_ART,OLD_SHA) or not track(FINAL_ART,FINAL_SHA) or not track(POSTSCRIPT,POSTSCRIPT_SHA): return {}
	var proof: Dictionary=E.json(REPORT);var old_art: Dictionary=E.json(OLD_ART);var art: Dictionary=E.json(FINAL_ART);var post: Dictionary=E.json(POSTSCRIPT)
	if not need(post.get("parent_author_sha256","").to_lower()==FINAL_SHA and post.new_atlas_assets.size()==2 and post.append_horizontal_components.size()==2,"EXACT_TWO_ROW_GATE_JAMB_POSTSCRIPT"): return {}
	for key: String in post.new_atlas_assets:
		var item: Dictionary=post.new_atlas_assets[key].duplicate(true);item.uniform_scale=1.0/3.0;art.atlas_assets[key]=item
	art.horizontal_components.append_array(post.append_horizontal_components)
	if not need(proof.get("passed")==true and proof.source_first==proof.source_final and proof.visual_rows==95 and proof.physical_rectangles==32,"EXACT_ACTUAL_PARENT"): return {}
	for path: String in proof.source_first:
		if not track(path,proof.source_first[path]): return {}
	for path: String in proof.artifacts:
		if not track(path,proof.artifacts[path]): return {}
	if not track(get_script().resource_path): return {}
	var parent: Variant=bytes_to_var(FileAccess.get_file_as_bytes(PARENT+"packet.bin"))
	var scene:=ResourceLoader.load(PARENT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(parent is Dictionary and scene!=null and B.equal(B.storage(scene),parent.scene_storage) and B.equal(B.storage(scene.map_layout),parent.layout_storage),"FULL_PARENT_NATIVE_STORAGE"): return {}
	var retained: Array[Dictionary]=[];var removed_visual: Array[Dictionary]=[];var removed: Array[Dictionary]=[];var solids: Array[Dictionary]=[]
	for row: Dictionary in scene.map_layout.visual_objects:
		if row.id in old_art.supersedes_only: removed_visual.append(row.duplicate(true))
		else: retained.append(row.duplicate(true))
	for row: Dictionary in parent.rectangular_solids:
		var erase: bool=false
		for id: String in old_art.supersedes_only:
			if row.id==id+"_solid_0": erase=true
		if erase: removed.append(row.duplicate(true))
		else: solids.append(row.duplicate(true))
	if not need(retained.size()==89 and removed_visual.size()==6 and removed.size()==6 and solids.size()==26,"EXACT_89_AND26_RETAINED_SIX_REMOVED"): return {}
	var assets: Dictionary={};var texture_artifacts: Dictionary={}
	var vertical: Dictionary=old_art.native_sources.vertical_wall
	if not track(vertical.texture_path,vertical.png_sha256) or not track(vertical.texture_path+".import",vertical.import_sha256) or not track(vertical.metadata_path,vertical.metadata_sha256) or not track(art.source.texture_path,art.source.png_sha256) or not track(art.source.import_path,art.source.import_sha256): return {}
	assets.vertical_wall={"texture":vertical.texture_path,"size":E.v(vertical.source_size_px),"anchor":E.v(vertical.ground_anchor_px),"scale":1.0}
	# Existing imported longitudinal wall is a runtime dependency, not a new
	# import. Follow its exact ART-pinned sidecar once to track its compiled leaf.
	var cfg:=ConfigFile.new()
	if not need(cfg.load(vertical.texture_path+".import")==OK,"VERTICAL_EXISTING_IMPORT_CONFIG"): return {}
	var compiled: Variant=cfg.get_value("remap","path",null)
	if not need(compiled is String and compiled.begins_with("res://.godot/imported/") and compiled.ends_with(".ctex"),"VERTICAL_EXACT_COMPILED_DEPENDENCY") or not track(compiled): return {}
	if not need(not DirAccess.dir_exists_absolute(OUTPUT) and not FileAccess.file_exists(WALK) and DirAccess.make_dir_recursive_absolute(OUTPUT)==OK,"NEW_OUTPUT_ONLY"): return {}
	var raw: Image=Image.load_from_file(art.source.texture_path)
	if not need(raw!=null,"GATE_SOURCE_IMAGE"): return {}
	for key: String in art.atlas_assets:
		var item: Dictionary=art.atlas_assets[key];var region: Rect2=E.rect(item.atlas_region_xywh);var image: Image=raw.get_region(Rect2i(region))
		if not need(image.get_size()==Vector2i(E.v(item.source_size_px)) and image.get_used_rect()==Rect2i(E.rect(item.complete_A1_xywh)),"EXACT_SOURCE_CROP_A1:"+key): return {}
		var path: String=OUTPUT+key+".tres";var atlas:=AtlasTexture.new();atlas.atlas=load(art.source.texture_path);atlas.region=region
		if not need(ResourceSaver.save(atlas,path)==OK,"NEW_UNEDITED_ATLAS_REGION"): return {}
		texture_artifacts[path]=FileAccess.get_sha256(path)
		assets[key]={"texture":path,"size":E.v(item.source_size_px),"anchor":E.v(item.ground_anchor_px),"scale":float(item.uniform_scale)}
	var components: Array=[]
	for row: Dictionary in old_art.wall_components:
		if row.asset=="vertical_wall": components.append(row.duplicate(true))
	components.append_array(art.horizontal_components)
	var walls: Array[Dictionary]=[];var added: Array[Dictionary]=[]
	for row: Dictionary in components:
		var item: Dictionary=assets[row.asset];walls.append(E.visual(row.id,item.texture,E.v(row.foot),item.size,item.anchor,item.scale))
		var foot: Vector2=E.v(row.foot);var box: Rect2
		if row.asset=="vertical_wall":
			var relative: Rect2=E.rect(vertical.world_ground_solid_relative_to_foot_xywh)
			box=Rect2(foot+relative.position,relative.size)
		else:
			var source_rect: Rect2=E.rect(art.atlas_assets[row.asset].solid_rect_px)
			box=Rect2(foot+(source_rect.position-item.anchor)*float(item.scale),source_rect.size*float(item.scale))
		added.append({"id":String(row.id)+"_solid_0","rect_px":[box.position.x,box.position.y,box.size.x,box.size.y],"source_semantics":"AN_final_ART_source_ground_rectangle_not_invisible_roof_extent"})
	if not need(walls.size()==22 and added.size()==22,"EXACT_TWENTY_TWO_WALL_ENTITIES"): return {}
	var changed: Array[Dictionary]=removed.duplicate(true);changed.append_array(added)
	solids.append_array(added)
	for i: int in added.size():
		for other: Dictionary in solids:
			if other.id==added[i].id: continue
			if not need(body_join(added[i],other),"ONLY_NAMED_GROUND_JOINTS:"+String(added[i].id)+":"+String(other.id)): return {}
	var base: Variant=bytes_to_var(FileAccess.get_file_as_bytes(parent.enclosure_successor_AM.parent_packet))
	if not need(base is Dictionary and base.walk_bytes is PackedByteArray,"AL_BASE_MASK"): return {}
	var old_mask:=Image.create_from_data(3072,2048,false,Image.FORMAT_RGBA8,parent.walk_bytes)
	var base_mask:=Image.create_from_data(3072,2048,false,Image.FORMAT_RGBA8,base.walk_bytes);var mask: Image=old_mask.duplicate()
	for row: Dictionary in removed:
		var raster: Rect2i=pixels(E.rect(row.rect_px))
		for y: int in range(raster.position.y,raster.end.y):
			for x: int in range(raster.position.x,raster.end.x):
				mask.set_pixel(x,y,Color.BLACK if A.point_in_solids(Vector2(x,y),solids.slice(0,26)) else base_mask.get_pixel(x,y))
	for row: Dictionary in added: mask.fill_rect(pixels(E.rect(row.rect_px)),Color.BLACK)
	var inverse_mask: Image=mask.duplicate()
	for row: Dictionary in changed:
		var raster: Rect2i=pixels(E.rect(row.rect_px))
		for y: int in range(raster.position.y,raster.end.y):
			for x: int in range(raster.position.x,raster.end.x): inverse_mask.set_pixel(x,y,old_mask.get_pixel(x,y))
	if not need(inverse_mask.get_data()==parent.walk_bytes,"FULL_RGBA_INVERSE_ONLY_REMOVED_AND_ADDED_DOMAINS"): return {}
	var base_author: Dictionary=E.json(E.AUTHOR);var routes: Array=[]
	for row: Dictionary in base_author.routes:
		if row.id!="dry_garden_loop": routes.append(row.duplicate(true))
	routes.append_array(parent.architecture_successor.new_routes);routes.append_array(parent.enclosure_successor_AM.new_routes)
	var reports: Array=[];var outer_replaced: int=0;var retired: Array[String]=[]
	const RETIRED=["am_around_northwest","am_around_northeast","am_around_west_return","am_around_east_return","am_around_southwest","am_around_southeast"]
	for route: Dictionary in routes:
		if route.id in RETIRED: retired.append(route.id);continue
		for replacement: Dictionary in parent.enclosure_successor_AM.route_replacements:
			if route.id==replacement.id: route.points=replacement.points.duplicate(true)
		var inherit: bool=true
		if route.id=="public_outer_loop":
			if not need(B.equal(route.points,[[1536,1840],[2950,1840],[2950,660],[140,660],[140,1840],[1536,1840]]),"EXACT_OLD_OUTER_LOOP"): return {}
			route.points=[[1536,1840],[2950,1840],[2950,360],[140,360],[140,1840],[1536,1840]];inherit=false;outer_replaced+=1
		var report: Dictionary=A.route_check(route,mask,solids,changed,inherit);reports.append(report)
		if not need(report.get("passed")==true,"AFFECTED_ROUTE:"+String(route.id)): return {"geometry":{"routes":reports}}
	if not need(outer_replaced==1,"SINGLE_OUTER_LOOP_EXPLICIT_SUCCESSOR"): return {}
	if not need(retired.size()==6,"ONLY_SIX_RETIRED_ENTITY_SPECIFIC_TEST_RINGS"): return {}
	var wall_routes: Array=[
		{"id":"an2_inside_north_wall","points":[[500,560],[1100,560],[1100,700],[1536,700],[1970,700],[1970,560],[2570,560]]},
		{"id":"an2_west_inner_wall","points":[[500,560],[500,900],[500,1212],[974,1212]]},
		{"id":"an2_east_inner_wall","points":[[2570,560],[2570,900],[2570,1212],[2098,1212]]}
	]
	for route: Dictionary in wall_routes:
		var report: Dictionary=A.route_check(route,mask,solids,changed,false);reports.append(report)
		if not need(report.get("passed")==true,"NEW_WALL_SIDE_ROUTE:"+String(route.id)): return {"geometry":{"routes":reports}}
	for foot: Vector2 in [Vector2(1536,544),Vector2(700,884),Vector2(2222,884),Vector2(1536,1144),Vector2(1536,1840),Vector2(1536,1940)]:
		for offset: Vector2 in [Vector2.ZERO,Vector2(0,24)]:
			if not need(E.safe_body(foot+offset,mask,solids),"REAL_DOORS_SPAWN_EXIT_PLUS24:"+str(foot+offset)): return {}
	# Test raised-wall source-base seams only, not a false sole-gate perimeter.
	# Two authentic open corridor bays retain their existing traversal routes.
	var crossing: Array=[]
	for foot: Vector2 in [Vector2(590,508),Vector2(750,508),Vector2(910,508),Vector2(1070,508),Vector2(2003,508),Vector2(2163,508),Vector2(2323,508),Vector2(2483,508),Vector2(430,680.192),Vector2(2642,680.192),Vector2(1160,1140),Vector2(1925,1140)]:
		var blocked: bool=not E.safe_body(foot,mask,solids);crossing.append({"foot":[foot.x,foot.y],"full875_plus17_blocked":blocked})
		if not need(blocked,"RAISED_WALL_TRUE_BASE_SEAM_NOT_CROSSABLE:"+str(foot)): return {"geometry":{"routes":reports,"crossing_probes":crossing}}
	var old_rows: Array[Dictionary]=scene.map_layout.visual_objects.duplicate(true);var old_blocks: Array[Dictionary]=scene.map_layout.blockers.duplicate(true)
	var rows: Array[Dictionary]=walls.duplicate(true);rows.append_array(retained)
	var blocks: Array[Dictionary]=[]
	for row: Dictionary in solids:
		var box: Rect2=E.rect(row.rect_px);blocks.append({"id":row.id,"pos":box.get_center()/SIZE,"size":box.size/SIZE,"walkability_margin":0.0})
	# Restore original unchanged blocker dictionaries rather than regenerate
	# their floating representation from nominal source rectangles.
	for i: int in 26:
		for block: Dictionary in old_blocks:
			if block.id==solids[i].id: blocks[i]=block.duplicate(true)
	scene.map_layout.visual_objects=rows;scene.map_layout.blockers=blocks
	var storage: Dictionary={"scene":B.storage(scene),"layout":B.storage(scene.map_layout)}
	scene.map_layout.visual_objects=old_rows;scene.map_layout.blockers=old_blocks
	if not need(B.equal(B.storage(scene),parent.scene_storage) and B.equal(B.storage(scene.map_layout),parent.layout_storage),"COMPLETE_TYPED_NATIVE_INVERSE"): return {}
	scene.map_layout.visual_objects=rows;scene.map_layout.blockers=blocks
	var packet: Dictionary=parent.duplicate(true)
	packet.scene_storage=storage.scene;packet.layout_storage=storage.layout;packet.rectangular_solids=solids;packet.walk_bytes=mask.get_data();packet.mask_sha256=B.bytes_sha(packet.walk_bytes)
	packet.geometry={"passed":true,"routes":reports,"all_solids":solids,"crossing_probes":crossing,"old_samples_inherited_except_changed_domain":true}
	var retained_routes: Array=[]
	for route: Dictionary in routes:
		if not route.id in RETIRED: retained_routes.append(route.duplicate(true))
	packet.wall_successor_AN2={"parent_packet":PARENT+"packet.bin","parent_sha256":proof.artifacts[PARENT+"packet.bin"],"art_path":FINAL_ART,"art_sha256":FINAL_SHA,"postscript_path":POSTSCRIPT,"postscript_sha256":POSTSCRIPT_SHA,"removed_exact_ids":old_art.supersedes_only,"retained89_and26_exact":true,"wall_draw_order":"NEW_WALLS_BEFORE_RETAINED89_AT_EQUAL_DEPTH_ONLY_TRUE_GROUND_FEET_UNCHANGED","south_depth_wording_successor":"Actual south wall foot1150 sorts at143, gate foot1120 sorts140. South wall is physically in front of jamb, not hidden behind gate; no false foot or arbitrary z override.","access_semantics":"RAISED_WALLS_BLOCKED_GATE_AND_TWO_OPEN_CORRIDORS_REMAIN_PASSABLE","retired_removed_entity_test_rings":retired,"retained_routes":retained_routes,"new_wall_routes":wall_routes,"no_full_old2710_or661_rerun":true}
	var inverse: Dictionary=packet.duplicate(true)
	for key: String in ["scene_storage","layout_storage","rectangular_solids","walk_bytes","mask_sha256","geometry"]: inverse[key]=parent[key]
	inverse.erase("wall_successor_AN2")
	if not need(B._plain(packet) and B.equal(inverse,parent),"FULL_PACKET_INVERSE"): return {}
	if not need(DirAccess.make_dir_recursive_absolute(WALK.get_base_dir())==OK and mask.save_png(WALK)==OK,"NEW_WALK_CANDIDATE"): return {}
	if not need(ResourceSaver.save(scene.map_layout,OUTPUT+"layout.res")==OK,"NEW_LAYOUT"): return {}
	scene.map_layout=ResourceLoader.load(OUTPUT+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not need(scene.map_layout!=null and ResourceSaver.save(scene,OUTPUT+"scene.res")==OK,"NEW_SCENE"): return {}
	var file:=FileAccess.open(OUTPUT+"packet.bin",FileAccess.WRITE)
	if not need(file!=null,"NEW_PACKET"): return {}
	file.store_buffer(var_to_bytes(packet));file.close()
	var readback:=ResourceLoader.load(OUTPUT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(readback!=null and B.equal(B.storage(readback),storage.scene) and B.equal(B.storage(readback.map_layout),storage.layout) and B.equal(bytes_to_var(FileAccess.get_file_as_bytes(OUTPUT+"packet.bin")),packet),"COMPLETE_NATIVE_READBACK"): return {}
	var artifacts: Dictionary=texture_artifacts.duplicate(true)
	for name: String in ["scene.res","layout.res","packet.bin"]: artifacts[OUTPUT+name]=FileAccess.get_sha256(OUTPUT+name)
	return {"published":true,"whole_parent_inverse":true,"artifacts":artifacts,"geometry":packet.geometry,"visual_rows":111,"physical_rectangles":48,"wall_components":components,"retained_visual_count":89,"new_wall_count":22,"walk_candidate":{"path":WALK,"sha256":FileAccess.get_sha256(WALK),"rgba_sha256":packet.mask_sha256,"future_path":"res://data/maps/luoyang_estate_courtyard_20261021am/walk.png"},"scope":"WALL_DELTA_ONLY_NOT_FIELD_FORMAL_OR_ART_ACCEPTANCE"}
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);var began: int=Time.get_ticks_msec();var result: Dictionary=run_delta();var final: Dictionary={}
	for path: String in pins:
		final[path]=FileAccess.get_sha256(path);need(final[path]==pins[path],"SOURCE_FINAL:"+path)
	need(Time.get_ticks_msec()-began<60000,"FIXED60S")
	result.merge({"passed":error.is_empty() and result.get("published")==true,"error":error,"source_first":pins,"source_final":final,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":60000},true)
	var path: String=ROOT2+"geometry/"+str(OS.get_process_id())+"/result.json";var written: bool=write_json(path,result)
	print(JSON.stringify({"passed":written and result.passed,"path":path,"error":error}));quit(0 if written and result.passed else 1)
