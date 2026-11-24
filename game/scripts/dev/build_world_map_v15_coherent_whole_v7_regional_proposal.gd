extends "res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd"

## NEW bounded regional mechanism pilot. Never invokes parent FULL _run,
## never writes any art/source JSON root; not 64/112 or Field/visual approval.
const REGIONAL_ROOT := "res://build/world_map_v15_coherent_whole_v7_regional/"
const REGIONAL_CASES := [
 {"id":"northeastern_forest","rect":Rect2i(9460,1690,1536,1024)},
 {"id":"southern_bamboo","rect":Rect2i(2450,6370,1536,1024)},
 {"id":"wet_bank","rect":Rect2i(9870,5840,1536,1024)},
 {"id":"bianzhou_bridge_end","rect":Rect2i(6960,1820,1536,1024)}
]
var regional_regions: Array[Dictionary]=[]

func _pilot_finish(passed: bool) -> void:
	if not passed:
		pilot_result["status"] = "V7_REGIONAL_OR_SOURCE_FORECAST_REFUSED_OR_TECHNICAL_FAIL"
		pilot_result["reason"] = error
	if not pilot_output.is_empty():
		if not _write_json(pilot_output + "result.json", pilot_result): passed = false
	await _pilot_release_world()
	v7_walk_cache.clear()
	v7_plane_prototypes.clear()
	pilot_transport = null
	pilot_global_mesh = null
	pilot_support_mesh = null
	pilot_shader = null
	print("COHERENT_WHOLE_V7_REGIONAL_RESULT ", pilot_output, " passed=", passed)
	await _finish(passed)

func _run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	pilot_output=REGIONAL_ROOT+"%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	failure_output=pilot_output
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pilot_output))
	if "--coherent-whole-v7-source-plan" in args:
		await _regional_source_plan(args)
		return
	if "--coherent-whole-v7-regional" not in args or "--coherent-whole-v7-full" in args or DisplayServer.get_name()=="headless":
		error="NEW regional GPU-only opt-in; default/headless/FULL refused."
		await _pilot_finish(false)
		return
	var auth_path: String=""
	for arg: String in args:
		if arg.begins_with("--authorization="): auth_path=arg.trim_prefix("--authorization=")
	if not _pilot_authorized(auth_path):
		await _pilot_finish(false)
		return
	v7_regional=true
	v7_art_root=pilot_output+"evidence/"
	for folder: String in ["","entities/","prototypes/","capture/"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(v7_art_root+folder))
	pilot_result={"schema_version":1,"coordinate_version":15,"capture_protocol":"V7_BOUNDED_FRESH_REGIONAL_NATIVE_CAMERA_V1","scope":V7_REGIONAL_SCOPE,"status":"BUILD_IN_PROGRESS","production_approved":false,"visual_approved":false,"whole_CPU_Image_allowed":false,"whole_GPU_allocation_requested":false,"cached_inputs_sha256":pilot_inputs,"executed_builder":{"path":get_script().resource_path,"sha256":FileAccess.get_sha256(get_script().resource_path)},"authorization":{"path":auth_path,"sha256":FileAccess.get_sha256(auth_path)},"regions":[]}
	pilot_memory_history=_pilot_square_history()
	if not bool(pilot_memory_history.get("valid",false)) or not _load_pilot_inputs() or not _full_prepare_semantics() or not _full_export_compounds():
		await _pilot_finish(false)
		return
	if not _regional_materialize_native_instances() or not _v7_measure_coverage() or not await _full_export_structures():
		await _pilot_finish(false)
		return
	for spec: Dictionary in REGIONAL_CASES:
		v7_region_rect=spec["rect"]
		var case: Dictionary={"id":spec["id"],"logical_rect_px":_recti(v7_region_rect),"worlds":{},"comparisons":{}}
		for identity: String in ["primary","reference"]:
			var actual: Dictionary=await _pilot_capture_world(String(spec["id"])+"_"+identity)
			if actual.is_empty():
				pilot_result["failed_region"]=case
				await _pilot_finish(false)
				return
			case["worlds"][identity]=actual
		var primary: Dictionary=case["worlds"]["primary"]
		var reference: Dictionary=case["worlds"]["reference"]
		for role: String in ROLE_NAMES:
			var first: Dictionary=primary["roles"][role]["windows"]["region"]
			var second: Dictionary=reference["roles"][role]["windows"]["region"]
			var raw: Dictionary=_pilot_compare_pngs(first["raw_path"],second["raw_path"])
			var logical: Dictionary=_pilot_compare_pngs(first["path"],second["path"])
			case["comparisons"][role]={"raw":raw,"logical":logical}
			if not bool(raw["byte_exact"]) or not bool(logical["byte_exact"]):
				error="Regional two genuinely independent worlds differ exactly."
				pilot_result["failed_region"]=case
				await _pilot_finish(false)
				return
		var on: Image=Image.load_from_file(primary["roles"]["visual"]["windows"]["region"]["path"])
		var off: Image=Image.load_from_file(primary["roles"]["shadow_off"]["windows"]["region"]["path"])
		var shadow: Dictionary=_full_ground_evidence(String(spec["id"]),Rect2(v7_region_rect),on,off,pilot_output)
		if shadow.is_empty() or int(shadow.get("outside_sourcebody_pixels",0))<=0:
			error="Bounded actual regional outside-body shadow empty; no claim from stem count."
			pilot_result["failed_region"]=case
			await _pilot_finish(false)
			return
		case["actual_shadow_evidence"]=shadow
		case["independent_body_scene"]=_regional_composite(primary)
		if case["independent_body_scene"].is_empty():
			await _pilot_finish(false)
			return
		if spec["id"]=="bianzhou_bridge_end":
			case["actual_full17_approach"]=_regional_approach_audit(primary)
			if not bool(case["actual_full17_approach"]["passed"]):
				error="Actual regional projected Bianzhou path intersects native black PNG/real solid."
				pilot_result["failed_region"]=case
				await _pilot_finish(false)
				return
		regional_regions.append(case)
	for path: String in pilot_inputs:
		if FileAccess.get_sha256(path).to_lower()!=String(pilot_inputs[path]).to_lower():
			error="Source changed during regional pilot: "+path
			await _pilot_finish(false)
			return
	pilot_result["regions"]=regional_regions
	pilot_result["input_hashes_unchanged_after"]=true
	pilot_result["alpha_union"]=v7_alpha_union
	pilot_result["actual_inverse_RF_approach"]=v7_approach_inverse
	pilot_result["status"]="REGIONAL_TECHNICAL_PASS_NOT_FULL_OR_FIELD"
	await _pilot_finish(true)

func _pilot_windows() -> Array[Dictionary]:
	return [{"id":"region","rect":v7_region_rect,"scope":"BOUNDED_REGIONAL_NOT_WHOLE_ROI_OR_SEAM"}]

func _pilot_set_role(role: String) -> bool:
	var visual: bool = role == "visual" or role == "shadow_off"
	active_view.size = v7_region_rect.size * (SSAA if visual else 1)
	pilot_water.visible = visual
	pilot_support.visible = role == "walk"
	for caster: MeshInstance3D in pilot_casters:
		caster.visible = role == "visual"
		caster.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	if not visual:
		pilot_environment.environment.background_mode = Environment.BG_COLOR
		pilot_environment.environment.background_color = Color(0, 0, 0, 1)
	for i in pilot_receivers.size():
		var node: MeshInstance3D = pilot_receivers[i]
		# Separate guard is exclusively visual; never authority or support.
		node.visible = visual or i == 0
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if visual else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if not visual: node.material_override = _full_authority(0 if role == "land" else 1)
	var material: ShaderMaterial = pilot_receivers[0].material_override as ShaderMaterial
	if visual and (not _shader_gate(material, ["biome_weights", "road_weights", "grass_ground_diff", "rock_01_arm"]) or not _shader_gate(pilot_water.material_override, ["actual_height_rf", "grid_origin", "grid_shape"])):
		error = "Actual global material binding rejected."
		return false
	return true


func _regional_source_plan(args: PackedStringArray) -> void:
	var auth_path: String=""
	for arg: String in args:
		if arg.begins_with("--authorization="): auth_path=arg.trim_prefix("--authorization=")
	if not _pilot_authorized(auth_path):
		await _pilot_finish(false)
		return
	v7_regional=true
	v7_art_root=pilot_output+"evidence/"
	for folder: String in ["","entities/","prototypes/","capture/"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(v7_art_root+folder))
	pilot_result={"schema_version":1,"scope":"V7_SOURCE_FORECAST_NOT_NAV_FIELD_OR_GPU","status":"BUILD_IN_PROGRESS","cached_inputs_sha256":pilot_inputs,"production_approved":false,"visual_approved":false,"GPU_framebuffers_allocated":false,"executed_builder":{"path":get_script().resource_path,"sha256":FileAccess.get_sha256(get_script().resource_path)}}
	if not _load_pilot_inputs() or not _full_prepare_semantics() or not _full_export_compounds() or not _regional_materialize_native_instances() or not _v7_measure_coverage():
		await _pilot_finish(false)
		return
	# Exact current native bridge authoring, CPU drawn-vertex footprint only.
	# No old v6 nav JSON, no fake native frame or actual Physics credit.
	var holder:=Node3D.new()
	root.add_child(holder)
	_add_bridge_geometry(holder,Rect2(Vector2.ZERO,Vector2(SOURCE.SIZE)))
	for bridge: Node3D in holder.get_children():
		for child: Node3D in bridge.get_children():
			if not child is MeshInstance3D or child.get_meta("runtime_role","") not in ["bridge_post","bridge_rail"]: continue
			var vertices: PackedVector3Array=_full_part_vertices(child)
			var projected:=PackedVector2Array()
			for vertex: Vector3 in vertices: projected.append(Vector2(vertex.x*SOURCE.PPM+SOURCE.SIZE.x*.5,vertex.z*SOURCE.Z_PPM+SOURCE.SIZE.y*.5))
			var hull: PackedVector2Array=Geometry2D.convex_hull(projected)
			if hull.size()<3:
				error="Degenerate actual CPU bridge draw hull."
				holder.free()
				await _pilot_finish(false)
				return
			full_objects.append({"id":String(bridge.get_meta("structure_id"))+"_"+String(child.get_meta("runtime_role"))+"_"+str(child.get_index()),"blocking":true,"solid_polygons_px":[_v7_pairs(hull)],"scope":"CPU current native fullXZ geometry, NOT v7 captured PNG"})
	holder.free()
	var failures: Array=[]
	var centers:=0
	for route: Dictionary in source.routes:
		var points: PackedVector2Array=route["points"]
		for segment in range(points.size()-1):
			var a: Vector2=points[segment]
			var b: Vector2=points[segment+1]
			var steps: int=maxi(1,ceili(a.distance_to(b)/4.))
			for n in range(steps+1):
				var src: Vector2=a.lerp(b,float(n)/steps)
				var world: Vector2=source.project_source(src)
				for structure: Dictionary in source.structures:
					if Geometry2D.is_point_in_polygon(src,structure["source_deck_polygon"]): world=src
				centers+=1
				for offset: Vector2 in source.foot_offsets():
					if not source.supported_walk(src+offset) or not _regional_solids_clear(world+offset):
						if failures.size()<1024: failures.append({"route_id":route["id"],"source_center_px":[src.x,src.y],"world_center_px":[world.x,world.y],"offset_px":[offset.x,offset.y]})
						break
	for portal: Dictionary in full_portals:
		var path: Array=portal["passage_path_px"]
		for segment in range(path.size()-1):
			var a:=Vector2(path[segment][0],path[segment][1])
			var b:=Vector2(path[segment+1][0],path[segment+1][1])
			var steps: int=maxi(1,ceili(a.distance_to(b)/4.))
			for n in range(steps+1):
				var world: Vector2=a.lerp(b,float(n)/steps)
				centers+=1
				for offset: Vector2 in source.foot_offsets():
					var src: Vector2=_v7_inverse_world_point(world+offset)
					if not is_finite(src.x) or not source.supported_walk(src) or not _regional_solids_clear(world+offset):
						if failures.size()<1024: failures.append({"portal_id":portal["id"],"world_center_px":[world.x,world.y],"offset_px":[offset.x,offset.y]})
						break
	pilot_result["route_count"]=source.routes.size()
	pilot_result["portal_count"]=full_portals.size()
	pilot_result["full17_centers"]=centers
	pilot_result["failures"]=failures
	pilot_result["alpha_union"]=v7_alpha_union
	pilot_result["actual_inverse_RF_approach"]=v7_approach_inverse
	pilot_result["caster_proposal"]="NEW actual plane source unexecuted; CPU forecast is never shadow/Field approval"
	pilot_result["status"]="SOURCE_FORECAST_PASS_NOT_NAV_FIELD_OR_GPU" if failures.is_empty() else "SOURCE_FORECAST_FAIL"
	if not failures.is_empty(): error="New full17 source/native-geometry forecast failed; no regional GPU until legitimate correction."
	for path: String in pilot_inputs:
		if FileAccess.get_sha256(path).to_lower()!=String(pilot_inputs[path]).to_lower():
			error="Actual input changed during source forecast."
			await _pilot_finish(false)
			return
	pilot_result["input_hashes_unchanged_after"]=true
	await _pilot_finish(failures.is_empty())

func _regional_solids_clear(point: Vector2) -> bool:
	if not _full_compound_clear(point): return false
	for object: Dictionary in full_objects:
		if not bool(object.get("blocking",false)) or object.has("solid_polygons_px"): continue
		var c: Array=object.get("collision_center_world_px",[])
		var s: Array=object.get("collision_size_px",[])
		if c.size()==2 and s.size()==2 and Rect2(Vector2(c[0],c[1])-Vector2(s[0],s[1])*.5,Vector2(s[0],s[1])).has_point(point): return false
	return true


func _pilot_coverage() -> Dictionary:
	var inverse: Transform3D = pilot_camera.global_transform.affine_inverse()
	var depth_min := INF
	var depth_max := -INF
	var projected_min := Vector2(INF, INF)
	var projected_max := Vector2(-INF, -INF)
	var points := 0
	var projection_error := 0.
	for node: MeshInstance3D in pilot_receivers:
		for s in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(s)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for vertex: Vector3 in vertices:
				var p: Vector3 = node.global_transform * vertex
				var projected: Vector2 = pilot_camera.unproject_position(p) / SSAA
				projected_min = projected_min.min(projected)
				projected_max = projected_max.max(projected)
				var expected := Vector2(p.x * SOURCE.PPM + SOURCE.SIZE.x * .5, p.z * SOURCE.Z_PPM + SOURCE.SIZE.y * .5 - p.y * SOURCE.Z_PPM) - Vector2(v7_region_rect.position)
				projection_error = maxf(projection_error, projected.distance_to(expected))
				var depth: float = -(inverse * p).z
				depth_min = minf(depth_min, depth)
				depth_max = maxf(depth_max, depth)
				points += 1
	var caster_min := INF
	var caster_max := -INF
	var caster_vertices := 0
	var bounds_records: Array = []
	for node: MeshInstance3D in pilot_casters:
		var vertices := PackedVector3Array()
		if node.has_meta("pilot_prototype_key"):
			var proto: Dictionary = native_prototype_cache[String(node.get_meta("pilot_prototype_key"))]
			var actual_bounds: Dictionary = proto["actual_native_bounds"]
			var low: Vector3 = actual_bounds["minimum"]
			var high: Vector3 = actual_bounds["maximum"]
			for x in [low.x, high.x]:
				for y in [low.y, high.y]:
					for z in [low.z, high.z]: vertices.append(node.global_transform * Vector3(x, y, z))
			caster_vertices += int(actual_bounds["unique_draw_vertex_count"])
			bounds_records.append({"prototype": node.get_meta("pilot_prototype_key"), "actual_used_index_bounds_m": [_v3(low), _v3(high)], "unique_draw_vertex_count": actual_bounds["unique_draw_vertex_count"], "coverage_method": "eight conservative AABB corners from actual indices-used original mesh vertices, transformed by actual instance; no expansion of millions of duplicate indices per instance"})
		else:
			vertices = _full_part_vertices(node)
			caster_vertices += vertices.size()
		for point: Vector3 in vertices:
			var depth: float = -(inverse * point).z
			caster_min = minf(caster_min, depth)
			caster_max = maxf(caster_max, depth)
	var covered: bool = projected_min.x <= 0. and projected_min.y <= 0. and projected_max.x >= v7_region_rect.size.x and projected_max.y >= v7_region_rect.size.y
	var valid: bool = points > 0 and caster_vertices > 0 and covered and projection_error <= .01 and depth_min > pilot_camera.near and depth_max < pilot_sun.directional_shadow_max_distance and depth_max < pilot_camera.far and caster_min > pilot_camera.near and caster_max < pilot_camera.far and caster_max < pilot_sun.directional_shadow_max_distance
	return {"passed": valid, "actual_receiver_vertices": points, "actual_receiver_depth_min_m": depth_min, "actual_receiver_depth_max_m": depth_max, "actual_caster_unique_draw_vertices_across_instances": caster_vertices, "actual_caster_depth_min_m": caster_min, "actual_caster_depth_max_m": caster_max, "logical_projection_bounds_px": [projected_min.x, projected_min.y, projected_max.x, projected_max.y], "max_actual_source_projection_error_px": projection_error, "shadow_max_actual_m": pilot_sun.directional_shadow_max_distance, "camera_near_actual": pilot_camera.near, "camera_far_actual": pilot_camera.far, "entire_canvas_covered": covered, "caster_bounds_evidence": bounds_records, "method": "actual saved mesh surface vertices and conservative bounds computed once from actual indices-used caster mesh vertices; actual per-instance transform/camera inverse; no old sixty-meter proof"}


func _pilot_capture_world(identity: String) -> Dictionary:
	var result: Dictionary=await super._pilot_capture_world(identity)
	if result.is_empty(): return result
	result["actual_regional_receiver"]=pilot_result["current_actual_regional_receiver"].duplicate(true)
	result["authoritative_global_mesh"]["scope"]="readonly Float32 source cache only; actual draw is separately saved regional mesh, NOT a whole capture"
	result["scope"]="BOUNDED_FRESH_REGIONAL_WORLD_NOT_WHOLE64_OR_SEAM"
	return result

func _pilot_memory_guard(identity: String) -> bool:
	# Conservative inherited square×6 bound remains, although actual allocation
	# is bounded3072×2048, not a whole402M target. Never lower required budget.
	return super._pilot_memory_guard(identity)

func _pilot_read_roi(item: Dictionary,role: String,directory: String,pass_index: int,draw: Dictionary) -> Dictionary:
	var factor: int=SSAA if role in ["visual","shadow_off"] else 1
	var raw: Image=active_view.get_texture().get_image()
	if raw==null or raw.get_size()!=v7_region_rect.size*factor or raw.get_format()!=Image.FORMAT_RGBA8 or raw.has_mipmaps() or raw.is_compressed() or active_view.render_target_update_mode!=SubViewport.UPDATE_DISABLED or active_view.get_texture().get_rid().get_id()!=draw["texture_rid"]:
		error="Bounded actual regional native RGBA/fenced primary identity invalid."
		return {}
	if raw.get_width()*raw.get_height()>V7_MAX_CPU_ROI_PIXELS:
		error="Regional bounded CPU cap exceeded."
		return {}
	var stats: Dictionary={}
	if factor==1:
		stats=_pilot_binary_stats(raw)
		if not bool(stats["passed"]):
			error="Regional raw binary is not exactly opaque black/white."
			return {}
	elif not _v7_opaque_exact(raw):
		error="Regional raw visual alpha is not exactly255."
		return {}
	var prefix: String=directory+role+"_region_pass"+str(pass_index)
	var raw_path: String=prefix+"_raw.png"
	if raw.save_png(raw_path)!=OK:
		error="Regional actual raw PNG write failed."
		return {}
	var decoded: Image=Image.load_from_file(raw_path)
	if decoded==null or decoded.get_format()!=Image.FORMAT_RGBA8 or decoded.get_data()!=raw.get_data():
		error="Regional raw decodedRGBA differs."
		return {}
	var derived: Image=raw.duplicate() as Image
	if factor>1: derived.resize(v7_region_rect.size.x,v7_region_rect.size.y,Image.INTERPOLATE_LANCZOS)
	if factor>1 and not _v7_opaque_exact(derived):
		error="Regional derived visual alpha is not exactly255."
		return {}
	var path: String=prefix+".png"
	if derived.save_png(path)!=OK: return {}
	return {"path":path,"sha256":FileAccess.get_sha256(path),"raw_path":raw_path,"raw_sha256":FileAccess.get_sha256(raw_path),"raw_RGBA_sha256":_bytes_sha(raw.get_data()),"logical_RGBA_sha256":_bytes_sha(derived.get_data()),"factor":factor,"actual_readback_canvas":_v2i(raw.get_size()),"logical_rect_px":_recti(v7_region_rect),"source_draw":draw,"actual_raw_binary_stats":stats,"resampling_identity":"OPAQUE_RGBA8_LANCZOS_REGIONAL_NATIVE_V1" if factor>1 else "NONE_NATIVE_MSAA0","capture_scope":"direct bounded native framebuffer, NOT whole texelROI/full64/112 proof","gamma_correction":false}

func _regional_materialize_native_instances() -> bool:
	# Actual cached native sourcebody/pose is reused by path, without thousands
	# of redundant image copies in this bounded mechanism test.
	for site: Dictionary in source.vegetation_sites:
		var key: String=String(site["kind"])+str(site["pose"])
		if not native_prototype_cache.has(key):
			error="Missing actual registered prototype/pose."
			return false
		var proto: Dictionary=native_prototype_cache[key]
		var body: Image=proto["image"]
		var foot: Vector2=source.project_source(site["source_foot"])
		var uv:=Vector2(proto["record"]["foot_uv"][0],proto["record"]["foot_uv"][1])
		var center: Vector2=foot-(uv-Vector2(.5,.5))*Vector2(body.get_size())
		var object: Dictionary=site.duplicate(true)
		object.merge({"texture":proto["record"]["texture"],"world_foot_px":[foot.x,foot.y],"foot_uv":[uv.x,uv.y],"render_size_px":[body.get_width(),body.get_height()],"pos":[center.x/SOURCE.SIZE.x,center.y/SOURCE.SIZE.y],"depth_sort_foot_y":foot.y/SOURCE.SIZE.y,"collision_center_world_px":[foot.x,foot.y],"collision_size_px":[site["collision_size_px"].x,site["collision_size_px"].y],"prototype_actual_sourcebody_evidence":proto["record"]},true)
		if site["kind"]=="boulder":
			var bounds: Array=proto["record"]["used_vertex_bounds_m"]
			var support: Vector3=proto["support"]
			var start: Vector2=site["source_foot"]+Vector2((bounds[0][0]-support.x)*SOURCE.PPM,(bounds[0][2]-support.z)*SOURCE.Z_PPM)
			var size:=Vector2((bounds[1][0]-bounds[0][0])*SOURCE.PPM,(bounds[1][2]-bounds[0][2])*SOURCE.Z_PPM)
			object["collision_size_px"]=[size.x,size.y]
			object["collision_center_world_px"]=[start.x+size.x*.5,start.y+size.y*.5-source.triangle_height(site["source_foot"])*SOURCE.Z_PPM]
		full_objects.append(object)
	return true

func _regional_approach_audit(primary: Dictionary) -> Dictionary:
	var nav: Image=Image.load_from_file(primary["roles"]["walk"]["windows"]["region"]["path"])
	var failures: Array=[]
	var centers:=0
	for segment in range(v7_approach_world.size()-1):
		var a: Vector2=v7_approach_world[segment]
		var b: Vector2=v7_approach_world[segment+1]
		var steps: int=maxi(1,ceili(a.distance_to(b)/4.))
		for n in range(steps+1):
			var center: Vector2=a.lerp(b,float(n)/steps)
			centers+=1
			for offset: Vector2 in source.foot_offsets():
				var point: Vector2=center+offset
				var local:=Vector2i(point.round())-v7_region_rect.position
				var nav_clear: bool=nav!=null and local.x>=0 and local.y>=0 and local.x<nav.get_width() and local.y<nav.get_height() and nav.get_pixelv(local)==Color.WHITE
				var solid_clear: bool=_full_compound_clear(point)
				for object: Dictionary in full_objects:
					if not bool(object.get("blocking",false)) or object.has("solid_polygons_px"): continue
					var c: Array=object.get("collision_center_world_px",[])
					var z: Array=object.get("collision_size_px",[])
					if c.size()==2 and z.size()==2 and Rect2(Vector2(c[0],c[1])-Vector2(z[0],z[1])*.5,Vector2(z[0],z[1])).has_point(point): solid_clear=false
				if not nav_clear or not solid_clear: failures.append({"center_px":[center.x,center.y],"shoe_px":[point.x,point.y],"nav_clear":nav_clear,"all_physical_solids_clear":solid_clear})
	return {"passed":failures.is_empty(),"centers":centers,"failures":failures,"scope":"ACTUAL_REGIONAL_NAV17_AND_SOURCE_SOLIDS_NOT_FIELD_PHYSICS","door_unchanged":true,"bridge_solids_unchanged":true,"world_path":_v7_pairs(v7_approach_world)}

func _regional_composite(primary: Dictionary) -> Dictionary:
	var base: Image=Image.load_from_file(primary["roles"]["visual"]["windows"]["region"]["path"])
	if base==null: return {}
	var ordered: Array[Dictionary]=full_objects.duplicate()
	ordered.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		var ga: bool=int(a.get("z_index",0))<0
		var gb: bool=int(b.get("z_index",0))<0
		if ga!=gb: return ga
		return float(a.get("depth_sort_foot_y",0.))<float(b.get("depth_sort_foot_y",0.)))
	for object: Dictionary in ordered:
		var size:=Vector2i(object["render_size_px"][0],object["render_size_px"][1])
		var center:=Vector2(object["pos"][0]*SOURCE.SIZE.x,object["pos"][1]*SOURCE.SIZE.y)
		var origin:=Vector2i((center-Vector2(size)*.5).round())-v7_region_rect.position
		if not Rect2i(origin,size).intersects(Rect2i(Vector2i.ZERO,v7_region_rect.size)): continue
		var body: Image=Image.load_from_file(object["texture"])
		if body==null: return {}
		if body.get_size()!=size: body=_alpha_resize(body,size)
		base.blend_rect(body,Rect2i(Vector2i.ZERO,size),origin)
	var path: String=pilot_output+"scene_"+str(v7_region_rect.position.x)+"_"+str(v7_region_rect.position.y)+".png"
	if base.save_png(path)!=OK: return {}
	return {"path":path,"sha256":FileAccess.get_sha256(path),"scope":"bounded actual regional GPU ground plus independently foot-ordered current-alpha bodies; NOT actual Field"}

func _pilot_authorized(path: String) -> bool:
	if not _v7_source_guard(): return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		error = "Missing explicit root pilot authorization JSON."
		return false
	pilot_auth = parsed
	var required_scope: String="V7_SOURCE_FORECAST_NOT_NAV_FIELD_OR_GPU" if "--coherent-whole-v7-source-plan" in OS.get_cmdline_user_args() else V7_REGIONAL_SCOPE
	if pilot_auth.get("approved", false) != true or pilot_auth.get("scope") != required_scope or pilot_auth.get("builder_path") != get_script().resource_path or String(pilot_auth.get("builder_sha256", "")).to_lower() != FileAccess.get_sha256(get_script().resource_path).to_lower():
		error = "Authorization scope/executed builder SHA mismatch."
		return false
	if pilot_auth.get("allow_full64", true) != false or pilot_auth.get("memory_budget_approved", false) != true:
		error = "Pilot-only/memory authorization not granted; no allocation."
		return false
	if not pilot_auth.get("input_sha256") is Dictionary:
		error = "Pinned cache/input catalog missing."
		return false
	pilot_inputs = pilot_auth["input_sha256"]
	for required: String in [get_script().resource_path, "res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd", V7_PILOT_PATH, FULL_FOOTPRINTS]:
		if pilot_inputs.get(required) != FileAccess.get_sha256(required):
			error = "Executed v7 regional dependency must be in the exact input closure: " + required
			return false
	for required: String in [CACHE_ROOT + "terrain_height.rf", CACHE_ROOT + "terrain_mesh.res", CACHE_ROOT + "source_topology.png", CACHE_ROOT + "capture/terrain_shader.gdshader", CACHE_ROOT + "chunks/r0_c0_actual_deck_support_mesh.res", "res://scripts/dev/world_map_v15_complete_v5_source.gd", "res://scripts/dev/world_map_v15_complete_v5_surface.gd", "res://scripts/dev/world_v15_outskirts_complete_v5_vegetation.gd", "res://scripts/dev/build_world_map_v15_complete_v5_full_draft.gd", TRANSPORT_PATH]:
		if not pilot_inputs.has(required):
			error = "Mandatory frozen input absent: " + required
			return false
	for input_path: String in pilot_inputs:
		if FileAccess.get_sha256(input_path).to_lower() != String(pilot_inputs[input_path]).to_lower():
			error = "Changed frozen input: " + input_path
			return false
	if FileAccess.get_sha256(TRANSPORT_PATH).to_lower() != TRANSPORT_SHA:
		error = "Unapproved transport shader bytes."
		return false
	var proof: Dictionary = pilot_auth.get("transport_proof", {})
	if String(proof.get("path", "")).is_empty() or FileAccess.get_sha256(proof["path"]).to_lower() != String(proof.get("sha256", "")).to_lower():
		error = "Actual StageA/whole transport proof not bound."
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(proof["path"]))
	if not data is Dictionary:
		error = "Actual transport proof JSON invalid."
		return false
	var proof_data: Dictionary = data
	if not bool(proof_data.get("stage_A", {}).get("passed", false)) or not bool(proof_data.get("stage_B", {}).get("passed", false)) or String(proof_data.get("transfer_shader", {}).get("sha256", "")).to_lower() != TRANSPORT_SHA:
		error = "Actual exact StageA and whole native-window proof required; no assumed pass."
		return false
	pilot_proof_gpu_uuid = String(proof_data.get("stage_B", {}).get("baseline", {}).get("gpu_uuid", ""))
	if pilot_proof_gpu_uuid.is_empty() or pilot_proof_gpu_uuid != String(proof_data.get("whole_guard", {}).get("gpu_uuid", "")):
		error = "Actual StageB baseline/guard GPU UUID unavailable or inconsistent."
		return false
	for required: String in V7_SOURCE_PINS:
		if not pilot_inputs.has(required) or String(pilot_inputs[required]).to_lower()!=String(V7_SOURCE_PINS[required]):
			error="Mandatory current v7 input/proof absent: "+required
			return false
	return true
