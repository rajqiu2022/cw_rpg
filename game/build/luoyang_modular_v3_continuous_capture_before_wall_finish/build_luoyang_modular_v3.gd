extends SceneTree

# New isolated art capture tool. Default invocation is refused. No gameplay writes.
const SOURCE := preload("res://scripts/dev/luoyang_modular_v3_source.gd")
const SURFACE := preload("res://scripts/dev/luoyang_modular_v3_surface.gd")
var OUT := SOURCE.OUT
const AUDIT := "res://build/luoyang_modular_v3_street_quay_revision/"
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
	if not "--luoyang-v3-source-plan" in args and not "--luoyang-modular-v3-capture" in args:
		push_error("Independent Luoyang default export refused; producer serial window required.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(AUDIT))
	source=SOURCE.new()
	var chosen: String="ch4_s0_luoyang_gate"
	for arg: String in args:
		if arg.begins_with("--city-region="): chosen=arg.trim_prefix("--city-region=")
	source.prepare(chosen)
	OUT=source.region_out
	var forecast: Dictionary=source.forecast()
	if not _json(AUDIT+chosen+"_source_forecast.json",forecast) or not forecast["passed"]:
		error="City route/door17 and Rectangle34x24 forecast failed."
		await _finish(false)
		return
	if "--luoyang-v3-source-plan" in args:
		var data:=source.snapshot()
		data["source_graph"]=_source_graph()
		data["forecast"]=forecast
		await _finish(_json(AUDIT+chosen+"_source_layout.json",data))
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
	if not _stage_generated_textures():
		await _finish(false)
		return
	var needed: Array[String]=[]
	for object in source.objects:
		var kind: String=object["prototype"]
		if kind!="" and not kind in needed: needed.append(kind)
	for kind: String in needed:
		if not await _prototype(kind):
			await _finish(false)
			return
	if not await _capture_city():
		await _finish(false)
		return
	await _finish(true)

func _source_graph() -> Dictionary:
	var graph: Dictionary={}
	for path: String in [get_script().resource_path,"res://scripts/dev/luoyang_modular_v3_source.gd","res://scripts/dev/luoyang_modular_v3_surface.gd"]: graph[path]=FileAccess.get_sha256(path)
	return graph

func _measure_buildings() -> bool:
	var records: Array=[]
	for object in source.objects:
		if object["prototype"]!="": continue
		var image: Image=Image.load_from_file(object["texture"])
		var expected:=Vector2i(object["source_size_px"][0],object["source_size_px"][1])
		if image==null or image.get_size()!=expected or FileAccess.get_sha256(object["texture"])!=object["source_sha256"]:
			error="Generated source missing, SHA or actual canvas changed: "+object["id"]
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
		var required_margin: int=int(ceil(mini(expected.x,expected.y)*.10))
		var strong: Rect2i=bounds["30"]
		object["alpha_measurement"]={"source_sha256":FileAccess.get_sha256(object["texture"]),"actual_size_px":[expected.x,expected.y],"histogram":histogram,"bounds_strict_alpha_greater_than":bboxes,"source_modified":false,"weak_alpha_not_thresholded":true,"thresholds_are_measurement_only_not_image_editing":true,"requested_10_percent_margin_satisfied":strong.position.x>=required_margin and strong.position.y>=required_margin and strong.end.x<=expected.x-required_margin and strong.end.y<=expected.y-required_margin,"margin_failure_is_recorded_not_alpha_cropped":true}
		records.append({"id":object["id"],"measurement":object["alpha_measurement"],"semantic_ground_polygons_world":object["solid_polygons_px"]})
	return _json(OUT+"architecture_measurements.json",{"sources":records,"approval":"SOURCE_MEASURED_NOT_FIELD_VISUAL_APPROVED","generation_record_path":SOURCE.GENERATION,"no_generated_source_claimed_cc0":true})

func _box(size: Vector3,position: Vector3,material: Material,root3: Node3D) -> void:
	var node:=MeshInstance3D.new()
	var mesh:=BoxMesh.new()
	mesh.size=size
	mesh.material=material
	node.mesh=mesh
	node.position=position
	root3.add_child(node)

func _stage_generated_textures() -> bool:
	# Runtime textures are district-local, while the exact common raw source and
	# provenance remain bound separately. No old source bytes are overwritten.
	for object in source.objects:
		if object["prototype"]!="": continue
		var raw_path: String=object["source"]
		var path: String=OUT+"entities/"+String(object["id"])+".png"
		if FileAccess.file_exists(path) and FileAccess.get_sha256(path)!=object["source_sha256"]:
			error="District raw-copy output already exists with different bytes: "+path
			return false
		if not FileAccess.file_exists(path) and DirAccess.copy_absolute(ProjectSettings.globalize_path(raw_path),ProjectSettings.globalize_path(path))!=OK:
			error="District source copy failed: "+path
			return false
		if FileAccess.get_sha256(path)!=object["source_sha256"]:
			error="District texture raw SHA mismatch: "+path
			return false
		object["texture"]=path
	return true

func _prop_mesh(kind: String) -> ArrayMesh:
	# Generated architecture/props keep original RGBA. These low semantic items
	# are openly project modeled, not substituted CC0 or a fake architectural kit.
	if kind=="tree": return _tree()
	if kind=="boat": return _boat_mesh()
	var result:=ArrayMesh.new()
	var parts: Array=[]
	if kind=="cargo":
		for i in range(6): parts.append([Vector3(.62,.082,.46),Vector3(0,.055+i*.083,0),SURFACE.wood()])
		for x in [-.25,.25]: parts.append([Vector3(.027,.52,.50),Vector3(x,.26,0),SURFACE.plain(Color(.14,.15,.145))])
	elif kind=="inscription":
		parts=[[Vector3(.9,.16,.55),Vector3(0,.08,0),SURFACE.plain(Color(.34,.35,.34))],[Vector3(.74,.87,.24),Vector3(0,.595,0),SURFACE.plain(Color(.42,.43,.415))],[Vector3(.82,.08,.30),Vector3(0,1.07,0),SURFACE.plain(Color(.35,.36,.35))]]
	elif kind=="mud_trace":
		parts=[[Vector3(.65,.003,.43),Vector3(0,.0015,0),SURFACE.plain(Color(.22,.205,.17))]]
	elif kind in ["wall_vertical","wall_horizontal"]:
		var horizontal: bool=kind=="wall_horizontal"
		var length: float=5. if horizontal else 5.
		var thickness: float=22./SOURCE.ZPPM if horizontal else 26./SOURCE.PPM
		for row in range(5):
			for stone in range(8):
				var along: float=-length*.5+(stone+.5)*length/8.
				var size:=Vector3(length/8.-.012,.228,thickness) if horizontal else Vector3(thickness,.228,length/8.-.012)
				var pos:=Vector3(along,.12+row*.24,0) if horizontal else Vector3(0,.12+row*.24,along)
				parts.append([size,pos,surface.masonry(Color(.92+row*.008,.90+row*.006,.85+row*.006))])
		var cap:=Vector3(length,.085,thickness) if horizontal else Vector3(thickness,.085,length)
		parts.append([cap,Vector3(0,1.24,0),surface.masonry(Color(.75,.76,.73))])
	elif kind=="quay_rail":
		for z in [-4.234375,0.,4.234375]: parts.append([Vector3(.28125,.85,.28125),Vector3(0,.425,z),SURFACE.plain(Color(.32,.34,.325))])
		for y in [.28,.66]: parts.append([Vector3(.15,.14,8.75),Vector3(0,y,0),SURFACE.wood()])
	elif kind=="loading_wharf":
		for i in range(16): parts.append([Vector3(1.56,.04,.38),Vector3(0,.02,-3.+i*.4),SURFACE.wood()])
	else:
		error="Unknown authored native city prop: "+kind
		return null
	for part in parts:
		var box:=BoxMesh.new()
		box.size=part[0]
		var arrays: Array=box.surface_get_arrays(0)
		var positions: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		for i in range(positions.size()): positions[i]+=Vector3(part[1])
		arrays[Mesh.ARRAY_VERTEX]=positions
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		result.surface_set_material(result.get_surface_count()-1,part[2])
	return result

func _boat_mesh() -> ArrayMesh:
	# Project-native actual curved timber hull, not an imported/CC0 claim and not
	# a walk-support extension. One independent transparent body and own Y line.
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array]=[]
	for j in range(9):
		var z: float=-3.4+j*.85
		var width: float=.12+1.02*sin(PI*j/8.)
		var ring:=PackedVector3Array([Vector3(-width,.55,z),Vector3(-width*.65,.08,z),Vector3(0,0,z),Vector3(width*.65,.08,z),Vector3(width,.55,z)])
		rings.append(ring)
	for j in range(8):
		for k in range(4):
			for tri in [[rings[j][k],rings[j+1][k],rings[j][k+1]],[rings[j][k+1],rings[j+1][k],rings[j+1][k+1]]]:
				var n: Vector3=-(Vector3(tri[1])-Vector3(tri[0])).cross(Vector3(tri[2])-Vector3(tri[0])).normalized()
				for p: Vector3 in tri:
					tool.set_normal(n);tool.set_uv(Vector2(p.x,p.z));tool.add_vertex(p)
	var mesh: ArrayMesh=tool.commit()
	var wood: ShaderMaterial=SURFACE.wood()
	wood.shader.code=wood.shader.code.replace("shader_type spatial;","shader_type spatial;render_mode cull_disabled;")
	mesh.surface_set_material(0,wood)
	# Cross seats remain genuine separately shaded timber geometry.
	for z in [-1.7,0.,1.7]:
		var box:=BoxMesh.new();box.size=Vector3(1.85,.10,.30)
		var arrays: Array=box.surface_get_arrays(0)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		for i in range(vertices.size()): vertices[i]+=Vector3(0,.43,z)
		arrays[Mesh.ARRAY_VERTEX]=vertices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		mesh.surface_set_material(mesh.get_surface_count()-1,wood)
	return mesh


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
		var indices:=PackedInt32Array()
		if arrays[Mesh.ARRAY_INDEX] is PackedInt32Array:
			indices=arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			for j in range(vertices.size()): indices.append(j)
		var seen: Dictionary={}
		for index in indices:
			if index<0 or index>=vertices.size():
				error="Native city mesh has invalid actual draw index."
				return {}
			if seen.has(index): continue
			seen[index]=true
			var p: Vector3=basis*vertices[index]
			minimum=minimum.min(p)
			maximum=maximum.max(p)
			points.append(p)
	if points.is_empty():
		error="Native city mesh has no actual drawn vertices."
		return {}
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
	if bounds.is_empty(): return false
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
	if kind in ["wall_horizontal","wall_vertical"]:
		for index in range(mesh.get_surface_count()):
			var masonry: ShaderMaterial=mesh.surface_get_material(index) as ShaderMaterial
			if masonry==null:
				error="Joining-wall material missing; reject fallback box capture."
				return false
			var declared: Array[String]=[]
			for uniform: Dictionary in masonry.shader.get_shader_uniform_list(): declared.append(String(uniform["name"]))
			for channel: String in ["original_stone","registered_normal","registered_arm","masonry_tint"]:
				if not channel in declared:
					error="Actual joining-wall shader failed reflection: "+channel
					return false
			if masonry.get_shader_parameter("original_stone")!=surface.textures["stone"] or masonry.get_shader_parameter("registered_normal")!=surface.textures["nor_gl"] or masonry.get_shader_parameter("registered_arm")!=surface.textures["arm"]:
				error="Actual joining-wall sampler binding mismatch."
				return false
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
	var record: Dictionary={"kind":kind,"texture":path,"metadata_path":prefix+".json","source_size_px":[image.get_width(),image.get_height()],"render_size_px":[image.get_width(),image.get_height()],"foot_uv":[foot.x/image.get_width(),foot.y/image.get_height()],"sourcebody_raw":prefix+"_raw.png","sourcebody_raw_repeat":prefix+"_raw_repeat.png","raw_camera":_camera_data(camera,view.size,Vector2i(768,768)),"crop_rect_px":[crop.position.x,crop.position.y,crop.size.x,crop.size.y],"native_mesh_path":prefix+".res","draw_basis_columns":[_v3(basis.x),_v3(basis.y),_v3(basis.z)],"support_m":_v3(support),"used_bounds_m":{"minimum":_v3(bounds["minimum"]),"maximum":_v3(bounds["maximum"])},"actual_used_vertices":bounds["actual_used_vertices"],"scale":scale,"alpha_resampling_algorithm":"RGBAF_PREMULTIPLIED_LANCZOS_UNPREMULTIPLY_V1","repeat_byte_exact":true,"source":"CC0 TreeSmall02 registered hybrid unchanged draw arrays" if kind=="tree" else "project original native box geometry with wood grain or stone material; NOT CC0 modeled asset","source_min_vertex_ground_delta_m":Vector3(bounds["minimum"]).y-support.y,"sourcebody_and_ground_caster_same_mesh_material_basis_support":true}
	if not _json(prefix+".json",record): return false
	prototypes[kind]={"mesh":mesh,"basis":basis,"support":support,"image":image,"record":record}
	view.queue_free()
	view=null
	await _sync()
	return true

func _paving_mesh() -> ArrayMesh:
	# Single native paving layer: real octagonal chipped slabs, varied open joints,
	# broad edge grime and narrow bevels. NO second procedural brick-grid shader.
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var random:=RandomNumberGenerator.new()
	random.seed=31722003
	var z: float=-32.
	var row: int=0
	while z<32.:
		var screen_y: float=z*SOURCE.ZPPM+1024.
		var row_height: float=random.randf_range(.76,1.08)
		var x: float=-24.-(.34 if row%2 else 0.)
		while x<24.:
			var center:=Vector2((x+.48)*SOURCE.PPM+1536.,screen_y+row_height*SOURCE.ZPPM*.5)
			var zone: String=source.ground_zone(center)
			if source.region=="ch4_s2_canal_docks" and x*SOURCE.PPM+1536.>=2230.:
				x+=1.0
				continue
			var width: float=random.randf_range(1.02,1.42) if zone=="main_street" else (random.randf_range(.76,1.06) if zone=="shop_apron" else random.randf_range(.52,.91))
			var joint: float=random.randf_range(.012,.018) if zone=="main_street" else random.randf_range(.018,.028)
			var x1: float=maxf(x+joint*.5,-24.)
			var x2: float=minf(x+width-joint*.5,24.)
			if source.region=="ch4_s2_canal_docks": x2=minf(x2,(2230.-1536.)/SOURCE.PPM)
			var z1: float=z+joint*.5
			var z2: float=minf(z+row_height-joint*.5,32.)
			var apron: bool=zone=="shop_apron" or zone=="public_square"
			# Continuous laid paving in every zone. Individual random holes were a
			# visual defect, not a credible street shoulder. Surface weathering now
			# transitions only along the continuous outer boundary band.
			if x2>x1 and z2>z1:
				var clip: float=random.randf_range(.013,.044)
				var outline: Array[Vector2]=[
					Vector2(x1+clip,z1),Vector2(x2-clip,z1),Vector2(x2,z1+clip),
					Vector2(x2,z2-clip),Vector2(x2-clip,z2),Vector2(x1+clip,z2),
					Vector2(x1,z2-clip),Vector2(x1,z1+clip)]
				var center3:=Vector3((x1+x2)*.5,.009,(z1+z2)*.5)
				var tone: float=random.randf_range(.95,1.02)
				var zone_value: float=0. if zone=="main_street" else (.20 if zone=="public_square" else (.40 if apron else (.66 if zone=="public_loop" else 1.)))
				var uv_offset:=Vector2(random.randf_range(-5.,5.),random.randf_range(-5.,5.))
				for i in range(outline.size()):
					var a2: Vector2=outline[i]
					var b2: Vector2=outline[(i+1)%outline.size()]
					var ia2: Vector2=a2.lerp(Vector2(center3.x,center3.z),.055)
					var ib2: Vector2=b2.lerp(Vector2(center3.x,center3.z),.055)
					var a:=Vector3(a2.x,.002,a2.y)
					var b:=Vector3(b2.x,.002,b2.y)
					var ia:=Vector3(ia2.x,.009,ia2.y)
					var ib:=Vector3(ib2.x,.009,ib2.y)
					# Native clockwise top faces. Edge band colour supplies real dirt
					# position; it is not a baked fake shadow around an alpha canvas.
					_stone_triangle(tool,center3,ib,ia,tone,zone_value,uv_offset)
					_stone_triangle(tool,ia,ib,b,tone*.94,zone_value,uv_offset)
					_stone_triangle(tool,ia,b,a,tone*.94,zone_value,uv_offset)
			x+=width
		z+=row_height
		row+=1
	tool.generate_tangents()
	return tool.commit()

func _stone_triangle(tool: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,tone: float,zone: float,uv_offset: Vector2) -> void:
	var normal: Vector3=(b-a).cross(c-a).normalized()
	# Godot clockwise front winding has mathematical negative cross for an UP face.
	if normal.y>0.:
		var old_b: Vector3=b
		b=c
		c=old_b
		normal=(b-a).cross(c-a).normalized()
	if normal.y<0.: normal=-normal
	for p in [a,b,c]:
		tool.set_normal(normal)
		var logical_p:=Vector2(p.x*SOURCE.PPM+1536.,p.z*SOURCE.ZPPM+1024.)
		var contact: float=source.floor_contact_strength(logical_p)
		var actual_tone: float=tone*lerpf(1.,.86,contact)
		tool.set_color(Color(actual_tone,actual_tone,actual_tone,zone))
		tool.set_uv(Vector2(p.x,p.z)/2.+uv_offset)
		tool.add_vertex(p)

func _capture_city() -> bool:
	view=_viewport(SOURCE.SIZE*SSAA,false)
	var world:=_world(view,false)
	var floor:=MeshInstance3D.new()
	var base: ArrayMesh=_support_mesh(false)
	floor.mesh=base
	var material: ShaderMaterial=surface.paving()
	floor.material_override=surface.shoulder() # compacted verge and actual dark joints
	floor.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(floor)
	var paving:=MeshInstance3D.new()
	paving.mesh=_paving_mesh()
	paving.material_override=material
	paving.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(paving)
	var water_material: ShaderMaterial=null
	if source.region=="ch4_s2_canal_docks":
		var bed:=MeshInstance3D.new()
		bed.mesh=_support_mesh(true)
		bed.material_override=SURFACE.plain(Color(.20,.215,.19))
		bed.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(bed)
		var water:=MeshInstance3D.new()
		var water_plane:=PlaneMesh.new()
		water_plane.size=Vector2((SOURCE.SIZE.x-2230.)/SOURCE.PPM,64.)
		water.mesh=water_plane
		water.position=SOURCE.point3(Vector2((2230.+SOURCE.SIZE.x)*.5,1024),-.025)
		water_material=surface.canal_water()
		water.material_override=water_material
		water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(water)
		var quay:=MeshInstance3D.new()
		quay.mesh=_quay_wall_mesh()
		quay.material_override=SURFACE.plain(Color(.31,.325,.315))
		quay.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(quay)
		if ResourceSaver.save(bed.mesh,OUT+"canal_bed_mesh.res")!=OK or ResourceSaver.save(water_plane,OUT+"water_plane.res")!=OK or ResourceSaver.save(quay.mesh,OUT+"quay_wall_mesh.res")!=OK: return false
	if ResourceSaver.save(paving.mesh,OUT+"paving_mesh.res")!=OK or ResourceSaver.save(base,OUT+"support_plane.res")!=OK: return false
	# Low broken storefront stone edging, not two debug kerbs extending the full street.
	var grey: Material=SURFACE.plain(Color(.30,.32,.325))
	for object in source.objects:
		if not object["id"] in ["inn","shop"]: continue
		for polygon in object["solid_polygons_px"]:
			var left: float=INF
			var right: float=-INF
			var front: float=-INF
			for p in polygon:
				left=minf(left,p[0])
				right=maxf(right,p[0])
				front=maxf(front,p[1])
			# Leave the explicit door front clear; strips are low visual floor only.
			var door_x: float=object["world_foot_px"][0]
			for limits in [[left,door_x-55.],[door_x+55.,right]]:
				var width: float=float(limits[1])-float(limits[0])
				if width>20.: _box(Vector3(width/SOURCE.PPM,.016,.15),SOURCE.point3(Vector2((float(limits[0])+float(limits[1]))*.5,front+2.),.004),grey,world)
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
		object["source_attribution"]="PolyHaven CC0 TreeSmall02 actual hybrid indices" if object["prototype"]=="tree" else "Project-native geometry authored in bound builder, NOT CC0. Own transparent body and same-pose caster."
	await _sync()
	var uniforms: Array[String]=[]
	for value in material.shader.get_shader_uniform_list(): uniforms.append(String(value["name"]))
	if not "native_flagstone_identity" in uniforms or not "rock_normal" in uniforms or not "stone_albedo" in uniforms:
		error="Actual paving shader reflection failed; no fallback default capture."
		return false
	var water_uniforms: Array[String]=[]
	if water_material!=null:
		for value in water_material.shader.get_shader_uniform_list(): water_uniforms.append(String(value["name"]))
		if not "native_canal_water_identity" in water_uniforms:
			error="Actual canal water compile/reflection failed; no fallback material capture."
			return false
	var bound_stone: Texture2D=material.get_shader_parameter("stone_albedo") as Texture2D
	var shoulder_stone: Texture2D=(floor.material_override as ShaderMaterial).get_shader_parameter("stone_albedo") as Texture2D
	if bound_stone==null or bound_stone!=surface.textures["stone"] or shoulder_stone!=bound_stone or bound_stone.get_size()!=Vector2(1254,1254):
		error="Generated stone sampler is declared but not bound to the measured actual texture."
		return false
	var bound_image: Image=bound_stone.get_image()
	if bound_image==null or bound_image.get_size()!=Vector2i(1254,1254) or not bound_image.has_mipmaps():
		error="Actual bound stone texture readback/mip evidence missing."
		return false
	var hash_context:=HashingContext.new()
	if hash_context.start(HashingContext.HASH_SHA256)!=OK or hash_context.update(bound_image.get_data())!=OK: return false
	var binding_evidence: Dictionary={"passed":true,"reflected_uniforms":uniforms,"canal_water_reflected_uniforms":water_uniforms,"stone_albedo_source":SURFACE.STONE,"stone_albedo_original_sha256":SURFACE.STONE_SHA,"actual_sampler_equals_loaded_image_texture":bound_stone==surface.textures["stone"],"shoulder_sampler_same_source":shoulder_stone==bound_stone,"actual_size_px":[bound_image.get_width(),bound_image.get_height()],"actual_format":bound_image.get_format(),"actual_mip_count":bound_image.get_mipmap_count(),"bound_image_data_including_mips_sha256":hash_context.finish().hex_encode(),"stone_albedo_used_in_fragment":"stone=texture(stone_albedo,UV).rgb; stone_share=.96 in every zone; finish uses continuous local-X avenue and low-frequency patina, NOT whole-slab zone palettes; ALBEDO=mix(surface,perimeter grit,shoulder*.22)*COLOR.rgb*native_flagstone_identity","scope":"actual reflected and bound texture; generated original ALBEDO plus project-authored wear treatments, not matching scanned PBR"}
	if not _json(OUT+"material_binding.json",binding_evidence): return false
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
	var authority_camera: Dictionary=_camera_data(camera,view.size,SOURCE.SIZE)
	if not _json(OUT+"authority_camera.json",authority_camera): return false
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
	for y in range(257):
		for x in range(385): values[y*385+x]=source.source_height(Vector2(x*8,y*8))
	rf.store_buffer(values.to_byte_array())
	rf.flush()
	var rf_error: int=rf.get_error()
	rf.close()
	if rf_error!=OK: return false
	# Source body sprites never enter floor.png. Preview is explicit independent layers.
	var review: Image=logical.duplicate() as Image
	var sorted: Array=source.objects.duplicate()
	sorted.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		var az: int=int(a.get("z_index",0))
		var bz: int=int(b.get("z_index",0))
		return az<bz if az!=bz else a["depth_foot_y"]<b["depth_foot_y"])
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
	data["authority_camera"]=authority_camera
	data["source_forecast"]=source.forecast()
	data["navigation_recipe"]="Actual native dry support mesh direct logical readback; final walk exact world-pixel semantic solids bounded raster and 24px canvas guard; water is absent from land/raw_walk, no normalized growth or alpha-shadow inference"
	data["height_grid"]={"size":[385,257],"step_px":8,"format":"Float32 little-endian RF","height_m":0.,"canal_bed_height_m":-.55 if source.region=="ch4_s2_canal_docks" else 0.,"canal_vertical_quay_boundary_world_px":2230 if source.region=="ch4_s2_canal_docks" else -1,"height_domain":"Flat constructed dry platform Y0, separate negative canal bottom with vertical masonry quay; RF values sampled from same explicit domains, not a natural slope interpolation across the wall","low_paving_geometry_m":[.002,.009],"native_joint_width_m":[.009,.023],"collision_support":"actual dry ArrayMesh and independent body polygons; no water floor white paint or atlas shadows"}
	data["ground_design"]={"zones":["main_street","public_square","shop_apron","public_loop","outer_shoulder"],"source_texture_role":"original builtin-generated worn limestone ALBEDO; NOT CC0 or scanned PBR","native_flagstones":"continuous octagonal chipped polygons, real open variable joints, .055 proportional bevel with .94 edge-tone factor","roughness":"main-axis polish separated from outer rough flags; independently licensed rock ARM/normal microdetail only","slab_width_m":[.52,1.42],"main_axis_slab_width_m":[1.02,1.42],"shop_apron_slab_width_m":[.76,1.06],"native_joint_width_m":[.012,.028],"regional_surface_treatments":"Actual broad avenue flags, warm shop apron and reserved court finishes plus continuously dustier outer flags, same original stone albedo; not falsely advertised as distinct material scans","row_height_m":[.76,1.08],"outer_flag_omission_probability":0.,"outer_shoulder_transition":"continuous native-local boundary band 1..6m, no per-stone missing blocks or checker mask","new_district_route_controls_and_actor_stations_authored":true,"original_source_ids_actions_and_flag_gates_owned_by_system":true,"low_storefront_stone_edges_role":"visual_floor_contact; not independent solid/ghost or generated-building cast"}
	data["ground_design"]["regional_surface_treatments"]="Continuous local-X avenue finish and low-frequency patina over .96 original stone share everywhere; authored slab widths/joints and roughness distinguish zones without brown/blue whole-slab colour blocks. Same original ALBEDO, not distinct material scans."
	data["ground_design"]["joining_wall_material"]="Original generated limestone colour with independently registered rock normal/ARM microdetail; project-authored shader on actual brick-row geometry, NOT a licensed modeled wall kit."
	data["ground_design"]["generated_foot_contact_recipe"]="native vertex dirt factor 1..0.86 within 14 logical pixels of actual semantic front edges only; NOT generated-architecture cast shadow, no alpha canvas decal, no native tree double shadow"
	data["native_material_sources"]=surface.evidence
	data["material_binding_evidence"]=binding_evidence
	data["shadow_evidence"]={"on_path":OUT+"ground_on_raw.png","off_path":OUT+"ground_off_raw.png","on_repeat_path":OUT+"ground_on_raw_repeat.png","off_repeat_path":OUT+"ground_off_raw_repeat.png","method":"same native mesh/material/basis/transform OFF vs SHADOWS_ONLY; body never baked into ground; no tree shadow drawn over runtime architecture","byte_exact_repeats":true,"logical_ssaa":2}
	data["limitations"]=["Independent human-scale candidate only; not production city or gameplay adoption.","Generated architecture is legacy baked daylight, not claimed to be relit by the native sun.","Original architecture weak-alpha noise is preserved; native and review resizing uses alpha-aware reconstruction without thresholding.","Semantic building footprints are authored from actual masonry/steps, not every opaque roof pixel.","Actual Field rectangle stop/bypass, current-frame local ghost and all source action identities await system/QA."]
	var catalog: Dictionary=_source_graph()
	for entry in surface.evidence:
		catalog[entry["path"]]=entry["sha256"]
		catalog[entry["source_path"]]=entry["source_sha256"]
	for object in source.objects:
		catalog[object["texture"]]=FileAccess.get_sha256(object["texture"])
		catalog[object["source"]]=FileAccess.get_sha256(object["source"])
		if object.has("original_source"): catalog[object["original_source"]]=FileAccess.get_sha256(object["original_source"])
	for path: String in [SOURCE.GENERATION,SOURCE.REUSED_AUTHORING,SOURCE.RAW+"module_semantics.json",SOURCE.RAW+"reused_city_prop_provenance.json"]: catalog[path]=FileAccess.get_sha256(path)
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
	for name: String in ["floor.png","land.png","raw_walk.png","walk.png","terrain_height.rf","paving_mesh.res","support_plane.res","capture_camera.json","authority_camera.json","architecture_measurements.json","material_binding.json","review_scene.png","ground_on_raw.png","ground_on_raw_repeat.png","ground_off_raw.png","ground_off_raw_repeat.png"]: catalog[OUT+name]=FileAccess.get_sha256(OUT+name)
	if source.region=="ch4_s2_canal_docks":
		for name: String in ["canal_bed_mesh.res","water_plane.res","quay_wall_mesh.res"]: catalog[OUT+name]=FileAccess.get_sha256(OUT+name)
	data["asset_sha256"]=catalog
	data["capture_graph"]={"source_script":{"path":"res://scripts/dev/luoyang_modular_v3_source.gd","sha256":catalog["res://scripts/dev/luoyang_modular_v3_source.gd"]},"surface_script":{"path":"res://scripts/dev/luoyang_modular_v3_surface.gd","sha256":catalog["res://scripts/dev/luoyang_modular_v3_surface.gd"]},"builder_script":{"path":get_script().resource_path,"sha256":catalog[get_script().resource_path]},"camera_contract":{"path":OUT+"capture_camera.json","sha256":catalog[OUT+"capture_camera.json"]},"height_rf":{"path":OUT+"terrain_height.rf","sha256":catalog[OUT+"terrain_height.rf"]},"native_support_mesh":{"path":OUT+"support_plane.res","sha256":catalog[OUT+"support_plane.res"]},"paving_mesh":{"path":OUT+"paving_mesh.res","sha256":catalog[OUT+"paving_mesh.res"]}}
	data["capture_graph"]["authority_camera_contract"]={"path":OUT+"authority_camera.json","sha256":catalog[OUT+"authority_camera.json"]}
	if source.region=="ch4_s2_canal_docks":
		for role: String in ["canal_bed_mesh","water_plane","quay_wall_mesh"]: data["capture_graph"][role]={"path":OUT+role+".res","sha256":catalog[OUT+role+".res"]}
	if not data["source_forecast"]["passed"]: return false
	return _json(OUT+"art_contract.json",data) and _json(AUDIT+source.region+"_capture_result.json",{"status":"ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA","scene_id":source.region,"source_graph":_source_graph(),"objects":source.objects.size(),"review_image":OUT+"review_scene.png","raw_repeat_exact":true,"production_approved":false})

func _viewport(size: Vector2i,transparent: bool) -> SubViewport:
	var viewport:=SubViewport.new()
	viewport.size=size
	viewport.own_world_3d=true
	viewport.transparent_bg=transparent
	viewport.msaa_3d=Viewport.MSAA_DISABLED
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	return viewport

func _support_mesh(wet: bool) -> ArrayMesh:
	var x0: float=2230. if wet else 0.
	var x1: float=float(SOURCE.SIZE.x) if wet or source.region!="ch4_s2_canal_docks" else 2230.
	var height: float=-.55 if wet else 0.
	var positions:=PackedVector3Array()
	for p in [Vector2(x0,0),Vector2(x1,0),Vector2(x0,SOURCE.SIZE.y),Vector2(x1,SOURCE.SIZE.y)]: positions.append(SOURCE.point3(p,height))
	var arrays: Array=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=positions
	arrays[Mesh.ARRAY_NORMAL]=PackedVector3Array([Vector3.UP,Vector3.UP,Vector3.UP,Vector3.UP])
	arrays[Mesh.ARRAY_TEX_UV]=PackedVector2Array([Vector2.ZERO,Vector2.RIGHT,Vector2.DOWN,Vector2.ONE])
	arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2,1,3,2])
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func _quay_wall_mesh() -> ArrayMesh:
	# A genuine vertical constructed shore, not a fake interpolated natural bank.
	# This visual mesh is absent from the support authority/nav captures.
	var arrays: Array=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=PackedVector3Array([SOURCE.point3(Vector2(2230,0),0.),SOURCE.point3(Vector2(2230,SOURCE.SIZE.y),0.),SOURCE.point3(Vector2(2230,0),-.55),SOURCE.point3(Vector2(2230,SOURCE.SIZE.y),-.55)])
	arrays[Mesh.ARRAY_NORMAL]=PackedVector3Array([Vector3.LEFT,Vector3.LEFT,Vector3.LEFT,Vector3.LEFT])
	arrays[Mesh.ARRAY_TEX_UV]=PackedVector2Array([Vector2.ZERO,Vector2.RIGHT,Vector2.DOWN,Vector2.ONE])
	arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2,1,3,2])
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

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
	return {"projection":camera.projection,"orthographic_size_m":camera.size,"position_m":_v3(camera.position),"basis_columns":[_v3(camera.basis.x),_v3(camera.basis.y),_v3(camera.basis.z)],"raw_canvas_px":[raw.x,raw.y],"logical_canvas_px":[logical.x,logical.y],"raw_to_logical_factor":float(raw.y)/logical.y,"logical_pixels_per_world_m_x":SOURCE.PPM,"logical_pixels_per_world_m_ground_z":SOURCE.ZPPM,"physical_world_size_m":[SOURCE.SIZE.x/SOURCE.PPM,SOURCE.SIZE.y/SOURCE.ZPPM],"camera_elevation_degrees":30.,"near":camera.near,"far":camera.far,"ambient_energy":.45,"sun_energy":.85,"sun_euler_degrees":[-55,-34,0],"shadow_max_m":120.,"msaa":0,"ordinary_actor_effective_height_px":113.5134}

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
		_json(AUDIT+String(source.region if source!=null else "unknown")+"_failed.json",{"status":"TECHNICAL_FAIL","reason":error,"production_approved":false})
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
