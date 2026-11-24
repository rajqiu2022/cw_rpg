extends "res://scripts/dev/build_luoyang_modular_v3_grey_tile_roof_revision.gd"

## Isolated material iteration, NOT gameplay adoption or a new city layout.
## Do not call the parent's _run: it resets OUT to the existing candidate.
const DETAIL_ADAPTER := preload("res://scripts/dev/build_luoyang_modular_v3_street_detail_proposal.gd")
const DETAIL_ADAPTER_PATH := "res://scripts/dev/build_luoyang_modular_v3_street_detail_proposal.gd"
const DETAIL_ADAPTER_SHA := "fed19382beb77e9bec1d147dedb70bea548041718b2be372624033b229b1ae11"
const DETAIL_SURFACE_PATH := "res://scripts/dev/luoyang_modular_v3_street_detail_surface_proposal.gd"
const DETAIL_SURFACE_SHA := "5f6a3f901645bdaed5e8a544c617375e2e2e02f5f2730b42d43895cf129c4dfa"
const DETAIL_ART_ROOT := "res://art/maps/luoyang_modular_v3_street_detail_proposal/"
const DETAIL_AUDIT_ROOT := "res://build/luoyang_modular_v3_street_detail_proposal/"
const DETAIL_IDENTITY := "ISOLATED_CONTINUOUS_CITY_STREET_MASONRY_MATERIAL_PROPOSAL_V1"
var detail_adapter: DETAIL_ADAPTER
var detail_audit := ""
var detail_baseline_navigation: Dictionary={}
var detail_wall_comparisons: Dictionary={}
var detail_paving_mesh: ArrayMesh
var detail_dry_mesh: ArrayMesh
var detail_paving_binding: Dictionary={}

func _run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	for required: String in ["--luoyang-v3-street-detail-capture","--luoyang-modular-v3-capture","--luoyang-v3-roof-capture","--luoyang-v3-grey-tile-roof-capture"]:
		if required not in args:
			error="Isolated street detail requires all explicit capture flags; no default export."
			await _roof_refuse()
			return
	if DisplayServer.get_name()=="headless" or "--luoyang-v3-source-plan" in args:
		error="This proposal requires an actual serial GPU capture, not headless or plan-only."
		await _roof_refuse()
		return
	var pins: Dictionary=DETAIL_ADAPTER.PINS.duplicate()
	pins[DETAIL_ADAPTER_PATH]=DETAIL_ADAPTER_SHA
	pins[DETAIL_SURFACE_PATH]=DETAIL_SURFACE_SHA
	pins[ROOF_TRIAL_PATH]=ROOF_TRIAL_SHA
	for path: String in pins:
		if FileAccess.get_sha256(path).to_lower()!=String(pins[path]):
			error="Frozen street-detail dependency changed: "+path
			await _roof_refuse()
			return
	var chosen := "ch4_s0_luoyang_gate"
	var run_tag := ""
	for arg: String in args:
		if arg.begins_with("--city-region="): chosen=arg.trim_prefix("--city-region=")
		if arg.begins_with("--street-detail-run-tag="): run_tag=arg.trim_prefix("--street-detail-run-tag=")
	var tag_rule:=RegEx.new()
	if tag_rule.compile("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$")!=OK or tag_rule.search(run_tag)==null or chosen not in SOURCE.REGIONS:
		error="Explicit safe unique run tag and exact canonical city region required."
		await _roof_refuse()
		return
	OUT=DETAIL_ART_ROOT+run_tag+"/"+chosen+"/"
	detail_audit=DETAIL_AUDIT_ROOT+run_tag+"/"+chosen+"/"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(OUT)) or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(detail_audit)):
		error="Proposal refuses overwrite, including failed output; choose a fresh run tag."
		await _roof_refuse()
		return
	source=SOURCE.new()
	source.prepare(chosen)
	if source.preparation_error!="":
		error=source.preparation_error
		await _roof_refuse()
		return
	# Only the output locator changes, never routes, solids, actors or functions.
	source.region_out=OUT
	detail_baseline_navigation=_detail_navigation_identity()
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(detail_audit))!=OK or DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT+"entities/"))!=OK:
		error="Cannot create new isolated output/audit directories."
		await _finish(false)
		return
	var forecast: Dictionary=source.forecast()
	if not _json(detail_audit+"source_forecast.json",forecast) or not bool(forecast.get("passed",false)):
		error="Unchanged city full17/Rectangle34x24 source forecast failed; no visual fallback."
		await _finish(false)
		return
	if not _json(OUT+"art_contract.json",{"schema_version":1,"status":"BUILD_IN_PROGRESS","production_approved":false,"scope":DETAIL_IDENTITY}):
		await _finish(false)
		return
	detail_adapter=DETAIL_ADAPTER.new()
	if not detail_adapter.prepare(source.snapshot()):
		error=detail_adapter.error
		await _finish(false)
		return
	# Parent _capture_city calls these instance methods for its actual paving and
	# shoulder materials. Static SURFACE.plain/environment/water geometry remain.
	surface=detail_adapter.detail
	if not _measure_buildings() or not _stage_generated_textures():
		await _finish(false)
		return
	var needed: Array[String]=[]
	for object: Dictionary in source.objects:
		var kind: String=object["prototype"]
		if kind!="" and kind not in needed: needed.append(kind)
	for kind: String in needed:
		if not await _prototype(kind):
			await _finish(false)
			return
	if not await _capture_city():
		await _finish(false)
		return
	await _finish(true)

func _source_graph() -> Dictionary:
	var graph: Dictionary=super._source_graph()
	for path: String in [DETAIL_ADAPTER_PATH,DETAIL_SURFACE_PATH,"res://scripts/dev/build_luoyang_modular_v3_grey_tile_roof_revision.gd"]:
		graph[path]=FileAccess.get_sha256(path)
	return graph

func _detail_navigation_identity() -> Dictionary:
	var geometry: Array[Dictionary]=[]
	for object: Dictionary in source.objects:
		var entry: Dictionary={}
		for key: String in ["id","prototype","world_foot_px","depth_foot_y","physical_center_px","collision_size_px","solid_polygons_px","blocking","z_index","sort_by_feet","ghost_occlusion","walk_support","role"]:
			if object.has(key): entry[key]=object[key]
		geometry.append(entry)
	return {"routes":source.routes.duplicate(true),"objects":geometry,"slots":source.gameplay_slots.duplicate(true),"anchors":source.anchors.duplicate(true),"entry_foot":source.entry_foot,"npc_stations":source.npc_stations()}

func _paving_mesh() -> ArrayMesh:
	if detail_paving_mesh!=null: return detail_paving_mesh
	var original: ArrayMesh=super._paving_mesh()
	var result: ArrayMesh=detail_adapter.decorate_native_clone(original,"paving")
	if result==null: error=detail_adapter.error
	detail_paving_mesh=result
	return result

func _support_mesh(wet: bool) -> ArrayMesh:
	if not wet and detail_dry_mesh!=null: return detail_dry_mesh
	var original: ArrayMesh=super._support_mesh(wet)
	if wet: return original
	var result: ArrayMesh=detail_adapter.decorate_native_clone(original,"base_joints")
	if result==null: error=detail_adapter.error
	detail_dry_mesh=result
	return result

func _detail_original_wall(kind: String) -> ArrayMesh:
	# Construct the exact frozen 9FF wall material/geometry recipe, sharing only
	# the already verified registered texture objects. No extra texture loads.
	var revised: SURFACE=surface
	var frozen:=SURFACE.new()
	frozen.textures=revised.textures
	surface=frozen
	var original: ArrayMesh=super._prop_mesh(kind)
	surface=revised
	return original

func _prop_mesh(kind: String) -> ArrayMesh:
	if kind not in ["wall_horizontal","wall_vertical"]: return super._prop_mesh(kind)
	var original: ArrayMesh=_detail_original_wall(kind)
	var result: ArrayMesh=detail_adapter.decorate_native_clone(original,kind)
	if result==null: error=detail_adapter.error
	return result

func _prototype(kind: String) -> bool:
	if kind not in ["wall_horizontal","wall_vertical"]: return await super._prototype(kind)
	# Do not invoke grey/roof _prototype: that chain correctly requires unchanged
	# original masonry MATERIALS, which this explicit iteration deliberately changes.
	var original: ArrayMesh=_detail_original_wall(kind)
	var mesh: ArrayMesh=_prop_mesh(kind)
	if original==null or mesh==null or not _roof_arrays_byte_exact(original,mesh):
		error="Material proposal changed actual wall/raised-roof primitive or stored arrays."
		return false
	var bounds: Dictionary=_bounds(mesh,Basis.IDENTITY)
	var old_bounds: Dictionary=_bounds(original,Basis.IDENTITY)
	if bounds.is_empty() or old_bounds.is_empty() or var_to_bytes(bounds)!=var_to_bytes(old_bounds):
		error="Material proposal changed actual complete wall bounds or foot support."
		return false
	var cap_index: int=mesh.get_surface_count()-1
	if mesh.surface_get_material(cap_index)!=original.surface_get_material(cap_index):
		# Independently constructed cap resources are not the same object; require
		# code plus every real uniform/sampler value exact, not merely an identity.
		if not _detail_material_exact(mesh.surface_get_material(cap_index),original.surface_get_material(cap_index)):
			error="Frozen 9FF grey tile cap material changed outside proposal scope."
			return false
	var material_rows: Array[Dictionary]=[]
	for index in range(mesh.get_surface_count()):
		var current: ShaderMaterial=mesh.surface_get_material(index) as ShaderMaterial
		var previous: ShaderMaterial=original.surface_get_material(index) as ShaderMaterial
		if current==null or current.shader==null or previous==null or previous.shader==null:
			error="Native wall material missing; no default/fallback capture."
			return false
		var declared: Array[String]=[]
		for uniform: Dictionary in current.shader.get_shader_uniform_list(): declared.append(String(uniform["name"]))
		# Both roles bind the original registered samplers, but the dedicated cap
		# is validated from its actual frozen uniform schema, not wall semantics.
		for channel: String in ["original_stone","registered_normal","registered_arm"]:
			if channel not in declared:
				error="Actual revised wall reflection failed: "+channel
				return false
		if current.get_shader_parameter("original_stone")!=surface.textures["stone"] or current.get_shader_parameter("registered_normal")!=surface.textures["nor_gl"] or current.get_shader_parameter("registered_arm")!=surface.textures["arm"]:
			error="Revised wall actual sampler binding differs from registered source."
			return false
		var row: Dictionary={"surface_index":index,"surface_role":"unchanged_9FF_raised_grey_tile_cap" if index==cap_index else "revised_original_masonry_material","previous_shader_code_sha256":_text_sha(previous.shader.code),"actual_shader_code_sha256":_text_sha(current.shader.code),"actual_sampler_objects_equal_registered_textures":true,"actual_uniform_schema":declared,"actual_parameters":_detail_uniform_evidence(current),"material_code_changed":previous.shader.code!=current.shader.code,"samplers":{"original_stone":{"path":SURFACE.STONE,"sha256":SURFACE.STONE_SHA},"registered_normal":{"path":SURFACE.ROOT+"rock_01_nor_gl_2k.jpg","sha256":FileAccess.get_sha256(SURFACE.ROOT+"rock_01_nor_gl_2k.jpg")},"registered_arm":{"path":SURFACE.ROOT+"rock_01_arm_2k.jpg","sha256":FileAccess.get_sha256(SURFACE.ROOT+"rock_01_arm_2k.jpg")}}}
		if index<cap_index:
			for channel: String in ["masonry_tint","masonry_profile"]:
				if channel not in declared:
					error="Actual original masonry uniform missing: "+channel
					return false
			var tint: Variant=current.get_shader_parameter("masonry_tint")
			var profile: Variant=current.get_shader_parameter("masonry_profile")
			var expected_profile: float=1. if _masonry_profile()=="yamen_white_lime_dark_stone" else 0.
			if not tint is Vector3 or not profile is float or float(profile)!=expected_profile or var_to_bytes(tint)!=var_to_bytes(previous.get_shader_parameter("masonry_tint")) or var_to_bytes(profile)!=var_to_bytes(previous.get_shader_parameter("masonry_profile")):
				error="Revised original masonry failed actual retained tint/district profile."
				return false
			row["actual_profile"]=profile
			row["actual_tint"]=_v3(tint)
			row["retained_original_masonry_tint_profile_exact"]=true
		else:
			# Exact pinned 9FF DOES declare these two masonry-compatible parameters.
			# Retain the original reflection/type/district gate as well as stronger
			# dedicated cap code/every-uniform exact comparison below.
			for channel: String in ["masonry_tint","masonry_profile"]:
				if channel not in declared:
					error="Frozen dedicated cap actual compatibility uniform missing: "+channel
					return false
			var tint: Variant=current.get_shader_parameter("masonry_tint")
			var profile: Variant=current.get_shader_parameter("masonry_profile")
			var expected_profile: float=1. if _masonry_profile()=="yamen_white_lime_dark_stone" else 0.
			if not tint is Vector3 or not profile is float or float(profile)!=expected_profile:
				error="Frozen dedicated cap actual compatibility profile/type failed."
				return false
			if not _detail_material_exact(current,previous):
				error="Dedicated raised cap differs in actual code, uniform or sampler."
				return false
			row["dedicated_cap_all_declared_parameters_and_code_exact"]=true
			row["actual_profile"]=profile
			row["actual_tint"]=_v3(tint)
			row["previous_uniform_schema"]=previous.shader.get_shader_uniform_list()
			row["previous_parameters"]=_detail_uniform_evidence(previous)
			row["profile_scope"]="Dedicated frozen cap schema including its real tint/profile compatibility parameters; every declared tile parameter/code/sampler exact, not a masonry shader substitution."
		material_rows.append(row)
	var support: Vector3=bounds["support"]
	view=_viewport(Vector2i(1536,1536),true)
	var world: Node3D=_world(view,true)
	var body:=MeshInstance3D.new()
	body.mesh=mesh
	body.transform=Transform3D(Basis.IDENTITY,-support)
	body.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(body)
	var camera: Camera3D=_camera(world,Vector2i(768,768),Vector3(0,1.6,0))
	await _sync()
	var raw: Image=_read(view)
	await _sync()
	var repeat: Image=_read(view)
	var prefix: String=OUT+"entities/native_"+kind
	if raw==null or repeat==null or raw.get_size()!=Vector2i(1536,1536) or repeat.get_size()!=raw.get_size():
		error="Actual wall readback/canvas invalid."
		return false
	if raw.save_png(prefix+"_raw.png")!=OK or repeat.save_png(prefix+"_raw_repeat.png")!=OK: return false
	if raw.get_data()!=repeat.get_data():
		error="Actual revised wall body raw byte repeat differs."
		return false
	var logical: Image=_alpha_resize(raw,Vector2i(768,768))
	if logical==null: return false
	var used: Rect2i=logical.get_used_rect()
	if used.size.x<=0 or used.position.x<4 or used.position.y<4 or used.end.x>764 or used.end.y>764:
		error="Actual revised wall alpha is empty or crosses capture margin."
		return false
	var crop:=Rect2i(used.position-Vector2i(4,4),used.size+Vector2i(8,8))
	var image: Image=logical.get_region(crop)
	var foot: Vector2=camera.unproject_position(Vector3.ZERO)/SSAA-Vector2(crop.position)
	if image.save_png(prefix+".png")!=OK or ResourceSaver.save(mesh,prefix+".res")!=OK: return false
	if not _roof_arrays_byte_exact(original,mesh) or var_to_bytes(_bounds(mesh,Basis.IDENTITY))!=var_to_bytes(old_bounds):
		error="Actual retained captured wall no longer matches frozen geometry/support."
		return false
	var comparison: Dictionary={"all_primitive_array_slots_byte_exact":true,"actual_complete_bounds_support_byte_exact":true,"slots_checked":mesh.get_surface_count()*Mesh.ARRAY_MAX,"surface_count":mesh.get_surface_count(),"all_slot_evidence":detail_adapter._array_evidence(original,mesh),"raised_cap_material_code_parameters_exact":_detail_material_exact(mesh.surface_get_material(cap_index),original.surface_get_material(cap_index)),"method":"Real separately constructed frozen9FF mesh versus actual captured mesh; every stored slot/primitive and complete used-index bounds/support exact; original masonry material is explicitly different."}
	detail_wall_comparisons[kind]=comparison
	var record: Dictionary={"kind":kind,"texture":prefix+".png","metadata_path":prefix+".json","source_size_px":[image.get_width(),image.get_height()],"render_size_px":[image.get_width(),image.get_height()],"foot_uv":[foot.x/image.get_width(),foot.y/image.get_height()],"sourcebody_raw":prefix+"_raw.png","sourcebody_raw_repeat":prefix+"_raw_repeat.png","raw_camera":_camera_data(camera,view.size,Vector2i(768,768)),"crop_rect_px":[crop.position.x,crop.position.y,crop.size.x,crop.size.y],"native_mesh_path":prefix+".res","draw_basis_columns":[_v3(Basis.IDENTITY.x),_v3(Basis.IDENTITY.y),_v3(Basis.IDENTITY.z)],"support_m":_v3(support),"used_bounds_m":{"minimum":_v3(bounds["minimum"]),"maximum":_v3(bounds["maximum"])},"actual_used_vertices":bounds["actual_used_vertices"],"scale":1.,"alpha_resampling_algorithm":"RGBAF_PREMULTIPLIED_LANCZOS_UNPREMULTIPLY_V1","alpha_unpremultiply_epsilon":.00001,"repeat_byte_exact":true,"source":"Project original native masonry + ROOT097 raised-cap geometry and frozen9FF grey tile material; original masonry receives explicit new project material, NOT CC0 wall geometry.","source_min_vertex_ground_delta_m":Vector3(bounds["minimum"]).y-support.y,"sourcebody_and_ground_caster_same_mesh_material_basis_support":true,"geometry_change_scope":"MATERIAL_ONLY_RELATIVE_TO_FROZEN_9FF_COMPLETE_RAISED_CAP_GEOMETRY; arrays/support exact; original masonry changes, final roof material unchanged; fresh PNG alpha/bounds measured, not old body reuse.","geometry_array_evidence":_geometry_array_evidence(mesh),"material_revision":{"identity":DETAIL_IDENTITY,"actual_original_geometry_comparison":comparison,"actual_surface_materials":material_rows,"executed_builder":{"path":get_script().resource_path,"sha256":FileAccess.get_sha256(get_script().resource_path)},"production_approved":false}}
	if not _json(prefix+".json",record): return false
	prototypes[kind]={"mesh":mesh,"basis":Basis.IDENTITY,"support":support,"image":image,"record":record}
	view.queue_free()
	view=null
	await _sync()
	return true

func _detail_material_exact(a: Material,b: Material) -> bool:
	var aa: ShaderMaterial=a as ShaderMaterial
	var bb: ShaderMaterial=b as ShaderMaterial
	if aa==null or bb==null or aa.shader==null or bb.shader==null or aa.shader.code!=bb.shader.code: return false
	for uniform: Dictionary in aa.shader.get_shader_uniform_list():
		var name: String=uniform["name"]
		var x: Variant=aa.get_shader_parameter(name)
		var y: Variant=bb.get_shader_parameter(name)
		if x is Resource or y is Resource:
			if x!=y: return false
		elif var_to_bytes(x)!=var_to_bytes(y): return false
	return true

func _detail_uniform_evidence(material: ShaderMaterial) -> Dictionary:
	var result: Dictionary={}
	for uniform: Dictionary in material.shader.get_shader_uniform_list():
		var name: String=uniform["name"]
		var value: Variant=material.get_shader_parameter(name)
		if value is Texture2D:
			var channel := ""
			for key: String in surface.textures:
				if value==surface.textures[key]: channel=key
			result[name]={"type":typeof(value),"registered_texture_key":channel,"actual_instance_id":value.get_instance_id(),"actual_size_px":[value.get_width(),value.get_height()],"same_actual_registered_object":channel!=""}
		elif value is Vector3:
			result[name]={"type":typeof(value),"value":_v3(value),"variant_sha256":_variant_sha(value)}
		elif value is Vector2:
			result[name]={"type":typeof(value),"value":[value.x,value.y],"variant_sha256":_variant_sha(value)}
		elif value is Color:
			result[name]={"type":typeof(value),"value":[value.r,value.g,value.b,value.a],"variant_sha256":_variant_sha(value)}
		else:
			result[name]={"type":typeof(value),"value":value,"variant_sha256":_variant_sha(value)}
	return result

func _capture_city() -> bool:
	# Inherited implementation has strict actual ON/OFF/raw repeat, no-msaa
	# binary authority and full semantic solid raster. Only instance materials
	# differ. No copy of old floor, nav, RF or wall PNG is accepted as a capture.
	if var_to_bytes(_detail_navigation_identity())!=var_to_bytes(detail_baseline_navigation):
		error="Proposal changed source routes/objects/slots before real capture."
		return false
	# Parent has no null fallback guard at these two geometry construction calls.
	# Check/cache the exact material clones first and refuse before entering it.
	if _paving_mesh()==null or _support_mesh(false)==null: return false
	if not await super._capture_city(): return false
	if var_to_bytes(_detail_navigation_identity())!=var_to_bytes(detail_baseline_navigation):
		error="Proposal changed authored geometry/navigation/actor/action identity during capture."
		return false
	return true

func _detail_measure_paving_binding() -> bool:
	if view==null or detail_paving_mesh==null: return false
	var matches: Array[ShaderMaterial]=[]
	for world: Node in view.get_children():
		for child: Node in world.get_children():
			if child is MeshInstance3D and child.mesh==detail_paving_mesh:
				var actual: ShaderMaterial=child.material_override as ShaderMaterial
				if actual!=null: matches.append(actual)
	if matches.size()!=1 or matches[0].shader==null:
		error="Actual paving node/override is not uniquely identified; refuse guessed binding."
		return false
	var actual: ShaderMaterial=matches[0]
	var uniforms: Array[String]=[]
	for entry: Dictionary in actual.shader.get_shader_uniform_list(): uniforms.append(String(entry["name"]))
	var expected_counts: Dictionary={"route_count":detail_adapter.detail.route_segments.size(),"contact_count":detail_adapter.detail.contact_segments.size(),"apron_count":detail_adapter.detail.apron_rects.size()}
	var measured_counts: Dictionary={}
	for name: String in expected_counts:
		if name not in uniforms or int(actual.get_shader_parameter(name))!=int(expected_counts[name]):
			error="Actual paving geometry-owner count binding differs: "+name
			return false
		measured_counts[name]=actual.get_shader_parameter(name)
	var expected_arrays: Dictionary={"route_segments":detail_adapter.detail._uniform_vectors(detail_adapter.detail.route_segments,128),"contact_segments":detail_adapter.detail._uniform_vectors(detail_adapter.detail.contact_segments,128),"apron_rects":detail_adapter.detail._uniform_vectors(detail_adapter.detail.apron_rects,32)}
	var measured_arrays: Dictionary={}
	for name: String in expected_arrays:
		if name not in uniforms:
			error="Actual paving geometry-owner uniform missing: "+name
			return false
		var values: Variant=actual.get_shader_parameter(name)
		if not (values is Array or values is PackedVector4Array) or values.size()!=expected_arrays[name].size():
			error="Actual paving geometry-owner vector array is missing or truncated: "+name
			return false
		for index in range(values.size()):
			if values[index]!=expected_arrays[name][index]:
				error="Actual paving world-metre geometry-owner vector differs: "+name
				return false
		measured_arrays[name]={"actual_count":values.size(),"actual_variant_sha256":_variant_sha(values),"exact_component_values_match_configured_source":true}
	if actual.get_shader_parameter("stone_albedo")!=surface.textures["stone"] or actual.get_shader_parameter("rock_normal")!=surface.textures["nor_gl"] or actual.get_shader_parameter("rock_arm")!=surface.textures["arm"]:
		error="Actual paving sampler object does not match registered original material."
		return false
	detail_paving_binding={"passed":true,"method":"Actual inherited capture node whose mesh is the checked native paving; get_shader_parameter on its real material_override after native draw; compare each geometry-owner vector/count, not source declarations.","actual_shader_code_sha256":_text_sha(actual.shader.code),"actual_counts":measured_counts,"actual_arrays":measured_arrays,"actual_sampler_objects_equal_registered_textures":true,"uniforms":uniforms}
	return true

func _json(path: String,data: Dictionary) -> bool:
	var destination: String=path
	if path.begins_with(AUDIT): destination=detail_audit+path.trim_prefix(AUDIT)
	if detail_audit=="" or not (destination.begins_with(OUT) or destination.begins_with(detail_audit)) or not OUT.begins_with(DETAIL_ART_ROOT):
		error="Isolated writer refused a path outside NEW proposal output/audit."
		return false
	if destination==OUT+"material_binding.json" and not _detail_measure_paving_binding(): return false
	var measured: Dictionary=data.duplicate(true)
	if destination==OUT+"material_binding.json" or measured.has("material_binding_evidence"):
		var binding: Dictionary=measured if destination==OUT+"material_binding.json" else measured["material_binding_evidence"]
		binding["stone_albedo_used_in_fragment"]="Actual new paving: stone=texture(stone_albedo,UV).rgb; face=stone*continuous traffic/apron finish; verge/contact mix restrained world-metre dust; ALBEDO=face*COLOR.rgb*native_flagstone_identity. No extra slab palette/grid or vertex displacement."
		binding["actual_surface_script"]={"path":DETAIL_SURFACE_PATH,"sha256":FileAccess.get_sha256(DETAIL_SURFACE_PATH)}
		binding["native_detail_material_records"]=detail_adapter.detail.material_records.duplicate(true)
		binding["native_geometry_owner_uniforms"]=detail_paving_binding.duplicate(true)
	if destination==OUT+"art_contract.json" and measured.get("status","")=="ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA":
		if surface==null or surface.get_script().resource_path!=DETAIL_SURFACE_PATH:
			error="Final contract surface binding is not the actual new surface instance."
			return false
		measured["scope"]="ISOLATED_STREET_DETAIL_PROPOSAL_NOT_RUNTIME_OR_FORMAL_APPROVED"
		measured["capture_surface_binding"]={"path":surface.get_script().resource_path,"sha256":FileAccess.get_sha256(surface.get_script().resource_path),"actual_instance_equals_prepared_adapter_surface":surface==detail_adapter.detail,"parent_surface_path":ROOF_SURFACE_PATH,"parent_surface_sha256":FileAccess.get_sha256(ROOF_SURFACE_PATH)}
		measured["material_iteration"]={"identity":DETAIL_IDENTITY,"parent_pins":DETAIL_ADAPTER.PINS,"native_clone_evidence":detail_adapter.evidence.duplicate(true),"captured_wall_geometry_comparisons":detail_wall_comparisons.duplicate(true),"source_navigation_identity_sha256":detail_adapter._hash(var_to_bytes(detail_baseline_navigation)),"scope":"Material iteration over same frozen layout and all stored arrays/support. New native wall PNG captured; original generated architecture byte-preserved. Exact old/new final nav/RF still requires independent root checker, not source-only approval.","not_solved_by_material_only":["open composition/architectural density","formal Field visual approval"],"production_approved":false}
		measured["ground_design"]["regional_surface_treatments"]="Actual unchanged route centrelines drive continuous metre-scale traffic polish/dust; source front polygons drive apron and narrow edge grime. Original stone ALBEDO and real native joints retained; no whole-slab checker palette, fake cast or new blocking geometry."
		measured["capture_graph"]["parent_surface_script"]={"path":ROOF_SURFACE_PATH,"sha256":FileAccess.get_sha256(ROOF_SURFACE_PATH)}
		measured["capture_graph"]["surface_script"]={"path":DETAIL_SURFACE_PATH,"sha256":FileAccess.get_sha256(DETAIL_SURFACE_PATH)}
		measured["capture_graph"]["material_adapter_script"]={"path":DETAIL_ADAPTER_PATH,"sha256":FileAccess.get_sha256(DETAIL_ADAPTER_PATH)}
		# material_binding was written earlier with new accurate description; bind
		# the measured bytes, never the parent's pre-description dictionary hash.
		measured["asset_sha256"][OUT+"material_binding.json"]=FileAccess.get_sha256(OUT+"material_binding.json")
	return super._json(destination,measured)

func _finish(passed: bool) -> void:
	# The adapter shares the same texture instances as parent surface/materials.
	# Release its strong references before inherited mesh/view caches and the
	# inherited sixteen natural frames/custom-cursor cleanup/quit lifecycle.
	if detail_adapter!=null: detail_adapter.release()
	detail_adapter=null
	detail_paving_mesh=null
	detail_dry_mesh=null
	detail_paving_binding.clear()
	detail_wall_comparisons.clear()
	detail_baseline_navigation.clear()
	await super._finish(passed)
