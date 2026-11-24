extends SceneTree

# New isolated art capture tool. Default invocation is refused. No gameplay writes.
const SOURCE := preload("res://scripts/dev/luoyang_modular_v1_source.gd")
const SURFACE := preload("res://scripts/dev/luoyang_modular_v1_surface.gd")
const OUT := SOURCE.OUT
const AUDIT := "res://build/luoyang_modular_v1/"
const SSAA := 2
var source: SOURCE
var surface: SURFACE
var view: SubViewport
var prototypes: Dictionary={}
var texture_cache: Dictionary={}
var error := ""

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args:=OS.get_cmdline_user_args()
	if not "--luoyang-source-plan" in args and not "--luoyang-modular-capture" in args:
		push_error("Independent Luoyang default export refused; producer serial window required.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(AUDIT))
	source=SOURCE.new()
	source.prepare()
	var forecast: Dictionary=source.forecast()
	if not _json(AUDIT+"source_forecast.json",forecast) or not forecast["passed"]:
		error="City route/door17 and Rectangle34x24 forecast failed."
		await _finish(false)
		return
	if "--luoyang-source-plan" in args:
		var data:=source.snapshot()
		data["source_graph"]=_source_graph()
		data["forecast"]=forecast
		await _finish(_json(AUDIT+"source_layout.json",data))
		return
	if DisplayServer.get_name()=="headless":
		error="Actual GPU required; headless is not art capture."
		await _finish(false)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT+"entities/"))
	if not _json(OUT+"art_contract.json",{"schema_version":1,"status":"BUILD_IN_PROGRESS","production_approved":false}):
		await _finish(false)
		return
	surface=SURFACE.new()
	if not surface.load_sources():
		error=surface.error
		await _finish(false)
		return
	if not _measure_buildings():
		await _finish(false)
		return
	for kind: String in ["notice","lamp","tree"]:
		if not await _prototype(kind):
			await _finish(false)
			return
	if not await _capture_city():
		await _finish(false)
		return
	await _finish(true)

func _source_graph() -> Dictionary:
	var graph: Dictionary={}
	for path: String in [get_script().resource_path,"res://scripts/dev/luoyang_modular_v1_source.gd","res://scripts/dev/luoyang_modular_v1_surface.gd"]: graph[path]=FileAccess.get_sha256(path)
	return graph

func _measure_buildings() -> bool:
	var records: Array=[]
	for object in source.objects:
		if object["prototype"]!="": continue
		var image: Image=Image.load_from_file(object["texture"])
		if image==null or image.get_size()!=Vector2i(1536,1024):
			error="Building source missing or changed canvas: "+object["id"]
			return false
		image.convert(Image.FORMAT_RGBA8)
		var histogram: Array=[]
		histogram.resize(256)
		histogram.fill(0)
		var bounds: Dictionary={}
		for threshold in [0,12,30,128,240]: bounds[str(threshold)]=Rect2i()
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var alpha: int=int(round(image.get_pixel(x,y).a*255.))
				histogram[alpha]+=1
				for threshold in [0,12,30,128,240]:
					if alpha<=threshold: continue
					var key:=str(threshold)
					var rect: Rect2i=bounds[key]
					bounds[key]=Rect2i(x,y,1,1) if rect.size==Vector2i.ZERO else rect.merge(Rect2i(x,y,1,1))
		var bboxes: Dictionary={}
		for key in bounds:
			var r: Rect2i=bounds[key]
			bboxes[key]=[r.position.x,r.position.y,r.size.x,r.size.y]
		if object["id"]=="south_gate":
			for point in object["source_semantics"]["transparent_hole_witnesses_source_px"]:
				if image.get_pixel(point[0],point[1]).a!=0:
					error="Original gate transparent passage changed."
					return false
		object["alpha_measurement"]={"source_sha256":FileAccess.get_sha256(object["texture"]),"histogram":histogram,"bounds_strict_alpha_greater_than":bboxes,"source_modified":false,"weak_alpha_not_thresholded":true,"thresholds_are_measurement_only_not_image_editing":true}
		records.append({"id":object["id"],"measurement":object["alpha_measurement"],"semantic_ground_polygons_world":object["solid_polygons_px"]})
	return _json(OUT+"architecture_measurements.json",{"sources":records,"approval":"SOURCE_MEASURED_NOT_FIELD_VISUAL_APPROVED","generation_record_path":"assets/raw/scene_module/luoyang_modular_v1/generation_record.json","no_generated_source_claimed_cc0":true})

func _box(size: Vector3,position: Vector3,material: Material,root3: Node3D) -> void:
	var node:=MeshInstance3D.new()
	var mesh:=BoxMesh.new()
	mesh.size=size
	mesh.material=material
	node.mesh=mesh
	node.position=position
	root3.add_child(node)

func _prop_mesh(kind: String) -> ArrayMesh:
	if kind=="tree": return _tree()
	var holder:=Node3D.new()
	var wood: Material=SURFACE.wood()
	var grey: Material=SURFACE.plain(Color(.25,.275,.29))
	var red: Material=SURFACE.plain(Color(.38,.105,.065))
	if kind=="lamp":
		_box(Vector3(.18,.2,.18),Vector3(0,.1,0),grey,holder)
		_box(Vector3(.105,2.55,.105),Vector3(0,1.34,0),wood,holder)
		_box(Vector3(.65,.09,.12),Vector3(0,2.55,0),wood,holder)
		_box(Vector3(.32,.42,.25),Vector3(.23,2.22,0),red,holder)
		_box(Vector3(.38,.075,.3),Vector3(.23,2.47,0),grey,holder)
		_box(Vector3(.38,.07,.3),Vector3(.23,1.98,0),wood,holder)
	else:
		for x in [-.65,.65]:
			_box(Vector3(.2,.22,.3),Vector3(x,.11,0),grey,holder)
			_box(Vector3(.13,2.35,.13),Vector3(x,1.3,0),wood,holder)
		_box(Vector3(1.25,1.0,.07),Vector3(0,1.47,0),wood,holder)
		var paper: Material=SURFACE.plain(Color(.52,.46,.33))
		for x in [-.34,.0,.34]: _box(Vector3(.23,.65,.018),Vector3(x,1.45,.054),paper,holder)
		# Four shallow sloping roof panels, independent 3D geometry, no black box.
		for side in [-1.,1.]:
			var panel:=MeshInstance3D.new()
			var roof:=BoxMesh.new()
			roof.size=Vector3(1.72,.08,.58)
			roof.material=grey
			panel.mesh=roof
			panel.position=Vector3(0,2.6,side*.24)
			panel.rotation.x=side*.32
			holder.add_child(panel)
	var combined:=ArrayMesh.new()
	for child: MeshInstance3D in holder.get_children():
		for i in range(child.mesh.get_surface_count()):
			var arrays: Array=child.mesh.surface_get_arrays(i)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
			for j in range(vertices.size()):
				vertices[j]=child.transform*vertices[j]
				normals[j]=child.basis*normals[j]
			arrays[Mesh.ARRAY_VERTEX]=vertices
			arrays[Mesh.ARRAY_NORMAL]=normals
			combined.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			combined.surface_set_material(combined.get_surface_count()-1,child.mesh.surface_get_material(i))
	holder.free()
	return combined

func _tree() -> ArrayMesh:
	var registered: ArrayMesh=load(SOURCE.TREE_MESH) as ArrayMesh
	if registered==null:
		error="Registered actual TreeSmall02 hybrid missing; no sapling enlargement fallback."
		return null
	var result:=ArrayMesh.new()
	for i in range(registered.get_surface_count()):
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,registered.surface_get_arrays(i))
		var original: StandardMaterial3D=registered.surface_get_material(i) as StandardMaterial3D
		if original==null: return null
		var material: StandardMaterial3D=original.duplicate() as StandardMaterial3D
		for key: String in ["albedo_texture","normal_texture","roughness_texture","ao_texture"]:
			var texture: Texture2D=material.get(key)
			if texture==null: continue
			var identity: int=texture.get_instance_id()
			if not texture_cache.has(identity):
				var image: Image=texture.get_image().duplicate() as Image
				if image.is_compressed() and image.decompress()!=OK: return null
				if image.generate_mipmaps()!=OK: return null
				texture_cache[identity]=ImageTexture.create_from_image(image)
			material.set(key,texture_cache[identity])
		material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		if i==1:
			material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			material.alpha_scissor_threshold=.4
		result.surface_set_material(i,material)
	return result

func _bounds(mesh: ArrayMesh,basis: Basis) -> Dictionary:
	var minimum:=Vector3(INF,INF,INF)
	var maximum:=Vector3(-INF,-INF,-INF)
	var points:=PackedVector3Array()
	for i in range(mesh.get_surface_count()):
		var arrays: Array=mesh.surface_get_arrays(i)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			for j in range(vertices.size()): indices.append(j)
		var seen: Dictionary={}
		for index in indices:
			if seen.has(index): continue
			seen[index]=true
			var p: Vector3=basis*vertices[index]
			minimum=minimum.min(p)
			maximum=maximum.max(p)
			points.append(p)
	var sum:=0.
	var front: float=-INF
	var count:=0
	for p in points:
		if p.y<=minimum.y+(maximum.y-minimum.y)*.02:
			sum+=p.x
			front=maxf(front,p.z)
			count+=1
	return {"minimum":minimum,"maximum":maximum,"support":Vector3(sum/maxi(count,1),minimum.y,front),"support_count":count,"actual_used_vertices":points.size()}

func _prototype(kind: String) -> bool:
	var mesh: ArrayMesh=_prop_mesh(kind)
	if mesh==null: return false
	var scale: float=.9 if kind=="tree" else 1.
	var basis:=Basis(Vector3.UP,deg_to_rad(18 if kind=="tree" else 0)).scaled(Vector3.ONE*scale)
	var bounds: Dictionary=_bounds(mesh,basis)
	var support: Vector3=bounds["support"]
	view=_viewport(Vector2i(1536,1536),true)
	var world:=_world(view,true)
	var body:=MeshInstance3D.new()
	body.mesh=mesh
	body.transform=Transform3D(basis,-support)
	body.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(body)
	var camera:=_camera(world,Vector2i(768,768),Vector3(0,1.6,0))
	await _sync()
	var raw:=_read(view)
	await _sync()
	var repeat:=_read(view)
	var prefix: String=OUT+"entities/native_"+kind
	if raw.save_png(prefix+"_raw.png")!=OK or repeat.save_png(prefix+"_raw_repeat.png")!=OK: return false
	if raw.get_data()!=repeat.get_data():
		error="Native city sourcebody raw repeat differs: "+kind
		return false
	var logical: Image=_alpha_resize(raw,Vector2i(768,768))
	var used: Rect2i=logical.get_used_rect()
	if used.size.x<=0 or used.position.x<4 or used.position.y<4 or used.end.x>764 or used.end.y>764:
		error="Native prop empty or touches capture bounds: "+kind
		return false
	var crop: Rect2i=Rect2i(used.position-Vector2i(4,4),used.size+Vector2i(8,8))
	var image: Image=logical.get_region(crop)
	var foot: Vector2=camera.unproject_position(Vector3.ZERO)/SSAA-Vector2(crop.position)
	var path: String=prefix+".png"
	if image.save_png(path)!=OK or ResourceSaver.save(mesh,prefix+".res")!=OK: return false
	var record: Dictionary={"kind":kind,"texture":path,"metadata_path":prefix+".json","source_size_px":[image.get_width(),image.get_height()],"render_size_px":[image.get_width(),image.get_height()],"foot_uv":[foot.x/image.get_width(),foot.y/image.get_height()],"sourcebody_raw":prefix+"_raw.png","sourcebody_raw_repeat":prefix+"_raw_repeat.png","raw_camera":_camera_data(camera,view.size,Vector2i(768,768)),"crop_rect_px":[crop.position.x,crop.position.y,crop.size.x,crop.size.y],"native_mesh_path":prefix+".res","draw_basis_columns":[_v3(basis.x),_v3(basis.y),_v3(basis.z)],"support_m":_v3(support),"used_bounds_m":{"minimum":_v3(bounds["minimum"]),"maximum":_v3(bounds["maximum"])},"actual_used_vertices":bounds["actual_used_vertices"],"scale":scale,"alpha_resampling_algorithm":"RGBAF_PREMULTIPLIED_LANCZOS_UNPREMULTIPLY_V1","repeat_byte_exact":true,"source":"CC0 TreeSmall02 registered hybrid unchanged draw arrays" if kind=="tree" else "project original native box/roof geometry with wood grain shader; NOT CC0 modeled asset","source_min_vertex_ground_delta_m":0.,"sourcebody_and_ground_caster_same_mesh_material_basis_support":true}
	if not _json(prefix+".json",record): return false
	prototypes[kind]={"mesh":mesh,"basis":basis,"support":support,"image":image,"record":record}
	view.queue_free()
	view=null
	await _sync()
	return true

func _paving_mesh() -> ArrayMesh:
	# Real low stone slabs and broad street shoulders, independently from buildings.
	# The ground/nav share this mesh; tiny 4mm bevel rises do not invent house support.
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var random:=RandomNumberGenerator.new()
	random.seed=31712003
	for row in range(66):
		var z: float=-32.+row*.98
		var x: float=-24.-(.43 if row%2 else 0.)
		while x<24.:
			var width: float=random.randf_range(.65,1.1)
			var x1: float=maxf(x,-24.)
			var x2: float=minf(x+width-.012,24.)
			var z2: float=minf(z+.966,32.)
			if x2>x1 and z2>z:
				var h: float=random.randf_range(.003,.005)
				var tone: float=random.randf_range(.91,1.06)
				tool.set_color(Color(tone,tone,tone,1.))
				var a:=Vector3(x1,h,z)
				var b:=Vector3(x2,h,z)
				var c:=Vector3(x1,h,z2)
				var d:=Vector3(x2,h,z2)
				for p in [a,b,c,b,d,c]:
					tool.set_normal(Vector3.UP)
					tool.set_uv(Vector2(p.x/48.+.5,p.z/64.+.5))
					tool.add_vertex(p)
			x+=width
	tool.generate_tangents()
	return tool.commit()

func _capture_city() -> bool:
	view=_viewport(SOURCE.SIZE*SSAA,false)
	var world:=_world(view,false)
	var floor:=MeshInstance3D.new()
	var base:=PlaneMesh.new()
	base.size=Vector2(48,64)
	floor.mesh=base
	var material: ShaderMaterial=surface.paving()
	floor.material_override=SURFACE.plain(Color(.155,.165,.166)) # actual mortar beneath real gaps
	floor.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(floor)
	var paving:=MeshInstance3D.new()
	paving.mesh=_paving_mesh()
	paving.material_override=material
	paving.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(paving)
	if ResourceSaver.save(paving.mesh,OUT+"paving_mesh.res")!=OK or ResourceSaver.save(base,OUT+"support_plane.res")!=OK: return false
	# Native kerbs define the middle avenue and side public-market inset, not a flat tint.
	var grey: Material=SURFACE.plain(Color(.30,.32,.325))
	for side in [-1.,1.]:
		_box(Vector3(.22,.06,28),Vector3(side*2.55,.025,0),grey,world)
		_box(Vector3(9,.035,.20),Vector3(side*8.5,.02,-7.5),grey,world)
	var camera:=_camera(world,SOURCE.SIZE,Vector3.ZERO)
	var camera_data: Dictionary=_camera_data(camera,view.size,SOURCE.SIZE)
	if not _json(OUT+"capture_camera.json",camera_data): return false
	var casters: Array[MeshInstance3D]=[]
	for object in source.objects:
		if object["prototype"]=="": continue
		var proto: Dictionary=prototypes[object["prototype"]]
		var foot:=Vector2(object["world_foot_px"][0],object["world_foot_px"][1])
		var caster:=MeshInstance3D.new()
		caster.mesh=proto["mesh"]
		caster.transform=Transform3D(proto["basis"],SOURCE.point3(foot)-Vector3(proto["support"]))
		caster.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(caster)
		caster.visible=false
		casters.append(caster)
		for key: String in ["texture","source_size_px","render_size_px","foot_uv","metadata_path"]: object[key]=proto["record"][key]
		object["source"]=object["texture"]
		object["source_sha256"]=FileAccess.get_sha256(object["texture"])
		object["native_transform"]={"basis_columns":[_v3(caster.basis.x),_v3(caster.basis.y),_v3(caster.basis.z)],"origin":_v3(caster.position)}
		object["original_licensed_source"]=SOURCE.TREE_RAW if object["prototype"]=="tree" else get_script().resource_path
	await _sync()
	var uniforms: Array[String]=[]
	for value in material.shader.get_shader_uniform_list(): uniforms.append(String(value["name"]))
	if not "native_flagstone_identity" in uniforms or not "rock_normal" in uniforms:
		error="Actual paving shader reflection failed; no fallback default capture."
		return false
	var off:=_read(view)
	await _sync()
	var off_again:=_read(view)
	for caster in casters:
		caster.visible=true
		caster.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	await _sync()
	var on:=_read(view)
	await _sync()
	var on_again:=_read(view)
	if on.get_data()!=on_again.get_data() or off.get_data()!=off_again.get_data():
		error="City actual ground native cast repeat failed."
		return false
	for pair in [["ground_on_raw.png",on],["ground_on_raw_repeat.png",on_again],["ground_off_raw.png",off],["ground_off_raw_repeat.png",off_again]]:
		if pair[1].save_png(OUT+pair[0])!=OK: return false
	var logical: Image=on.duplicate() as Image
	logical.resize(SOURCE.SIZE.x,SOURCE.SIZE.y,Image.INTERPOLATE_LANCZOS)
	if logical.save_png(OUT+"floor.png")!=OK: return false
	# Binary authority is this native support plane at the SAME camera, no objects,
	# no screenshot recolouring, no resizing or MSAA. Solids remain separate physics.
	for caster in casters: caster.visible=false
	paving.visible=false
	view.size=SOURCE.SIZE
	var authority:=Shader.new()
	authority.code="shader_type spatial;render_mode unshaded;void fragment(){ALBEDO=vec3(1.); }"
	var binary:=ShaderMaterial.new()
	binary.shader=authority
	floor.material_override=binary
	var env: WorldEnvironment=world.get_node("Environment") as WorldEnvironment
	env.environment.background_color=Color.BLACK
	for child in world.get_children():
		if child is MeshInstance3D and child!=floor: child.visible=false
	await _sync()
	var mask:=_read(view)
	await _sync()
	var mask_repeat:=_read(view)
	if mask.get_data()!=mask_repeat.get_data():
		error="City support authority direct logical repeat failed."
		return false
	for name: String in ["land.png","raw_walk.png"]:
		if mask.save_png(OUT+name)!=OK: return false
	var final_walk: Image=_raster_solids(mask)
	if final_walk.save_png(OUT+"walk.png")!=OK: return false
	var rf:=FileAccess.open(OUT+"terrain_height.rf",FileAccess.WRITE)
	if rf==null: return false
	var values:=PackedFloat32Array()
	values.resize(385*257)
	values.fill(0.)
	rf.store_buffer(values.to_byte_array())
	rf.flush()
	var rf_error: int=rf.get_error()
	rf.close()
	if rf_error!=OK: return false
	# Source body sprites never enter floor.png. Preview is explicit independent layers.
	var review: Image=logical.duplicate() as Image
	var sorted: Array=source.objects.duplicate()
	sorted.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a["depth_foot_y"]<b["depth_foot_y"])
	for object in sorted:
		var image: Image=Image.load_from_file(object["texture"])
		if image==null: return false
		var render:=Vector2i(int(round(object["render_size_px"][0])),int(round(object["render_size_px"][1])))
		if image.get_size()!=render: image=_alpha_resize(image,render)
		var foot:=Vector2(object["world_foot_px"][0],object["world_foot_px"][1])
		var uv:=Vector2(object["foot_uv"][0],object["foot_uv"][1])
		var origin:=Vector2i((foot-uv*Vector2(render)).round())
		review.blend_rect(image,Rect2i(Vector2i.ZERO,render),origin)
	if review.save_png(OUT+"review_scene.png")!=OK: return false
	var data:=source.snapshot()
	data["status"]="ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA"
	data["production_approved"]=false
	data["ground_path"]=OUT+"floor.png"
	data["land_path"]=OUT+"land.png"
	data["raw_walk_path"]=OUT+"raw_walk.png"
	data["walk_path"]=OUT+"walk.png"
	data["review_image"]=OUT+"review_scene.png"
	data["source_graph"]=_source_graph()
	data["capture_camera"]=camera_data
	data["source_forecast"]=source.forecast()
	data["navigation_recipe"]="Actual native support plane direct logical readback; final walk exact world-pixel semantic solids bounded raster and 24px canvas guard; no normalized growth, no alpha-shadow inference"
	data["height_grid"]={"size":[385,257],"step_px":8,"format":"Float32 little-endian RF","height_m":0.,"low_paving_geometry_m":[.003,.005],"native_joint_width_m":[.012,.014],"collision_support":"native city plane and independent body polygons, not atlas shadows"}
	data["native_material_sources"]=surface.evidence
	data["shadow_evidence"]={"on_path":OUT+"ground_on_raw.png","off_path":OUT+"ground_off_raw.png","on_repeat_path":OUT+"ground_on_raw_repeat.png","off_repeat_path":OUT+"ground_off_raw_repeat.png","method":"same native mesh/material/basis/transform OFF vs SHADOWS_ONLY; body never baked into ground; no tree shadow drawn over runtime architecture","byte_exact_repeats":true,"logical_ssaa":2}
	data["limitations"]=["Independent human-scale candidate only; not production city or gameplay adoption.","Generated architecture is legacy baked daylight, not claimed to be relit by the native sun.","Original architecture weak-alpha noise is preserved; native and review resizing uses alpha-aware reconstruction without thresholding.","Semantic building footprints are authored from actual masonry/steps, not every opaque roof pixel.","Actual Field rectangle stop/bypass, current-frame local ghost and all source action identities await system/QA."]
	var catalog: Dictionary=_source_graph()
	for entry in surface.evidence:
		catalog[entry["path"]]=entry["sha256"]
		catalog[entry["source_path"]]=entry["source_sha256"]
	for object in source.objects: catalog[object["texture"]]=FileAccess.get_sha256(object["texture"])
	catalog[SOURCE.TREE_MESH]=FileAccess.get_sha256(SOURCE.TREE_MESH)
	catalog[SOURCE.TREE_RAW]=FileAccess.get_sha256(SOURCE.TREE_RAW)
	var tree_json: Variant=JSON.parse_string(FileAccess.get_file_as_string(SOURCE.TREE_RAW))
	if not tree_json is Dictionary: return false
	for item in tree_json.get("buffers",[])+tree_json.get("images",[]):
		if item.has("uri"):
			var path: String=SOURCE.TREE_RAW.get_base_dir()+"/"+String(item["uri"])
			catalog[path]=FileAccess.get_sha256(path)
	for proto in prototypes.values():
		for key: String in ["texture","metadata_path","native_mesh_path","sourcebody_raw","sourcebody_raw_repeat"]:
			var path: String=proto["record"][key]
			catalog[path]=FileAccess.get_sha256(path)
	for name: String in ["floor.png","land.png","raw_walk.png","walk.png","terrain_height.rf","paving_mesh.res","support_plane.res","capture_camera.json","architecture_measurements.json","review_scene.png","ground_on_raw.png","ground_on_raw_repeat.png","ground_off_raw.png","ground_off_raw_repeat.png"]: catalog[OUT+name]=FileAccess.get_sha256(OUT+name)
	data["asset_sha256"]=catalog
	data["capture_graph"]={"source_script":{"path":"res://scripts/dev/luoyang_modular_v1_source.gd","sha256":catalog["res://scripts/dev/luoyang_modular_v1_source.gd"]},"surface_script":{"path":"res://scripts/dev/luoyang_modular_v1_surface.gd","sha256":catalog["res://scripts/dev/luoyang_modular_v1_surface.gd"]},"builder_script":{"path":get_script().resource_path,"sha256":catalog[get_script().resource_path]},"camera_contract":{"path":OUT+"capture_camera.json","sha256":catalog[OUT+"capture_camera.json"]},"height_rf":{"path":OUT+"terrain_height.rf","sha256":catalog[OUT+"terrain_height.rf"]},"native_support_mesh":{"path":OUT+"support_plane.res","sha256":catalog[OUT+"support_plane.res"]},"paving_mesh":{"path":OUT+"paving_mesh.res","sha256":catalog[OUT+"paving_mesh.res"]}}
	if not data["source_forecast"]["passed"]: return false
	return _json(OUT+"art_contract.json",data) and _json(AUDIT+"capture_result.json",{"status":"ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA","source_graph":_source_graph(),"objects":source.objects.size(),"review_image":OUT+"review_scene.png","raw_repeat_exact":true,"production_approved":false})

func _viewport(size: Vector2i,transparent: bool) -> SubViewport:
	var viewport:=SubViewport.new()
	viewport.size=size
	viewport.own_world_3d=true
	viewport.transparent_bg=transparent
	viewport.msaa_3d=Viewport.MSAA_DISABLED
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	return viewport

func _raster_solids(mask: Image) -> Image:
	var result: Image=mask.duplicate() as Image
	result.fill_rect(Rect2i(0,0,SOURCE.SIZE.x,24),Color.BLACK)
	result.fill_rect(Rect2i(0,SOURCE.SIZE.y-24,SOURCE.SIZE.x,24),Color.BLACK)
	result.fill_rect(Rect2i(0,0,24,SOURCE.SIZE.y),Color.BLACK)
	result.fill_rect(Rect2i(SOURCE.SIZE.x-24,0,24,SOURCE.SIZE.y),Color.BLACK)
	for object in source.objects:
		for values in object["solid_polygons_px"]:
			var polygon:=PackedVector2Array()
			var minimum:=Vector2(INF,INF)
			var maximum:=Vector2(-INF,-INF)
			for q in values:
				var p:=Vector2(q[0],q[1])
				polygon.append(p)
				minimum=minimum.min(p)
				maximum=maximum.max(p)
			for y in range(maxi(0,int(floor(minimum.y))),mini(SOURCE.SIZE.y,int(ceil(maximum.y))+1)):
				for x in range(maxi(0,int(floor(minimum.x))),mini(SOURCE.SIZE.x,int(ceil(maximum.x))+1)):
					if Geometry2D.is_point_in_polygon(Vector2(x,y),polygon): result.set_pixel(x,y,Color.BLACK)
		var size:=Vector2(object["collision_size_px"][0],object["collision_size_px"][1])
		if size.x<=0: continue
		var center:=Vector2(object["physical_center_px"][0],object["physical_center_px"][1])
		var rect:=Rect2(center-size*.5,size)
		for y in range(maxi(0,int(ceil(rect.position.y))),mini(SOURCE.SIZE.y,int(ceil(rect.end.y)))):
			for x in range(maxi(0,int(ceil(rect.position.x))),mini(SOURCE.SIZE.x,int(ceil(rect.end.x)))):
				result.set_pixel(x,y,Color.BLACK)
	return result

func _world(viewport: SubViewport,transparent: bool) -> Node3D:
	var world:=Node3D.new()
	viewport.add_child(world)
	var environment:=WorldEnvironment.new()
	environment.name="Environment"
	environment.environment=SURFACE.environment(transparent)
	world.add_child(environment)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-55,-34,0)
	sun.light_energy=.85
	sun.shadow_enabled=true
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance=120.
	sun.shadow_bias=.02
	sun.shadow_normal_bias=1.
	world.add_child(sun)
	return world

func _camera(world: Node3D,logical: Vector2i,target: Vector3) -> Camera3D:
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=logical.y/SOURCE.PPM
	camera.near=.1
	camera.far=160.
	world.add_child(camera)
	camera.position=target+Vector3(0,32,55.4256258422)
	camera.look_at(target,Vector3.UP)
	return camera

func _camera_data(camera: Camera3D,raw: Vector2i,logical: Vector2i) -> Dictionary:
	return {"projection":camera.projection,"orthographic_size_m":camera.size,"position_m":_v3(camera.position),"basis_columns":[_v3(camera.basis.x),_v3(camera.basis.y),_v3(camera.basis.z)],"raw_canvas_px":[raw.x,raw.y],"logical_canvas_px":[logical.x,logical.y],"raw_to_logical_factor":2,"logical_pixels_per_world_m_x":SOURCE.PPM,"logical_pixels_per_world_m_ground_z":SOURCE.ZPPM,"physical_world_size_m":[SOURCE.SIZE.x/SOURCE.PPM,SOURCE.SIZE.y/SOURCE.ZPPM],"camera_elevation_degrees":30.,"near":camera.near,"far":camera.far,"ambient_energy":.45,"sun_energy":.85,"sun_euler_degrees":[-55,-34,0],"shadow_max_m":120.,"msaa":0,"ordinary_actor_effective_height_px":113.5134}

func _alpha_resize(image: Image,size: Vector2i) -> Image:
	var result: Image=image.duplicate() as Image
	result.convert(Image.FORMAT_RGBAF)
	for y in range(result.get_height()):
		for x in range(result.get_width()):
			var c: Color=result.get_pixel(x,y)
			result.set_pixel(x,y,Color(c.r*c.a,c.g*c.a,c.b*c.a,c.a))
	result.resize(size.x,size.y,Image.INTERPOLATE_LANCZOS)
	for y in range(size.y):
		for x in range(size.x):
			var c: Color=result.get_pixel(x,y)
			result.set_pixel(x,y,Color(c.r/c.a,c.g/c.a,c.b/c.a,c.a) if c.a>.00001 else Color(0,0,0,0))
	result.convert(Image.FORMAT_RGBA8)
	return result

func _read(viewport: SubViewport) -> Image:
	var image: Image=viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	return image

func _sync() -> void:
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw

func _json(path: String,data: Dictionary) -> bool:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:
		error="City checked JSON open failed: "+path
		return false
	var text: String=JSON.stringify(data,"\t")
	file.store_string(text)
	file.flush()
	var code: int=file.get_error()
	file.close()
	if code!=OK or FileAccess.get_file_as_string(path)!=text or not JSON.parse_string(text) is Dictionary:
		error="City exact JSON write failed: "+path
		return false
	return true

func _finish(passed: bool) -> void:
	if not passed:
		if error=="": error="Checked city capture or source export failed."
		push_error(error)
		_json(AUDIT+"failed.json",{"status":"TECHNICAL_FAIL","reason":error,"production_approved":false})
		if FileAccess.file_exists(OUT+"art_contract.json"): _json(OUT+"art_contract.json",{"status":"TECHNICAL_FAIL","reason":error,"production_approved":false})
	if view!=null:
		view.queue_free()
		view=null
	prototypes.clear()
	texture_cache.clear()
	if surface!=null: surface.release()
	surface=null
	source=null
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	var cursor:=root.get_node_or_null("CursorManager")
	if cursor!=null:
		for key in ["_arrow","_hand","_wait"]: cursor.set(key,null)
	for i in range(16): await process_frame
	quit(0 if passed else 1)

func _v3(p: Vector3) -> Array:
	return [p.x,p.y,p.z]
