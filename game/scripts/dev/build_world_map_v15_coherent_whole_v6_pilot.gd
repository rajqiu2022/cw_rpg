extends "res://scripts/dev/build_world_map_v15_complete_v5_full_draft.gd"

## NEW protocol pilot only. No old ART writes, publisher, Field, or full64 mode.
## Never call get_image() on the 402M-pixel whole viewport. CPU Images are ROIs.
const PILOT_ROOT := "res://build/world_map_v15_coherent_whole_v6_pilot/"
const CACHE_ROOT := "res://art/maps/world_map_v15_complete_v5/"
const TRANSPORT_PATH := "res://shaders/world_v15_native_texel_transfer.gdshader"
const TRANSPORT_SHA := "4997274fc2a62404235a69117785448c2ec65cc50667a4353d27c456d33ec47e"
const PROTOCOL := "COHERENT_WHOLE_FIXED_CAMERA_INTEGER_TEXEL_ROI_V1_PILOT"
const MAX_CPU_ROI_PIXELS := 8388608
const HALO := 96
const GUARD := 1024
const ROLE_NAMES := ["visual", "shadow_off", "land", "raw_walk", "walk"]
const NVIDIA_QUERY := "C:/Windows/System32/nvidia-smi.exe"
const POWERSHELL_QUERY := "C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
const MIB := 1048576
const GIB := 1073741824
const SQUARE_RESULT := "res://build/world_map_v15_whole_framebuffer_memory/1791062610_2434323/result.json"
const SQUARE_RESULT_SHA := "635f79565e1258f077c47ab53ed5e22c235921896c48079dbdc695b5859cd6fe"
const SQUARE_PNG := "res://build/world_map_v15_whole_framebuffer_memory/1791062610_2434323/native_8192x8192_raw.png"
const SQUARE_REPEAT := "res://build/world_map_v15_whole_framebuffer_memory/1791062610_2434323/native_8192x8192_raw_repeat.png"
const SQUARE_PNG_SHA := "d9a06a25a2bd0394d86a2ba246cafe6b5229f8d64f0b0751277da131348a97e5"
var pilot_output := ""
var pilot_auth: Dictionary = {}
var pilot_inputs: Dictionary = {}
var pilot_result: Dictionary = {}
var pilot_transport: Shader
var pilot_global_mesh: ArrayMesh
var pilot_support_mesh: Mesh
var pilot_shader: Shader
var pilot_transfer_view: SubViewport
var pilot_world: Node3D
var pilot_camera: Camera3D
var pilot_sun: DirectionalLight3D
var pilot_environment: WorldEnvironment
var pilot_water: MeshInstance3D
var pilot_support: MeshInstance3D
var pilot_receivers: Array[MeshInstance3D] = []
var pilot_casters: Array[MeshInstance3D] = []
var pilot_caster_records: Array[Dictionary] = []
var pilot_fence := 0
var pilot_proof_gpu_uuid := ""
var pilot_memory_history: Dictionary = {}

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	pilot_output = PILOT_ROOT + "%d_%d/" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	failure_output = pilot_output
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pilot_output)) != OK:
		error = "Cannot create unique pilot output."
		await _pilot_finish(false)
		return
	if "--coherent-whole-v6-pilot" not in args or DisplayServer.get_name() == "headless":
		error = "Only explicit GPU bounded pilot allowed; default/full64/headless refused."
		await _pilot_finish(false)
		return
	var auth_path := ""
	for arg: String in args:
		if arg.begins_with("--authorization="): auth_path = arg.trim_prefix("--authorization=")
	if not _pilot_authorized(auth_path):
		await _pilot_finish(false)
		return
	pilot_result = {"schema_version": 1, "capture_protocol": PROTOCOL, "scope": "TWO_CHUNKS_ONE_SEAM_NEW_PROTOCOL_NOT_FULL64", "status": "BUILD_IN_PROGRESS", "production_approved": false, "visual_approved": false, "engine_pid": OS.get_process_id(), "executed_builder": {"path": get_script().resource_path, "sha256": FileAccess.get_sha256(get_script().resource_path)}, "authorization": {"path": auth_path, "sha256": FileAccess.get_sha256(auth_path)}, "cached_inputs_sha256": pilot_inputs, "whole_cpu_image_requested": false, "whole_cpu_image_allowed": false, "maximum_CPU_ROI_pixels": MAX_CPU_ROI_PIXELS, "no_legacy_frustum_seam_pass_claim": true, "worlds": {}, "comparisons": {}}
	pilot_memory_history = _pilot_square_history()
	pilot_result["actual_memory_history"] = pilot_memory_history
	if not bool(pilot_memory_history.get("valid", false)):
		error = "ROOT078 actual square memory history cannot be strictly bound; no whole allocation."
		await _pilot_finish(false)
		return
	if not _load_pilot_inputs():
		await _pilot_finish(false)
		return
	# Sequential independent worlds, never two huge GPU targets alive together.
	for identity: String in ["primary", "reference"]:
		var measured: Dictionary = await _pilot_capture_world(identity)
		if measured.is_empty():
			await _pilot_finish(false)
			return
		pilot_result["worlds"][identity] = measured
	if not _pilot_compare():
		await _pilot_finish(false)
		return
	for path: String in pilot_inputs:
		if FileAccess.get_sha256(path).to_lower() != String(pilot_inputs[path]).to_lower():
			error = "Frozen input changed during actual pilot: " + path
			await _pilot_finish(false)
			return
	pilot_result["input_hashes_unchanged_after"] = true
	pilot_result["status"] = "NEW_PROTOCOL_BOUNDED_PILOT_TECHNICAL_PASS_REQUIRES_ROOT_VISUAL_REVIEW"
	await _pilot_finish(true)

func _pilot_authorized(path: String) -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		error = "Missing explicit root pilot authorization JSON."
		return false
	pilot_auth = parsed
	if pilot_auth.get("approved", false) != true or pilot_auth.get("scope") != PROTOCOL or pilot_auth.get("builder_path") != get_script().resource_path or String(pilot_auth.get("builder_sha256", "")).to_lower() != FileAccess.get_sha256(get_script().resource_path).to_lower():
		error = "Authorization scope/executed builder SHA mismatch."
		return false
	if pilot_auth.get("allow_full64", true) != false or pilot_auth.get("memory_budget_approved", false) != true:
		error = "Pilot-only/memory authorization not granted; no allocation."
		return false
	if not pilot_auth.get("input_sha256") is Dictionary:
		error = "Pinned cache/input catalog missing."
		return false
	pilot_inputs = pilot_auth["input_sha256"]
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
	return true

func _pilot_exact_integer(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= 0. and float(value) == floorf(float(value))

func _pilot_square_history() -> Dictionary:
	var record: Dictionary = {"valid": false, "result_path": SQUARE_RESULT, "result_sha256": FileAccess.get_sha256(SQUARE_RESULT), "square_PNG_path": SQUARE_PNG, "square_repeat_path": SQUARE_REPEAT, "square_PNG_sha256": FileAccess.get_sha256(SQUARE_PNG), "square_repeat_sha256": FileAccess.get_sha256(SQUARE_REPEAT), "historical_overall_scope": "ROOT078 overall OS1/whole Image cap failure NOT overridden; only its real square peak component informs safety budget"}
	if record["result_sha256"] != SQUARE_RESULT_SHA or record["square_PNG_sha256"] != SQUARE_PNG_SHA or record["square_repeat_sha256"] != SQUARE_PNG_SHA: return record
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SQUARE_RESULT))
	if not parsed is Dictionary: return record
	var report: Dictionary = parsed
	if report.get("executed_fixture_sha256") != "fa4a63b9e3413362e0eb14b3de97556fc4ddb82a9c1fa25f5ab06bbc4306c26a" or report.get("parent_fixture_sha256") != "73cc260391873fa7f167a8a29c0099b20b9375de787e90c88fd870dfc40100c7" or report.get("status") != "WHOLE_FRAMEBUFFER_ACTUAL_FAILED" or not _pilot_exact_integer(report.get("proposed_exit_code_not_external_OS_evidence")) or int(report["proposed_exit_code_not_external_OS_evidence"]) != 1: return record
	var square: Dictionary = report.get("square", {})
	var canvas: Variant = square.get("actual_raw_canvas")
	if not canvas is Array or canvas.size() != 2: return record
	for component: Variant in canvas:
		if not _pilot_exact_integer(component) or int(component) != 8192: return record
	if not bool(square.get("passed", false)) or not bool(square.get("raw_repeat_byte_exact", false)) or not bool(square.get("actual_viewport_node_released", false)): return record
	var images: Array = square.get("images", [])
	if images.size() != 2 or images[0].get("path") != SQUARE_PNG or images[1].get("path") != SQUARE_REPEAT: return record
	for item: Dictionary in images:
		if item.get("sha256") != SQUARE_PNG_SHA: return record
	var baseline: Dictionary = square.get("baseline", {})
	var released: Dictionary = square.get("released", {})
	if not bool(baseline.get("valid", false)) or not bool(released.get("valid", false)) or baseline.get("gpu_uuid") != pilot_proof_gpu_uuid or released.get("gpu_uuid") != pilot_proof_gpu_uuid: return record
	for key: String in ["vram_used_bytes", "process_private_bytes"]:
		if not _pilot_exact_integer(baseline.get(key)) or not _pilot_exact_integer(released.get(key)): return record
	var gpu_peak := 0
	var process_peak := 0
	var peaks: Dictionary = {}
	for key: String in ["allocated", "first_readback_memory", "two_readbacks_memory", "byte_comparison_peak_memory", "after_save_memory"]:
		var sample: Dictionary = square.get(key, {})
		if not bool(sample.get("valid", false)) or sample.get("gpu_uuid") != pilot_proof_gpu_uuid or not _pilot_exact_integer(sample.get("vram_used_bytes")) or not _pilot_exact_integer(sample.get("process_private_bytes")): return record
		gpu_peak = maxi(gpu_peak, int(sample["vram_used_bytes"]) - int(baseline["vram_used_bytes"]))
		process_peak = maxi(process_peak, int(sample["process_private_bytes"]) - int(baseline["process_private_bytes"]))
		peaks[key] = {"GPU_UUID": sample["gpu_uuid"], "vram_used_bytes": sample["vram_used_bytes"], "process_private_bytes": sample["process_private_bytes"]}
	var reported: Dictionary = report.get("square_measured_deltas", {})
	if gpu_peak <= 0 or process_peak <= 0 or not bool(reported.get("valid", false)) or not _pilot_exact_integer(reported.get("vram_peak_delta_bytes")) or not _pilot_exact_integer(reported.get("process_peak_delta_bytes")) or int(reported["vram_peak_delta_bytes"]) != gpu_peak or int(reported["process_peak_delta_bytes"]) != process_peak: return record
	record.merge({"valid": true, "gpu_uuid": pilot_proof_gpu_uuid, "actual_peak_samples": peaks, "vram_peak_delta_bytes": gpu_peak, "process_peak_delta_bytes": process_peak, "whole_pixel_to_square_ratio": 6, "vram_requirement_bytes": gpu_peak * 6 + GIB, "host_RAM_requirement_bytes": maxi(8 * GIB, process_peak * 6), "method": "independently recompute bound ROOT078 actual square peak minus baseline; exact numeric JSON semantics, no epsilon or OS1 override"}, true)
	return record

func _pilot_fresh_memory(stage: String) -> Dictionary:
	var record: Dictionary = {"stage": stage, "valid": false, "ticks_usec_before_queries": Time.get_ticks_usec(), "engine_pid": OS.get_process_id(), "engine_static_memory_bytes": OS.get_static_memory_usage(), "GPU_UUID_required": pilot_proof_gpu_uuid}
	if not FileAccess.file_exists(NVIDIA_QUERY) or not FileAccess.file_exists(POWERSHELL_QUERY):
		record["reason"] = "Fixed native read-only query executable missing."
		return record
	var gpu_output: Array = []
	var gpu_args := PackedStringArray(["--query-gpu=index,uuid,name,memory.total,memory.used,memory.free", "--format=csv,noheader,nounits"])
	record["gpu_query"] = {"path": NVIDIA_QUERY, "args": gpu_args}
	var gpu_exit: int = OS.execute(NVIDIA_QUERY, gpu_args, gpu_output, true, false)
	var text: String = "".join(gpu_output).strip_edges()
	record["gpu_query_exit"] = gpu_exit
	record["gpu_raw_output"] = text
	var rows: PackedStringArray = text.split("\n", false)
	if gpu_exit != 0 or rows.size() != 1:
		record["reason"] = "Fresh GPU memory query must bind one actual adapter; no guess."
		return record
	var columns: PackedStringArray = rows[0].split(",")
	if columns.size() != 6: return record
	for index in [0, 3, 4, 5]:
		if not columns[index].strip_edges().is_valid_int(): return record
	var total: int = int(columns[3].strip_edges()) * MIB
	var used: int = int(columns[4].strip_edges()) * MIB
	var free: int = int(columns[5].strip_edges()) * MIB
	if total <= 0 or used < 0 or used > total or free < 0 or free > total or columns[1].strip_edges() != pilot_proof_gpu_uuid: return record
	record.merge({"gpu_index": int(columns[0].strip_edges()), "gpu_uuid": columns[1].strip_edges(), "gpu_name": columns[2].strip_edges(), "vram_total_bytes": total, "vram_used_bytes": used, "vram_free_bytes": free}, true)
	# Read only operating-system RAM and this owned exporter PID; never touch
	# another process/editor. These fixed executables are launched without UI.
	var query: String = "$ErrorActionPreference='Stop'; $os=Get-CimInstance Win32_OperatingSystem; $p=Get-Process -Id %d -ErrorAction Stop; [pscustomobject]@{host_free_bytes=([int64]$os.FreePhysicalMemory*1024);host_total_bytes=([int64]$os.TotalVisibleMemorySize*1024);process_working_set_bytes=[int64]$p.WorkingSet64;process_private_bytes=[int64]$p.PrivateMemorySize64;process_peak_working_set_bytes=[int64]$p.PeakWorkingSet64}|ConvertTo-Json -Compress" % OS.get_process_id()
	var host_args := PackedStringArray(["-NoProfile", "-NonInteractive", "-Command", query])
	var host_output: Array = []
	var host_exit: int = OS.execute(POWERSHELL_QUERY, host_args, host_output, true, false)
	var host_text: String = "".join(host_output).strip_edges()
	record["host_query"] = {"path": POWERSHELL_QUERY, "args": host_args}
	record["host_query_exit"] = host_exit
	record["host_raw_output"] = host_text
	var host: Variant = JSON.parse_string(host_text)
	if host_exit != 0 or not host is Dictionary: return record
	for key: String in ["host_free_bytes", "host_total_bytes", "process_working_set_bytes", "process_private_bytes", "process_peak_working_set_bytes"]:
		if not _pilot_exact_integer(host.get(key)): return record
		record[key] = int(host[key])
	if int(record["host_total_bytes"]) <= 0 or int(record["host_free_bytes"]) > int(record["host_total_bytes"]): return record
	record["ticks_usec_after_queries"] = Time.get_ticks_usec()
	record["valid"] = true
	return record

func _pilot_memory_guard(identity: String) -> bool:
	var actual: Dictionary = _pilot_fresh_memory(identity + "_immediately_before_whole_GPU_allocation")
	var required_GPU: int = int(pilot_memory_history.get("vram_requirement_bytes", 0))
	var required_RAM: int = int(pilot_memory_history.get("host_RAM_requirement_bytes", 0))
	var safe: bool = bool(pilot_memory_history.get("valid", false)) and bool(actual.get("valid", false)) and actual.get("gpu_uuid") == pilot_proof_gpu_uuid and required_GPU > GIB and required_RAM >= 8 * GIB and int(actual.get("vram_free_bytes", 0)) >= required_GPU and int(actual.get("host_free_bytes", 0)) >= required_RAM
	var record: Dictionary = {"world_identity": identity, "passed": safe, "actual_fresh_queries": actual, "ROOT078_square_peak_bound": pilot_memory_history, "vram_required_bytes": required_GPU, "host_RAM_required_bytes": required_RAM, "no_resolution_or_SSAA_downgrade": true, "allocation_requested_after_guard": false}
	if not pilot_result.has("fresh_preallocation_guards"): pilot_result["fresh_preallocation_guards"] = []
	pilot_result["fresh_preallocation_guards"].append(record)
	if not safe:
		error = "Fresh GPU UUID/VRAM/CIM RAM safety guard refused " + identity + "; no whole allocation or downgrade."
		return false
	record["allocation_requested_after_guard"] = true
	return true

func _load_pilot_inputs() -> bool:
	source = SOURCE.new()
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(CACHE_ROOT + "terrain_height.rf")
	if bytes.size() != SOURCE.GRID_SIZE.x * SOURCE.GRID_SIZE.y * 4:
		error = "Actual cached RF byte count mismatch."
		return false
	source.heights = bytes.to_float32_array()
	source.prepare()
	full_rf = ImageTexture.create_from_image(Image.create_from_data(SOURCE.GRID_SIZE.x, SOURCE.GRID_SIZE.y, false, Image.FORMAT_RF, bytes))
	var topology: Image = Image.load_from_file(CACHE_ROOT + "source_topology.png")
	if topology == null or topology.get_size() != SOURCE.SIZE / SOURCE.SELECTOR_STEP:
		error = "Cached selector size missing."
		return false
	full_topology = ImageTexture.create_from_image(topology)
	pilot_global_mesh = ResourceLoader.load(CACHE_ROOT + "terrain_mesh.res", "", ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	pilot_support_mesh = ResourceLoader.load(CACHE_ROOT + "chunks/r0_c0_actual_deck_support_mesh.res", "", ResourceLoader.CACHE_MODE_IGNORE) as Mesh
	pilot_shader = ResourceLoader.load(CACHE_ROOT + "capture/terrain_shader.gdshader", "", ResourceLoader.CACHE_MODE_IGNORE) as Shader
	pilot_transport = ResourceLoader.load(TRANSPORT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Shader
	if pilot_global_mesh == null or pilot_support_mesh == null or pilot_shader == null or pilot_transport == null:
		error = "Actual frozen mesh/support/shader load failed."
		return false
	surface = SURFACE.new()
	if not surface.load_sources():
		error = surface.error
		return false
	for entry: Dictionary in surface.evidence:
		for key: String in ["path", "source_path"]:
			var p: String = entry[key]
			if not pilot_inputs.has(p):
				error = "Unpinned actual PBR dependency: " + p
				return false
	full_map_textures = _material_maps(Rect2(Vector2.ZERO, Vector2(SOURCE.SIZE)))
	var weights: Dictionary = {}
	for role: String in ["ecology", "roads"]:
		var image: Image = full_map_textures[role].get_image()
		var path: String = pilot_output + role + "_reconstructed.png"
		if image.save_png(path) != OK:
			error = "Weight texture write failed."
			return false
		weights[role] = {"path": path, "sha256": FileAccess.get_sha256(path), "canvas": _v2i(image.get_size()), "recipe": "unchanged parent global _material_maps 8px centers; reconstructed once, NOT cached topology regeneration"}
	for kind: String in ["boulder", "tree", "bamboo", "herb"]:
		for pose in 3:
			var metadata_path: String = CACHE_ROOT + "prototypes/native_" + kind + str(pose) + ".json"
			if not pilot_inputs.has(metadata_path):
				error = "Unpinned native prototype metadata."
				return false
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
			if not parsed is Dictionary:
				error = "Native metadata parse failed."
				return false
			var record: Dictionary = parsed
			for key: String in ["actual_draw_mesh_path", "texture", "sourcebody_raw", "sourcebody_repeat", "draw_mesh_source"]:
				if not pilot_inputs.has(record[key]):
					error = "Unpinned actual native prototype input: " + String(record[key])
					return false
			if FileAccess.get_sha256(record["actual_draw_mesh_path"]) != record["actual_draw_mesh_sha256"] or record.get("kind") != kind or int(record.get("pose", -1)) != pose:
				error = "Actual native draw source/pose mismatch."
				return false
			var mesh: ArrayMesh = ResourceLoader.load(record["actual_draw_mesh_path"], "", ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
			var body: Image = Image.load_from_file(record["texture"])
			if mesh == null or body == null or body.is_empty():
				error = "Frozen caster mesh/sourcebody missing."
				return false
			var bounds: Dictionary = _pilot_native_bounds(mesh)
			if bounds.is_empty(): return false
			var b: Array = record["basis_columns"]
			var support: Vector3 = _array3(record["support_m"])
			var uv: Array = record["foot_uv"]
			native_prototype_cache[kind + str(pose)] = {"mesh": mesh, "basis": Basis(_array3(b[0]), _array3(b[1]), _array3(b[2])), "support": support, "image": body, "foot": Vector2(uv[0] * body.get_width(), uv[1] * body.get_height()), "record": record, "actual_native_bounds": bounds}
	pilot_result["cache_provenance"] = {"producer_approved_exact_SHA_reuse": true, "origin": "ROOT066 failed per-frustum capture; reuse only exact same-source authored RF/selector/native geometry, NOT its failed seam or visual approval", "height_grid_regenerated": false, "25M_selector_regenerated": false, "global_mesh_reserialized_as_original": false, "rf_shape": _v2i(SOURCE.GRID_SIZE), "rf_spacing_px": SOURCE.GRID_STEP, "weight_maps": weights}
	pilot_result["actual_materials"] = surface.evidence.duplicate(true)
	return true

func _pilot_capture_world(identity: String) -> Dictionary:
	var directory: String = pilot_output + identity + "/"
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) != OK:
		error = "Cannot create actual world output."
		return {}
	if not _pilot_memory_guard(identity): return {}
	if not _pilot_make_world(directory): return {}
	var effective_world: World3D = active_view.find_world_3d()
	if effective_world == null:
		error = "Actual effective World3D unavailable; no synthetic identity credit."
		return {}
	var water_shape: PlaneMesh = pilot_water.mesh as PlaneMesh
	var measured: Dictionary = {"identity": identity, "world_node_instance_id": pilot_world.get_instance_id(), "viewport_instance_id": active_view.get_instance_id(), "world_3d_instance_id": effective_world.get_instance_id(), "camera": _pilot_camera_record(), "coverage": _pilot_coverage(), "roles": {}, "casters": pilot_caster_records.duplicate(true), "authoritative_global_mesh": {"path": CACHE_ROOT + "terrain_mesh.res", "sha256": pilot_inputs[CACHE_ROOT + "terrain_mesh.res"]}, "support_mesh": {"path": CACHE_ROOT + "chunks/r0_c0_actual_deck_support_mesh.res", "sha256": pilot_inputs[CACHE_ROOT + "chunks/r0_c0_actual_deck_support_mesh.res"]}, "visual_guard_meshes": pilot_result["visual_guard_recipe"].duplicate(true), "water_recipe": {"native_mesh": "actual flat PlaneMesh in source XZ, one surface", "path": directory + "actual_visual_water_plane.res", "sha256": FileAccess.get_sha256(directory + "actual_visual_water_plane.res"), "water_Y": SOURCE.WATER_Y, "RF_grid_origin": [0, 0], "RF_grid_shape": _v2i(SOURCE.GRID_SIZE), "RF_grid_spacing_px": SOURCE.GRID_STEP, "RF_triangle_formula": "same stored [a,b,c,b,d,c] Float32 texelFetch affine triangles; global p, not PlaneMesh UV", "source_width_m": water_shape.size.x, "source_Z_depth_m": water_shape.size.y}}
	if not bool(measured["coverage"]["passed"]):
		error = "Actual fullreceiver depth/projection or model clip rejected."
		return {}
	for role: String in ROLE_NAMES:
		if not _pilot_set_role(role): return {}
		var role_record: Dictionary = {"actual_native_canvas": _v2i(active_view.size), "frozen_camera_projection": _pilot_camera_record(), "passes": [], "windows": {}, "caster_actual_visible": role == "visual", "caster_shadow_setting_actual": GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY, "terrain_actual_cast_shadow": pilot_receivers[0].cast_shadow, "support_actual_visible": pilot_support.visible, "water_actual_visible": pilot_water.visible, "MSAA_3D_actual": active_view.msaa_3d, "MSAA_2D_actual": active_view.msaa_2d}
		for pass_index in 2:
			var pass_record: Dictionary = await _pilot_draw(identity + "_" + role + "_" + str(pass_index))
			if not bool(pass_record["fresh_actual_post_draw_observed"]):
				error = "Fresh native whole draw not fenced."
				return {}
			if role in ["visual", "shadow_off"] and (not _shader_gate(pilot_receivers[0].material_override, ["biome_weights", "road_weights", "grass_ground_diff", "rock_01_arm"]) or not _shader_gate(pilot_water.material_override, ["actual_height_rf", "grid_origin", "grid_shape"])):
				error = "Actual after-draw shader binding rejected; no default fallback."
				return {}
			role_record["passes"].append(pass_record)
			for item: Dictionary in _pilot_windows():
				var captured: Dictionary = await _pilot_read_roi(item, role, directory, pass_index, pass_record)
				if captured.is_empty(): return {}
				var id: String = item["id"]
				if pass_index == 0:
					role_record["windows"][id] = captured
				else:
					var first: Dictionary = role_record["windows"][id]
					var raw_difference: Dictionary = _pilot_compare_pngs(first["raw_path"], captured["raw_path"])
					var logical_difference: Dictionary = _pilot_compare_pngs(first["path"], captured["path"])
					first["raw_repeat_path"] = captured["raw_path"]
					first["repeat_path"] = captured["path"]
					first["repeat_transfer_evidence"] = captured
					first["actual_repeat_raw"] = raw_difference
					first["actual_repeat_logical"] = logical_difference
					if not bool(raw_difference["byte_exact"]) or not bool(logical_difference["byte_exact"]):
						error = "Actual raw/logical repeat failed: " + identity + "/" + role + "/" + id
						pilot_result["failed_role_evidence"] = role_record
						return {}
		measured["roles"][role] = role_record
		# ON/OFF are still native 3D draws. Terrain self shadow never disabled
		# for visual or shadow_off; only sourcebody casters become invisible.
	var primary_ref: WeakRef = weakref(active_view)
	await _pilot_release_world()
	measured["actual_world_released_before_next"] = primary_ref.get_ref() == null
	if not bool(measured["actual_world_released_before_next"]):
		error = "Actual primary viewport not released; no second huge allocation."
		return {}
	return measured

func _pilot_make_world(directory: String) -> bool:
	active_view = SubViewport.new()
	active_view.size = SOURCE.SIZE * SSAA
	active_view.own_world_3d = true
	active_view.msaa_2d = Viewport.MSAA_DISABLED
	active_view.msaa_3d = Viewport.MSAA_DISABLED
	active_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(active_view)
	pilot_world = Node3D.new()
	active_view.add_child(pilot_world)
	pilot_environment = WorldEnvironment.new()
	pilot_environment.environment = surface.environment()
	pilot_world.add_child(pilot_environment)
	pilot_sun = DirectionalLight3D.new()
	pilot_sun.rotation_degrees = Vector3(-55, -34, 0)
	pilot_sun.light_energy = .85
	pilot_sun.shadow_enabled = true
	pilot_sun.shadow_normal_bias = 2.
	pilot_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	pilot_sun.directional_shadow_max_distance = 160.
	pilot_world.add_child(pilot_sun)
	var material: ShaderMaterial = surface.terrain_material(full_map_textures["ecology"], full_map_textures["roads"], Rect2(Vector2.ZERO, Vector2(SOURCE.SIZE)))
	if material == null or material.shader == null or material.shader.code != pilot_shader.code:
		error = "Frozen actual global terrain shader differs."
		return false
	var terrain := MeshInstance3D.new()
	terrain.mesh = pilot_global_mesh
	terrain.material_override = material
	pilot_world.add_child(terrain)
	pilot_receivers.append(terrain)
	# Real domain-external edge receivers, not a painted sky/water/nav guard.
	# Preserve cached authoritative domain mesh/RF. Only this recipe is new.
	var guards: Array[Rect2] = [Rect2(-GUARD, -GUARD, SOURCE.SIZE.x + GUARD * 2, GUARD), Rect2(-GUARD, SOURCE.SIZE.y, SOURCE.SIZE.x + GUARD * 2, GUARD), Rect2(-GUARD, 0, GUARD, SOURCE.SIZE.y), Rect2(SOURCE.SIZE.x, 0, GUARD, SOURCE.SIZE.y)]
	var guard_evidence: Array = []
	for i in guards.size():
		var node := MeshInstance3D.new()
		node.mesh = _mesh(guards[i], false)
		node.material_override = material
		var path: String = directory + "visual_only_guard_" + str(i) + ".res"
		if ResourceSaver.save(node.mesh, path) != OK:
			error = "Cannot preserve actual visual guard mesh."
			return false
		pilot_world.add_child(node)
		pilot_receivers.append(node)
		guard_evidence.append({"path": path, "sha256": FileAccess.get_sha256(path), "source_rect_px": [guards[i].position.x, guards[i].position.y, guards[i].size.x, guards[i].size.y], "role": "visual_only_receiver_no_land_nav_support", "recipe": "unchanged parent exact 8px mesh with cached RF edge clamp; original domain vertices never rewritten"})
	pilot_result["visual_guard_recipe"] = guard_evidence
	pilot_water = MeshInstance3D.new()
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(float(SOURCE.SIZE.x + 2 * GUARD) / SOURCE.PPM, float(SOURCE.SIZE.y + 2 * GUARD) / SOURCE.Z_PPM)
	pilot_water.mesh = water_mesh
	if ResourceSaver.save(water_mesh, directory + "actual_visual_water_plane.res") != OK:
		error = "Cannot save actual global planar water geometry."
		return false
	pilot_water.position.y = SOURCE.WATER_Y
	pilot_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pilot_water.material_override = surface.water_material(full_rf, Vector2i.ZERO, SOURCE.GRID_SIZE)
	pilot_world.add_child(pilot_water)
	pilot_camera = Camera3D.new()
	pilot_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	pilot_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	pilot_camera.size = float(SOURCE.SIZE.y) / SOURCE.PPM
	pilot_camera.near = .05
	pilot_camera.far = 200.
	pilot_camera.position = Vector3(0, 60, 60)
	pilot_world.add_child(pilot_camera)
	pilot_camera.look_at(Vector3.ZERO)
	pilot_camera.current = true
	var bridges := Node3D.new()
	pilot_world.add_child(bridges)
	_add_bridge_geometry(bridges, Rect2(Vector2.ZERO, Vector2(SOURCE.SIZE)))
	_full_set_shadow_only(bridges, pilot_casters)
	for site: Dictionary in source.vegetation_sites:
		var key: String = String(site["kind"]) + str(site["pose"])
		var proto: Dictionary = native_prototype_cache[key]
		var node := MeshInstance3D.new()
		node.mesh = proto["mesh"]
		var foot: Vector2 = site["source_foot"]
		node.transform = Transform3D(proto["basis"], SOURCE.point3(foot, source.triangle_height(foot)) - Vector3(proto["support"]))
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		node.set_meta("pilot_prototype_key", key)
		pilot_world.add_child(node)
		pilot_casters.append(node)
		pilot_caster_records.append({"id": site["id"], "kind": site["kind"], "pose": site["pose"], "source_foot_px": [foot.x, foot.y], "actual_draw_mesh_path": proto["record"]["actual_draw_mesh_path"], "actual_draw_mesh_sha256": proto["record"]["actual_draw_mesh_sha256"], "transform": _pilot_transform(node.global_transform), "support_m": _v3(proto["support"]), "shadow_on_enum": node.cast_shadow, "sourcebody_baked": false})
	pilot_support = MeshInstance3D.new()
	pilot_support.mesh = pilot_support_mesh
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.cull_mode = BaseMaterial3D.CULL_DISABLED
	white.albedo_color = Color.WHITE
	pilot_support.material_override = white
	pilot_support.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pilot_support.visible = false
	pilot_world.add_child(pilot_support)
	return true

func _pilot_set_role(role: String) -> bool:
	var visual: bool = role == "visual" or role == "shadow_off"
	active_view.size = SOURCE.SIZE * (SSAA if visual else 1)
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
				var expected := Vector2(p.x * SOURCE.PPM + SOURCE.SIZE.x * .5, p.z * SOURCE.Z_PPM + SOURCE.SIZE.y * .5 - p.y * SOURCE.Z_PPM)
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
	var covered: bool = projected_min.x <= 0. and projected_min.y <= 0. and projected_max.x >= SOURCE.SIZE.x and projected_max.y >= SOURCE.SIZE.y
	var valid: bool = points > 0 and caster_vertices > 0 and covered and projection_error <= .01 and depth_min > pilot_camera.near and depth_max < pilot_sun.directional_shadow_max_distance and depth_max < pilot_camera.far and caster_min > pilot_camera.near and caster_max < pilot_camera.far and caster_max < pilot_sun.directional_shadow_max_distance
	return {"passed": valid, "actual_receiver_vertices": points, "actual_receiver_depth_min_m": depth_min, "actual_receiver_depth_max_m": depth_max, "actual_caster_unique_draw_vertices_across_instances": caster_vertices, "actual_caster_depth_min_m": caster_min, "actual_caster_depth_max_m": caster_max, "logical_projection_bounds_px": [projected_min.x, projected_min.y, projected_max.x, projected_max.y], "max_actual_source_projection_error_px": projection_error, "shadow_max_actual_m": pilot_sun.directional_shadow_max_distance, "camera_near_actual": pilot_camera.near, "camera_far_actual": pilot_camera.far, "entire_canvas_covered": covered, "caster_bounds_evidence": bounds_records, "method": "actual saved mesh surface vertices and conservative bounds computed once from actual indices-used caster mesh vertices; actual per-instance transform/camera inverse; no old sixty-meter proof"}

func _pilot_native_bounds(mesh: ArrayMesh) -> Dictionary:
	var minimum := Vector3(INF, INF, INF)
	var maximum := Vector3(-INF, -INF, -INF)
	var count := 0
	for surface_index in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(surface_index)
		if arrays[Mesh.ARRAY_VERTEX] == null:
			error = "Native prototype vertex array missing."
			return {}
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices := PackedInt32Array()
		if arrays[Mesh.ARRAY_INDEX] != null: indices = arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			for vertex: Vector3 in vertices:
				minimum = minimum.min(vertex)
				maximum = maximum.max(vertex)
				count += 1
		else:
			var seen: Dictionary = {}
			for index: int in indices:
				if index < 0 or index >= vertices.size():
					error = "Invalid actual native draw index."
					return {}
				if seen.has(index): continue
				seen[index] = true
				minimum = minimum.min(vertices[index])
				maximum = maximum.max(vertices[index])
				count += 1
	if count == 0:
		error = "Empty actual caster draw geometry."
		return {}
	return {"minimum": minimum, "maximum": maximum, "unique_draw_vertex_count": count}

func _pilot_windows() -> Array[Dictionary]:
	return [{"id": "r0_c0", "rect": Rect2i(0, 0, 1536, 1024)}, {"id": "r0_c1", "rect": Rect2i(1536, 0, 1536, 1024)}, {"id": "narrow", "rect": Rect2i(1520, 0, 32, 1024)}, {"id": "wide", "rect": Rect2i(1360, 0, 352, 1024)}]

func _pilot_draw(id: String) -> Dictionary:
	var before: int = Engine.get_process_frames()
	var fences: Array = []
	for tick in 8:
		active_view.render_target_update_mode = SubViewport.UPDATE_ONCE
		await process_frame
		await RenderingServer.frame_post_draw
		pilot_fence += 1
		fences.append({"sequence": pilot_fence, "process_frame": Engine.get_process_frames(), "draw_counter": Engine.get_frames_drawn(), "ticks_usec": Time.get_ticks_usec(), "update_request": SubViewport.UPDATE_ONCE})
	active_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	return {"id": id, "process_before": before, "process_after": Engine.get_process_frames(), "post_draw_fences": fences, "fence_sequence": pilot_fence, "fresh_actual_post_draw_observed": fences.size() == 8 and Engine.get_process_frames() > before, "texture_rid": active_view.get_texture().get_rid().get_id(), "viewport_rid": active_view.get_viewport_rid().get_id(), "whole_native_canvas": _v2i(active_view.size), "frozen_update_mode": active_view.render_target_update_mode, "identity_method": "fresh UPDATE_ONCE requests plus actual process/frame_post_draw; not assumed Engine draw-counter growth"}

func _pilot_read_roi(item: Dictionary, role: String, directory: String, pass_index: int, draw: Dictionary) -> Dictionary:
	var factor: int = SSAA if role in ["visual", "shadow_off"] else 1
	var rect: Rect2i = item["rect"]
	var logical_window: Rect2i = rect.grow(HALO).intersection(Rect2i(Vector2i.ZERO, SOURCE.SIZE))
	var native_window := Rect2i(logical_window.position * factor, logical_window.size * factor)
	if native_window.size.x * native_window.size.y > MAX_CPU_ROI_PIXELS or native_window.size.x <= 0 or native_window.size.y <= 0:
		error = "Bounded CPU ROI cap exceeded."
		return {}
	pilot_transfer_view = SubViewport.new()
	pilot_transfer_view.size = native_window.size
	pilot_transfer_view.disable_3d = true
	pilot_transfer_view.msaa_2d = Viewport.MSAA_DISABLED
	pilot_transfer_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(pilot_transfer_view)
	var panel := ColorRect.new()
	panel.size = Vector2(native_window.size)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var material := ShaderMaterial.new()
	material.shader = pilot_transport
	material.set_shader_parameter("primary_texture", active_view.get_texture())
	material.set_shader_parameter("source_origin_px", native_window.position)
	panel.material = material
	pilot_transfer_view.add_child(panel)
	var before: int = Engine.get_process_frames()
	pilot_transfer_view.render_target_update_mode = SubViewport.UPDATE_ONCE
	await process_frame
	await RenderingServer.frame_post_draw
	pilot_fence += 1
	pilot_transfer_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	# The only GPU get_image call in this sibling is this bounded target.
	var raw: Image = pilot_transfer_view.get_texture().get_image()
	if raw == null or raw.get_size() != native_window.size or raw.get_format() != Image.FORMAT_RGBA8 or raw.is_compressed() or raw.has_mipmaps() or Engine.get_process_frames() <= before or active_view.render_target_update_mode != SubViewport.UPDATE_DISABLED or active_view.get_texture().get_rid().get_id() != draw["texture_rid"]:
		error = "Integer transport actual native RGBA/identity/fence failure."
		return {}
	var prefix: String = directory + role + "_" + String(item["id"]) + "_pass" + str(pass_index)
	var raw_path: String = prefix + "_raw.png"
	if raw.save_png(raw_path) != OK:
		error = "Actual ROI raw PNG write failed."
		return {}
	var decoded: Image = Image.load_from_file(raw_path)
	if decoded == null or decoded.get_format() != Image.FORMAT_RGBA8 or decoded.get_data() != raw.get_data():
		error = "Raw PNG decoded bytes changed."
		return {}
	decoded = null
	var raw_binary: Dictionary = {}
	if factor == 1:
		raw_binary = _pilot_binary_stats(raw)
		if not bool(raw_binary["passed"]):
			pilot_result["failed_binary_raw_ROI_evidence"] = {"raw_path": raw_path, "raw_sha256": FileAccess.get_sha256(raw_path), "role": role, "window_id": item["id"], "pass_index": pass_index, "source_draw": draw, "actual_raw_binary_stats": raw_binary}
			error = "Actual raw binary ROI/halo must be pure RGB black/white AND alpha255."
			return {}
	var derived: Image = raw.duplicate() as Image
	if factor > 1: derived.resize(logical_window.size.x, logical_window.size.y, Image.INTERPOLATE_LANCZOS)
	var crop := Rect2i(rect.position - logical_window.position, rect.size)
	derived = derived.get_region(crop)
	var path: String = prefix + ".png"
	if derived.save_png(path) != OK:
		error = "Logical bounded ROI write failed."
		return {}
	var record: Dictionary = {"path": path, "sha256": FileAccess.get_sha256(path), "raw_path": raw_path, "raw_sha256": FileAccess.get_sha256(raw_path), "raw_RGBA_sha256": _bytes_sha(raw.get_data()), "logical_RGBA_sha256": _bytes_sha(derived.get_data()), "logical_rect_px": _recti(rect), "global_native_readback_rect_px": _recti(native_window), "logical_overscan_rect_px": _recti(logical_window), "local_logical_crop_px": _recti(crop), "actual_readback_canvas": _v2i(raw.get_size()), "actual_whole_GPU_canvas": _v2i(active_view.size), "factor": factor, "resampling_identity": "OPAQUE_RGBA8_LANCZOS_ROI96_V1" if factor > 1 else "NONE_NATIVE_MSAA0", "96px_kernel_halo_actual_boundaries_clipped_to_whole": true, "source_draw": draw, "actual_transfer_post_draw_fence_sequence": pilot_fence, "transfer_shader": {"path": TRANSPORT_PATH, "sha256": TRANSPORT_SHA}, "gamma_correction": false, "source_primary_texture_rid": active_view.get_texture().get_rid().get_id(), "destination_texture_rid": pilot_transfer_view.get_texture().get_rid().get_id()}
	if factor == 1:
		var logical_binary: Dictionary = _pilot_binary_stats(derived)
		record["actual_raw_binary_stats"] = raw_binary
		record["actual_logical_binary_stats"] = logical_binary
		if not bool(logical_binary["passed"]):
			pilot_result["failed_binary_ROI_evidence"] = record
			error = "Actual binary capture must be pure RGB black/white AND alpha255; no transparent mask accepted."
			return {}
	raw = null
	derived = null
	panel.material = null
	material.set_shader_parameter("primary_texture", null)
	material = null
	panel = null
	var destination_ref: WeakRef = weakref(pilot_transfer_view)
	pilot_transfer_view.queue_free()
	pilot_transfer_view = null
	for i in 4: await process_frame
	record["actual_transfer_view_released"] = destination_ref.get_ref() == null
	if not bool(record["actual_transfer_view_released"]):
		error = "ROI transfer viewport release failed."
		return {}
	return record

func _pilot_binary_stats(image: Image) -> Dictionary:
	var bytes: PackedByteArray = image.get_data()
	var nonbinary := 0
	var nonopaque := 0
	for n in range(0, bytes.size(), 4):
		if not ((bytes[n] == 0 and bytes[n + 1] == 0 and bytes[n + 2] == 0) or (bytes[n] == 255 and bytes[n + 1] == 255 and bytes[n + 2] == 255)): nonbinary += 1
		if bytes[n + 3] != 255: nonopaque += 1
	return {"passed": nonbinary == 0 and nonopaque == 0, "canvas": _v2i(image.get_size()), "actual_nonbinary_RGB_pixels": nonbinary, "actual_nonopaque_alpha_pixels": nonopaque, "required_alpha_byte": 255, "pixels_checked": bytes.size() / 4, "thresholding_or_alpha_correction": false}

func _pilot_compare() -> bool:
	var all_exact := true
	for role: String in ROLE_NAMES:
		var primary: Dictionary = pilot_result["worlds"]["primary"]["roles"][role]["windows"]
		var reference: Dictionary = pilot_result["worlds"]["reference"]["roles"][role]["windows"]
		var left: Image = Image.load_from_file(primary["r0_c0"]["path"])
		var right: Image = Image.load_from_file(primary["r0_c1"]["path"])
		var joined := Image.create(32, 1024, false, Image.FORMAT_RGBA8)
		joined.blit_rect(left, Rect2i(1520, 0, 16, 1024), Vector2i.ZERO)
		joined.blit_rect(right, Rect2i(0, 0, 16, 1024), Vector2i(16, 0))
		var narrow: Image = Image.load_from_file(reference["narrow"]["path"])
		var wide: Image = Image.load_from_file(reference["wide"]["path"])
		var wide_strip: Image = wide.get_region(Rect2i(160, 0, 32, 1024))
		var record: Dictionary = {"primary_chunks_vs_independent_reference_narrow": _pilot_difference(joined, narrow), "primary_chunks_vs_independent_reference_wide": _pilot_difference(joined, wide_strip), "reference_narrow_vs_wide_ROI_kernel_overlap": _pilot_difference(narrow, wide_strip), "independent_worlds_same_global_coordinates": {}}
		for item: Dictionary in _pilot_windows():
			var id: String = item["id"]
			var difference: Dictionary = _pilot_compare_pngs(primary[id]["path"], reference[id]["path"])
			record["independent_worlds_same_global_coordinates"][id] = difference
			all_exact = all_exact and bool(difference["byte_exact"])
		for key: String in ["primary_chunks_vs_independent_reference_narrow", "primary_chunks_vs_independent_reference_wide", "reference_narrow_vs_wide_ROI_kernel_overlap"]:
			all_exact = all_exact and bool(record[key]["byte_exact"])
		pilot_result["comparisons"][role] = record
	if pilot_result["worlds"]["primary"]["world_node_instance_id"] == pilot_result["worlds"]["reference"]["world_node_instance_id"]:
		all_exact = false
		error = "Independent world identity reused."
	if not all_exact and error.is_empty(): error = "NEW_PROTOCOL strict all-role actual repeat/independent seam/ROI kernel comparison failed."
	return all_exact

func _pilot_compare_pngs(a: String, b: String) -> Dictionary:
	return _pilot_difference(Image.load_from_file(a), Image.load_from_file(b))

func _pilot_difference(a: Image, b: Image) -> Dictionary:
	if a == null or b == null or a.get_size() != b.get_size() or a.get_format() != Image.FORMAT_RGBA8 or b.get_format() != Image.FORMAT_RGBA8: return {"byte_exact": false, "reason": "actual native image shape/format mismatch"}
	var x: PackedByteArray = a.get_data()
	var y: PackedByteArray = b.get_data()
	var result: Dictionary = {"byte_exact": x == y, "different_bytes": 0, "maximum_delta": 0, "tolerance": 0, "canvas": _v2i(a.get_size()), "a_RGBA_sha256": _bytes_sha(x), "b_RGBA_sha256": _bytes_sha(y)}
	for i in x.size():
		if x[i] == y[i]: continue
		if int(result["different_bytes"]) == 0: result["first_difference"] = {"byte_index": i, "pixel": [int(i / 4) % a.get_width(), int(i / 4) / a.get_width()], "channel": i % 4, "a": x[i], "b": y[i]}
		result["different_bytes"] = int(result["different_bytes"]) + 1
		result["maximum_delta"] = maxi(int(result["maximum_delta"]), absi(int(x[i]) - int(y[i])))
	return result

func _pilot_camera_record() -> Dictionary:
	return {"projection": pilot_camera.projection, "keep_aspect": pilot_camera.keep_aspect, "size_m": pilot_camera.size, "transform": _pilot_transform(pilot_camera.global_transform), "whole_logical_canvas": _v2i(SOURCE.SIZE), "whole_visual_native_canvas": _v2i(SOURCE.SIZE * SSAA), "actual_current_GPU_canvas": _v2i(active_view.size), "source_center_px": [6144, 4096], "PPM_X": SOURCE.PPM, "PPM_source_Z": SOURCE.Z_PPM, "near": pilot_camera.near, "far": pilot_camera.far, "light_rotation_degrees": _v3(pilot_sun.rotation_degrees), "light_energy": pilot_sun.light_energy, "directional_shadow_mode": pilot_sun.directional_shadow_mode, "shadow_max_distance": pilot_sun.directional_shadow_max_distance, "shadow_normal_bias": pilot_sun.shadow_normal_bias}

func _pilot_transform(t: Transform3D) -> Dictionary:
	return {"origin": _v3(t.origin), "basis_columns": [_v3(t.basis.x), _v3(t.basis.y), _v3(t.basis.z)]}

func _array3(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])

func _v2i(p: Vector2i) -> Array:
	return [p.x, p.y]

func _recti(r: Rect2i) -> Array:
	return [r.position.x, r.position.y, r.size.x, r.size.y]

func _pilot_release_world() -> void:
	if pilot_transfer_view != null:
		pilot_transfer_view.queue_free()
		pilot_transfer_view = null
	pilot_receivers.clear()
	pilot_casters.clear()
	pilot_caster_records.clear()
	pilot_camera = null
	pilot_sun = null
	pilot_environment = null
	pilot_water = null
	pilot_support = null
	pilot_world = null
	if active_view != null:
		active_view.queue_free()
		active_view = null
	for tick in 16: await process_frame

func _pilot_finish(passed: bool) -> void:
	if not passed:
		pilot_result["status"] = "NEW_PROTOCOL_PILOT_REFUSED_OR_TECHNICAL_FAIL"
		pilot_result["reason"] = error
	if not pilot_output.is_empty():
		if not _write_json(pilot_output + "result.json", pilot_result): passed = false
	await _pilot_release_world()
	pilot_transport = null
	pilot_global_mesh = null
	pilot_support_mesh = null
	pilot_shader = null
	print("COHERENT_WHOLE_V6_PILOT_RESULT ", pilot_output, " passed=", passed)
	await _finish(passed)
