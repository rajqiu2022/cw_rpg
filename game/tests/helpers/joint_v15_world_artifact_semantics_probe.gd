extends RefCounted
## Independent artifact oracle, NOT a renderer or a production selector. Every
## record is current-byte bound; raw/derived images are reconstructed here.
## Prototype memoization is by the exact evidence bytes, not by instance count.
const ROOT := "res://art/maps/world_map_v15_complete_v6/"
const PROTOCOL := "COHERENT_WHOLE_FIXED_CAMERA_INTEGER_TEXEL_ROI_V1_FULL"
const ROI_CAP: int=8404992
const TRANSFER: String="res://shaders/world_v15_native_texel_transfer.gdshader"
const TRANSFER_SHA: String="4997274fc2a62404235a69117785448c2ec65cc50667a4353d27c456d33ec47e"
const WHOLE_ROLES: Array[String]=["visual","shadow_off","land","raw_walk","walk"]
const SIZE := Vector2(12288,8192)
const TILE := Vector2i(1536,1024)
const PPM: float=102.4
const Z_PPM: float=102.4*0.7071067811865476
const ALPHA_ID := "RGBAF_PREMULTIPLIED_LANCZOS_UNPREMULTIPLY_V1"
const ALPHA_UNPREMULTIPLY_EPSILON: float=0.00001
const GEOMETRY := preload("res://tests/helpers/joint_v15_world_geometry_phase.gd")
const TREE := "res://art/maps/world_map_v14/entities/tree_small02_native_hybrid.res"
const TREE_SOURCE := "res://art/external/polyhaven/tree_small_02/tree_small_02_1k.gltf"
const BOULDER := "res://art/external/polyhaven/boulder_01/boulder_01_1k.gltf"
const HERB := "res://art/external/polyhaven/shrub_03/shrub_03_1k.gltf"
const BAMBOO := "res://art/external/opengameart/yughues_bamboo_v1/derived/bamboo_native_godot462.mesh"
const BAMBOO_RAW := "res://art/external/opengameart/yughues_bamboo_v1/original/Bamboo 01.obj"
const ECOLOGY_PROFILES: Array[String]=["snow_rock_ridge","western_limestone","northeastern_pine_forest","luoyang_fields","central_meadow","western_forest","southern_bamboo","river_fields","southeastern_marsh"]
var phase: RefCounted
var tree: SceneTree
var geometry: RefCounted=GEOMETRY.new()
var catalog: Dictionary={}
var checks: int=0
var failures: int=0
var records: Dictionary={"chunks":[],"prototypes":[],"instances":[],"decks":[],"ecology":[]}
var decoded_models: Dictionary={}
var prototype_checks: Dictionary={}
var support_checks: Dictionary={}
var whole_capture: Dictionary={}
var whole_windows: Dictionary={}
var whole_complete: bool=false

func _sha(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new()
	if context.start(HashingContext.HASH_SHA256)!=OK or context.update(bytes)!=OK: return ""
	return context.finish().hex_encode()

func _integer(value: Variant,minimum: int=0) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and float(value)>=minimum and float(value)==floorf(float(value))

func _numeric_equal(actual: Variant,expected: Variant) -> bool:
	# Exact JSON numeric representation equality, NEVER an epsilon or pixel rule.
	if typeof(expected) in [TYPE_INT,TYPE_FLOAT]: return typeof(actual) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(actual)) and float(actual)==float(expected)
	if expected is Array:
		if not actual is Array or actual.size()!=expected.size(): return false
		for n in expected.size():
			if not _numeric_equal(actual[n],expected[n]): return false
		return true
	if expected is Dictionary:
		if not actual is Dictionary or actual.size()!=expected.size(): return false
		for key: Variant in expected:
			if not actual.has(key) or not _numeric_equal(actual[key],expected[key]): return false
		return true
	return typeof(actual)==typeof(expected) and actual==expected

func _near_number(value: Variant,expected: float) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and absf(float(value)-expected)<=.0001

func _camera(value: Variant,factor: int) -> bool:
	if not value is Dictionary: return false
	var c: Dictionary=value
	if c.get("projection")!=Camera3D.PROJECTION_ORTHOGONAL or c.get("keep_aspect")!=Camera3D.KEEP_HEIGHT or c.get("size_m")!=80 or _p(c.get("whole_logical_canvas"))!=SIZE or _p(c.get("whole_visual_native_canvas"))!=SIZE*2 or _p(c.get("actual_current_GPU_canvas"))!=SIZE*factor or _p(c.get("source_center_px"))!=SIZE*.5: return false
	if c.get("PPM_X")!=PPM or not _near_number(c.get("PPM_source_Z"),Z_PPM) or not _near_number(c.get("near"),.05) or c.get("far")!=200 or c.get("shadow_max_distance")!=160 or c.get("directional_shadow_mode")!=DirectionalLight3D.SHADOW_ORTHOGONAL or c.get("shadow_normal_bias")!=2: return false
	var t: Variant=c.get("transform")
	if not t is Dictionary or not t.get("basis_columns") is Array or t.basis_columns.size()!=3: return false
	var expected: Array[Vector3]=[Vector3.RIGHT,Vector3(0,sqrt(.5),-sqrt(.5)),Vector3(0,sqrt(.5),sqrt(.5))]
	if not _v(t.get("origin")).is_finite() or _v(t.origin).distance_to(Vector3(0,60,60))>.0001: return false
	for n in 3:
		var actual: Vector3=_v(t.basis_columns[n])
		if not actual.is_finite() or actual.distance_to(expected[n])>.0001: return false
	return _v(c.get("light_rotation_degrees")).is_finite() and _v(c.light_rotation_degrees).distance_to(Vector3(-55,-34,0))<=.0001 and is_finite(float(c.get("light_energy",NAN))) and absf(float(c.light_energy)-.85)<=.0001

func _pass(value: Variant,id: String,canvas: Vector2) -> bool:
	if not value is Dictionary: return _check(false,"typed actual whole draw "+id)
	var d: Dictionary=value
	var good: bool=d.get("id")==id and d.get("fresh_actual_post_draw_observed")==true and _p(d.get("whole_native_canvas"))==canvas and d.get("frozen_update_mode")==SubViewport.UPDATE_DISABLED and _integer(d.get("texture_rid"),1) and _integer(d.get("viewport_rid"),1) and _integer(d.get("process_before")) and _integer(d.get("process_after")) and float(d.get("process_after",-1))>float(d.get("process_before",-1))
	var fences: Variant=d.get("post_draw_fences")
	if not fences is Array or fences.size()!=8: return _check(false,"eight real postdraw fences "+id)
	var last_sequence: float=-1
	var last_frame: float=-1
	for item: Variant in fences:
		if not item is Dictionary: good=false; continue
		if not _integer(item.get("sequence"),1) or not _integer(item.get("process_frame")) or not _integer(item.get("ticks_usec")): good=false; continue
		good=good and float(item.sequence)>last_sequence and float(item.process_frame)>=last_frame and item.get("update_request")==SubViewport.UPDATE_ONCE
		last_sequence=float(item.get("sequence",-1))
		last_frame=float(item.get("process_frame",-1))
	return _check(good and d.get("fence_sequence")==last_sequence,"actual whole UPDATE_ONCE then frozen draw identity/fences "+id)

func _enumerate_windows() -> Dictionary:
	var result: Dictionary={}
	for row in 8:
		for col in 8:
			var id: String="r%d_c%d"%[row,col]
			result[id]=Rect2i(Vector2i(col*TILE.x,row*TILE.y),TILE)
			if col<7: result[id+"--r%d_c%d"%[row,col+1]]=Rect2i((col+1)*TILE.x-16,row*TILE.y,32,TILE.y)
			if row<7: result[id+"--r%d_c%d"%[row+1,col]]=Rect2i(col*TILE.x,(row+1)*TILE.y-16,TILE.x,32)
	return result

func _whole_roi(value: Variant,rect: Rect2i,role: String,native: Dictionary,label: String) -> bool:
	if not value is Dictionary: return _check(false,"typed actual integer ROI "+label)
	var record: Dictionary=value
	var before: int=failures
	var factor: int=2 if role in ["visual","shadow_off"] else 1
	var halo: Rect2i=rect.grow(96).intersection(Rect2i(Vector2i.ZERO,Vector2i(SIZE)))
	var native_rect:=Rect2i(halo.position*factor,halo.size*factor)
	var crop:=Rect2i(rect.position-halo.position,rect.size)
	if not _check(native_rect.size.x*native_rect.size.y<=ROI_CAP,"exact approved bounded ROI ceiling "+label): return false
	var repeat: Variant=record.get("repeat_transfer_evidence")
	if not _check(repeat is Dictionary,"second genuine GPU integer-transfer record "+label): return false
	for n in 2:
		var r: Dictionary=record if n==0 else repeat
		var draw: Dictionary=native.passes[n]
		var shape: bool=_rect(r.get("logical_rect_px"))==rect and _rect(r.get("global_native_readback_rect_px"))==native_rect and _rect(r.get("logical_overscan_rect_px"))==halo and _rect(r.get("local_logical_crop_px"))==crop and _p(r.get("actual_readback_canvas"))==Vector2(native_rect.size) and _p(r.get("actual_whole_GPU_canvas"))==SIZE*factor and r.get("factor")==factor
		if not _check(shape and r.get("96px_kernel_halo_actual_boundaries_clipped_to_whole")==true and r.get("gamma_correction")==false and r.get("actual_transfer_view_released")==true,"integer global native ROI/actual clipped halo/crop; no gamma or whole CPU readback "+label): continue
		var shader: Variant=r.get("transfer_shader")
		var source_draw: bool=r.get("source_draw")==draw and r.get("source_primary_texture_rid")==draw.get("texture_rid") and _integer(r.get("destination_texture_rid"),1) and _integer(r.get("actual_transfer_post_draw_fence_sequence"),1) and float(r.get("actual_transfer_post_draw_fence_sequence",-1))>float(draw.get("fence_sequence",-1))
		var identity: String="OPAQUE_RGBA8_LANCZOS_ROI96_V1" if factor==2 else "NONE_NATIVE_MSAA0"
		if not _check(source_draw and shader is Dictionary and shader.get("path")==TRANSFER and String(shader.get("sha256","")).to_lower()==TRANSFER_SHA and _bound(TRANSFER,TRANSFER_SHA) and r.get("resampling_identity")==identity,"actual fenced whole source RID→texelFetch target and exact recipe "+label): continue
		var raw_path: String=String(r.get("raw_path",""))
		var path: String=String(r.get("path",""))
		if not _check(raw_path.begins_with(ROOT) and path.begins_with(ROOT) and raw_path!=path and String(r.get("raw_sha256","")).length()==64 and String(r.get("sha256","")).length()==64 and _bound(raw_path,String(r.get("raw_sha256",""))) and _bound(path,String(r.get("sha256",""))),"actual raw/logical PNG bytes bound, not metadata-only "+label): continue
		var raw: Image=Image.load_from_file(raw_path)
		var output: Image=Image.load_from_file(path)
		if not _check(raw!=null and output!=null and raw.get_size()==native_rect.size and output.get_size()==rect.size and raw.get_format()==Image.FORMAT_RGBA8 and output.get_format()==Image.FORMAT_RGBA8 and not raw.has_mipmaps() and not output.has_mipmaps(),"original decoded RGBA8 dimensions/format, no representation conversion "+label): continue
		var bytes: PackedByteArray=raw.get_data()
		_check(_sha(bytes)==r.get("raw_RGBA_sha256") and _sha(output.get_data())==r.get("logical_RGBA_sha256"),"independent decoded raw/logical RGBA SHA "+label)
		var pixels_good: bool=raw.detect_alpha()==Image.ALPHA_NONE
		if factor==1:
			# Little-endian RGBA8 words: exact opaque black/white only. Packed
			# native count scans ALL pixels without billions of GDScript calls.
			var words: PackedInt32Array=bytes.to_int32_array()
			pixels_good=pixels_good and words.size()*4==bytes.size() and words.count(-1)+words.count(-16777216)==words.size()
		_check(pixels_good,"every original pixel opaque; native authority RGB exactly binary, no threshold "+label)
		# Independent original-image reconstruction; never call a capture helper.
		if factor==2: raw.resize(halo.size.x,halo.size.y,Image.INTERPOLATE_LANCZOS)
		_check(raw.get_region(crop).get_data()==output.get_data(),"independent exact Lanczos once then integer crop / native binary noresize "+label)
	var raw_repeat: String=String(record.get("raw_repeat_path",""))
	var logical_repeat: String=String(record.get("repeat_path",""))
	_check(raw_repeat==String(repeat.get("raw_path","")) and logical_repeat==String(repeat.get("path","")),"repeat filenames identify actual second transport "+label)
	# Both independent passes were fully decoded above. Reuse only their proven
	# decoded-byte SHA, then independently compare the ORIGINAL PNG byte arrays;
	# this avoids a redundant third decoding, never a repeat or pixel omission.
	for keys: Array in [["raw_path","raw_repeat_path","raw_RGBA_sha256"],["path","repeat_path","logical_RGBA_sha256"]]:
		var first: String=String(record.get(keys[0],""))
		var second: String=String(record.get(keys[1],""))
		_check(first!=second and _bound(first) and _bound(second) and record.get(keys[2])==repeat.get(keys[2]) and FileAccess.get_file_as_bytes(first)==FileAccess.get_file_as_bytes(second),"distinct actual raw/logical passes decoded RGBA and original PNG byteexact "+label+"/"+String(keys[0]))
	return failures==before

func _whole(manifest: Dictionary) -> void:
	var before: int=failures
	var binding: Variant=manifest.get("whole_actual_capture")
	if not _check(binding is Dictionary and binding.get("path")==ROOT+"whole_actual_capture.json" and String(binding.get("sha256","")).length()==64 and _bound(String(binding.get("path","")),String(binding.get("sha256",""))),"new FULL whole report current SHA"): return
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(binding.path))
	if not _check(data is Dictionary,"actual whole report dictionary"): return
	whole_capture=data
	if not _check(whole_capture.get("capture_protocol")==PROTOCOL and whole_capture.get("scope")=="FULL64_112SEAMS_NEW_PROTOCOL_NOT_FORMAL_APPROVED" and whole_capture.get("status")=="FULL64_112SEAMS_NEW_PROTOCOL_TECHNICAL_PASS_REQUIRES_ROOT_VISUAL_REVIEW" and whole_capture.get("chunk_count_required")==64 and whole_capture.get("seam_count_required")==112 and whole_capture.get("input_hashes_unchanged_after")==true and whole_capture.get("no_legacy_frustum_seam_pass_claim")==true and whole_capture.get("whole_cpu_image_requested")==false and whole_capture.get("whole_cpu_image_allowed")==false and whole_capture.get("maximum_CPU_ROI_pixels")==ROI_CAP,"FULL protocol/scope/64+112 with exact CPU ceiling; bounded pilot is not FULL"): return
	var expected_budget: Dictionary={"previous_pilot_pixels":8388608,"maximum_pixels":8404992,"maximum_native_canvas":[3456,2432],"logical_tile":[1536,1024],"logical_halo_px":96,"ssaa_scale":2,"additional_pixels":16384,"additional_RGBA_bytes":65536,"whole_CPU_Image_allowed":false}
	_check(_numeric_equal(whole_capture.get("CPU_ROI_budget"),expected_budget),"new FULL explicit memory delta, not silently relabelled pilot cap")
	var executed: Variant=whole_capture.get("executed_builder")
	var authorization: Variant=whole_capture.get("authorization")
	if not _check(executed is Dictionary and executed.get("path")=="res://scripts/dev/build_world_map_v15_coherent_whole_v6_full.gd" and String(executed.get("sha256","")).length()==64 and _bound(executed.path,String(executed.get("sha256",""))) and authorization is Dictionary and String(authorization.get("sha256","")).length()==64 and _bound(String(authorization.get("path","")),String(authorization.get("sha256",""))),"exact executed FULL source and actual authorization bytes"): return
	var auth: Variant=JSON.parse_string(FileAccess.get_file_as_string(authorization.path))
	_check(auth is Dictionary and auth.get("approved")==true and auth.get("scope")==PROTOCOL and auth.get("builder_path")==executed.path and auth.get("builder_sha256")==executed.sha256 and auth.get("output_root")==ROOT and auth.get("allow_full64")==true and auth.get("memory_budget_approved")==true and auth.get("maximum_cpu_roi_pixels")==ROI_CAP and _numeric_equal(auth.get("CPU_ROI_budget"),expected_budget) and auth.get("CPU_whole_402M_Image_allowed")==false,"root FULL authorization explicitly binds actual source/cap and forbids whole CPU Image")
	var worlds: Variant=whole_capture.get("worlds")
	if not _check(worlds is Dictionary and worlds.size()==2 and worlds.get("primary") is Dictionary and worlds.get("reference") is Dictionary,"exact two independent typed whole-world identities"): return
	var guards: Variant=whole_capture.get("fresh_preallocation_guards")
	var history: Variant=whole_capture.get("actual_memory_history")
	if not _check(guards is Array and guards.size()==2 and history is Dictionary and history.get("valid")==true,"both actual whole allocations have fresh guards and bound actual memory history"): return
	var guard_ids: Dictionary={}
	for guard: Variant in guards:
		if not _check(guard is Dictionary and guard.get("world_identity") in ["primary","reference"] and not guard_ids.has(guard.get("world_identity")),"unique typed primary/reference preallocation guard"): continue
		guard_ids[guard.world_identity]=true
		var actual: Variant=guard.get("actual_fresh_queries")
		_check(guard.get("passed")==true and guard.get("allocation_requested_after_guard")==true and guard.get("no_resolution_or_SSAA_downgrade")==true and actual is Dictionary and actual.get("valid")==true and actual.get("gpu_uuid")==history.get("gpu_uuid") and _integer(guard.get("vram_required_bytes"),1) and _integer(guard.get("host_RAM_required_bytes"),1) and _integer(actual.get("vram_free_bytes")) and _integer(actual.get("host_free_bytes")) and float(actual.get("vram_free_bytes",-1))>=float(guard.get("vram_required_bytes",INF)) and float(actual.get("host_free_bytes",-1))>=float(guard.get("host_RAM_required_bytes",INF)),"actual preallocation capacity/fresh adapter and no resolution downgrade "+String(guard.world_identity))
	_check(guard_ids.size()==2,"each fresh whole-world allocation has its own guard")
	whole_windows=_enumerate_windows()
	var completed: int=0
	for identity: String in ["primary","reference"]:
		var w: Variant=worlds[identity]
		if not _check(w is Dictionary and w.get("identity")==identity and w.get("actual_world_released_before_next")==true and _integer(w.get("world_node_instance_id"),1) and _integer(w.get("viewport_instance_id"),1) and _integer(w.get("world_3d_instance_id"),1) and _camera(w.get("camera"),2) and w.get("roles") is Dictionary and w.roles.size()==5,"fresh true World3D/viewport/whole camera released before next "+identity): continue
		var coverage: Variant=w.get("coverage")
		_check(coverage is Dictionary and coverage.get("passed")==true and coverage.get("entire_canvas_covered")==true and _integer(coverage.get("actual_receiver_vertices"),1) and _integer(coverage.get("actual_caster_unique_draw_vertices_across_instances"),1) and coverage.get("shadow_max_actual_m")==160 and is_finite(float(coverage.get("max_actual_source_projection_error_px",NAN))) and float(coverage.get("max_actual_source_projection_error_px",INF))<=.01,"actual full receiver/native casters/projection contract "+identity)
		for role: String in WHOLE_ROLES:
			var r: Variant=w.roles.get(role)
			var factor: int=2 if role in ["visual","shadow_off"] else 1
			if not _check(r is Dictionary and _p(r.get("actual_native_canvas"))==SIZE*factor and _camera(r.get("frozen_camera_projection"),factor) and r.get("MSAA_3D_actual")==0 and r.get("MSAA_2D_actual")==0 and r.get("passes") is Array and r.passes.size()==2 and r.get("windows") is Dictionary and r.windows.size()==176,"five-role actual camera/native canvas and 2 draws/176 ROIs "+identity+"/"+role): continue
			var draws_ok: bool=true
			for n in 2: draws_ok=_pass(r.passes[n],identity+"_"+role+"_"+str(n),SIZE*factor) and draws_ok
			if not draws_ok: continue
			_check(float(r.passes[1].process_before)>float(r.passes[0].process_after) and float(r.passes[1].fence_sequence)>float(r.passes[0].fence_sequence),"repeat is later actual fenced draw, never file copy "+identity+"/"+role)
			for id: String in whole_windows:
				if _whole_roi(r.windows.get(id),whole_windows[id],role,r,identity+"/"+role+"/"+id): completed+=1
	for key: String in ["world_node_instance_id","viewport_instance_id","world_3d_instance_id"]:
		_check(worlds.primary.get(key)!=worlds.reference.get(key),"second actual world has distinct "+key)
	if completed==2*5*176:
		for role: String in WHOLE_ROLES:
			for id: String in whole_windows:
				var a: Dictionary=worlds.primary.roles[role].windows[id]
				var b: Dictionary=worlds.reference.roles[role].windows[id]
				var matched: bool=a.path!=b.path and a.raw_path!=b.raw_path
				# Every raw/logical source in both worlds has already been decoded
				# and independently reconstructed. Compare those proven RGBA hashes
				# plus each original PNG byte array; do not allocate a whole Image.
				for keys: Array in [["path","logical_RGBA_sha256"],["raw_path","raw_RGBA_sha256"]]:
					matched=matched and a.get(keys[1])==b.get(keys[1]) and FileAccess.get_file_as_bytes(a[keys[0]])==FileAccess.get_file_as_bytes(b[keys[0]])
				_check(matched,"two fresh worlds same global native/raw and logical PNG/RGBA byteexact, zero tolerance "+role+"/"+id)
	_check(completed==1760,"all2 worlds×5 roles×176 windows independently reconstructed twice")
	whole_complete=failures==before
	records["whole"]={"path":binding.path,"sha256":binding.sha256,"completed_windows":completed,"required_windows":1760,"pixel_tolerance":0,"local_frustum_authority_claimed":false,"complete":whole_complete}

func _check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failures+=1
	phase.call("_check",ok,"world actual artifact: "+label)
	return ok

func _p(v: Variant) -> Vector2:
	if v is Vector2: return v
	if v is Array and v.size()==2: return Vector2(float(v[0]),float(v[1]))
	return Vector2(INF,INF)

func _v(v: Variant) -> Vector3:
	if v is Array and v.size()==3: return Vector3(float(v[0]),float(v[1]),float(v[2]))
	return Vector3(INF,INF,INF)

func _bound(path: String,expected: String="") -> bool:
	return path.begins_with("res://") and not ".." in path and catalog.has(path) and String(catalog[path]).length()==64 and FileAccess.file_exists(path) and FileAccess.get_sha256(path).to_lower()==String(catalog[path]).to_lower() and (expected.is_empty() or expected.to_lower()==String(catalog[path]).to_lower())

func _image(path: String) -> Image:
	if not _check(_bound(path),"actual image SHA in fixed full catalog: "+path): return null
	var image: Image=Image.load_from_file(path)
	if not _check(image!=null,"actual image independently decoded: "+path): return null
	image.convert(Image.FORMAT_RGBA8)
	return image

func _rect(value: Variant) -> Rect2i:
	if not value is Array or value.size()!=4: return Rect2i()
	for n: Variant in value:
		if typeof(n) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(n)) or float(n)!=float(int(n)): return Rect2i()
	return Rect2i(int(value[0]),int(value[1]),int(value[2]),int(value[3]))

func _alpha_resize(raw: Image,logical: Vector2i) -> Image:
	# Independent packed Float32 reconstruction. This epsilon is a declared
	# algorithm operation, NOT an image comparison tolerance or alpha-hit waiver.
	# Do not call any capture helper. Low/negative Lanczos alpha clears all RGBA.
	var working: Image=raw.duplicate() as Image
	working.convert(Image.FORMAT_RGBAF)
	var packed: PackedByteArray=working.get_data()
	for n in range(0,packed.size(),16):
		var a: float=packed.decode_float(n+12)
		for channel in 3: packed.encode_float(n+channel*4,packed.decode_float(n+channel*4)*a)
	working=Image.create_from_data(raw.get_width(),raw.get_height(),false,Image.FORMAT_RGBAF,packed)
	working.resize(logical.x,logical.y,Image.INTERPOLATE_LANCZOS)
	packed=working.get_data()
	for n in range(0,packed.size(),16):
		var a: float=packed.decode_float(n+12)
		if a>ALPHA_UNPREMULTIPLY_EPSILON:
			for channel in 3: packed.encode_float(n+channel*4,packed.decode_float(n+channel*4)/a)
		else:
			for channel in 4: packed.encode_float(n+channel*4,0.)
	working=Image.create_from_data(logical.x,logical.y,false,Image.FORMAT_RGBAF,packed)
	working.convert(Image.FORMAT_RGBA8)
	return working

func _raw_pair(path: String,repeat_path: String,size: Vector2i) -> Image:
	var image: Image=_image(path)
	var repeat: Image=_image(repeat_path)
	if image==null or repeat==null: return null
	if not _check(path!=repeat_path and image.get_size()==size and repeat.get_size()==size and image.get_data()==repeat.get_data() and FileAccess.get_file_as_bytes(path)==FileAccess.get_file_as_bytes(repeat_path),"separate actual raw PNG and RGBA exact repeat, no tolerance: "+path): return null
	return image

func _chunk(entry: Dictionary) -> void:
	var id: String=String(entry.get("id",""))
	var capture: Variant=entry.get("capture")
	if not _check(capture is Dictionary,"actual full chunk capture record: "+id): return
	var c: Dictionary=capture
	if not _check(whole_complete and whole_windows.has(id) and c.get("capture_protocol")==PROTOCOL and c.get("capture_role")=="primary" and c.get("window_id")==id and _p(c.get("actual_native_canvas"))==SIZE*2 and _p(c.get("actual_logical_canvas"))==Vector2(TILE) and c.get("binary_MSAA")==0 and c.get("binary_resized")==false and c.get("whole_CPU_Image_requested")==false,"runtime tile originates in verified fixed whole primary draw, not local viewport "+id): return
	var w: Dictionary=whole_capture.worlds.primary
	_check(c.get("actual_camera")==w.camera,"tile camera equals actual whole camera; not re-labelled local frustum "+id)
	var before: int=failures
	var completed: Array[String]=[]
	for role: String in WHOLE_ROLES:
		var r: Dictionary=w.roles[role].windows[id]
		if not _check(c.get("roles",{}).get(role)==r,"runtime alias references exact verified whole ROI record "+id+"/"+role): continue
		var path: String=ROOT+"chunks/"+id+"_"+role+".png"
		var repeat_path: String=ROOT+"chunks/"+id+"_"+role+"_repeat.png"
		var output: Image=_raw_pair(path,repeat_path,TILE)
		var original: Image=_image(r.path)
		var exact: bool=output!=null and original!=null and c.get(role+"_path")==path and entry.get(role+"_path")==path and c.get(role+"_repeat_path")==repeat_path and c.get("outputs_sha256",{}).get(path)==catalog.get(path) and c.get("outputs_sha256",{}).get(repeat_path)==catalog.get(repeat_path) and output.get_data()==original.get_data() and FileAccess.get_file_as_bytes(path)==FileAccess.get_file_as_bytes(r.path) and FileAccess.get_file_as_bytes(repeat_path)==FileAccess.get_file_as_bytes(r.repeat_path)
		_check(exact,"distinct runtime file is byteexact verified whole ROI copy, no extra capture claim "+id+"/"+role)
		if exact: completed.append(role)
	var visual: Image=_image(ROOT+"chunks/"+id+"_visual.png")
	var on: Image=_image(String(w.roles.visual.windows[id].path))
	_check(visual!=null and on!=null and visual.get_data()==on.get_data(),"runtime visual is actual primary ON ground; v6 has no invented shadow_on alias file: "+id)
	_check(w.roles.visual.get("caster_actual_visible")==true and w.roles.shadow_off.get("caster_actual_visible")==false and w.roles.visual.get("caster_shadow_setting_actual")==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY,"actual independent native ON/OFF caster pass is SHADOWS_ONLY; no body baked into ground "+id)
	records.chunks.append({"id":id,"exact_roles":completed,"actual_whole_GPU_native_size":[24576,16384],"actual_runtime_size":[TILE.x,TILE.y],"complete":completed.size()==5 and failures==before,"capture":c.duplicate(true)})

func _collect(node: Node,output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D: output.append(node as MeshInstance3D)
	for child: Node in node.get_children(): _collect(child,output)

func _raw_meshes(path: String) -> Array[ArrayMesh]:
	if decoded_models.has(path): return decoded_models[path]
	var meshes: Array[ArrayMesh]=[]
	if not _check(_bound(path),"original actual model source bytes bound: "+path): return meshes
	var document:=GLTFDocument.new()
	var state:=GLTFState.new()
	if not _check(document.append_from_file(path,state)==OK,"independent raw GLTFDocument import"): return meshes
	var scene: Node=document.generate_scene(state)
	if not _check(scene!=null,"original raw source scene exists"): return meshes
	var nodes: Array[MeshInstance3D]=[]
	_collect(scene,nodes)
	for node: MeshInstance3D in nodes:
		if node.mesh is ArrayMesh: meshes.append(node.mesh as ArrayMesh)
	nodes.clear()
	scene.free()
	decoded_models[path]=meshes
	return meshes

func _draw_mesh(kind: String,pose: int,record: Dictionary) -> ArrayMesh:
	var path: String=String(record.get("draw_mesh_source",""))
	var expected: String=TREE if kind=="tree" else BAMBOO if kind=="bamboo" else BOULDER if kind=="boulder" else HERB if kind=="herb" else ""
	if not _check(not expected.is_empty() and path==expected and _bound(path,String(record.get("draw_mesh_source_sha256",""))),"draw mesh source is actual declared species, no herb source mislabeled as Boulder"): return null
	if kind in ["herb","boulder"]:
		var originals: Array[ArrayMesh]=_raw_meshes(path)
		var selected: int=pose%4 if kind=="herb" else 0
		if not _check(pose>=0 and originals.size()==(4 if kind=="herb" else 1) and selected>=0 and selected<originals.size(),"actual original mesh variant count/index"): return null
		var control:=ArrayMesh.new()
		for surface in originals[selected].get_surface_count(): control.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,originals[selected].surface_get_arrays(surface))
		return control
	var stored: ArrayMesh=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	if not _check(stored!=null,"actual saved native geometry"): return null
	if kind=="bamboo":
		if not _check(_bound(BAMBOO_RAW),"licensed original Bamboo OBJ bytes bound, not procedural substitute"): return null
		var raw_obj: ArrayMesh=ResourceLoader.load(BAMBOO_RAW,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
		if not _check(raw_obj!=null and raw_obj.get_surface_count()==stored.get_surface_count(),"independent normal Godot OBJ source import matches stored derived mesh surfaces"): return null
		for surface in stored.get_surface_count():
			var actual_control:=ArrayMesh.new()
			actual_control.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,stored.surface_get_arrays(surface))
			var control:=ArrayMesh.new()
			control.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,raw_obj.surface_get_arrays(surface))
			var expected_arrays: Array=control.surface_get_arrays(0)
			var actual: Array=actual_control.surface_get_arrays(0)
			for slot in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_INDEX]: _check(expected_arrays[slot].to_byte_array()==actual[slot].to_byte_array(),"bamboo original arrays same-native packing exact slot "+str(slot))
	else:
		var originals: Array[ArrayMesh]=_raw_meshes(TREE_SOURCE)
		if not _check(originals.size()==1 and originals[0].get_surface_count()==stored.get_surface_count(),"original mature tree GLTF surfaces bound before hybrid check"): return null
		var original: ArrayMesh=originals[0]
		var importer:=ImporterMesh.new()
		for surface in original.get_surface_count(): importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,original.surface_get_arrays(surface),[],{},original.surface_get_material(surface))
		importer.generate_lods(60.,60.,[])
		var independent:=ArrayMesh.new()
		for surface in original.get_surface_count():
			var arrays: Array=original.surface_get_arrays(surface).duplicate()
			if surface!=1:
				if not _check(importer.get_surface_lod_count(surface)>2,"native branch/trunk actual LOD2 exists"): return null
				arrays[Mesh.ARRAY_INDEX]=importer.get_surface_lod_indices(surface,2)
			independent.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			var expected_arrays: Array=independent.surface_get_arrays(surface)
			var actual: Array=stored.surface_get_arrays(surface)
			for slot in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_INDEX]: _check(expected_arrays[slot].to_byte_array()==actual[slot].to_byte_array(),"hybrid leaves sourceL0/branch-trunk nativeLOD2 with exact same-native packing "+str(surface)+"/"+str(slot))
	return stored

func _camera_foot(record: Dictionary,canvas: Vector2i,crop: Rect2i) -> Vector2:
	var data: Variant=record.get("camera")
	if not _check(data is Dictionary and data.get("projection")==Camera3D.PROJECTION_ORTHOGONAL,"actual prototype orthographic camera properties"): return Vector2(INF,INF)
	var columns: Variant=data.get("basis_columns")
	if not _check(columns is Array and columns.size()==3,"actual full camera basis"): return Vector2(INF,INF)
	var viewport:=SubViewport.new()
	viewport.size=canvas
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	viewport.own_world_3d=true
	tree.root.add_child(viewport)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=float(data.get("size",NAN))
	viewport.add_child(camera)
	camera.transform=Transform3D(Basis(_v(columns[0]),_v(columns[1]),_v(columns[2])),_v(data.get("position")))
	camera.current=true
	var foot: Vector2=camera.unproject_position(Vector3.ZERO)/2-Vector2(crop.position)
	viewport.free()
	return foot

func _prototype(entry: Dictionary) -> Dictionary:
	var raw_record: Variant=entry.get("prototype_actual_sourcebody_evidence")
	if not _check(raw_record is Dictionary,"native object actual original prototype evidence: "+String(entry.get("id",""))): return {}
	var r: Dictionary=raw_record
	var key: String=JSON.stringify(r).sha256_text()
	if prototype_checks.has(key): return prototype_checks[key]
	var first_fail: int=failures
	var logical:=Vector2i(_p(r.get("logical_canvas")))
	var canvas:=Vector2i(_p(r.get("actual_canvas")))
	var crop: Rect2i=_rect(r.get("crop_rect_px"))
	if not _check(logical==Vector2i(512,512) and canvas==logical*2 and r.get("alpha_algorithm")==ALPHA_ID and r.get("alpha_unpremultiply_epsilon")==ALPHA_UNPREMULTIPLY_EPSILON and Rect2i(Vector2i.ZERO,logical).encloses(crop) and crop.size.x>0,"exact native alpha-aware identity/declared epsilon/canvas/crop, not implicit algorithm fallback"): return {}
	var raw: Image=_raw_pair(String(r.get("sourcebody_raw","")),String(r.get("sourcebody_repeat","")),canvas)
	var body: Image=_image(String(r.get("texture","")))
	if raw==null or body==null: return {}
	var rebuilt: Image=_alpha_resize(raw,logical)
	_check(rebuilt.get_region(crop).get_data()==body.get_data() and body.get_size()==crop.size,"independent alpha-aware packed-float SSAA crop byte exact")
	var used: Rect2i=rebuilt.get_used_rect()
	_check(used.size!=Vector2i.ZERO and used.position.x>=8 and used.position.y>=8 and used.end.x<=504 and used.end.y<=504 and crop==Rect2i(used.position-Vector2i(4,4),used.size+Vector2i(8,8)),"actual transparent support and exact dynamic safety crop")
	var foot: Vector2=_camera_foot(r,canvas,crop)
	_check(foot.is_finite() and foot.distance_to(_p(r.get("foot_uv"))*Vector2(crop.size))<.01,"actual Camera3D projection /2 yields exact logical cropped foot within .01px original budget")
	var columns: Variant=r.get("basis_columns")
	if not _check(columns is Array and columns.size()==3,"actual model transform full basis"): return {}
	var basis:=Basis(_v(columns[0]),_v(columns[1]),_v(columns[2]))
	var kind: String=String(entry.get("kind",""))
	var pose: int=int(entry.get("pose",-1))
	if not _check(pose>=0 and pose<3,"explicit approved prototype pose domain, no unsupported source variant"): return {}
	var metric_scale: float=[.19,.20,.20][pose] if kind=="tree" else .005 if kind=="bamboo" else [.85,1.05,.70][pose] if kind=="boulder" else .65 if kind=="herb" else NAN
	var independent_basis:=Basis(Vector3.UP,deg_to_rad(25.+pose*65.)).scaled(Vector3.ONE*metric_scale)
	_check(is_finite(metric_scale) and float(r.get("metric_scale",NAN))==metric_scale and basis.x.distance_to(independent_basis.x)<.0001 and basis.y.distance_to(independent_basis.y)<.0001 and basis.z.distance_to(independent_basis.z)<.0001,"source-authorized actual metric scale/yaw independently reconstruct all model basis columns")
	var mesh: ArrayMesh=_draw_mesh(kind,pose,r)
	if mesh==null: return {}
	var minimum:=Vector3(INF,INF,INF)
	var maximum:=Vector3(-INF,-INF,-INF)
	var points:=PackedVector3Array()
	var valid_indices: bool=true
	for surface in mesh.get_surface_count():
		var arrays: Array=mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		var seen: Dictionary={}
		for index in indices:
			if index<0 or index>=vertices.size(): valid_indices=false; continue
			if seen.has(index): continue
			seen[index]=true
			var p: Vector3=basis*vertices[index]
			points.append(p)
			minimum=minimum.min(p)
			maximum=maximum.max(p)
	var sum: float=0
	var front: float=-INF
	var count: int=0
	for p: Vector3 in points:
		if p.y<=minimum.y+(maximum.y-minimum.y)*.02: sum+=p.x; front=maxf(front,p.z); count+=1
	var support:=Vector3(sum/count if count>0 else INF,minimum.y,front)
	_check(valid_indices and not points.is_empty(),"all actual used draw indices address source vertices (aggregate, no millions of artificial check credits)")
	var bounds: Variant=r.get("used_vertex_bounds_m")
	_check(bounds is Array and bounds.size()==2 and _v(bounds[0]).distance_to(minimum)<.0001 and _v(bounds[1]).distance_to(maximum)<.0001 and _v(r.get("support_m")).distance_to(support)<.0001 and count>0,"independent actual referenced-vertex bounds and lowest2% support, minY0 contact not literal meshvertex fiction")
	_check(r.get("sourcebody_and_caster_same_model_material_transform")==true,"body/caster same pose contract disclosed; image proof is not a visual verdict")
	var result: Dictionary={"prototype_key":key,"id":r.get("id"),"complete":failures==first_fail,"foot_px":[foot.x,foot.y],"support_m":[support.x,support.y,support.z],"used_bounds":[[minimum.x,minimum.y,minimum.z],[maximum.x,maximum.y,maximum.z]],"drawn_used_vertices":points.size(),"actual_indices_only":true,"sourcebody_raw_sha256":FileAccess.get_sha256(String(r.sourcebody_raw)),"sourcebody_crop_sha256":FileAccess.get_sha256(String(r.texture))}
	prototype_checks[key]=result
	records.prototypes.append(result)
	return result

func _instances(source: Dictionary) -> void:
	var objects: Variant=source.get("objects")
	if not _check(objects is Array and not objects.is_empty(),"actual final source independent object records"): return
	for entry: Dictionary in objects:
		if not entry.has("prototype_actual_sourcebody_evidence"): continue
		var proof: Dictionary=_prototype(entry)
		var r: Dictionary=entry.prototype_actual_sourcebody_evidence
		var own: Image=_image(String(entry.get("texture","")))
		var prototype: Image=_image(String(r.get("texture","")))
		var equal: bool=own!=null and prototype!=null and own.get_data()==prototype.get_data() and own.get_size()==prototype.get_size()
		_check(equal,"each distinct instance PNG strictly equals registered real prototype crop, not claimed fresh repeated GPU: "+String(entry.id))
		var source_foot: Vector2=_p(entry.get("source_XZ_foot_px"))
		var h: float=geometry.call("height_at",source_foot)
		var foot: Vector2=source_foot-Vector2(0,h*Z_PPM)
		_check(is_finite(h) and _p(entry.get("world_foot_px")).distance_to(foot)<.01 and (_p(entry.get("pos"))*SIZE+(_p(entry.get("foot_uv"))-Vector2(.5,.5))*_p(entry.get("render_size_px"))).distance_to(foot)<.01 and absf(float(entry.get("depth_sort_foot_y",NAN))*SIZE.y-foot.y)<.01,"own signed RF contact/crop/center/depth all use true projected foot")
		if String(entry.get("kind",""))=="boulder" and not proof.is_empty():
			var bounds: Array=proof.used_bounds
			var low: Vector3=_v(bounds[0])
			var high: Vector3=_v(bounds[1])
			var support: Vector3=_v(proof.support_m)
			var start: Vector2=source_foot+Vector2((low.x-support.x)*PPM,(low.z-support.z)*Z_PPM)
			var extent:=Vector2((high.x-low.x)*PPM,(high.z-low.z)*Z_PPM)
			var center: Vector2=start+extent*.5-Vector2(0,h*Z_PPM)
			_check(bool(entry.get("blocking",false)) and _p(entry.get("collision_size_px")).distance_to(extent)<.01 and _p(entry.get("collision_center_world_px")).distance_to(center)<.01,"actual Boulder's complete used-index XZ bound is collision, no miniature footprint waiver")
		records.instances.append({"id":entry.id,"prototype":proof.get("prototype_key",""),"source_height_m":h,"actual_foot_px":[foot.x,foot.y],"repeat_scope":"REAL_PROTOTYPE_RAW_PAIR_AND_INDEPENDENT_TRANSLATED_INSTANCE_CROP_NOT_FRESH_GPU_PER_INSTANCE","complete":equal and bool(proof.get("complete",false))})
	_check(not records.instances.is_empty(),"at least one genuinely independent native model, not only baked compounds")

func _decks(manifest: Dictionary,source: Dictionary,raw: RefCounted) -> void:
	var structures: Variant=source.get("structures")
	if not _check(structures is Array and structures.size()==5,"five actual bridge/deck structures bound, not CPU-fill permission"): return
	var source_polygons: Array[PackedVector2Array]=[]
	for structure: Dictionary in structures:
		var polygon:=PackedVector2Array()
		for point: Variant in structure.get("source_deck_polygon",[]): polygon.append(_p(point))
		_check(polygon.size()>=3 and float(structure.get("deck_height_m",NAN))==0,"explicit source deck polygon and separate physical Y0")
		source_polygons.append(polygon)
	for chunk: Dictionary in manifest.get("chunks",[]):
		var capture: Dictionary=chunk.get("capture",{})
		var path: String=String(capture.get("actual_deck_mesh_path",""))
		if not _check(_bound(path,String(capture.get("actual_deck_mesh_sha256",""))),"each walk capture binds actual independently saved Y0 support mesh"): continue
		var key: String=String(catalog[path])
		if support_checks.has(key): continue
		var mesh: ArrayMesh=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
		if not _check(mesh!=null and mesh.get_surface_count()==1,"actual combined support ArrayMesh, not metadata-only plane"): continue
		var arrays: Array=mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		var control:=ArrayMesh.new()
		var expected_vertices:=PackedVector3Array()
		var expected_indices:=PackedInt32Array()
		var normals:=PackedVector3Array()
		for polygon: PackedVector2Array in source_polygons:
			var offset: int=expected_vertices.size()
			for p: Vector2 in polygon: expected_vertices.append(Vector3((p.x-SIZE.x*.5)/PPM,0,(p.y-SIZE.y*.5)/Z_PPM)); normals.append(Vector3.UP)
			for index in Geometry2D.triangulate_polygon(polygon): expected_indices.append(offset+index)
		var expected_arrays: Array=[]
		expected_arrays.resize(Mesh.ARRAY_MAX)
		expected_arrays[Mesh.ARRAY_VERTEX]=expected_vertices
		expected_arrays[Mesh.ARRAY_INDEX]=expected_indices
		expected_arrays[Mesh.ARRAY_NORMAL]=normals
		control.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,expected_arrays)
		var packed: Array=control.surface_get_arrays(0)
		_check(vertices.to_byte_array()==packed[Mesh.ARRAY_VERTEX].to_byte_array() and indices.to_byte_array()==packed[Mesh.ARRAY_INDEX].to_byte_array() and arrays[Mesh.ARRAY_NORMAL].to_byte_array()==packed[Mesh.ARRAY_NORMAL].to_byte_array(),"actual support geometry equals independently reconstructed polygon/native packing, RF bed NOT substituted")
		support_checks[key]={"path":path,"sha256":key,"vertices":vertices.size(),"triangles":indices.size()/3}
	for index in structures.size():
		var structure: Dictionary=structures[index]
		var polygon: PackedVector2Array=source_polygons[index]
		var points: Variant=structure.get("source_passage_px")
		if not _check(points is Array and points.size()>=2,"actual authored passage includes two real dry approaches"): continue
		var deck: int=0
		var banks: int=0
		var wet: int=0
		for segment in range(1,points.size()):
			var a: Vector2=_p(points[segment-1])
			var b: Vector2=_p(points[segment])
			var count: int=maxi(1,ceili(a.distance_to(b)/4))
			for n in range(count+1):
				var p: Vector2=a.lerp(b,float(n)/count)
				var on_deck: bool=Geometry2D.is_point_in_polygon(p,polygon)
				var bed: float=geometry.call("height_at",p)
				var physical: float=0 if on_deck else bed
				var projected: Vector2=p-Vector2(0,physical*Z_PPM)
				_check(is_finite(bed) and bool(raw.call("clear",projected)),"each <=4px actual support/approach center has full17 legal projected shoes, signed bed/deck distinct")
				if on_deck: deck+=1; wet+=1 if bed<0 else 0
				else: banks+=1
		_check(deck>0 and banks>=2 and wet>0,"real Y0 bridge spans independently negative wet RF bed and both dry banks")
		var negatives: Variant=structure.get("water_negative_probes")
		if _check(negatives is Array and negatives.size()>=2,"actual structure water off-deck negative witnesses required, no white shoreline waiver"):
			for negative: Dictionary in negatives:
				var source_at: Vector2=_p(negative.get("source_px"))
				var foot: Vector2=_p(negative.get("projected_water_px"))
				var outside_all: bool=true
				for other: PackedVector2Array in source_polygons: outside_all=outside_all and not Geometry2D.is_point_in_polygon(source_at,other)
				var water_foot: Vector2=source_at-Vector2(0,-.025*Z_PPM)
				_check(outside_all and float(geometry.call("height_at",source_at))<-.025 and foot.distance_to(water_foot)<.01 and not bool(raw.call("clear",foot)),"true wet bed plus actual Y-.025 water-surface projection stays full17 forbidden outside every real deck")
		records.decks.append({"id":structure.get("id"),"deck_samples":deck,"dry_approach_samples":banks,"negative_bed_under_support":wet,"source":structure.duplicate(true)})

func _ecology(source: Dictionary,raw: RefCounted) -> void:
	var probes: Variant=source.get("ecology_probes")
	if not _check(probes is Array and probes.size()==9,"nine current authored ecology regions have actual source/projected witnesses, not metadata visual PASS"): return
	var ids: Dictionary={}
	var profiles: Dictionary={}
	for probe: Dictionary in probes:
		var id: String=String(probe.get("id",""))
		_check(not id.is_empty() and not ids.has(id),"unique true regional ecology witness")
		ids[id]=true
		var p: Vector2=_p(probe.get("source_XZ_px"))
		var h: float=geometry.call("height_at",p)
		var projected: Vector2=p-Vector2(0,h*Z_PPM)
		_check(is_finite(h) and projected.distance_to(_p(probe.get("projected_px")))<.01,"regional witness actual RF/camera-global projected coordinate")
		_check(probe.get("profile") in ECOLOGY_PROFILES and probe.get("walkable") is bool,"declared exact source-authored region ecology/navigation ownership, no invented desert")
		profiles[String(probe.get("profile",""))]=true
		_check(absf(float(probe.get("actual_rf_height_m",NAN))-h)<.0001,"regional recorded RF height independently matches original stored triangle-affine height")
		_check(bool(raw.call("clear",projected))==bool(probe.get("walkable",false)),"regional actual native raster full17 positive/negative agrees, no default grass-white fiction")
		var material: Variant=probe.get("material_binding")
		if _check(material is Dictionary and not material.is_empty(),"actual shader/sampler PBR source map binding for region, not PNG SHA alone"):
			for path: String in material: _check(_bound(path,String(material[path])),"regional actual PBR/shader input bytes")
		records.ecology.append({"id":id,"height_m":h,"projected_px":[projected.x,projected.y],"source":probe.duplicate(true),"visual_verdict":"NOT_REVIEWED"})
	_check(profiles.size()==ECOLOGY_PROFILES.size(),"all nine actual authored region profiles occur once, not nine copies of grass")

func run(owner: RefCounted) -> Dictionary:
	phase=owner
	tree=phase.get("owner_tree") as SceneTree
	var manifest: Dictionary=phase.get("manifest")
	var source: Dictionary=phase.get("source")
	catalog=manifest.get("asset_sha256",{})
	_whole(manifest)
	if not whole_complete: return _finish()
	var rf: String=ROOT+"terrain_height.rf"
	if not _check(_bound(rf) and FileAccess.get_file_as_bytes(rf).size()==1537*1025*4,"actual full RF bytes before independent instance/deck projection"): return _finish()
	geometry.set("height",FileAccess.get_file_as_bytes(rf).to_float32_array())
	var ids: Dictionary={}
	for chunk: Dictionary in manifest.get("chunks",[]):
		var id: String=String(chunk.get("id",""))
		_check(not ids.has(id),"unique actual chunk capture")
		ids[id]=true
		_chunk(chunk)
	_check(ids.size()==64 and records.chunks.size()==64,"all64 whole-world high/raw/repeat/derived authoritative capture checks completed")
	_instances(source)
	_decks(manifest,source,phase.get("oracle"))
	_ecology(source,phase.get("oracle"))
	return _finish()

func _finish() -> Dictionary:
	var result: Dictionary={"scope":"ALL64_ACTUAL_ARTIFACTS_MODEL_PROTOTYPES_Y0_DECK_VS_SIGNED_BED_NINE_REGIONS_NOT_VISUAL_APPROVAL","capture_protocol":PROTOCOL,"checks":checks,"failures":failures,"complete":whole_complete and failures==0 and records.chunks.size()==64 and records.decks.size()==5 and records.ecology.size()==9 and not records.instances.is_empty(),"records":records.duplicate(true),"executing_script_path":get_script().resource_path,"executing_script_sha256":FileAccess.get_sha256(get_script().resource_path)}
	_check(bool(phase.call("_write_json","actual_world_artifact_semantics.json",result)),"full independent artifact evidence checked readback")
	result.checks=checks
	result.failures=failures
	result.complete=bool(result.complete) and failures==0
	geometry.call("release")
	geometry=null
	decoded_models.clear()
	prototype_checks.clear()
	support_checks.clear()
	whole_capture.clear()
	whole_windows.clear()
	catalog.clear()
	phase=null
	tree=null
	return result
