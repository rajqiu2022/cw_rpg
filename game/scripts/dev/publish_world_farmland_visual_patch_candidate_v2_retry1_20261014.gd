extends "res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd"
## Reuse the original memory guard and integer-texel ROI96 readback only.
## Never invoke the inherited full builder, prepare(), exporter or NAV roles.
const FARM_AUTHOR := preload("res://scripts/dev/world_farmland_coherent_author_v2_20261014.gd")
const FARM_SURFACE := preload("res://scripts/dev/world_farmland_coherent_surface_v2_20261014.gd")
const FARM_CHECK := preload("res://scripts/dev/world_farmland_visual_patch_candidate_contract_v2_retry1_20261014.gd")
const DIRTY_PLAN := preload("res://scripts/dev/world_farmland_dirty_plan_v2_20261014.gd")
const FARM_ROOT := "res://art/maps/world_map_v15_complete_v9c/"
const FARM_PROOF := FARM_ROOT+"whole_actual_capture.json"
const FARM_PROOF_SHA := "cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851"
const BASELINE_QA_PATH := "res://build/world_farmland_v2_gpu_20261014_root03/qa_baseline_vs_formal_two_roi.json"
const BASELINE_QA_SHA := "13ff6db57dc7041791bad00a2b3525dc6d3f6e48a06e658aed36e29f0d443d49"
const FARM_SCOPE := "WORLD_FARMLAND_NATIVE_VISUAL_PATCH_12_DIRTY_CANDIDATE_PHASE2"
const FARM_BUDGET_MS := 360000
const SUBSET_DIAGNOSTIC_PATH := "res://build/world_farmland_overview_subset_diagnostic_20261014/22660_3189020/result.json"
const SUBSET_DIAGNOSTIC_SHA := "7df04d16138233806ecf8f8a7d6fc6203fcec1f46e9af30bf157a318dbbad280"
const SUBSET_DIAGNOSTIC_SOURCE := "res://scripts/dev/diagnose_world_farmland_overview_subset_20261014.gd"
const SUBSET_DIAGNOSTIC_SOURCE_SHA := "3bc14fa260556f26a2a56331dc461c46b1174cec7dcbc4f3c3e22c7622a5c129"
const OLD_FAILED_EXECUTOR := "res://scripts/dev/publish_world_farmland_visual_patch_candidate_v2_20261014.gd"
const OLD_FAILED_EXECUTOR_SHA := "82ae3338879fa01be899c8ada8ec31a0e768a882ca534456da36019c3b38a1be"
var farm_pins: Dictionary = {}
var farm_failures: Array[String] = []
var farm_rows: Array[Dictionary] = []
var farm_author: RefCounted
var farm_surface: RefCounted
var farm_old_material: ShaderMaterial
var farm_new_material: ShaderMaterial
var farm_proof: Dictionary
var farm_source: Dictionary
var farm_author_audit: Dictionary
var farm_started: int
var farm_native_actual: Dictionary = {}
var farm_dirty_plan: Dictionary = {}
var farm_overview_record: Dictionary = {}
var farm_baselines: Array[Dictionary] = []
var farm_baseline_review: Dictionary = {}
var farm_overview_preflight: Dictionary = {}

func _farm_require(ok: bool,label: String) -> bool:
	if not ok: farm_failures.append(label); push_error("[FARM PHASE2 CANDIDATE] "+label)
	return ok
func _farm_pin(path: String,expected: String) -> bool:
	if not _farm_require(expected.length()==64 and FileAccess.get_sha256(path).to_lower()==expected.to_lower(),"Exact native input "+path): return false
	if farm_pins.has(path) and farm_pins[path] != expected.to_lower(): return _farm_require(false,"Conflicting input identity "+path)
	farm_pins[path]=expected.to_lower(); return true
func _farm_vec(value: Array) -> Vector3: return Vector3(float(value[0]),float(value[1]),float(value[2]))
func _farm_native_real(value: Variant) -> float: return Vector2(float(value),0.0).x
func _farm_transform(value: Dictionary) -> Transform3D:
	var columns: Array = value.basis_columns
	return Transform3D(Basis(_farm_vec(columns[0]),_farm_vec(columns[1]),_farm_vec(columns[2])),_farm_vec(value.origin))

func _farm_overview_schema_preflight() -> bool:
	if not _farm_pin(SUBSET_DIAGNOSTIC_PATH,SUBSET_DIAGNOSTIC_SHA) or not _farm_pin(SUBSET_DIAGNOSTIC_SOURCE,SUBSET_DIAGNOSTIC_SOURCE_SHA) or not _farm_pin(OLD_FAILED_EXECUTOR,OLD_FAILED_EXECUTOR_SHA): return false
	var diagnostic: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SUBSET_DIAGNOSTIC_PATH))
	if not _farm_require(diagnostic.get("failures",["missing"]).is_empty() and diagnostic.get("GPU_allocated")==false and diagnostic.get("source_path")==FARM_ROOT+"source_contract.json" and diagnostic.get("source_sha256")==farm_pins.get(FARM_ROOT+"source_contract.json") and diagnostic.get("failed_executor_sha256")==OLD_FAILED_EXECUTOR_SHA and diagnostic.get("diagnostic_source_sha256")==SUBSET_DIAGNOSTIC_SOURCE_SHA,"Actual native CPU subset diagnostic binding"): return false
	var chunk_ids: Dictionary={}
	for entry: Dictionary in farm_source.chunks:
		if not _farm_require(entry.has("id") and entry.has("row") and entry.has("col") and entry.has("visual_path"),"Original chunk overview schema"): return false
		var id:=String(entry.id)
		if not _farm_require(not chunk_ids.has(id) and id=="r%d_c%d"%[int(entry.row),int(entry.col)],"Original distinct chunk identity"): return false
		chunk_ids[id]=true
	if not _farm_require(chunk_ids.size()==64,"Original64 overview chunk identities"): return false
	var draws:=0; var bodies:=0; var resized_pixels:=0
	var keys: Dictionary={}
	for object: Dictionary in farm_source.objects:
		if not _farm_require(object.has("texture") and object.get("render_size_px") is Array and object.render_size_px.size()==2 and object.get("pos") is Array and object.pos.size()==2 and object.has("depth_sort_foot_y"),"Original independent object overview schema"): return false
		var size:=Vector2i(object.render_size_px[0],object.render_size_px[1])
		if not _farm_require(size.x>0 and size.y>0 and size.x*size.y<=8404992,"Original bounded body render size"): return false
		var center:=Vector2(object.pos[0]*12288.0,object.pos[1]*8192.0)
		var bounds:=Rect2i(Vector2i((center-Vector2(size)*.5).round()),size)
		var uses:=0
		for roi: Dictionary in farm_dirty_plan.tiles:
			if bounds.intersects(roi.rect): uses+=1
		if uses==0: continue
		bodies+=1; draws+=uses
		var key:=String(object.texture)+"|"+str(size.x)+"|"+str(size.y)
		if not keys.has(key): keys[key]=true; resized_pixels+=size.x*size.y
		if not _farm_pin(object.texture,String(farm_source.asset_sha256.get(object.texture,""))): return false
	farm_overview_preflight={"original_objects":2687,"used_objects":bodies,"tile_draws":draws,"unique_texture_render_keys":keys.size(),"summed_resized_pixels":resized_pixels,"resize_cache_added":false,"reason":"Only2 repeated reads; preserve exact original per-body alpha resize and feet sort.","actual_native_diagnostic":{"path":SUBSET_DIAGNOSTIC_PATH,"sha256":SUBSET_DIAGNOSTIC_SHA,"source_sha256":SUBSET_DIAGNOSTIC_SOURCE_SHA,"old_failed_executor_sha256":OLD_FAILED_EXECUTOR_SHA,"counts":diagnostic.actual_counts}}
	if not _farm_require(bodies==45 and draws==47 and keys.size()==45 and resized_pixels==1554563 and diagnostic.actual_counts.used_objects==bodies and diagnostic.actual_counts.tile_draws==draws and diagnostic.actual_counts.unique_texture_render_keys==keys.size() and diagnostic.actual_counts.summed_resized_pixels==resized_pixels,"Frozen actual native12-cell subset45bodies/47draws/45resizekeys"): return false
	return true

func _farm_load() -> bool:
	var auth_path := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--authorization="): auth_path=arg.trim_prefix("--authorization=")
	var auth: Variant = JSON.parse_string(FileAccess.get_file_as_string(auth_path)) if not auth_path.is_empty() else null
	if not _farm_require(auth is Dictionary and auth.get("approved_by")=="root" and auth.get("scope")==FARM_SCOPE and auth.get("approved")==true,"Independent ROOT phase2/360 authorization required"): return false
	var source_inputs: Dictionary = auth.get("input_sha256",{})
	for required: String in [get_script().resource_path,"res://scripts/dev/world_farmland_coherent_author_v2_20261014.gd","res://scripts/dev/world_farmland_coherent_surface_v2_20261014.gd","res://scripts/dev/world_farmland_visual_patch_candidate_contract_v2_retry1_20261014.gd","res://scripts/dev/world_farmland_dirty_plan_v2_20261014.gd","res://scripts/dev/world_map_v15_v9_visual_quality_proposal_surface.gd","res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd","res://scripts/dev/build_world_map_v15_coherent_whole_v6_pilot.gd",FARM_ROOT+"source_contract.json"]:
		if not _farm_require(source_inputs.has(required),"Authorization binds "+required) or not _farm_pin(required,String(source_inputs.get(required,""))): return false
	for path: String in source_inputs:
		if not _farm_pin(path,String(source_inputs[path])): return false
	if not _farm_pin(FARM_PROOF,FARM_PROOF_SHA) or not _farm_pin(BASELINE_QA_PATH,BASELINE_QA_SHA): return false
	farm_baseline_review=JSON.parse_string(FileAccess.get_file_as_string(BASELINE_QA_PATH))
	if not _farm_require(farm_baseline_review.get("scope")=="BOUNDED_TWO_ACTUAL_BASELINE_ROIS_VS_CURRENT_FORMAL_CHUNKS_ALL_RGBA_NO_TOLERANCE" and farm_baseline_review.get("total_compared_pixels")==3145728 and farm_baseline_review.get("comparisons",[]).size()==2,"Actual independent baseline comparison preflight"): return false
	for comparison: Dictionary in farm_baseline_review.comparisons:
		if not _farm_require(comparison.get("all_RGBA_exact")==true and comparison.get("changed_pixels")==0 and comparison.get("changed_channels")==0,"Independent old baseline fullRGBA preflight"): return false
		if not _farm_pin(comparison.baseline_path,comparison.baseline_PNG_sha256): return false
		for chunk: Dictionary in comparison.formal_chunk_PNG_sha256:
			if not _farm_pin(chunk.path,chunk.sha256): return false
	farm_proof=JSON.parse_string(FileAccess.get_file_as_string(FARM_PROOF))
	farm_source=JSON.parse_string(FileAccess.get_file_as_string(FARM_ROOT+"source_contract.json"))
	if not _farm_require(farm_source.get("objects",[]).size()==2687 and farm_proof.worlds.primary.casters.size()==2578 and farm_proof.worlds.primary.visual_guard_meshes.size()==4,"Original2687 runtime bodies / actual2578 casters /4guards retained distinctly"): return false
	# Source JSON is unchanged; these paths remain exact without decoding NAV.
	for chunk: Dictionary in farm_source.chunks:
		for key: String in ["visual_path","walk_path","raw_walk_path","land_path"]:
			var path: String = chunk[key]
			if not _farm_pin(path,String(farm_source.asset_sha256.get(path,""))): return false
	var rf_path := FARM_ROOT+"terrain_height.rf"
	if not _farm_pin(rf_path,String(farm_proof.actual_RF.sha256)): return false
	var rf_bytes := FileAccess.get_file_as_bytes(rf_path)
	farm_dirty_plan=DIRTY_PLAN.new().derive(rf_bytes,farm_proof.worlds.primary.camera)
	if not _farm_require(not farm_dirty_plan.is_empty(),"Actual old18/new12 RF-projected12 closure"): return false
	if not _farm_overview_schema_preflight(): return false
	farm_author=FARM_AUTHOR.new(); farm_surface=FARM_SURFACE.new()
	farm_author_audit=farm_author.call("audit",Image.load_from_file(FARM_ROOT+"capture/roads_reconstructed.png"),Image.load_from_file(FARM_ROOT+"capture/ecology_reconstructed.png"),rf_bytes)
	if not _farm_require(not farm_author_audit.is_empty() and farm_author_audit.get("identity")==FARM_AUTHOR.ID and farm_author_audit.get("parcel_count")==12 and farm_author_audit.get("all_rectangles_clear")==true,"Real V2 original owner/RF audit requires all12 whole rectangles clear"): return false
	for path: String in [FARM_ROOT+"capture/roads_reconstructed.png",FARM_ROOT+"capture/ecology_reconstructed.png"]:
		if not _farm_pin(path,String(farm_source.asset_sha256.get(path,""))): return false
	var material_row: Dictionary = farm_proof.v9c_revision_evidence.attached_material_creations[1]
	if not _farm_pin(material_row.path,material_row.sha256): return false
	farm_old_material=ResourceLoader.load(material_row.path,"",ResourceLoader.CACHE_MODE_IGNORE) as ShaderMaterial
	if not _farm_require(farm_old_material != null,"Saved exact native terrain material"): return false
	if not _farm_require(_bytes_sha(farm_old_material.shader.code.to_utf8_buffer())==farm_proof.actual_terrain_shader.sha256,"Saved material and actual native shader code binding"): return false
	var clearance_rf := ImageTexture.create_from_image(Image.create_from_data(1537,1025,false,Image.FORMAT_RF,rf_bytes))
	if not _farm_require(clearance_rf.get_image().get_data()==rf_bytes,"Actual clearance sampler full original RF bytes"): return false
	farm_new_material=farm_surface.call("rewrite_original",farm_old_material,clearance_rf)
	if not _farm_require(farm_new_material != null,"New only-farm shader "+String(farm_surface.get("error"))): return false
	if not _farm_pin(TRANSPORT_PATH,TRANSPORT_SHA): return false
	pilot_transport=ResourceLoader.load(TRANSPORT_PATH,"",ResourceLoader.CACHE_MODE_IGNORE) as Shader
	for path: String in [SQUARE_RESULT,SQUARE_PNG,SQUARE_REPEAT]:
		if not _farm_pin(path,SQUARE_RESULT_SHA if path==SQUARE_RESULT else SQUARE_PNG_SHA): return false
	pilot_proof_gpu_uuid=String(farm_proof.actual_memory_history.gpu_uuid)
	pilot_memory_history=_pilot_square_history()
	if not _farm_require(pilot_memory_history.get("valid")==true and pilot_memory_history.vram_requirement_bytes==4188012544 and pilot_memory_history.host_RAM_requirement_bytes==11392942080,"Original measured memory budget recomputed without downgrade"): return false
	return true

func _farm_make_world() -> bool:
	if not _farm_require(Time.get_ticks_msec()-farm_started < FARM_BUDGET_MS,"Independent phase2 shared360s before whole allocation"): return false
	var record: Dictionary = farm_proof.worlds.primary
	var receiver: Dictionary = record.authoritative_global_mesh
	if not _farm_pin(receiver.path,receiver.sha256): return false
	pilot_global_mesh=ResourceLoader.load(receiver.path,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	var meshes: Dictionary = {}
	for caster: Dictionary in record.casters:
		var path: String = caster.actual_draw_mesh_path
		if not meshes.has(path):
			if not _farm_pin(path,caster.actual_draw_mesh_sha256): return false
			meshes[path]=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
			if not _farm_require(meshes[path]!=null,"Original caster native mesh "+path): return false
	if not _farm_require(meshes.size()==18,"Actual18 cached native caster meshes"): return false
	if not _pilot_memory_guard("farm_phase2_candidate"): return _farm_require(false,error)
	active_view=SubViewport.new(); active_view.size=Vector2i(24576,16384); active_view.own_world_3d=true
	active_view.msaa_2d=Viewport.MSAA_DISABLED; active_view.msaa_3d=Viewport.MSAA_DISABLED; active_view.render_target_update_mode=SubViewport.UPDATE_DISABLED
	root.add_child(active_view); pilot_world=Node3D.new(); active_view.add_child(pilot_world)
	pilot_environment=WorldEnvironment.new(); pilot_environment.environment=farm_surface.call("environment"); pilot_world.add_child(pilot_environment)
	pilot_sun=DirectionalLight3D.new(); pilot_sun.rotation_degrees=Vector3(-55,-34,0)
	pilot_sun.light_energy=record.camera.light_energy; pilot_sun.shadow_enabled=true; pilot_sun.shadow_normal_bias=record.camera.shadow_normal_bias
	pilot_sun.directional_shadow_mode=record.camera.directional_shadow_mode; pilot_sun.directional_shadow_max_distance=record.camera.shadow_max_distance; pilot_world.add_child(pilot_sun)
	var terrain:=MeshInstance3D.new(); terrain.mesh=pilot_global_mesh; terrain.material_override=farm_old_material
	terrain.cast_shadow=record.roles.visual.terrain_actual_cast_shadow; pilot_world.add_child(terrain); pilot_receivers.append(terrain)
	for guard: Dictionary in record.visual_guard_meshes:
		if not _farm_pin(guard.path,guard.sha256): return false
		var node:=MeshInstance3D.new(); node.mesh=ResourceLoader.load(guard.path,"",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
		node.material_override=farm_old_material; pilot_world.add_child(node); pilot_receivers.append(node)
	for caster: Dictionary in record.casters:
		var node:=MeshInstance3D.new(); node.mesh=meshes[caster.actual_draw_mesh_path]; node.transform=_farm_transform(caster.transform)
		node.cast_shadow=int(caster.shadow_on_enum); pilot_world.add_child(node); pilot_casters.append(node)
	# Bridge parts were native SHADOWS_ONLY too. Reuse actual world-vertex meshes.
	var bridge_count := 0
	for object: Dictionary in farm_source.objects:
		if not String(object.id).begins_with("bridge_"): continue
		var path: String=object.metadata_path
		if not _farm_pin(path,String(farm_source.asset_sha256.get(path,""))): return false
		var meta: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
		if not _farm_require(meta.actual_draw_geometry_vertex_space=="global world metres; identity transform; actual drawn triangle vertices in source order","Native bridge vertex-space exact"): return false
		if not _farm_pin(meta.actual_draw_geometry_path,meta.actual_draw_geometry_sha256): return false
		var node:=MeshInstance3D.new(); node.mesh=ResourceLoader.load(meta.actual_draw_geometry_path,"",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY; pilot_world.add_child(node); bridge_count+=1
	if not _farm_require(bridge_count==93,"Original93 native bridge draw groups"): return false
	var water_row: Dictionary=farm_proof.v9c_revision_evidence.attached_material_creations[2]
	if not _farm_pin(water_row.path,water_row.sha256) or not _farm_pin(record.water_recipe.path,record.water_recipe.sha256): return false
	pilot_water=MeshInstance3D.new(); pilot_water.mesh=ResourceLoader.load(record.water_recipe.path,"",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
	pilot_water.material_override=ResourceLoader.load(water_row.path,"",ResourceLoader.CACHE_MODE_IGNORE) as ShaderMaterial
	pilot_water.position.y=record.water_recipe.water_Y; pilot_water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; pilot_world.add_child(pilot_water)
	pilot_camera=Camera3D.new(); pilot_camera.projection=record.camera.projection; pilot_camera.keep_aspect=record.camera.keep_aspect
	pilot_camera.size=record.camera.size_m; pilot_camera.near=record.camera.near; pilot_camera.far=record.camera.far
	pilot_world.add_child(pilot_camera); pilot_camera.transform=_farm_transform(record.camera.transform); pilot_camera.current=true
	var camera_exact := pilot_camera.global_transform==_farm_transform(record.camera.transform) and pilot_camera.projection==int(record.camera.projection) and pilot_camera.keep_aspect==int(record.camera.keep_aspect) and pilot_camera.size==_farm_native_real(record.camera.size_m) and pilot_camera.near==_farm_native_real(record.camera.near) and pilot_camera.far==_farm_native_real(record.camera.far)
	farm_native_actual={"caster_count":pilot_casters.size(),"caster_mesh_count":meshes.size(),"bridge_draw_groups":bridge_count,"guard_count":pilot_receivers.size()-1,"GPU_canvas":[active_view.size.x,active_view.size.y],"actual_camera":_pilot_camera_record(),"camera_exact":camera_exact,"sun_shadows_enabled":pilot_sun.shadow_enabled}
	if not _farm_require(camera_exact,"Actual native camera transform/projection exact to frozen primary"): return false
	return _farm_require(active_view.size==Vector2i(24576,16384) and pilot_casters.size()==2578,"Native full-camera replay, no frustum crop")

func _farm_capture(variant: String) -> bool:
	for node: MeshInstance3D in pilot_receivers: node.material_override=farm_old_material if variant=="baseline" else farm_new_material
	for pass_index in (1 if variant=="baseline" else 2):
		if not _farm_require(Time.get_ticks_msec()-farm_started < FARM_BUDGET_MS,"Phase2 shared360s before draw"): return false
		var draw: Dictionary=await _pilot_draw("farm_"+variant+"_"+str(pass_index))
		if not _farm_require(draw.get("fresh_actual_post_draw_observed")==true,"Native whole draw fenced"): return false
		for roi: Dictionary in farm_dirty_plan.tiles:
			if not _farm_require(Time.get_ticks_msec()-farm_started < FARM_BUDGET_MS,"Phase2 shared360s before ROI readback"): return false
			var captured: Dictionary=await _pilot_read_roi(roi,"visual",pilot_output+variant+"_",pass_index,draw)
			if not _farm_require(not captured.is_empty(),"Bounded integer transfer ROI "+error): return false
			captured["variant"]=variant; captured["pass_index"]=pass_index; captured["id"]=roi.id; farm_rows.append(captured)
			if variant=="baseline":
				var old_path:=FARM_ROOT+"chunks/"+String(roi.id)+"_visual.png"
				var old:=Image.load_from_file(old_path)
				var actual:=Image.load_from_file(captured.path)
				if not _farm_require(old!=null and actual!=null and old.get_size()==Vector2i(1536,1024) and actual.get_size()==old.get_size(),"Whole12 old/current baseline canvas"): return false
				old.convert(Image.FORMAT_RGBA8); actual.convert(Image.FORMAT_RGBA8)
				var exact:=old.get_data()==actual.get_data()
				farm_baselines.append({"id":roi.id,"old_path":old_path,"old_sha256":FileAccess.get_sha256(old_path),"actual_path":captured.path,"actual_sha256":captured.sha256,"old_RGBA_sha256":_bytes_sha(old.get_data()),"actual_RGBA_sha256":_bytes_sha(actual.get_data()),"byte_exact":exact,"pixels":1536*1024,"comparison":"FULL_RGBA_ZERO_TOLERANCE"})
				if not _farm_require(exact,"Current formal chunk full RGBA differs from native baseline: "+String(roi.id)): return false
	return true

func _farm_overview() -> bool:
	var old_path:=FARM_ROOT+"overview.png"
	if not _farm_pin(old_path,String(farm_source.asset_sha256.get(old_path,""))): return false
	var old:=Image.load_from_file(old_path)
	if not _farm_require(old!=null and old.get_size()==Vector2i(3072,2048),"Original bounded overview"): return false
	old.convert(Image.FORMAT_RGBA8)
	var overview:=old.duplicate() as Image
	full_chunks.clear(); full_objects.clear()
	for entry: Dictionary in farm_source.chunks: full_chunks.append(entry.duplicate(false))
	for object: Dictionary in farm_source.objects:
		var size:=Vector2i(object.render_size_px[0],object.render_size_px[1])
		var center:=Vector2(object.pos[0]*12288.0,object.pos[1]*8192.0)
		var bounds:=Rect2i(Vector2i((center-Vector2(size)*.5).round()),size)
		var used:=false
		for roi: Dictionary in farm_dirty_plan.tiles:
			if bounds.intersects(roi.rect): used=true; break
		if used and not _farm_pin(object.texture,String(farm_source.asset_sha256.get(object.texture,""))): return false
		full_objects.append(object)
	for captured: Dictionary in farm_rows:
		if captured.variant!="candidate" or captured.pass_index!=0: continue
		for entry: Dictionary in full_chunks:
			if entry.id==captured.id: entry.visual_path=captured.path
	var replaced: Array[String]=[]
	for roi: Dictionary in farm_dirty_plan.tiles:
		if not _farm_require(Time.get_ticks_msec()-farm_started < FARM_BUDGET_MS,"Phase2 shared360s before bounded overview cell"): return false
		# Reuse exact old alpha resize/feet ordering. Only this tile's ground path
		# changes; the old 2687 objects stay the original dictionaries/textures.
		var scene_image: Image=_v7_composite_roi(roi.rect)
		if not _farm_require(scene_image!=null and scene_image.get_size()==Vector2i(1536,1024),"Original independent-body overview composition"): return false
		scene_image.resize(384,256,Image.INTERPOLATE_LANCZOS)
		overview.blit_rect(scene_image,Rect2i(0,0,384,256),Vector2i(int(roi.col)*384,int(roi.row)*256))
		replaced.append(roi.id)
	var cells: Array[Dictionary]=[]
	for row in 8:
		for col in 8:
			var id:="r%d_c%d"%[row,col]
			if replaced.has(id): continue
			var rect:=Rect2i(col*384,row*256,384,256)
			var a:=old.get_region(rect); var b:=overview.get_region(rect)
			var exact:=a.get_data()==b.get_data()
			if not _farm_require(exact,"Original non-dirty overview cell "+id): return false
			cells.append({"id":id,"old_RGBA_sha256":_bytes_sha(a.get_data()),"new_RGBA_sha256":_bytes_sha(b.get_data()),"byte_exact":exact})
	var path:=pilot_output+"overview.png"
	if not _farm_require(overview.save_png(path)==OK,"New bounded candidate overview saved"): return false
	farm_overview_record={"path":path,"sha256":FileAccess.get_sha256(path),"size":[3072,2048],"original_path":old_path,"original_sha256":FileAccess.get_sha256(old_path),"replaced_cells":replaced,"unchanged_cells":cells,"original_object_count":full_objects.size(),"composition":"ORIGINAL_ALPHA_RESIZE_AND_FEET_ORDER_PER1536_TILE_THEN_384x256_LANCZOS","max_CPU_pixels":6291456,"whole_CPU_Image_requested":false}
	full_chunks.clear(); full_objects.clear()
	return true

func _run() -> void:
	farm_started=Time.get_ticks_msec()
	pilot_output="res://build/world_farmland_visual_patch_candidate_v2_20261014/%d_%d/"%[OS.get_process_id(),Time.get_ticks_usec()]
	if not _farm_require(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(pilot_output)),"Fresh candidate-only output required"):
		quit(1); return
	if not _farm_require(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pilot_output))==OK,"Unique phase2 candidate output"):
		quit(1); return
	var prior := false; var platform: Node=root.get_node_or_null("PlatformBridge")
	if platform != null: prior=platform.call("is_checkpoint_saves_suspended"); platform.call("set_checkpoint_saves_suspended",true)
	var ready := _farm_require("--world-farmland-visual-patch-phase2" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless","Explicit GPU phase2 candidate only") and _farm_load()
	if ready:
		ready=_farm_make_world()
		if ready: ready=await _farm_capture("baseline")
		if ready: ready=await _farm_capture("candidate")
	if active_view != null:
		active_view.queue_free(); active_view=null; pilot_world=null
		for frame in 8: await process_frame
	pilot_receivers.clear(); pilot_casters.clear(); farm_old_material=null; farm_new_material=null; pilot_global_mesh=null
	if ready: ready=_farm_overview()
	for path: String in farm_pins: _farm_require(FileAccess.get_sha256(path).to_lower()==farm_pins[path],"Fresh final input unchanged "+path)
	var report: Dictionary={"scope":FARM_SCOPE,"candidate_only":true,"ready":ready,"failures":farm_failures,"source_pins":farm_pins,"rows":farm_rows,"author_audit":farm_author_audit,"material_patch":farm_surface.get("patch_record") if farm_surface != null else {},"old_whole_proof_sha256":FARM_PROOF_SHA,"same_whole_camera":farm_proof.get("worlds",{}).get("primary",{}).get("camera",{}),"caster_count":2578,"caster_mesh_count":18,"bridge_draw_groups":93,"guard_count":4,"memory_guard":pilot_result.get("fresh_preallocation_guards",[]),"GPU_canvas":[24576,16384],"max_CPU_image_pixels":8404992,"nav_rebuilt":false,"full64_rebuilt":false,"Field_loaded":false,"formal_changed":false,"visual_approved":false,"production_approved":false,"elapsed_ms":Time.get_ticks_msec()-farm_started}
	report["shared_budget_ms"]=FARM_BUDGET_MS
	report["expected_native_scope"]={"caster_count":2578,"caster_mesh_count":18,"bridge_draw_groups":93,"guard_count":4,"GPU_canvas":[24576,16384]}
	for key: String in ["caster_count","caster_mesh_count","bridge_draw_groups","guard_count","GPU_canvas"]: report[key]=farm_native_actual.get(key,0 if key!="GPU_canvas" else [])
	report["native_actual"]=farm_native_actual
	report["dirty_plan"]=farm_dirty_plan
	report["baseline_formal"]=farm_baselines
	report["overview"]=farm_overview_record
	report["overview_schema_preflight"]=farm_overview_preflight
	report["baseline_pass_count"]=1; report["candidate_pass_count"]=2
	report["baseline_QA"]={"path":BASELINE_QA_PATH,"sha256":BASELINE_QA_SHA,"scope":farm_baseline_review.get("scope",""),"passed":farm_baseline_review.get("comparisons",[]).size()==2}
	var patch_entries: Array[Dictionary]=[]
	for captured: Dictionary in farm_rows:
		if captured.variant=="candidate" and captured.pass_index==0: patch_entries.append({"id":captured.id,"path":captured.path,"sha256":captured.sha256,"old_path":FARM_ROOT+"chunks/"+String(captured.id)+"_visual.png","logical_rect":captured.logical_rect_px,"draw_scale":1.0})
	report["visual_patch_entries"]=patch_entries
	var validation: Dictionary=FARM_CHECK.new().call("validate",report)
	report["elapsed_ms"]=Time.get_ticks_msec()-farm_started
	_farm_require(Time.get_ticks_msec()-farm_started < FARM_BUDGET_MS,"Independent phase2 shared360s complete validation budget")
	report["validation"]=validation; report["passed"]=ready and farm_failures.is_empty() and validation.get("passed")==true
	var saved := _write_json(pilot_output+"result.json",report)
	_farm_require(saved,"Finite phase2 result saved")
	if platform != null: platform.call("set_checkpoint_saves_suspended",prior)
	print("FARM_VISUAL_PATCH_PHASE2_RESULT="+pilot_output+"result.json passed="+str(report.passed))
	quit(0 if report.passed and saved else 1)
