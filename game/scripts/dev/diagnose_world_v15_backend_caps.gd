extends SceneTree

# Independent backend query; never allocates a world-sized texture/view.
# Godot Compatibility does not expose its OpenGL glGetIntegerv handles.
# An optional 64x64 capture proves only a tiny native viewport, NOT a limit.
const OUTPUT := "res://build/world_map_v15_backend_caps/"
const PREVIOUS_QUERY_ONLY_SOURCE_SHA := "3eadba781c37c7e624a047731ea62bb61f0b39a3729523f15c7a7d9a9a627516"
var active_view: SubViewport
var output := ""

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if "--query-world-v15-backend-caps" not in args or DisplayServer.get_name()=="headless":
		push_error("Explicit GPU backend-query argument required; headless cannot report native GPU caps.")
		await _finish(2)
		return
	output=OUTPUT+str(Time.get_unix_time_from_system()).replace(".","_")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var result: Dictionary={
		"status":"BACKEND_CAPS_DIAGNOSTIC_NOT_WHOLE_CAPTURE_APPROVAL",
		"executed_fixture_path":get_script().resource_path,
		"executed_fixture_sha256":FileAccess.get_sha256(get_script().resource_path),
		"godot_version":Engine.get_version_info(),
		"display_server":DisplayServer.get_name(),
		"configured_renderer":ProjectSettings.get_setting("rendering/renderer/rendering_method","UNKNOWN"),
		"requested_whole_native_canvas":[24576,16384],
		"whole_viewport_allocated":false,
		"largest_fixture_allocation_px":[0,0],
		"gl_max_texture_size":{"available":false,"value":null,"method":"No public OpenGL glGetIntegerv API in this GDScript fixture; never inferred from GPU marketing name."},
		"gl_max_renderbuffer_size":{"available":false,"value":null,"method":"No public OpenGL glGetIntegerv API in this GDScript fixture."},
		"whole_feasibility_verified":false
	}
	result["previous_query_only_authored_source_sha256"]=PREVIOUS_QUERY_ONLY_SOURCE_SHA
	for method: String in ["get_video_adapter_name","get_video_adapter_vendor","get_video_adapter_api_version"]:
		if RenderingServer.has_method(method): result[method]=RenderingServer.call(method)
	# RenderingDevice is normally null for gl_compatibility. Its limits, if
	# present, describe that actual device API, never pretend to be GL caps.
	var device: Object=null
	if RenderingServer.has_method("get_rendering_device"):
		device=RenderingServer.call("get_rendering_device")
	result["rendering_device_present"]=device!=null
	var device_limits: Dictionary={}
	if device!=null and device.has_method("limit_get"):
		for name: String in ClassDB.class_get_integer_constant_list("RenderingDevice"):
			if name.begins_with("LIMIT_") and ("TEXTURE_SIZE" in name or "FRAMEBUFFER" in name or "RENDERBUFFER" in name):
				var enum_value: int=ClassDB.class_get_integer_constant("RenderingDevice",name)
				device_limits[name]={"enum":enum_value,"value":device.call("limit_get",enum_value),"scope":"actual RenderingDevice API; NOT an OpenGL glGetIntegerv result"}
	result["public_rendering_device_limits"]=device_limits
	device=null
	if "--verify-tiny-native-viewport" in args:
		var tiny: Dictionary=await _tiny_native()
		result["tiny_native_sanity"]=tiny
		result["largest_fixture_allocation_px"]=[64,64]
		if not bool(tiny.get("passed",false)):
			_write_result(result)
			await _finish(1)
			return
	if "--verify-native-long-axes" in args:
		var axes: Array[Dictionary]=[]
		var all_axes_passed := true
		# Strictly sequential; destroy each GPU framebuffer before the next.
		for size: Vector2i in [Vector2i(24576,64),Vector2i(64,16384)]:
			var axis: Dictionary=await _long_axis(size)
			axes.append(axis)
			if not bool(axis.get("passed",false)): all_axes_passed=false
		result["native_long_axes"]={"passed":all_axes_passed,"cases":axes,"scope":"Only two separately allocated thin native axes. NOT whole 24576x16384 memory feasibility or GL enumerated limit."}
		result["largest_fixture_pixel_count"]=24576*64
		result["largest_fixture_allocation_px"]=[24576,64]
		if not all_axes_passed:
			_write_result(result)
			await _finish(1)
			return
	if not _write_result(result):
		await _finish(1)
		return
	print("BACKEND_CAPS_QUERY_COMPLETE ",output," GL limits unavailable unless explicitly returned; whole allocation untested.")
	await _finish(0)

func _tiny_native() -> Dictionary:
	active_view=SubViewport.new()
	active_view.size=Vector2i(64,64)
	active_view.msaa_3d=Viewport.MSAA_DISABLED
	active_view.own_world_3d=true
	active_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(active_view)
	var world:=Node3D.new()
	active_view.add_child(world)
	var environment:=WorldEnvironment.new()
	var settings:=Environment.new()
	settings.background_mode=Environment.BG_COLOR
	settings.background_color=Color(0,0,0,1)
	environment.environment=settings
	world.add_child(environment)
	var box:=MeshInstance3D.new()
	box.mesh=BoxMesh.new()
	var material:=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color=Color(.25,.5,.75,1)
	box.material_override=material
	world.add_child(box)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=2.
	camera.position=Vector3(0,2,3)
	world.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current=true
	for i in range(8):
		await process_frame
		await RenderingServer.frame_post_draw
	var first: Image=active_view.get_texture().get_image()
	await process_frame
	await RenderingServer.frame_post_draw
	var second: Image=active_view.get_texture().get_image()
	if first==null or second==null: return {"passed":false,"reason":"Actual 64px GPU readback missing."}
	first.convert(Image.FORMAT_RGBA8)
	second.convert(Image.FORMAT_RGBA8)
	var center: Color=first.get_pixel(32,32)
	var exact: bool=first.get_data()==second.get_data()
	var paths: Array[String]=[output+"native64.png",output+"native64_repeat.png"]
	if first.save_png(paths[0])!=OK or second.save_png(paths[1])!=OK: return {"passed":false,"reason":"Tiny evidence PNG save failed."}
	var result: Dictionary={"passed":exact and first.get_size()==Vector2i(64,64) and center.a>.99 and center.g>.1 and center.b>.1,
		"raw_repeat_byte_exact":exact,"actual_canvas":[first.get_width(),first.get_height()],
		"actual_center_rgba":[center.r,center.g,center.b,center.a],"msaa_enum":active_view.msaa_3d,
		"images":[{"path":paths[0],"sha256":FileAccess.get_sha256(paths[0])},{"path":paths[1],"sha256":FileAccess.get_sha256(paths[1])}],
		"scope":"64px native allocation/readback sanity ONLY; not maximum texture/renderbuffer capability or whole-map memory proof."}
	await _release_view()
	return result

func _long_axis(size: Vector2i) -> Dictionary:
	var id: String="native_"+str(size.x)+"x"+str(size.y)
	active_view=SubViewport.new()
	active_view.size=size
	active_view.msaa_3d=Viewport.MSAA_DISABLED
	active_view.own_world_3d=true
	active_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(active_view)
	var world:=Node3D.new()
	active_view.add_child(world)
	var environment:=WorldEnvironment.new()
	var settings:=Environment.new()
	settings.background_mode=Environment.BG_COLOR
	settings.background_color=Color(0,0,0,1)
	environment.environment=settings
	world.add_child(environment)
	# Native unlit 3D quads fill a genuinely orthographic framebuffer. Nothing
	# is resized, cropped, replicated or reconstructed after readback.
	var view_height := 2.
	var view_width: float=view_height*float(size.x)/float(size.y)
	var colors: Array[Color]=[Color(.8,.03,.03,1),Color(.03,.8,.03,1),Color(.03,.03,.8,1),Color(.8,.8,.03,1)]
	for index in range(4):
		var x_sign: float=-1. if index%2==0 else 1.
		var y_sign: float=1. if index<2 else -1.
		_axis_quad(world,Vector2(view_width*.5,view_height*.5),Vector3(x_sign*view_width*.25,y_sign*view_height*.25,0),colors[index])
	_axis_quad(world,Vector2(view_width*.2,view_height*.2),Vector3(0,0,.01),Color(.8,.03,.8,1))
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect=Camera3D.KEEP_HEIGHT
	camera.size=view_height
	camera.position=Vector3(0,0,10)
	world.add_child(camera)
	camera.current=true
	for i in range(8):
		await process_frame
		await RenderingServer.frame_post_draw
	var first: Image=active_view.get_texture().get_image()
	await process_frame
	await RenderingServer.frame_post_draw
	var second: Image=active_view.get_texture().get_image()
	var record: Dictionary={"id":id,"requested_canvas":[size.x,size.y],"actual_viewport_size":[active_view.size.x,active_view.size.y],"max_wait_frames":9,"msaa_enum":active_view.msaa_3d,"readback_resized_or_cropped":false,"camera":{"projection":camera.projection,"keep_aspect":camera.keep_aspect,"size":camera.size,"position":[0,0,10]},"scope":"Thin native 3D framebuffer axes only; not whole-map memory, shadow or GL enumerated caps."}
	if first==null or second==null:
		record["passed"]=false
		record["reason"]="Actual long-axis GPU readback missing."
		await _release_view()
		return record
	first.convert(Image.FORMAT_RGBA8)
	second.convert(Image.FORMAT_RGBA8)
	record["actual_raw_canvas"]=[first.get_width(),first.get_height()]
	record["actual_repeat_raw_canvas"]=[second.get_width(),second.get_height()]
	var dimensions_exact: bool=first.get_size()==size and second.get_size()==size
	var repeat_exact: bool=first.get_data()==second.get_data()
	var witnesses: Array[Dictionary]=[]
	var colors_valid := false
	if dimensions_exact:
		var points: Array[Vector2i]=[Vector2i(1,1),Vector2i(size.x-2,1),Vector2i(1,size.y-2),Vector2i(size.x-2,size.y-2),size/2]
		var samples: Array[Color]=[]
		for index in range(points.size()):
			var color: Color=first.get_pixelv(points[index])
			samples.append(color)
			witnesses.append({"id":["top_left_red","top_right_green","bottom_left_blue","bottom_right_yellow","center_magenta"][index],"pixel":[points[index].x,points[index].y],"raw_rgba":[color.r,color.g,color.b,color.a]})
		colors_valid=samples[0].r>.3 and samples[0].g<.3 and samples[0].b<.3 and samples[1].g>.3 and samples[1].r<.3 and samples[1].b<.3 and samples[2].b>.3 and samples[2].r<.3 and samples[2].g<.3 and samples[3].r>.3 and samples[3].g>.3 and samples[3].b<.3 and samples[4].r>.3 and samples[4].b>.3 and samples[4].g<.3
		for color: Color in samples:
			if color.a<.99: colors_valid=false
	var path: String=output+id+"_raw.png"
	var repeat_path: String=output+id+"_raw_repeat.png"
	var saved: bool=first.save_png(path)==OK and second.save_png(repeat_path)==OK
	record["dimensions_exact"]=dimensions_exact
	record["raw_repeat_byte_exact"]=repeat_exact
	record["five_native_color_witnesses_passed"]=colors_valid
	record["witnesses"]=witnesses
	record["images"]=[{"path":path,"sha256":FileAccess.get_sha256(path)},{"path":repeat_path,"sha256":FileAccess.get_sha256(repeat_path)}]
	record["passed"]=dimensions_exact and repeat_exact and colors_valid and saved
	first=null
	second=null
	await _release_view()
	return record

func _axis_quad(world: Node3D,size: Vector2,position: Vector3,color: Color) -> void:
	var node:=MeshInstance3D.new()
	var mesh:=QuadMesh.new()
	mesh.size=size
	node.mesh=mesh
	node.position=position
	var material:=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	material.albedo_color=color
	node.material_override=material
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(node)

func _release_view() -> void:
	if active_view!=null:
		active_view.queue_free()
		active_view=null
	for i in range(16): await process_frame

func _write_result(result: Dictionary) -> bool:
	var path: String=output+"result.json"
	var json: String=JSON.stringify(result,"\t")
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:
		push_error("Backend diagnostic JSON open failed.")
		return false
	file.store_string(json)
	file.flush()
	var error: Error=file.get_error()
	file.close()
	if error!=OK or FileAccess.get_file_as_string(path)!=json or not JSON.parse_string(json) is Dictionary:
		push_error("Backend diagnostic JSON exact write/readback failed.")
		return false
	return true

func _finish(code: int) -> void:
	if active_view!=null:
		active_view.queue_free()
		active_view=null
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]:
		Input.set_custom_mouse_cursor(null,shape)
	var cursor:=root.get_node_or_null("CursorManager")
	if cursor!=null:
		for key in ["_arrow","_hand","_wait"]: cursor.set(key,null)
	for i in range(16): await process_frame
	quit(code)
