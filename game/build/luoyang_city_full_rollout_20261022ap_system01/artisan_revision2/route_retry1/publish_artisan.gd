extends SceneTree
## Root-only Artisan revision. No old 2714 route batch, other city or room geometry.
const C=preload("res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision2/quarters_compiler.gd")
const BASE="res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision2/route_retry1/"
const AUTHOR=BASE+"author.json"
const AUTHOR_SHA="7486af2b8792522ee864702a106ee24fa14bbfea6d5b98796a99eb49d963ef5f"
const ID="luoyang_artisan_residential_20261022ap"
const OUT="res://data/maps/luoyang_full_city_20261022ap/quarters/"+ID+"/"
const PARENT="res://data/maps/luoyang_full_city_20261022ap/"+ID+"/"
const PARENT_REPORT="res://build/luoyang_city_full_rollout_20261022ap_system01/publication/48408/result.json"
const PARENT_REPORT_SHA="ebcd7086038ffce7c99d1ba827f940df2ed9f4f98193bbf1ad6f6d88436f8229"
const PARENT_ARTIFACTS={"layout.res":"d00b47ec67203649ed74d64ca3fb0cc2f1093100c460a0b50e433e8f69f037a9","scene.res":"5dfb9c67a0456749c7e5b9911df2b71a7d706b0b9443443374e590724111290d","packet.bin":"41f5849d16c0ccf8e200bbefa8da9863d32024d683a0fc7a6c4681110b298107"}
var pins: Dictionary={}
var error: String=""
func _initialize() -> void: call_deferred("run")
func need(value: bool,label: String) -> bool:
	if not value and error.is_empty(): error=label;push_error("AP_ARTISAN_V2 "+label)
	return value
func track(p: String,expected: String="") -> bool:
	var sha: String=FileAccess.get_sha256(p)
	if not need(sha.length()==64 and (expected.is_empty() or sha==expected) and (not pins.has(p) or pins[p]==sha),"SOURCE:"+p): return false
	pins[p]=sha;return true
func write_json(p: String,data: Dictionary) -> bool:
	if FileAccess.file_exists(p) or DirAccess.make_dir_recursive_absolute(p.get_base_dir())!=OK: return false
	var f:=FileAccess.open(p,FileAccess.WRITE)
	if f==null: return false
	f.store_string(JSON.stringify(data,"\t",true,true));f.close();return true
func bounds(solid: Dictionary) -> Rect2:
	if solid.has("rect_px"): return C.rect(solid.rect_px)
	var lo:=Vector2(INF,INF);var hi:=Vector2(-INF,-INF)
	for p: Vector2 in solid.polygon_px: lo=lo.min(p);hi=hi.max(p)
	return Rect2(lo,hi-lo)
func main_exact(author: Dictionary,previous: Dictionary) -> bool:
	var old: Array=[];var current: Array=[]
	for row: Dictionary in previous.scenes[0].routes:
		if row.id=="main_axis": old=row.points
	for row: Dictionary in author.scenes[0].routes:
		if row.id=="main_axis": current=row.points
	if old.size()!=3 or current.size()!=3: return false
	for i: int in 3:
		if C.v(old[i])!=C.v(current[i]): return false
	return true
func exact_inverse(scene: SceneScript,parent: SceneScript) -> Dictionary:
	var now: Dictionary=C.b().storage(scene);var old: Dictionary=C.b().storage(parent)
	var inverse: Dictionary=now.duplicate(true)
	var meta: String="metadata/"+C.META
	if old.fields.has(meta): inverse.fields[meta]=old.fields[meta]
	else: inverse.fields.erase(meta)
	if not C.b().equal(inverse,old): return {"ok":false,"error":"ALL_SCENE_FIELDS_EXCEPT_AUTHOR_METADATA_EXACT"}
	var layout_now: Dictionary=C.b().storage(scene.map_layout);var layout_old: Dictionary=C.b().storage(parent.map_layout)
	var layout_inverse: Dictionary=layout_now.duplicate(true)
	for key: String in ["visual_objects","blockers","portals","walkable_mask_path"]:
		if not old_field_exists(layout_old,key): return {"ok":false,"error":"PARENT_LAYOUT_FIELD:"+key}
		layout_inverse.fields[key]=layout_old.fields[key].duplicate(true) if layout_old.fields[key] is Array or layout_old.fields[key] is Dictionary else layout_old.fields[key]
	if not C.b().equal(layout_inverse,layout_old): return {"ok":false,"error":"LAYOUT_UNLISTED_FIELDS_EXACT"}
	if not C.b().equal(scene.npcs,parent.npcs): return {"ok":false,"error":"ALL_FOUR_NPC_ROWS_EXACT"}
	return {"ok":true,"scene_fields_inverse":true,"layout_fields_inverse":true,"unchanged_NPCs_spawn_BGM_background_walkregions":true,"declared_layout_delta":["visual_objects","blockers","portals","walkable_mask_path"],"scene_metadata_delta_only":meta}
func old_field_exists(s: Dictionary,key: String) -> bool: return s.get("fields",{}).has(key)
func local_mask(parent: Dictionary,compiled: Dictionary,areas: Array[Rect2]) -> Dictionary:
	var old: PackedByteArray=parent.walk_bytes;var fresh: PackedByteArray=compiled.mask.get_data()
	if old.size()!=3072*2048*4 or fresh.size()!=old.size(): return {"ok":false,"error":"MASK_SIZE"}
	var count: int=0;var inverse: PackedByteArray=fresh.duplicate()
	for pixel: int in 3072*2048:
		var offset: int=pixel*4
		if old[offset]==fresh[offset] and old[offset+1]==fresh[offset+1] and old[offset+2]==fresh[offset+2] and old[offset+3]==fresh[offset+3]: continue
		var p:=Vector2(pixel%3072,pixel/3072);var allowed: bool=false
		for area: Rect2 in areas:
			if area.grow(1).has_point(p): allowed=true;break
		if not allowed: return {"ok":false,"error":"MASK_PIXEL_OUTSIDE_OLD_NEW_EXACT_SOLID_DOMAINS","pixel":p}
		for channel: int in 4: inverse[offset+channel]=old[offset+channel]
		count+=1
	return {"ok":inverse==old,"changed_pixels":count,"whole_RGBA_inverse":inverse==old,"outside_declared_solid_domains_unchanged":true,"new_mask_derived_from_all_authored_real_solids":true}
func publish() -> Dictionary:
	for p: String in [get_script().resource_path,"res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision2/quarters_compiler.gd",C.B_PATH,"res://scripts/domain/scene_script.gd","res://scripts/domain/walkable_map_layout.gd"]:
		if not track(p): return {}
	if not track(AUTHOR,AUTHOR_SHA) or not track(PARENT_REPORT,PARENT_REPORT_SHA): return {}
	for name: String in PARENT_ARTIFACTS:
		if not track(PARENT+name,PARENT_ARTIFACTS[name]): return {}
	var author: Variant=JSON.parse_string(FileAccess.get_file_as_string(AUTHOR))
	if not need(author is Dictionary,"AUTHOR_OBJECT"): return {}
	var checked: Dictionary=C.source_pins(author)
	if not need(checked.get("ok")==true,"AUTHOR_BINDINGS:"+str(checked)): return checked
	for p: String in checked.pins:
		if not track(p,checked.pins[p]): return {}
	var parent_packet: Variant=bytes_to_var(FileAccess.get_file_as_bytes(PARENT+"packet.bin"))
	var parent_scene: SceneScript=ResourceLoader.load(PARENT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(parent_packet is Dictionary and parent_scene!=null and C.b().equal(C.b().storage(parent_scene),parent_packet.scene_storage) and C.b().equal(C.b().storage(parent_scene.map_layout),parent_packet.layout_storage),"PARENT_NATIVE_WHOLE_PACKET_EXACT"): return {}
	if not track(parent_packet.author_path,parent_packet.author_sha256): return {}
	var parent_author: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(parent_packet.author_path))
	var compiled: Dictionary=C.compile(author,ID)
	if not need(compiled.get("ok")==true,"COMPILE:"+str(compiled)): return compiled
	compiled.scene.set_meta(C.META,pins[AUTHOR])
	var whole: Dictionary=exact_inverse(compiled.scene,parent_scene)
	if not need(whole.get("ok")==true,"WHOLE_INVERSE:"+str(whole)): return whole
	var areas: Array[Rect2]=[]
	for solid: Dictionary in parent_packet.solids: areas.append(bounds(solid))
	for solid: Dictionary in compiled.solids: areas.append(bounds(solid))
	var local: Dictionary=local_mask(parent_packet,compiled,areas)
	if not need(local.get("ok")==true,"LOCAL_MASK:"+str(local)): return local
	var delta: Dictionary={"main_axis_exact":main_exact(author,parent_author),"changed_areas":areas}
	if not need(delta.main_axis_exact,"UNCHANGED_MAIN_AXIS_AUTHOR_EXACT"): return {}
	var geometry: Dictionary=C.audit(compiled,delta)
	if not need(geometry.get("ok")==true,"NEW_AND_AFFECTED_ROUTES:"+str(geometry)): return geometry
	if not need(not DirAccess.dir_exists_absolute(OUT) and not FileAccess.file_exists(BASE+"publication_assets/walk.png"),"NEW_OUTPUT_ONLY"): return {}
	if not need(DirAccess.make_dir_recursive_absolute(OUT)==OK and DirAccess.make_dir_recursive_absolute(BASE+"publication_assets")==OK,"OUTPUT_DIR"): return {}
	var scene: SceneScript=compiled.scene;var storage: Dictionary={"scene":C.b().storage(scene),"layout":C.b().storage(scene.map_layout)}
	var walk: String=BASE+"publication_assets/walk.png"
	if not need(compiled.mask.save_png(walk)==OK,"WALK_WRITE"): return {}
	var read_image: Image=Image.load_from_file(walk)
	if read_image!=null: read_image.convert(Image.FORMAT_RGBA8)
	if not need(read_image!=null and read_image.get_data()==compiled.mask.get_data(),"WALK_RGBA_READBACK"): return {}
	if not need(ResourceSaver.save(scene.map_layout,OUT+"layout.res")==OK,"NATIVE_LAYOUT"): return {}
	scene.map_layout=ResourceLoader.load(OUT+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not need(scene.map_layout!=null and ResourceSaver.save(scene,OUT+"scene.res")==OK,"NATIVE_SCENE"): return {}
	var read: SceneScript=ResourceLoader.load(OUT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(read!=null and C.b().equal(C.b().storage(read),storage.scene) and C.b().equal(C.b().storage(read.map_layout),storage.layout),"WHOLE_NATIVE_READBACK"): return {}
	var packet: Dictionary={"kind":"AP_SOURCE_BOUND_NEW_ORDINARY_QUARTER","scene_id":ID,"author_path":AUTHOR,"author_sha256":pins[AUTHOR],"scene_storage":storage.scene,"layout_storage":storage.layout,"solids":compiled.solids,"mask_sha256":C.b().bytes_sha(compiled.mask.get_data()),"walk_bytes":compiled.mask.get_data(),"geometry":geometry,"parent_packet_sha256":PARENT_ARTIFACTS["packet.bin"],"parent_whole_inverse":whole,"local_mask_inverse":local}
	if not need(C.b()._plain(packet),"PLAIN_PACKET"): return {}
	var f:=FileAccess.open(OUT+"packet.bin",FileAccess.WRITE)
	if not need(f!=null,"PACKET_OPEN"): return {}
	f.store_buffer(var_to_bytes(packet));f.close()
	if not need(C.b().equal(bytes_to_var(FileAccess.get_file_as_bytes(OUT+"packet.bin")),packet),"WHOLE_PACKET_READBACK"): return {}
	var artifacts: Dictionary={}
	for name: String in ["layout.res","scene.res","packet.bin"]: artifacts[OUT+name]=FileAccess.get_sha256(OUT+name)
	return {"published":true,"artifacts":artifacts,"geometry":geometry,"mask_delta":local,"whole_parent_inverse":whole,"natural_depth_exact_visual_pairs":compiled.exact_natural_depth_overlaps,"visual_count":read.map_layout.visual_objects.size(),"solid_count":compiled.solids.size(),"portal_count":read.map_layout.portals.size(),"walk_candidate":{"path":walk,"canonical_target":OUT+"walk.png","sha256":FileAccess.get_sha256(walk),"rgba_sha256":packet.mask_sha256},"old_2714_not_replayed":true,"no_other_city_or_room_geometry":true}
func run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var began: int=Time.get_ticks_msec();var result: Dictionary=publish();var final: Dictionary={}
	for p: String in pins:
		final[p]=FileAccess.get_sha256(p);need(final[p]==pins[p],"SOURCE_FINAL:"+p)
	need(Time.get_ticks_msec()-began<=60000,"FIXED_60S_LIMIT")
	result.merge({"passed":error.is_empty() and result.get("published")==true,"error":error,"source_first":pins,"source_final":final,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":60000,"scope":"AP_ARTISAN_VISUAL_AND_LOCAL_GEOMETRY_SUCCESSOR_NOT_FORMAL_FIELD_ART"},true)
	var report: String=BASE+"publication/"+str(OS.get_process_id())+"/result.json"
	var written: bool=write_json(report,result)
	print(JSON.stringify({"path":report,"passed":written and result.passed,"error":error}));quit(0 if written and result.passed else 1)
