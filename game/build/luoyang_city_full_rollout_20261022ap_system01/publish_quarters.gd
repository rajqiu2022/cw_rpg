extends SceneTree
## Root-only new native publication. No old scene/C setup, no save slots.
const C=preload("res://build/luoyang_city_full_rollout_20261022ap_system01/quarters_compiler.gd")
const AUTHORS={"luoyang_artisan_residential_20261022ap":"res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_author.json","luoyang_riverside_garden_20261022ap":"res://build/luoyang_city_full_rollout_20261022ap_system01/garden_author.json"}
const OUT="res://data/maps/luoyang_full_city_20261022ap/"
const BUILD="res://build/luoyang_city_full_rollout_20261022ap_system01/"
var error: String=""
var pins: Dictionary={}
var selected_ids: Array[String]=[]
func _initialize() -> void: call_deferred("_run")
func need(ok: bool,label: String) -> bool:
	if not ok and error.is_empty(): error=label;push_error("AP "+label)
	return ok
func track(path: String,expected: String="") -> bool:
	var sha: String=FileAccess.get_sha256(path)
	if not need(C.path(path) and sha.length()==64 and (expected.is_empty() or sha==expected) and (not pins.has(path) or pins[path]==sha),"SOURCE:"+path): return false
	pins[path]=sha;return true
func write_json(path: String,value: Dictionary) -> bool:
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(value,"\t",true,true));file.close();return true
func publish() -> Dictionary:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if not need(args.size()==1 and args[0] in ["--district=artisan","--district=garden"],"EXACT_ONE_DISTRICT_ARGUMENT"): return {}
	selected_ids.assign(["luoyang_artisan_residential_20261022ap"] if args[0]=="--district=artisan" else ["luoyang_riverside_garden_20261022ap"])
	for path: String in [get_script().resource_path,"res://build/luoyang_city_full_rollout_20261022ap_system01/quarters_compiler.gd",C.B_PATH,"res://scripts/domain/scene_script.gd","res://scripts/domain/walkable_map_layout.gd"]:
		if not track(path): return {}
	var pending: Array[Dictionary]=[]
	# Each scene's source author is independently frozen at its own actual.
	# A pending bridge/pavilion cannot stall or mutate an already-proved Artisan.
	for id: String in selected_ids:
		var author_path: String=AUTHORS[id]
		if not track(author_path): return {}
		var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(author_path))
		if not need(raw is Dictionary,"AUTHOR_DICTIONARY:"+id): return {}
		var checked: Dictionary=C.source_pins(raw)
		if not need(checked.get("ok")==true,"AUTHOR_AND_EXACT_SOURCE_BINDINGS:"+str(checked.get("error"))): return checked
		for path: String in checked.pins:
			if not track(path,checked.pins[path]): return {}
		var compiled: Dictionary=C.compile(raw,id)
		if not need(compiled.get("ok")==true,"COMPILE:"+id+":"+str(compiled.get("error"))): return compiled
		var geometry: Dictionary=C.audit(compiled)
		if not need(geometry.get("ok")==true,"GEOMETRY:"+id+":"+str(geometry.get("error"))): return geometry
		if not need(not DirAccess.dir_exists_absolute(OUT+id) and not FileAccess.file_exists(BUILD+"publication_assets/"+id+"_walk.png"),"NEW_OUTPUT_ONLY:"+id): return {}
		pending.append({"id":id,"compiled":compiled,"geometry":geometry,"author_path":author_path})
	var published: Dictionary={}
	for task: Dictionary in pending:
		var id: String=task.id;var folder: String=OUT+id+"/";var compiled: Dictionary=task.compiled;var scene: SceneScript=compiled.scene
		if not need(DirAccess.make_dir_recursive_absolute(folder)==OK and DirAccess.make_dir_recursive_absolute(BUILD+"publication_assets")==OK,"OUTPUT_DIR"): return {}
		var walk: String=BUILD+"publication_assets/"+id+"_walk.png"
		if not need(compiled.mask.save_png(walk)==OK,"MASK_WRITE"): return {}
		var read_image: Image=Image.load_from_file(walk)
		if read_image!=null: read_image.convert(Image.FORMAT_RGBA8)
		if not need(read_image!=null and read_image.get_data()==compiled.mask.get_data(),"MASK_RGBA_READBACK"): return {}
		scene.set_meta(C.META,pins[task.author_path])
		var storage: Dictionary={"scene":C.b().storage(scene),"layout":C.b().storage(scene.map_layout)}
		if not need(ResourceSaver.save(scene.map_layout,folder+"layout.res")==OK,"NATIVE_LAYOUT"): return {}
		scene.map_layout=ResourceLoader.load(folder+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
		if not need(scene.map_layout!=null and ResourceSaver.save(scene,folder+"scene.res")==OK,"NATIVE_SCENE"): return {}
		var read: SceneScript=ResourceLoader.load(folder+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		if not need(read!=null and C.b().equal(C.b().storage(read),storage.scene) and C.b().equal(C.b().storage(read.map_layout),storage.layout),"WHOLE_TYPED_NATIVE_READBACK"): return {}
		var packet: Dictionary={"kind":"AP_SOURCE_BOUND_NEW_ORDINARY_QUARTER","scene_id":id,"author_path":task.author_path,"author_sha256":pins[task.author_path],"scene_storage":storage.scene,"layout_storage":storage.layout,"solids":compiled.solids,"mask_sha256":C.b().bytes_sha(compiled.mask.get_data()),"walk_bytes":compiled.mask.get_data(),"geometry":task.geometry}
		if not need(C.b()._plain(packet),"PLAIN_PACKET"): return {}
		var file:=FileAccess.open(folder+"packet.bin",FileAccess.WRITE)
		if not need(file!=null,"PACKET_OPEN"): return {}
		file.store_buffer(var_to_bytes(packet));file.close()
		if not need(C.b().equal(bytes_to_var(FileAccess.get_file_as_bytes(folder+"packet.bin")),packet),"WHOLE_PACKET_READBACK"): return {}
		var artifacts: Dictionary={}
		for name: String in ["layout.res","scene.res","packet.bin"]: artifacts[folder+name]=FileAccess.get_sha256(folder+name)
		published[id]={"artifacts":artifacts,"walk_candidate":{"path":walk,"sha256":FileAccess.get_sha256(walk),"rgba_sha256":packet.mask_sha256,"canonical_target":folder+"walk.png"},"geometry":task.geometry,"visual_count":scene.map_layout.visual_objects.size(),"solid_count":compiled.solids.size(),"portal_count":scene.map_layout.portals.size()}
	return {"published":published,"no_old_city_or_room_geometry_replayed":true,"no_import_or_canonical_runtime_hook":true}
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var began: int=Time.get_ticks_msec();var result: Dictionary=publish();var final: Dictionary={}
	for path: String in pins:
		final[path]=FileAccess.get_sha256(path);need(final[path]==pins[path],"SOURCE_FINAL:"+path)
	need(Time.get_ticks_msec()-began<=60000,"FIXED_60S_QUARTER_NATIVE_PUBLICATION")
	result.merge({"passed":error.is_empty() and result.get("published",{}).size()==selected_ids.size(),"error":error,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":60000,"selected_scene_ids":selected_ids,"source_first":pins,"source_final":final,"scope":"AP_SELECTED_NEW_QUARTER_NATIVE_NOT_FORMAL_FIELD_ADMISSION"},true)
	var report_path: String=BUILD+"publication/"+str(OS.get_process_id())+"/result.json"
	var written: bool=write_json(report_path,result)
	print(JSON.stringify({"path":report_path,"passed":written and result.passed,"error":error}));quit(0 if written and result.passed else 1)
