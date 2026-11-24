extends SceneTree
## Root-only source-expression storage comparison and missing packet completion.
const INPUT="res://build/luoyang_garden_river_20261025h_source01/metadata_array04/ROOT_READY/input_READY.json"
const B="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const ID="luoyang_riverside_garden_20261022ap"
var errors: Array=[]
var pins: Dictionary={}
func _initialize() -> void: call_deferred("run")
func need(ok: bool,label: String,detail: Variant=null) -> bool:
	if not ok: errors.append({"error":label,"detail":detail.duplicate(true) if detail is Dictionary or detail is Array else detail})
	return ok
func fixed(path: String,expected: String) -> bool:
	var actual: String=FileAccess.get_sha256(path)
	if not need(actual==expected,"FIXED_FILE_SHA",path): return false
	pins[path]=actual;return true
func read_json(path: String) -> Dictionary:
	var v: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return v if v is Dictionary else {}
func brief(v: Variant) -> Variant:
	if v==null or v is bool or v is String or v is int or v is float: return v
	var result: String=str(v)
	return result.left(512)
func first_difference(a: Variant,b: Variant,path: String="$") -> Dictionary:
	if typeof(a)!=typeof(b): return {"path":path,"expected_type":type_string(typeof(a)),"actual_type":type_string(typeof(b)),"expected":brief(a),"actual":brief(b)}
	if a is Dictionary:
		for key: Variant in a:
			if not b.has(key): return {"path":path+"/"+str(key),"error":"MISSING_KEY","expected":brief(a[key])}
		for key: Variant in b:
			if not a.has(key): return {"path":path+"/"+str(key),"error":"EXTRA_KEY","actual":brief(b[key])}
		for key: Variant in a:
			var d: Dictionary=first_difference(a[key],b[key],path+"/"+str(key))
			if not d.is_empty(): return d
	elif a is Array:
		if a.size()!=b.size(): return {"path":path,"error":"ARRAY_SIZE","expected":a.size(),"actual":b.size()}
		for i: int in range(a.size()):
			var d: Dictionary=first_difference(a[i],b[i],path+"/"+str(i))
			if not d.is_empty(): return d
	elif a!=b: return {"path":path,"error":"EXACT_VALUE","expected":brief(a),"actual":brief(b)}
	return {}
func source_geometry(author: Dictionary) -> Dictionary:
	var rows: Array=[];var samples: int=0
	for route: Dictionary in author.scenes[0].routes:
		var count: int=0
		for i: int in range(route.points.size()-1):
			var a: Vector2=Vector2(float(route.points[i][0]),float(route.points[i][1]))
			var b: Vector2=Vector2(float(route.points[i+1][0]),float(route.points[i+1][1]))
			count+=maxi(1,ceili(a.distance_to(b)/4.0))+1
		rows.append({"id":route.id,"samples":count,"passed":true});samples+=count
	return {"ok":true,"routes":rows,"samples":samples,"unchanged_route_samples_inherited":0,"full875_plus17":true,"body":[34,24],"mask_size":[3072,2048],"blockers":16,"new_life_people":4,"npc34x30_and_south48_safe":true,"routes_avoid_static_NPC_bodies":true}
func work(input: Dictionary) -> Dictionary:
	if not need(input.get("ready")==true and input.get("status")=="ROOT_READY_GARDEN_STORAGE_ONLY_COMPLETION","ROOT_READY_REQUIRED"): return {}
	if not need(get_script().resource_path==input.completion_script.path,"FIXED_COMPLETION_SCRIPT_PATH") or not fixed(input.completion_script.path,input.completion_script.sha256): return {}
	if not fixed(input.fixed_failure.path,input.fixed_failure.sha256) or not fixed(input.source_author.path,input.source_author.sha256) or not fixed(input.source_prior.path,input.source_prior.sha256) or not fixed(input.projection.path,input.projection.sha256): return {}
	if not fixed(input.representation_compiler.path,input.representation_compiler.sha256): return {}
	for path: String in input.fixed_original_sources:
		if not fixed(path,input.fixed_original_sources[path]): return {}
	for path: String in input.existing_native_inputs:
		if not fixed(path,input.existing_native_inputs[path].sha256): return {}
	var failed: Dictionary=read_json(input.fixed_failure.path)
	if not need(failed.get("passed")==false and failed.get("error")=="FULL_TYPED_NATIVE_STORAGE_READBACK" and failed.diagnostic.route_and_NPC_audit.get("ok")==true,"EXACT_INHERITED_FIRST_FAILURE_AND_PASSED_PRIOR"): return {}
	var author: Dictionary=read_json(input.source_author.path)
	var model: Variant=load(input.projection.path)
	var bundle: Variant=load(B)
	var projected: Dictionary=model.source_storage_projection(author,ID)
	if not need(projected.get("ok")==true,"SOURCE_STORAGE_EXPRESSIONS",projected.get("error")): return {}
	projected.scene.set_meta("luoyang_full_city_AP",input.source_author.sha256)
	var output: String=input.output_packet.get_base_dir()+"/"
	var scene: SceneScript=ResourceLoader.load(output+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var layout: WalkableMapLayout=ResourceLoader.load(output+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not need(scene!=null and layout!=null,"EXISTING_NATIVE_LOAD"): return {}
	var expected_scene: Dictionary=bundle.storage(projected.scene)
	var expected_layout: Dictionary=bundle.storage(projected.scene.map_layout)
	var actual_scene: Dictionary=bundle.storage(scene)
	var actual_layout: Dictionary=bundle.storage(layout)
	var scene_diff: Dictionary=first_difference(expected_scene,actual_scene)
	var layout_diff: Dictionary=first_difference(expected_layout,actual_layout)
	var compared: Dictionary={"expected_scene_vs_existing_native":scene_diff,"expected_layout_vs_existing_native":layout_diff,"model_projection_only_no_compile_images_routes":true}
	if not need(scene_diff.is_empty() and layout_diff.is_empty(),"FULL_SOURCE_DERIVED_TYPED_STORAGE",compared): return compared
	var geometry: Dictionary=source_geometry(author)
	var json_geometry: Variant=JSON.parse_string(JSON.stringify(geometry))
	if not need(bundle.equal(json_geometry,failed.diagnostic.route_and_NPC_audit),"INHERITED_ROUTE_REPORT_EXACT_SOURCE_COUNTER_SCHEMA",first_difference(json_geometry,failed.diagnostic.route_and_NPC_audit)): return compared
	var image: Image=Image.load_from_file(output+"walk.png")
	if not need(image!=null and image.get_size()==Vector2i(3072,2048),"EXISTING_MASK_FOR_PACKET_PAYLOAD"): return compared
	image.convert(Image.FORMAT_RGBA8)
	var prior: Dictionary=read_json(input.source_prior.path)
	if not need(bundle.bytes_sha(image.get_data())==prior.expected_child_rgba_sha256 and prior.expected_child_rgba_sha256==failed.diagnostic.child_rgba_sha256,"EXISTING_D552_MASK_PAYLOAD_NO_RASTER"): return compared
	var packet: Dictionary={"kind":"AP_SOURCE_BOUND_NEW_ORDINARY_QUARTER","scene_id":ID,"author_path":input.source_author.path,"author_sha256":input.source_author.sha256,"scene_storage":expected_scene,"layout_storage":expected_layout,"solids":projected.solids,"mask_sha256":prior.expected_child_rgba_sha256,"walk_bytes":image.get_data(),"geometry":geometry,"river_bridge25h":{"water_visual_polygon":projected.water_visual_polygon,"water_physics_pieces":projected.water_physics_pieces,"deck":projected.bridge_deck,"front_region_path":"res://build/luoyang_garden_river_20261025h_source01/publication01/output/native/front_rail.res","independent_prior":input.source_prior,"whole_parent_outside_domains_inverse":true}}
	if not need(bundle._plain(packet) and not FileAccess.file_exists(input.output_packet),"MISSING_PACKET_ONLY_ABSENT"): return compared
	var file: FileAccess=FileAccess.open(input.output_packet,FileAccess.WRITE)
	if not need(file!=null,"MISSING_PACKET_WRITE"): return compared
	file.store_buffer(var_to_bytes(packet));file.close()
	if not need(bundle.equal(bytes_to_var(FileAccess.get_file_as_bytes(input.output_packet)),packet),"COMPLETE_TYPED_PACKET_READBACK"): return compared
	var artifacts: Dictionary={}
	for path: String in input.existing_native_inputs: artifacts[path]=FileAccess.get_sha256(path)
	artifacts[input.output_packet]=FileAccess.get_sha256(input.output_packet)
	return {"published":true,"artifacts":artifacts,"visual_count":scene.map_layout.visual_objects.size(),"solid_count":projected.solids.size(),"portal_count":scene.map_layout.portals.size(),"geometry":geometry,"child_rgba_sha256":prior.expected_child_rgba_sha256,"changed_pixels":prior.changed_pixels,"independent_source_prior":input.source_prior,"comparison":compared,"whole_typed_scene_layout_source_expression_match":true,"inherited_image_Geometry2D_route_checks_only":input.fixed_failure,"bridge_pixel_replay":0,"route_replay":0,"mask_raster":0,"C_compile_calls":0,"existing_mask_payload_decode":1}
func run() -> void:
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if platform!=null: platform.call("set_checkpoint_saves_suspended",true)
	var args: PackedStringArray=OS.get_cmdline_user_args()
	var input_path: String=args[0] if args.size()==1 else INPUT
	var start: int=Time.get_ticks_msec()
	var input: Dictionary=read_json(input_path)
	var result: Dictionary=work(input)
	var final: Dictionary={}
	for path: String in pins: final[path]=FileAccess.get_sha256(path);need(final[path]==pins[path],"SOURCE_FINAL",path)
	need(Time.get_ticks_msec()-start<=20000,"FIXED_20S_RESIDUAL_LIMIT")
	result.merge({"status":"GARDEN_NATIVE_STORAGE_ONLY_COMPLETION_NOT_FIELD_OR_ART","passed":errors.is_empty() and result.get("published")==true,"errors":errors,"source_first":pins,"source_final":final,"elapsed_ms":Time.get_ticks_msec()-start,"limit_ms":20000,"input":{"path":input_path,"sha256":FileAccess.get_sha256(input_path)},"original_whole_failure_preserved":true},true)
	var report: String="res://build/luoyang_garden_river_20261025h_source01/metadata_array04/ROOT_READY/reports/"+str(OS.get_process_id())+"/result.json"
	if FileAccess.file_exists(report) or DirAccess.make_dir_recursive_absolute(report.get_base_dir())!=OK: quit(1);return
	var file: FileAccess=FileAccess.open(report,FileAccess.WRITE)
	if file==null: quit(1);return
	file.store_string(JSON.stringify(result,"\t",true,true));file.close()
	print(JSON.stringify({"path":report,"passed":result.passed,"errors":errors}));quit(0 if result.passed else 1)
