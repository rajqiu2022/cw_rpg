extends SceneTree
## Root-only new Garden publication. Scenic bridge is never positive support.
const C=preload("res://build/luoyang_city_full_rollout_20261022ap_system01/garden_revision4/shore_landing_retry2/quarters_compiler.gd")
const WATER=preload("res://scripts/city/luoyang_harbour_water_patch_20261016.gd")
const BASE="res://build/luoyang_city_full_rollout_20261022ap_system01/garden_revision4/shore_landing_retry2/"
const AUTHOR=BASE+"author_READY.json"
const AUTHOR_SHA="937320f2e24d159e0dc5b023d72222be4118fb4e6d90e9558fa3cfba4ae55dfe"
const ID="luoyang_riverside_garden_20261022ap"
const OUT="res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/"+ID+"/"
const DOCK_PACKET="res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/packet.bin"
const DOCK_SHA="1cb6bbf9825d538c982fcdf1171c5f3e268854be54796c3684c91502da14f221"
var pins: Dictionary={}
var error: String=""
func _initialize() -> void: call_deferred("run")
func need(value: bool,label: String) -> bool:
	if not value and error.is_empty(): error=label;push_error("AP_GARDEN "+label)
	return value
func track(p: String,expected: String="") -> bool:
	var sha: String=FileAccess.get_sha256(p)
	if not need(sha.length()==64 and (expected.is_empty() or sha==expected) and (not pins.has(p) or pins[p]==sha),"SOURCE:"+p): return false
	pins[p]=sha;return true
func write_json(path: String,data: Dictionary) -> bool:
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(data,"\t",true,true));file.close();return true
func dock_return() -> Dictionary:
	if not track(DOCK_PACKET,DOCK_SHA): return {}
	var raw: Variant=bytes_to_var(FileAccess.get_file_as_bytes(DOCK_PACKET))
	if not need(raw is Dictionary and raw.get("walk_bytes") is PackedByteArray and raw.walk_bytes.size()==3072*2048*4 and raw.get("solids") is Array,"DOCK_PACKET_SHAPE"): return {}
	var image:=Image.create_from_data(3072,2048,false,Image.FORMAT_RGBA8,raw.walk_bytes)
	var solids: Array[Dictionary]=[]
	for i: int in raw.solids.size():
		if not need(raw.solids[i] is PackedVector2Array,"DOCK_POLYGON_TYPE"): return {}
		solids.append({"id":"old_docks_"+str(i),"polygon_px":raw.solids[i]})
	for dy: float in [0.0,10.0,24.0]:
		if not need(C.safe_body(Vector2(512,1840+dy),image,solids),"DOCK_RETURN_FULL87517_PLUS24"): return {}
	return {"ok":true,"foot":Vector2(512,1840),"full875_plus17":true,"plus10_plus24":true,"geometry_not_replayed":true,"immutable_packet_sha256":DOCK_SHA}
func publish() -> Dictionary:
	for path: String in [get_script().resource_path,"res://build/luoyang_city_full_rollout_20261022ap_system01/garden_revision4/shore_landing_retry2/quarters_compiler.gd",C.B_PATH,"res://scripts/domain/scene_script.gd","res://scripts/domain/walkable_map_layout.gd"]:
		if not track(path): return {}
	if not track(AUTHOR,AUTHOR_SHA): return {}
	var author: Variant=JSON.parse_string(FileAccess.get_file_as_string(AUTHOR))
	if not need(author is Dictionary,"AUTHOR_OBJECT"): return {}
	var checked: Dictionary=C.source_pins(author)
	if not need(checked.get("ok")==true,"AUTHOR_BINDINGS:"+str(checked)): return checked
	for path: String in checked.pins:
		if not track(path,checked.pins[path]): return {}
	var docking: Dictionary=dock_return()
	if not need(docking.get("ok")==true,"CURRENT_DOCKS_RETURN"): return docking
	var compiled: Dictionary=C.compile(author,ID)
	if not need(compiled.get("ok")==true,"COMPILE:"+str(compiled)): return compiled
	compiled.scene.set_meta(C.META,pins[AUTHOR])
	var geometry: Dictionary=C.audit(compiled)
	if not need(geometry.get("ok")==true,"ALL_GARDEN_ROUTES:"+str(geometry)): return geometry
	var blocked_points: Array=[Vector2(1580,1240),Vector2(1450,1200),Vector2(1800,1290)]
	for point: Vector2 in blocked_points:
		if not need(not C.safe_body(point,compiled.mask,compiled.solids),"SCENIC_BRIDGE_AND_WATER_REJECT_BODY"): return {}
	var water_packet: Dictionary=WATER.prepare_packet()
	if not need(WATER.packet_valid(water_packet),"EXACT_DOCKS_DEEPWATER_SAME_CAPTURE"): return {}
	if not need(not DirAccess.dir_exists_absolute(OUT) and not FileAccess.file_exists(BASE+"publication_assets/walk.png"),"NO_OVERWRITE_NEW_GARDEN_ONLY"): return {}
	if not need(DirAccess.make_dir_recursive_absolute(OUT)==OK and DirAccess.make_dir_recursive_absolute(BASE+"publication_assets")==OK,"OUTPUT_DIR"): return {}
	var water_image:=Image.create_from_data(200,280,false,Image.FORMAT_RGBA8,water_packet.bytes)
	var water_texture:=ImageTexture.create_from_image(water_image)
	if not need(ResourceSaver.save(water_texture,OUT+"deepwater.res")==OK,"WATER_NATIVE_TEXTURE_WRITE"): return {}
	var water_read: Texture2D=ResourceLoader.load(OUT+"deepwater.res","",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	if not need(water_read!=null and water_read.get_image().get_data()==water_packet.bytes,"WATER_FULL_RGBA_READBACK"): return {}
	var walk: String=BASE+"publication_assets/walk.png"
	if not need(compiled.mask.save_png(walk)==OK,"WALK_WRITE"): return {}
	var read_image: Image=Image.load_from_file(walk)
	if read_image!=null: read_image.convert(Image.FORMAT_RGBA8)
	if not need(read_image!=null and read_image.get_data()==compiled.mask.get_data(),"WHOLE_MASK_RGBA_READBACK"): return {}
	var scene: SceneScript=compiled.scene
	var expected_scene: Dictionary=C.b().storage(scene);var expected_layout: Dictionary=C.b().storage(scene.map_layout)
	if not need(ResourceSaver.save(scene.map_layout,OUT+"layout.res")==OK,"LAYOUT_WRITE"): return {}
	scene.map_layout=ResourceLoader.load(OUT+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not need(scene.map_layout!=null and ResourceSaver.save(scene,OUT+"scene.res")==OK,"SCENE_WRITE"): return {}
	var read: SceneScript=ResourceLoader.load(OUT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(read!=null and C.b().equal(C.b().storage(read),expected_scene) and C.b().equal(C.b().storage(read.map_layout),expected_layout),"FULL_TYPED_NATIVE_READBACK"): return {}
	var packet: Dictionary={"kind":"AP_SOURCE_BOUND_NEW_ORDINARY_QUARTER","scene_id":ID,"author_path":AUTHOR,"author_sha256":pins[AUTHOR],"scene_storage":expected_scene,"layout_storage":expected_layout,"solids":compiled.solids,"mask_sha256":C.b().bytes_sha(compiled.mask.get_data()),"walk_bytes":compiled.mask.get_data(),"geometry":geometry,"scenic_bridge_not_traversable":true,"water_texture_path":OUT+"deepwater.res","water_rgba_sha256":WATER.RGBA_SHA}
	if not need(C.b()._plain(packet),"PLAIN_PACKET"): return {}
	var file:=FileAccess.open(OUT+"packet.bin",FileAccess.WRITE)
	if not need(file!=null,"PACKET_OPEN"): return {}
	file.store_buffer(var_to_bytes(packet));file.close()
	if not need(C.b().equal(bytes_to_var(FileAccess.get_file_as_bytes(OUT+"packet.bin")),packet),"FULL_PACKET_READBACK"): return {}
	var artifacts: Dictionary={}
	for name: String in ["scene.res","layout.res","packet.bin","deepwater.res"]: artifacts[OUT+name]=FileAccess.get_sha256(OUT+name)
	return {"published":true,"artifacts":artifacts,"geometry":geometry,"adult_doors":compiled.adult_doors,"visual_count":read.map_layout.visual_objects.size(),"solid_count":compiled.solids.size(),"portal_count":read.map_layout.portals.size(),"water_visual_polygons":1,"water_visual_equals_physics_and_mask_polygon":true,"scenic_bridge_not_traversable":true,"no_bridge_positive_support":true,"water_rgba_sha256":WATER.RGBA_SHA,"docks_reciprocal_return":docking,"walk_candidate":{"path":walk,"canonical_target":OUT+"walk.png","sha256":FileAccess.get_sha256(walk),"rgba_sha256":packet.mask_sha256},"no_Artisan_Market_or_old_geometry_replay":true}
func run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var began: int=Time.get_ticks_msec();var result: Dictionary=publish();var final: Dictionary={}
	for path: String in pins:
		final[path]=FileAccess.get_sha256(path);need(final[path]==pins[path],"SOURCE_FINAL:"+path)
	need(Time.get_ticks_msec()-began<=60000,"FIXED_60S_LIMIT")
	result.merge({"passed":error.is_empty() and result.get("published")==true,"error":error,"source_first":pins,"source_final":final,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":60000,"scope":"AP_GARDEN_NATIVE_LAND_PATHS_SCENIC_BRIDGE_NOT_FORMAL_FIELD_ART"},true)
	var report: String=BASE+"publication/"+str(OS.get_process_id())+"/result.json"
	var written: bool=write_json(report,result)
	print(JSON.stringify({"path":report,"passed":written and result.passed,"error":error}));quit(0 if written and result.passed else 1)
