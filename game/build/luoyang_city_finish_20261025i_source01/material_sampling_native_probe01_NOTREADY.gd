extends SceneTree
# ROOT-only finite GPU sampling test, no Field/Scene/geometry or imports.
const READY: bool=false
const INPUT: String="res://build/luoyang_city_finish_20261025i_source01/material_sampling_native_probe01_NOTREADY_input.json"
const INPUT_SHA: String="PENDING_INPUT_PIN"
var config: Dictionary={}
var first: Dictionary={}
var before_save: Dictionary={}
var errors: Array=[]
var checks: int=0
var out: String=""
var started: int=0
func _initialize() -> void: call_deferred("run")
func check(value: bool,label: String) -> bool:
	checks+=1
	if not value: errors.append(label)
	return value
func snapshot(paths: Array) -> Dictionary:
	var rows: Dictionary={}
	for path: String in paths:
		if not FileAccess.file_exists(path): rows[path]={"exists":false};continue
		var file: FileAccess=FileAccess.open(path,FileAccess.READ)
		if file==null: rows[path]={"unreadable":true};continue
		rows[path]={"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":file.get_length(),"mtime":FileAccess.get_modified_time(path)}
		file.close()
	return rows
func finish(samples: Dictionary) -> void:
	var final: Dictionary={}
	for path: String in first: final[path]=FileAccess.get_sha256(path)
	check(first==final,"SOURCE_FIRST_FINAL")
	var after_save: Dictionary=snapshot(config.get("save_absolute_paths",[]))
	check(before_save==after_save,"SAVE15_READONLY")
	var result: Dictionary={"passed":errors.is_empty(),"checks":checks,"errors":errors.duplicate(true),"elapsed_ms":Time.get_ticks_msec()-started,"source_first":first,"source_final":final,"save_first":before_save,"save_final":after_save,"actual_GPU_samples":samples,"Field":0,"native_packets":0,"geometry_PIP":0,"old_routes":0,"import":0}
	if out!="":
		var file: FileAccess=FileAccess.open(out+"result.json",FileAccess.WRITE)
		if file!=null: file.store_string(JSON.stringify(result,"\t")+"\n");file.close()
	quit(0 if errors.is_empty() else 1)
func sample_variation(image: Image,points: Array,label: String) -> Dictionary:
	var colors: Dictionary={};var recorded: Array=[]
	var minimum: Vector3=Vector3.ONE;var maximum: Vector3=Vector3.ZERO
	for raw: Array in points:
		var point: Vector2i=Vector2i(int(raw[0]),int(raw[1]))
		var pixel: Color=image.get_pixelv(point)
		var bytes: Array=[roundi(pixel.r*255),roundi(pixel.g*255),roundi(pixel.b*255),roundi(pixel.a*255)]
		colors[str(bytes[0])+":"+str(bytes[1])+":"+str(bytes[2])]=true
		minimum=minimum.min(Vector3(pixel.r,pixel.g,pixel.b));maximum=maximum.max(Vector3(pixel.r,pixel.g,pixel.b))
		recorded.append({"point":raw,"RGBA8":bytes})
		check(pixel.a==1.0,label+"_OPAQUE_INTERIOR:"+str(point))
	var spread: Vector3=maximum-minimum
	check(colors.size()>=int(config.minimum_unique_RGB_samples),label+"_ACTUAL_TEXTURE_RGB_VARIATION")
	check(maxf(spread.x,maxf(spread.y,spread.z))>=float(config.minimum_RGB_channel_range),label+"_NOT_FLAT_TINT")
	return {"samples":recorded,"unique_RGB":colors.size(),"channel_range":[spread.x,spread.y,spread.z]}
func run() -> void:
	started=Time.get_ticks_msec()
	if not READY or FileAccess.get_sha256(INPUT)!=INPUT_SHA: quit(1);return
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(INPUT))
	if not parsed is Dictionary: quit(1);return
	config=parsed
	var platform: Node=get_root().get_node_or_null("PlatformBridge")
	if platform!=null: platform.call("set_checkpoint_saves_suspended",true)
	before_save=snapshot(config.save_absolute_paths)
	if not check(config.ready==true and not DirAccess.dir_exists_absolute(config.output_absolute),"NEW_READY_OUTPUT"): finish({});return
	for path: String in config.sources:
		first[path]=FileAccess.get_sha256(path)
		if not check(first[path]==config.sources[path],"SOURCE:"+path): finish({});return
	out=String(config.output_absolute).path_join(str(OS.get_process_id()))+"/"
	if DirAccess.make_dir_recursive_absolute(out)!=OK: quit(1);return
	var factory: Variant=load(config.factory)
	var shader: Shader=load(config.shader) as Shader
	if not check(factory is GDScript and factory.can_instantiate() and shader!=null,"NEW_FACTORY_AND_SHADER_NATIVE_LOAD"): finish({});return
	var textures: Dictionary={}
	for role: String in config.textures:
		var texture: Texture2D=load(String(config.textures[role])) as Texture2D
		if not check(texture!=null,"SOURCE_TEXTURE_NATIVE_LOAD:"+role): finish({});return
		textures[role]=texture
	var viewport: SubViewport=SubViewport.new();viewport.size=Vector2i(768,768);viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;get_root().add_child(viewport)
	var world: Node2D=factory.create(config.rows,textures,shader)
	if not check(world!=null,"EXACT_FACTORY_ROWS"): finish({});return
	viewport.add_child(world)
	for polygon: Node in world.get_children():
		if not check(polygon is Polygon2D and polygon.texture!=null,"POLYGON_NATIVE_TEXTURE_BOUND:"+String(polygon.name)): finish({});return
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image=viewport.get_texture().get_image()
	if not check(image!=null and image.get_size()==Vector2i(768,768),"ACTUAL_GPU_IMAGE"): finish({});return
	image.convert(Image.FORMAT_RGBA8)
	var samples: Dictionary={}
	for label: String in config.sample_points: samples[label]=sample_variation(image,config.sample_points[label],label)
	if not check(image.save_png(out+"floor_and_road_native_probe.png")==OK,"ONLY_NEW_PROBE_IMAGE"): finish(samples);return
	check(Time.get_ticks_msec()-started<int(config.whole_budget_ms),"FINITE_15S_BUDGET")
	viewport.queue_free();finish(samples)
