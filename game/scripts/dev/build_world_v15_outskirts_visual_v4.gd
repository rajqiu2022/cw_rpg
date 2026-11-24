extends SceneTree

# Serial, explicitly authorised authoring tool. No world64 export or save writes.
const SOURCE := preload("res://scripts/dev/world_v15_outskirts_source_v4.gd")
const PLANTS := preload("res://scripts/dev/world_v15_outskirts_vegetation_v4.gd")
const SURFACE := preload("res://scripts/dev/world_v15_outskirts_surface_v4.gd")
const OUT := "res://build/world_v15_outskirts_visual_v4/"
const AUDIT := "res://build/world_v15_outskirts_visual_v4/"
const TREE := "res://art/maps/world_map_v14/entities/tree_small02_native_hybrid.res"
const TREE_RAW := "res://art/external/polyhaven/tree_small_02/tree_small_02_1k.gltf"
const SSAA := 2
const SOURCE_PATH := "res://scripts/dev/world_v15_outskirts_source_v4.gd"
const PLANTS_PATH := "res://scripts/dev/world_v15_outskirts_vegetation_v4.gd"
const SURFACE_PATH := "res://scripts/dev/world_v15_outskirts_surface_v4.gd"
var source: SOURCE
var surface: SURFACE
var view: SubViewport
var prototypes: Dictionary={}
var texture_cache: Dictionary={}
var records: Array[Dictionary]=[]
var error := ""

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args:=OS.get_cmdline_user_args()
	var stage := ""
	for arg: String in args:
		if arg.begins_with("--outskirts-visual-stage="): stage=arg.trim_prefix("--outskirts-visual-stage=")
	if not "--outskirts-source-plan" in args and not stage in ["bamboo","forest","marsh"]:
		push_error("Default outskirts export refused; producer serial window required.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(AUDIT))
	if "--outskirts-source-plan" in args:
		var all:=true
		for kind: String in ["bamboo","forest","marsh"]:
			source=SOURCE.new()
			source.prepare(kind)
			var result: Dictionary=source.forecast()
			result["kind"]=kind
			result["source_sha256"]=FileAccess.get_sha256(SOURCE_PATH)
			var suffix: String="_source_forecast_retry1.json" if "--outskirts-source-plan-retry1" in args else "_source_forecast.json"
			all=_json(AUDIT+kind+suffix,result) and bool(result["passed"]) and all
		if not all: error="Projected complete-foot route/branch forecast failed; inspect preserved per-scene JSON."
		await _finish(all)
		return
	if DisplayServer.get_name()=="headless":
		error="Actual GPU required; a headless fallback is not art capture."
		await _finish(false)
		return
	surface=SURFACE.new()
	if not surface.load_sources():
		error=surface.error
		await _finish(false)
		return
	for kind: String in [stage]:
		source=SOURCE.new()
		source.prepare(kind)
		surface.field_ecology_mode={"bamboo":0,"forest":1,"marsh":2}[kind]
		if not bool(source.forecast()["passed"]):
			error="Projected full17 source forecast refused "+kind
			await _finish(false)
			return
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT+kind+"/entities/"))
		if not _json(OUT+kind+"/art_contract.json",{"status":"BUILD_IN_PROGRESS","schema_version":1,"scene_id":SOURCE.IDS[kind]}):
			await _finish(false)
			return
		prototypes.clear()
		for prototype_kind: String in [kind,"waymarker","discovery"]:
			var count: int=3 if prototype_kind==kind else 1
			for variant in range(count):
				if not await _prototype(prototype_kind,variant,kind):
					await _finish(false)
					return
		if not await _field(kind):
			await _finish(false)
			return
		prototypes.clear()
	if not _json(AUDIT+stage+"_result.json",{"status":"SINGLE_FIELD_VISUAL_SAMPLE_REQUIRES_ROOT_REVIEW","cases":records,"production_approved":false,"executed_source_graph":_source_graph()}):
		await _finish(false)
		return
	await _finish(true)

func _source_graph() -> Dictionary:
	var result: Dictionary={}
	for path: String in [get_script().resource_path,SOURCE_PATH,PLANTS_PATH,SURFACE_PATH]: result[path]=FileAccess.get_sha256(path)
	return result

func _tree() -> ArrayMesh:
	var registered: ArrayMesh=load(TREE) as ArrayMesh
	if registered==null: return null
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
				if image==null: return null
				if image.is_compressed() and image.decompress()!=OK:
					error="Native compressed texture decompression rejected: "+String(texture.resource_path)
					return null
				if image.generate_mipmaps()!=OK: return null
				texture_cache[identity]=ImageTexture.create_from_image(image)
			material.set(key,texture_cache[identity])
		material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		if i==1:
			material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			material.alpha_scissor_threshold=.40
		result.surface_set_material(i,material)
	return result

func _draw_bounds(mesh: ArrayMesh,basis: Basis) -> Dictionary:
	var minimum:=Vector3(INF,INF,INF)
	var maximum:=Vector3(-INF,-INF,-INF)
	var points:=PackedVector3Array()
	for i in range(mesh.get_surface_count()):
		var arrays: Array=mesh.surface_get_arrays(i)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices:=PackedInt32Array()
		if arrays[Mesh.ARRAY_INDEX] is PackedInt32Array: indices=arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			for index in range(vertices.size()): indices.append(index)
		var seen: Dictionary={}
		for index in indices:
			if seen.has(index): continue
			seen[index]=true
			var p: Vector3=basis*vertices[index]
			minimum=minimum.min(p)
			maximum=maximum.max(p)
			points.append(p)
	var support_front: float=-INF
	var support_sum:=0.
	var support_count:=0
	var base_min:=Vector3(INF,INF,INF)
	var base_max:=Vector3(-INF,-INF,-INF)
	for p in points:
		if p.y<=minimum.y+(maximum.y-minimum.y)*.02:
			support_front=maxf(support_front,p.z)
			support_sum+=p.x
			support_count+=1
			base_min=base_min.min(p)
			base_max=base_max.max(p)
	return {"min":minimum,"max":maximum,"support":Vector3(support_sum/maxi(1,support_count),minimum.y,support_front),"used_vertex_count":points.size(),"bottom2_min":base_min,"bottom2_max":base_max}

func _prototype(kind: String,variant: int,field: String) -> bool:
	var mesh: ArrayMesh=_tree() if kind=="forest" else PLANTS.waymarker() if kind=="waymarker" else PLANTS.discovery() if kind=="discovery" else PLANTS.plant(kind,variant)
	if mesh==null:
		error="Registered/native mesh unavailable: "+kind
		return false
	var scale: float=.65 if kind=="forest" else .015 if kind=="bamboo" else 1.
	var yaw: float=25.+variant*65. if kind=="forest" else variant*27.
	var basis:=Basis(Vector3.UP,deg_to_rad(yaw)).scaled(Vector3.ONE*scale)
	var bounds: Dictionary=_draw_bounds(mesh,basis)
	var support: Vector3=bounds["support"]
	var identity: String=kind+"_%d"%variant
	view=SubViewport.new()
	view.size=Vector2i(1024,1024)
	view.transparent_bg=true
	view.msaa_3d=Viewport.MSAA_DISABLED
	view.own_world_3d=true
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var world:=Node3D.new()
	view.add_child(world)
	var environment:=WorldEnvironment.new()
	environment.environment=surface.environment()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color(0,0,0,0)
	world.add_child(environment)
	_sun(world)
	var body:=MeshInstance3D.new()
	body.mesh=mesh
	body.transform=Transform3D(basis,-support)
	body.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(body)
	var camera:=_camera(world,Vector2i(512,512),Vector3(0,1.45,0))
	await _sync()
	for index in range(mesh.get_surface_count()):
		var native_material: Material=mesh.surface_get_material(index)
		if native_material is ShaderMaterial:
			var keys: Array[String]=[]
			if kind=="bamboo": keys.assign(["original_diffuse","original_normal","original_specular"])
			else: keys.assign(["native_timber_contract"])
			if not _gate(native_material,keys):
				error="Actual native plant/prop shader reflection failed: "+identity
				return false
	var raw: Image=_read(view)
	await _sync()
	var repeat: Image=_read(view)
	var path: String=OUT+field+"/entities/"+identity
	if raw.get_data()!=repeat.get_data() or raw.save_png(path+"_sourcebody_raw.png")!=OK or repeat.save_png(path+"_sourcebody_raw_repeat.png")!=OK:
		error="Sourcebody exact repeat failed: "+identity
		return false
	var logical: Image=_alpha_resample(raw,Vector2i(512,512))
	var used: Rect2i=logical.get_used_rect()
	if used.size==Vector2i.ZERO or used.position.x<4 or used.position.y<4 or used.end.x>508 or used.end.y>508:
		error="Sourcebody crop/apron failed: "+identity
		return false
	var crop: Rect2i=used.grow(4)
	var alpha: Image=logical.get_region(crop)
	if alpha.save_png(path+".png")!=OK: return false
	var foot: Vector2=camera.unproject_position(Vector3.ZERO)/SSAA-Vector2(crop.position)
	var uv: Vector2=foot/Vector2(crop.size)
	var geometry_path: String=path+"_mesh.res"
	if ResourceSaver.save(mesh,geometry_path)!=OK: return false
	var meta: Dictionary={"id":identity,"texture":path+".png","render_size_px":[crop.size.x,crop.size.y],"foot_uv":[uv.x,uv.y],"sourcebody_raw":path+"_sourcebody_raw.png","sourcebody_raw_repeat":path+"_sourcebody_raw_repeat.png","raw_size":[1024,1024],"logical_canvas":[512,512],"crop_rect_px":[crop.position.x,crop.position.y,crop.size.x,crop.size.y],"alpha_resampling_algorithm":"RGBAF_PREMULTIPLIED_LANCZOS_UNPREMULTIPLY_V1","sourcebody_camera":_camera_data(camera,view.size,Vector2i(512,512)),"native_mesh_path":geometry_path,"native_mesh_sha256":FileAccess.get_sha256(geometry_path),"scale":scale,"yaw_degrees":yaw,"actual_used_vertex_count":bounds["used_vertex_count"],"actual_bounds_min":_v3(bounds["min"]),"actual_bounds_max":_v3(bounds["max"]),"actual_support_point":_v3(support),"actual_model_translation":_v3(-support),"support_method":"minimum actual draw-index Y plus frontZ of bottom6%, synthetic support anchor not a claimed existing vertex","license":"CC0-1.0" if kind=="forest" else "project-original native geometry/material","source":TREE_RAW if kind=="forest" else PLANTS_PATH,"source_sha256":FileAccess.get_sha256(TREE_RAW if kind=="forest" else PLANTS_PATH),"derived_mesh_source":TREE if kind=="forest" else PLANTS_PATH,"derived_mesh_source_sha256":FileAccess.get_sha256(TREE if kind=="forest" else PLANTS_PATH),"tree_recipe":"registered source-leaf L0 + native branch/trunkLOD2; no model bytes changed; ordinary scene scale.65" if kind=="forest" else "curved segmented stalks and six-section lance leaves","geometry_bounds_use_only_actual_draw_indices":true,"raw_repeat_byte_exact":true,"blocking_footprint_kind":"narrow physical stem/trunk, NOT canopy XZ"}
	meta["support_method"]="minimum actual draw-index Y plus averageX/frontZ of bottom2%; synthetic support anchor, not a claimed existing vertex"
	meta["bottom2_bounds_min_m"]=_v3(bounds["bottom2_min"])
	meta["bottom2_bounds_max_m"]=_v3(bounds["bottom2_max"])
	if kind in ["bamboo","marsh"]:
		var evidence_key: String="bamboo" if kind=="bamboo" else "marsh_%d"%variant
		meta["licensed_geometry"]=PLANTS.geometry_evidence[evidence_key].duplicate(true)
		meta["source"]=meta["licensed_geometry"]["source"]
		meta["source_sha256"]=meta["licensed_geometry"]["source_sha256"]
		meta["license"]="CC0-1.0"
		meta["tree_recipe"]="not a tree; original author geometry and UVs unchanged"
		meta["derived_mesh_source"]=PLANTS.BAMBOO_MESH if kind=="bamboo" else PLANTS.HERB
		meta["derived_mesh_source_sha256"]=FileAccess.get_sha256(meta["derived_mesh_source"])
		meta["original_texture_evidence"]=PLANTS.texture_evidence.duplicate(true)
	if kind=="bamboo":
		var base_min: Vector3=bounds["bottom2_min"]
		var base_max: Vector3=bounds["bottom2_max"]
		var base_center: Vector3=(base_min+base_max)*.5-support
		meta["physical_offset_px"]=[base_center.x*SOURCE.PPM,base_center.z*SOURCE.Z_PPM]
		meta["physical_size_px"]=[maxf(6.,(base_max.x-base_min.x)*SOURCE.PPM),maxf(4.,(base_max.z-base_min.z)*SOURCE.Z_PPM)]
		meta["physical_recipe"]="actual transformed bottom2% stem XZ bounds, projected as ground rect; min6x4px numeric blocker pad explicitly recorded; canopy excluded"
	if not _json(path+".json",meta): return false
	prototypes[identity]={"mesh":mesh,"basis":basis,"support":support,"texture":alpha,"metadata":meta,"foot_uv":uv,"path":path+".png","metadata_path":path+".json"}
	view.queue_free()
	view=null
	await _sync()
	return true

func _field(kind: String) -> bool:
	var directory: String=OUT+kind+"/"
	var rect:=Rect2(-256,-256,2048,1536)
	var grid_origin:=Vector2i(-32,-32)
	var grid_size:=Vector2i(257,193)
	var heights:=PackedFloat32Array()
	for y in range(grid_size.y):
		for x in range(grid_size.x): heights.append(source.vertex(grid_origin+Vector2i(x,y)))
	var rf:=Image.create_from_data(grid_size.x,grid_size.y,false,Image.FORMAT_RF,heights.to_byte_array())
	var file:=FileAccess.open(directory+"terrain_height.rf",FileAccess.WRITE)
	if file==null: return false
	file.store_buffer(heights.to_byte_array())
	file.flush()
	var rf_error: int=file.get_error()
	file.close()
	if rf_error!=OK: return false
	var maps: Dictionary=_maps(rect)
	view=SubViewport.new()
	view.size=SOURCE.SIZE*SSAA
	view.msaa_3d=Viewport.MSAA_DISABLED
	view.own_world_3d=true
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var world:=Node3D.new()
	view.add_child(world)
	var environment:=WorldEnvironment.new()
	environment.environment=surface.environment()
	world.add_child(environment)
	_sun(world)
	var terrain:=MeshInstance3D.new()
	terrain.mesh=_mesh(grid_origin,grid_size,false)
	var terrain_material: ShaderMaterial=surface.terrain_material(maps["ecology"],maps["roads"],Rect2(SOURCE.MATERIAL_ORIGIN+rect.position,rect.size))
	terrain.material_override=terrain_material
	world.add_child(terrain)
	if ResourceSaver.save(terrain.mesh,directory+"terrain_mesh.res")!=OK: return false
	var water:=MeshInstance3D.new()
	water.mesh=_mesh(grid_origin,grid_size,true)
	water.material_override=surface.water_material(ImageTexture.create_from_image(rf),Vector2i(SOURCE.MATERIAL_ORIGIN/8.)+grid_origin,grid_size)
	water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(water)
	var camera:=_camera(world,SOURCE.SIZE,Vector3.ZERO)
	var capture_camera: Dictionary=_camera_data(camera,view.size,SOURCE.SIZE)
	if not _json(directory+"capture_camera.json",capture_camera): return false
	var casters: Array[MeshInstance3D]=[]
	var objects: Array[Dictionary]=[]
	for i in range(source.props.size()):
		var spec: Dictionary=source.props[i]
		var key: String=spec["prototype"]+"_%d"%(0 if spec["prototype"] in ["waymarker","discovery"] else i%3)
		var prototype: Dictionary=prototypes[key]
		var p: Vector2=spec["source_foot"]
		var position3: Vector3=SOURCE.point3(p,source.height(p))
		var physical_offset := Vector2.ZERO
		if kind=="bamboo" and spec["prototype"]=="bamboo":
			var physical: Array=prototype["metadata"]["physical_size_px"]
			var offset: Array=prototype["metadata"]["physical_offset_px"]
			spec["collision_size_px"]=Vector2(physical[0],physical[1])
			physical_offset=Vector2(offset[0],offset[1])
			spec["physical_offset_px"]=physical_offset
		var caster:=MeshInstance3D.new()
		caster.mesh=prototype["mesh"]
		caster.transform=Transform3D(prototype["basis"],position3-Vector3(prototype["support"]))
		caster.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		caster.visible=false
		caster.layers=2
		world.add_child(caster)
		casters.append(caster)
		var projected: Vector2=camera.unproject_position(position3)/SSAA
		objects.append({"id":spec["id"],"texture":prototype["path"],"metadata_path":prototype["metadata_path"],"source_size_px":prototype["metadata"]["render_size_px"],"source_sha256":FileAccess.get_sha256(prototype["path"]),"world_foot_px":[projected.x,projected.y],"source_foot_px":[p.x,p.y],"ground_m":source.height(p),"render_size_px":prototype["metadata"]["render_size_px"],"foot_uv":prototype["metadata"]["foot_uv"],"physical_center_px":[projected.x,projected.y],"collision_size_px":[spec["collision_size_px"].x,spec["collision_size_px"].y] if spec["blocking"] else [0,0],"depth_foot_y":projected.y,"blocking":spec["blocking"],"nature":spec["nature"],"native_transform":{"basis_columns":[_v3(caster.basis.x),_v3(caster.basis.y),_v3(caster.basis.z)],"origin":_v3(caster.position)},"sourcebody_and_caster_same_geometry_material":true})
		objects[-1]["physical_center_px"]=[projected.x+physical_offset.x,projected.y+physical_offset.y]
	camera.cull_mask=3
	await _sync()
	if not _gate(terrain_material,["biome_weights","road_weights","grass_ground_diff"]) or not _gate(water.material_override,["actual_height_rf","grid_origin","grid_shape"]):
		error="Native surface shader rejected default fallback: "+kind
		return false
	var off: Image=_read(view)
	await _sync()
	var off_repeat: Image=_read(view)
	# Same camera masks; SHADOWS_ONLY emits no visible body in either ground pass.
	for caster in casters:
		caster.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		caster.visible=true
	await _sync()
	var on: Image=_read(view)
	await _sync()
	var on_repeat: Image=_read(view)
	if off.get_data()!=off_repeat.get_data() or on.get_data()!=on_repeat.get_data():
		error="Ground cast exact repeat failed: "+kind
		return false
	for pair in [["ground_on_raw.png",on],["ground_on_raw_repeat.png",on_repeat],["ground_off_raw.png",off],["ground_off_raw_repeat.png",off_repeat]]:
		if pair[1].save_png(directory+pair[0])!=OK: return false
	var logical_on: Image=on.duplicate() as Image
	logical_on.resize(SOURCE.SIZE.x,SOURCE.SIZE.y,Image.INTERPOLATE_LANCZOS)
	if logical_on.save_png(directory+"ground.png")!=OK: return false
	# Native authority is direct original canvas readback. No SSAA, resize or AA.
	for caster in casters: caster.visible=false
	water.visible=false
	view.size=SOURCE.SIZE
	view.msaa_3d=Viewport.MSAA_DISABLED
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color.BLACK
	var topology: Image=_topology()
	if topology.save_png(directory+"source_topology.png")!=OK: return false
	for mode in [0,1]:
		terrain.material_override=_authority(ImageTexture.create_from_image(topology),mode)
		await _sync()
		var authority: Image=_read(view)
		await _sync()
		var again: Image=_read(view)
		if authority.get_data()!=again.get_data():
			error="Binary native repeat failed: "+kind
			return false
		var name: String="land.png" if mode==0 else "raw_walk.png"
		if authority.save_png(directory+name)!=OK: return false
		if mode==1 and authority.save_png(directory+"walk.png")!=OK: return false
	var actual_camera: Dictionary=_camera_data(camera,SOURCE.SIZE*SSAA,SOURCE.SIZE)
	var scene: Image=logical_on.duplicate() as Image
	objects.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a["depth_foot_y"]<b["depth_foot_y"])
	for object in objects:
		var prototype: Dictionary=prototypes[String(object["metadata_path"]).get_file().get_basename()]
		var image: Image=prototype["texture"]
		var position:=Vector2(object["world_foot_px"][0],object["world_foot_px"][1])-Vector2(object["foot_uv"][0],object["foot_uv"][1])*Vector2(image.get_size())
		scene.blend_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),Vector2i(position.round()))
	if scene.save_png(directory+"review_scene.png")!=OK: return false
	var route_points: Array=[]
	for p in source.route:
		var projected: Vector2=source.projected(p)
		route_points.append([projected.x,projected.y])
	var branch_points: Array=[]
	for p in source.branch:
		var projected: Vector2=source.projected(p)
		branch_points.append([projected.x,projected.y])
	var return_foot: Vector2=source.projected(source.route[0])
	var discovery: Vector2=source.projected(source.branch[-1])
	var blocked: Array=[]
	for p: Vector2 in [Vector2(1220,315),Vector2(285,430),Vector2(1420,325)]:
		if source.bank(p)<-30.:
			var projected: Vector2=source.projected(p)
			blocked.append({"id":"natural_water_%d"%blocked.size(),"point_px":[projected.x,projected.y],"source_px":[p.x,p.y],"kind":"water","actual_bed_m":source.height(p)})
	for object in objects:
		if object["blocking"]: blocked.append({"id":object["id"],"point_px":object["physical_center_px"],"kind":"independent_trunk_or_stem"})
	var probes: Array=[]
	for i in range(route_points.size()): probes.append({"id":"loop_%d"%i,"point_px":route_points[i]})
	for i in range(branch_points.size()): probes.append({"id":"branch_%d"%i,"point_px":branch_points[i]})
	var entry: Dictionary={}
	for object in objects:
		if object["id"]=="return_waymarker": entry=object
	var assets: Dictionary={}
	for path in _source_graph(): assets[path]=_source_graph()[path]
	for record in surface.evidence:
		assets[record["path"]]=record["sha256"]
		assets[record["source_path"]]=record["source_sha256"]
	for record in PLANTS.texture_evidence:
		assets[record["path"]]=record["sha256"]
		assets[record["source_path"]]=record["source_sha256"]
	if kind=="forest":
		assets[TREE]=FileAccess.get_sha256(TREE)
		assets[TREE_RAW]=FileAccess.get_sha256(TREE_RAW)
		var gltf: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(TREE_RAW))
		for item in gltf.get("buffers",[])+gltf.get("images",[]):
			if item.has("uri"):
				var raw_path: String=TREE_RAW.get_base_dir()+"/"+String(item["uri"])
				assets[raw_path]=FileAccess.get_sha256(raw_path)
	if kind=="bamboo":
		for path: String in [PLANTS.BAMBOO_RAW,PLANTS.BAMBOO_MESH,PLANTS.BAMBOO_ROOT+"SOURCE.json",PLANTS.BAMBOO_ROOT+"derived/native_import_record.json"]: assets[path]=FileAccess.get_sha256(path)
	if kind=="marsh":
		assets[PLANTS.HERB]=FileAccess.get_sha256(PLANTS.HERB)
		var herb_gltf: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(PLANTS.HERB))
		for item in herb_gltf.get("buffers",[])+herb_gltf.get("images",[]):
			if item.has("uri"):
				var path: String=PLANTS.HERB.get_base_dir()+"/"+String(item["uri"])
				assets[path]=FileAccess.get_sha256(path)
	assets[directory+"capture_camera.json"]=FileAccess.get_sha256(directory+"capture_camera.json")
	for name: String in ["ground.png","land.png","raw_walk.png","walk.png","source_topology.png","terrain_height.rf","terrain_mesh.res","review_scene.png","ground_on_raw.png","ground_on_raw_repeat.png","ground_off_raw.png","ground_off_raw_repeat.png"]: assets[directory+name]=FileAccess.get_sha256(directory+name)
	for prototype in prototypes.values():
		for path: String in [prototype["path"],prototype["metadata_path"],prototype["metadata"]["native_mesh_path"],prototype["metadata"]["sourcebody_raw"],prototype["metadata"]["sourcebody_raw_repeat"]]: assets[path]=FileAccess.get_sha256(path)
	var data: Dictionary={"schema_version":1,"scene_id":SOURCE.IDS[kind],"status":"ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA","logical_size_px":[1536,1024],"production_approved":false,"ground_path":directory+"ground.png","land_path":directory+"land.png","raw_walk_path":directory+"raw_walk.png","walk_path":directory+"walk.png","terrain_height_path":directory+"terrain_height.rf","terrain_mesh_path":directory+"terrain_mesh.res","source_topology_path":directory+"source_topology.png","return_foot_px":[return_foot.x,return_foot.y],"discovery_foot_px":[discovery.x,discovery.y],"source_entry_object":entry,"objects":objects,"routes":[{"id":"central_loop_and_return","points_px":route_points}],"walkable_probes":probes,"blocked_probes":blocked,"source_forecast":source.forecast(),"asset_sha256":assets,"capture_camera":_camera_data(camera,SOURCE.SIZE*SSAA,SOURCE.SIZE),"authority_camera":{"projection":"same ortho transform, direct logical canvas/MSAA0; no resizing or props in ground mask"},"height_grid":{"size":[grid_size.x,grid_size.y],"origin_px":[-256,-256],"step_px":8,"format":"RF Float32 little-endian","interpolation":"actual [a,b,c,b,d,c] triangles, not bilinear"},"native_material_sources":surface.evidence,"shadow_evidence":{"on_path":directory+"ground_on_raw.png","off_path":directory+"ground_off_raw.png","on_repeat_path":directory+"ground_on_raw_repeat.png","off_repeat_path":directory+"ground_off_raw_repeat.png","method":"native same mesh/material/transform SHADOWS_ONLY vs OFF; same camera/lights/terrain self-shadow; independent body NEVER baked in ground","raw_repeat_byte_exact":true},"review_image":directory+"review_scene.png","ecology":{"type":kind,"original_native_layout":true,"height_function_source":SOURCE_PATH,"independent_instance_count":objects.size(),"not_recolored_old_story_map":true},"limitations":["Native bamboo/reed quality pending actual image review; no claim of photogrammetry.","Source forecast not a replacement for independent PNG + real Field full17/input QA.","Source-entry waymarker is new native geometry, not claimed as an existing authorised wooden sign asset."]}
	data["capture_camera"]=actual_camera
	data["native_texture_provenance"]=PLANTS.texture_evidence.duplicate(true)
	data["native_geometry_provenance"]=PLANTS.geometry_evidence.duplicate(true)
	data["ecology"]["material_recipe"]="v4 registered leafy_grass2m dominant bamboo/forest; local actual root forest soil, mud route/shore; six shared normalized weights for ALBEDO, ARM and normal; no global tint iteration"
	data["limitations"]=["Single-stage visual candidate only; no old three-field assets, formal v14 or world64 updated.","Yughues original bamboo source units not declared; authoring metric scale.015 gives approximately3.07m, not a claimed author unit convention.","Shrub03 is a real low ground plant on dry mud-bank, NOT a tall reed model.","Source forecast is not independent actual Field input/full17/occlusion approval."]
	data["pixel_sampling"]="round_world_pixel"
	data["physical_navigation_margin_px"]=0
	data["source_graph"]=_source_graph()
	data["capture_graph"]={"camera_contract":{"path":directory+"capture_camera.json","sha256":assets[directory+"capture_camera.json"]},"height_rf":{"path":directory+"terrain_height.rf","sha256":assets[directory+"terrain_height.rf"]},"terrain_mesh":{"path":directory+"terrain_mesh.res","sha256":assets[directory+"terrain_mesh.res"]},"source_script":{"path":SOURCE_PATH,"sha256":assets[SOURCE_PATH]},"builder_script":{"path":get_script().resource_path,"sha256":assets[get_script().resource_path]},"surface_script":{"path":SURFACE_PATH,"sha256":assets[SURFACE_PATH]},"vegetation_script":{"path":PLANTS_PATH,"sha256":assets[PLANTS_PATH]}}
	data["routes"].append({"id":"exploration_branch","points_px":branch_points})
	data["shadow_evidence"]["method"]="native identical mesh/material/transform/camera masks, SHADOWS_ONLY visible ON vs hidden OFF; no visible model body in either pass; terrain self-shadow unchanged"
	if not _json(directory+"art_contract.json",data): return false
	records.append({"scene_id":SOURCE.IDS[kind],"art_contract":directory+"art_contract.json","image":directory+"review_scene.png","objects":objects.size()})
	view.queue_free()
	view=null
	await _sync()
	return true

func _maps(rect: Rect2) -> Dictionary:
	var ecology:=Image.create(256,192,false,Image.FORMAT_RGBA8)
	var roads:=Image.create(256,192,false,Image.FORMAT_RGB8)
	for y in range(192):
		for x in range(256):
			var p: Vector2=rect.position+Vector2(x+.5,y+.5)*8.
			var e: Vector4=source.ecology(p)
			ecology.set_pixel(x,y,Color(e.x,e.y,e.z,e.w))
			var distance: float=source.road_distance(p)
			roads.set_pixel(x,y,Color(1.-smoothstep(20.,48.,distance),1.-smoothstep(40.,83.,distance),0))
	return {"ecology":ImageTexture.create_from_image(ecology),"roads":ImageTexture.create_from_image(roads)}

func _topology() -> Image:
	var result:=Image.create(768,512,false,Image.FORMAT_RGB8)
	for y in range(512):
		for x in range(768):
			var info: Dictionary=source.selector(Vector2(x,y)*2.)
			result.set_pixel(x,y,Color(1. if info["land"] else 0.,0,1. if info["walk"] else 0.))
	return result

func _authority(topology: Texture2D,mode: int) -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code="""shader_type spatial;render_mode unshaded,cull_disabled;uniform sampler2D topology:filter_nearest,repeat_disable;uniform int mode;varying vec3 xyz;void vertex(){xyz=VERTEX;}void fragment(){vec2 p=vec2(xyz.x*102.4+768.,xyz.z*72.40773439+512.);vec3 t=texture(topology,p/vec2(1536.,1024.)).rgb;float land=xyz.y>-.025?1.:0.;float allowed=mode==0?land:land*(t.b>.5?1.:0.);ALBEDO=vec3(allowed);}"""
	var material:=ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("topology",topology)
	material.set_shader_parameter("mode",mode)
	return material

func _mesh(origin: Vector2i,shape: Vector2i,water: bool) -> ArrayMesh:
	var vertices:=PackedVector3Array()
	var normals:=PackedVector3Array()
	var uv:=PackedVector2Array()
	var indices:=PackedInt32Array()
	for y in range(shape.y):
		for x in range(shape.x):
			var g: Vector2i=origin+Vector2i(x,y)
			var p: Vector2=Vector2(g*8)
			vertices.append(SOURCE.point3(p,SOURCE.WATER_Y if water else source.vertex(g)))
			var dx: float=(source.vertex(g+Vector2i(1,0))-source.vertex(g-Vector2i(1,0)))*SOURCE.PPM/16.
			var dz: float=(source.vertex(g+Vector2i(0,1))-source.vertex(g-Vector2i(0,1)))*SOURCE.Z_PPM/16.
			normals.append(Vector3.UP if water else Vector3(-dx,1,-dz).normalized())
			uv.append(p/Vector2(SOURCE.SIZE))
	for y in range(shape.y-1):
		for x in range(shape.x-1):
			var a: int=y*shape.x+x
			indices.append_array(PackedInt32Array([a,a+1,a+shape.x,a+1,a+shape.x+1,a+shape.x]))
	var arrays: Array=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_TEX_UV]=uv
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func _camera(world: Node3D,logical: Vector2i,target: Vector3) -> Camera3D:
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=logical.y/SOURCE.PPM
	camera.near=.05
	camera.far=100.
	camera.position=target+Vector3(0,20,20)
	world.add_child(camera)
	camera.look_at(target)
	camera.current=true
	return camera

func _sun(world: Node3D) -> void:
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-55,-34,0)
	sun.light_energy=.85
	sun.shadow_enabled=true
	sun.shadow_normal_bias=1.
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance=60.
	world.add_child(sun)

func _camera_data(camera: Camera3D,actual: Vector2i,logical: Vector2i) -> Dictionary:
	return {"position":_v3(camera.position),"basis_columns":[_v3(camera.basis.x),_v3(camera.basis.y),_v3(camera.basis.z)],"orthographic_size":camera.size,"projection_enum":camera.projection,"actual_canvas":[actual.x,actual.y],"logical_canvas":[logical.x,logical.y],"actual_to_logical_factor":2,"logical_pixels_per_meter":102.4}

func _alpha_resample(raw: Image,size: Vector2i) -> Image:
	var value: Image=raw.duplicate() as Image
	value.convert(Image.FORMAT_RGBAF)
	for y in range(value.get_height()):
		for x in range(value.get_width()):
			var c: Color=value.get_pixel(x,y)
			value.set_pixel(x,y,Color(c.r*c.a,c.g*c.a,c.b*c.a,c.a))
	value.resize(size.x,size.y,Image.INTERPOLATE_LANCZOS)
	for y in range(size.y):
		for x in range(size.x):
			var c: Color=value.get_pixel(x,y)
			value.set_pixel(x,y,Color(c.r/c.a,c.g/c.a,c.b/c.a,c.a) if c.a>.00001 else Color(0,0,0,0))
	value.convert(Image.FORMAT_RGBA8)
	return value

func _gate(material: ShaderMaterial,keys: Array[String]) -> bool:
	if material==null or material.shader==null: return false
	var names: Array[String]=[]
	for value in material.shader.get_shader_uniform_list(): names.append(String(value["name"]))
	for key in keys:
		if not key in names: return false
	return true

func _read(viewport: SubViewport) -> Image:
	var image: Image=viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	return image

func _sync() -> void:
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw

func _json(path: String,value: Dictionary) -> bool:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:
		error="JSON open failed "+path
		return false
	var text: String=JSON.stringify(value,"\t")
	file.store_string(text)
	file.flush()
	var code: int=file.get_error()
	file.close()
	if code!=OK or FileAccess.get_file_as_string(path)!=text or not JSON.parse_string(text) is Dictionary:
		error="JSON exact write failed "+path
		return false
	return true

func _finish(passed: bool) -> void:
	if not passed:
		push_error(error)
		_json(AUDIT+"failed.json",{"status":"TECHNICAL_FAIL","reason":error,"production_approved":false})
	if view!=null:
		view.queue_free()
		view=null
	prototypes.clear()
	texture_cache.clear()
	PLANTS.release()
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
