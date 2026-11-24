extends SceneTree
## Root-only Garden native publication. No Field, other-city compiler or collector.
const C=preload("res://build/luoyang_garden_river_20261025h_source01/garden_river_compiler02_NOTREADY.gd")
const BASE="res://build/luoyang_garden_river_20261025h_source01/"
const ID="luoyang_riverside_garden_20261022ap"
const PNG="res://art/modules/world_map_v13/bridge_stone_eastwest_v1.png"
const DIRECT="res://.godot/imported/bridge_stone_eastwest_v1.png-0998f3b4f19020d7c304ba512c851a24.ctex"
var error: String=""
var checks: int=0
var pins: Dictionary={}
var diagnostic: Dictionary={}
func _initialize() -> void: call_deferred("run")
func need(ok: bool,label: String,detail: Variant=null) -> bool:
	checks+=1
	if not ok and error.is_empty(): error=label;diagnostic["failure_detail"]=detail;push_error("GARDEN25H "+label)
	return ok
func track(path: String,expected: String) -> bool:
	if not need(path.begins_with("res://") and not ".." in path and expected.length()==64,"FIXED_SOURCE_LEAF",path): return false
	var actual: String=FileAccess.get_sha256(path)
	if not need(actual==expected and (not pins.has(path) or pins[path]==actual),"SOURCE_CHANGED",path): return false
	pins[path]=actual;return true
func json_file(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
func write_json(path: String,value: Dictionary) -> bool:
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var file: FileAccess=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(value,"\t",true,true));file.close();return true
func bridge_images() -> Dictionary:
	var cfg: ConfigFile=ConfigFile.new()
	if not need(cfg.load(PNG+".import")==OK,"BRIDGE_EXISTING_SIDECAR_LOAD"): return {}
	if not need(cfg.get_section_keys("params").size()==23 and cfg.get_value("params","compress/mode",-1)==0 and cfg.get_value("params","mipmaps/generate",true)==false and cfg.get_value("params","process/fix_alpha_border",false)==true and cfg.get_value("params","detect_3d/compress_to",-1)==1,"UNCHANGED_EXISTING_23_PARAMS_MIP0_FIXTRUE_DETECT1"): return {}
	var raw: Image=Image.load_from_file(PNG)
	var imported: Texture2D=ResourceLoader.load(PNG,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var direct: Texture2D=ResourceLoader.load(DIRECT,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	if not need(raw!=null and imported!=null and direct!=null,"BRIDGE_THREE_READS"): return {}
	var imported_image: Image=imported.get_image();var direct_image: Image=direct.get_image()
	if not need(imported_image!=null and direct_image!=null and raw.get_size()==Vector2i(1774,887) and imported_image.get_size()==raw.get_size() and direct_image.get_size()==raw.get_size() and not imported_image.has_mipmaps() and not direct_image.has_mipmaps(),"BRIDGE_EXACT_THREE_SIZES_MIP0"): return {}
	raw.convert(Image.FORMAT_RGBA8);imported_image.convert(Image.FORMAT_RGBA8);direct_image.convert(Image.FORMAT_RGBA8)
	var a: PackedByteArray=raw.get_data();var b: PackedByteArray=imported_image.get_data();var d: PackedByteArray=direct_image.get_data()
	if not need(b==d,"IMPORTED_EQUALS_DIRECT_WHOLE_RGBA"): return {}
	var visible: int=0;var hidden_rgb_differences: int=0
	for i: int in range(0,a.size(),4):
		if not need(a[i+3]==b[i+3],"BRIDGE_WHOLE_ALPHA_CHANNEL_EXACT",i/4): return {}
		if a[i+3]>=250:
			if not need(a[i]==b[i] and a[i+1]==b[i+1] and a[i+2]==b[i+2],"VISIBLE_BODY_RGB_EXACT",i/4): return {}
			visible+=1
		elif a[i]!=b[i] or a[i+1]!=b[i+1] or a[i+2]!=b[i+2]: hidden_rgb_differences+=1
	var deck_pixels: int=0;var minimum_alpha: int=255
	for y: int in range(298,523):
		for x: int in range(48,1719):
			var alpha: int=a[(y*1774+x)*4+3]
			if not need(alpha>=250,"CLOSED_VISIBLE_DECK_ALL_PIXELS",Vector2i(x,y)): return {}
			minimum_alpha=mini(minimum_alpha,alpha);deck_pixels+=1
	return {"ok":true,"raw_rgba_sha256":C.b().bytes_sha(a),"imported_rgba_sha256":C.b().bytes_sha(b),"direct_rgba_sha256":C.b().bytes_sha(d),"full_raw_import_RGBA_equal":a==b,"whole_alpha_equal":true,"all_raw_alpha_ge250_RGB_exact":true,"visible_pixels":visible,"hidden_or_edge_RGB_differences":hidden_rgb_differences,"source_deck_closed_pixels":deck_pixels,"source_deck_minimum_alpha":minimum_alpha,"PNG_and_import_parameters_unchanged":true}
func publish(input: Dictionary) -> Dictionary:
	if not need(input.get("ready")==true and input.get("status")=="ROOT_READY_GARDEN_NATIVE_PUBLICATION_ONLY" and input.get("scope")=="GARDEN_ONLY_NO_OTHER_CITY_OR_ROOM_GEOMETRY_REPLAY","ROOT_READY_REQUIRED"): return {}
	if not need(input.get("sources") is Dictionary and not input.sources.is_empty(),"FIXED_SOURCES_REQUIRED"): return {}
	for path: String in input.sources:
		if not track(path,input.sources[path]): return {}
	if not need(input.sources.has(get_script().resource_path),"PUBLISHER_SELF_PIN"): return {}
	var author: Dictionary=json_file(input.author.path)
	var prior: Dictionary=json_file(input.prior.path)
	if not need(prior.get("status")=="SOURCE_EXPRESSION_GARDEN_PIXEL_PRIOR_PROPOSAL_NOT_NATIVE_OR_ART_ADMISSION" and prior.get("author",{}).get("sha256")==input.author.sha256 and prior.get("outside_domains_changed_pixels") == 0 and prior.get("engine") == 0,"FIXED_SOURCE_PRIOR_SCHEMA"): return {}
	var art: Dictionary=C.source_pins(author)
	if not need(art.get("ok")==true,"AUTHOR_SOURCE_PINS",art): return {}
	diagnostic["bridge_source_images"]=bridge_images()
	if not need(diagnostic.bridge_source_images.get("ok")==true,"BRIDGE_LEGACY_IMPORTED_TUPLE"): return {}
	var compiled: Dictionary=C.compile(author,ID)
	if not need(compiled.get("ok")==true,"GARDEN_COMPILE",compiled): return {}
	compiled.scene.set_meta(C.META,input.author.sha256)
	var child_sha: String=C.b().bytes_sha(compiled.mask.get_data())
	diagnostic["child_rgba_sha256"]=child_sha
	if not need(child_sha==prior.expected_child_rgba_sha256,"INDEPENDENT_SOURCE_RGBA_PRIOR",{"expected":prior.expected_child_rgba_sha256,"actual":child_sha}): return {}
	var geometry: Dictionary=C.audit(compiled)
	diagnostic["route_and_NPC_audit"]=geometry
	if not need(geometry.get("ok")==true,"FINITE_NEW_GARDEN_ROUTES_AND_NPCS",geometry): return {}
	for foot: Vector2 in [Vector2(1536,976),Vector2(920,976),Vector2(2160,976)]:
		if not need(C.safe_body(foot,compiled.mask,compiled.solids),"BRIDGE_DECK_OR_LANDING_FULL_BODY",foot): return {}
	for foot: Vector2 in [Vector2(1536,860),Vector2(1536,1100),Vector2(1536,890),Vector2(1536,1070)]:
		if not need(not C.safe_body(foot,compiled.mask,compiled.solids),"RAIL_OR_ADJACENT_WATER_NEGATIVE",foot): return {}
	var parent_walk: Image=Image.load_from_file(prior.parent_walk.path)
	if not need(parent_walk!=null,"FIXED_PARENT_WALK"): return {}
	parent_walk.convert(Image.FORMAT_RGBA8)
	if not need(C.b().bytes_sha(parent_walk.get_data())==prior.parent_walk.rgba_sha256,"PARENT_RGBA_EXACT"): return {}
	var old: PackedByteArray=parent_walk.get_data();var now: PackedByteArray=compiled.mask.get_data()
	var changed: int=0;var outside: int=0
	for y: int in range(2048):
		for x: int in range(3072):
			var at: int=(y*3072+x)*4
			if old[at]==now[at] and old[at+1]==now[at+1] and old[at+2]==now[at+2] and old[at+3]==now[at+3]: continue
			changed+=1;var in_domain: bool=false
			for domain: Array in prior.closed_rect_domains_xywh:
				if Rect2i(int(domain[0]),int(domain[1]),int(domain[2]),int(domain[3])).has_point(Vector2i(x,y)): in_domain=true;break
			if not in_domain: outside+=1
	if not need(changed==int(prior.changed_pixels) and outside==0,"FINITE_CHANGED_COUNT_AND_OUTSIDE_INVERSE",{"changed":changed,"outside":outside}): return {}
	var output: String=C.NATIVE_ROOT+ID+"/"
	if not need(not DirAccess.dir_exists_absolute(C.NATIVE_ROOT) and not FileAccess.file_exists(C.NATIVE_ROOT+"front_rail.res"),"NEW_NATIVE_OUTPUT_ABSENT"): return {}
	if not need(DirAccess.make_dir_recursive_absolute(output)==OK,"NEW_NATIVE_DIR"): return {}
	var atlas: AtlasTexture=AtlasTexture.new();atlas.atlas=ResourceLoader.load(PNG) as Texture2D
	atlas.region=C.rect(author.bridge_contract.front_region_source_rect);atlas.margin=Rect2();atlas.filter_clip=true
	if not need(ResourceSaver.save(atlas,C.NATIVE_ROOT+"front_rail.res")==OK,"NATIVE_FRONT_REGION_WRITE"): return {}
	var front: AtlasTexture=ResourceLoader.load(C.NATIVE_ROOT+"front_rail.res","",ResourceLoader.CACHE_MODE_IGNORE) as AtlasTexture
	if not need(front!=null and front.atlas.resource_path==PNG and front.region==atlas.region and front.margin==Rect2() and front.get_image().get_data()==atlas.atlas.get_image().get_region(Rect2i(atlas.region)).get_data(),"FRONT_ORIGINAL_UV_PIXEL_ALIGNMENT"): return {}
	if not need(compiled.mask.save_png(output+"walk.png")==OK,"NEW_WALK_WRITE"): return {}
	var scene: SceneScript=compiled.scene
	var expected_scene: Dictionary=C.b().storage(scene);var expected_layout: Dictionary=C.b().storage(scene.map_layout)
	if not need(ResourceSaver.save(scene.map_layout,output+"layout.res")==OK,"NEW_LAYOUT_WRITE"): return {}
	scene.map_layout=ResourceLoader.load(output+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not need(scene.map_layout!=null and ResourceSaver.save(scene,output+"scene.res")==OK,"NEW_SCENE_WRITE"): return {}
	var loaded: SceneScript=ResourceLoader.load(output+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(loaded!=null and C.b().equal(C.b().storage(loaded),expected_scene) and C.b().equal(C.b().storage(loaded.map_layout),expected_layout),"FULL_TYPED_NATIVE_STORAGE_READBACK"): return {}
	var packet: Dictionary={"kind":"AP_SOURCE_BOUND_NEW_ORDINARY_QUARTER","scene_id":ID,"author_path":input.author.path,"author_sha256":input.author.sha256,"scene_storage":expected_scene,"layout_storage":expected_layout,"solids":compiled.solids,"mask_sha256":child_sha,"walk_bytes":compiled.mask.get_data(),"geometry":geometry,"river_bridge25h":{"water_visual_polygon":compiled.water_visual_polygon,"water_physics_pieces":compiled.water_physics_pieces,"deck":compiled.bridge_deck,"front_region_path":C.NATIVE_ROOT+"front_rail.res","independent_prior":input.prior,"whole_parent_outside_domains_inverse":true}}
	if not need(C.b()._plain(packet),"PLAIN_NATIVE_PACKET"): return {}
	var file: FileAccess=FileAccess.open(output+"packet.bin",FileAccess.WRITE)
	if not need(file!=null,"NATIVE_PACKET_FILE"): return {}
	file.store_buffer(var_to_bytes(packet));file.close()
	if not need(C.b().equal(bytes_to_var(FileAccess.get_file_as_bytes(output+"packet.bin")),packet),"FULL_PACKET_NATIVE_READBACK"): return {}
	var artifacts: Dictionary={}
	for path: String in [output+"scene.res",output+"layout.res",output+"packet.bin",output+"walk.png",C.NATIVE_ROOT+"front_rail.res"]: artifacts[path]=FileAccess.get_sha256(path)
	return {"published":true,"artifacts":artifacts,"visual_count":loaded.map_layout.visual_objects.size(),"solid_count":compiled.solids.size(),"portal_count":loaded.map_layout.portals.size(),"geometry":geometry,"adult_doors":compiled.adult_doors,"changed_pixels":changed,"outside_domains_changed_pixels":outside,"child_rgba_sha256":child_sha,"independent_source_prior":input.prior,"water_minus_deck_same_native_physics_and_mask":true,"whole_bridge_below_actor_and_native_front_Atlas_region":true,"no_other_city_native_or_room_geometry_replayed":true}
func run() -> void:
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if platform!=null: platform.call("set_checkpoint_saves_suspended",true)
	var args: PackedStringArray=OS.get_cmdline_user_args()
	var input_path: String=args[0] if args.size()==1 else BASE+"publication_input_NOTREADY.json"
	var began: int=Time.get_ticks_msec()
	var input: Dictionary=json_file(input_path)
	var result: Dictionary=publish(input)
	var final: Dictionary={}
	for path: String in pins: final[path]=FileAccess.get_sha256(path);need(final[path]==pins[path],"SOURCE_FINAL",path)
	need(Time.get_ticks_msec()-began<=60000,"FIXED_60S_PUBLICATION_LIMIT")
	result.merge({"status":"GARDEN_RIVER_NATIVE_PUBLICATION_NOT_FIELD_OR_ART","passed":error.is_empty() and result.get("published")==true,"error":error,"checks":checks,"diagnostic":diagnostic,"source_first":pins,"source_final":final,"input":{"path":input_path,"sha256":FileAccess.get_sha256(input_path)},"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":60000,"Field_credit":false,"GPU_ART_credit":false},true)
	var report: String=BASE+"publication01/reports/"+str(OS.get_process_id())+"/result.json"
	var written: bool=write_json(report,result)
	print(JSON.stringify({"path":report,"passed":written and result.passed,"error":error,"checks":checks}));quit(0 if written and result.passed else 1)
