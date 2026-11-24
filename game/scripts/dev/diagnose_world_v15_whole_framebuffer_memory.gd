extends "res://scripts/dev/diagnose_world_v15_backend_caps.gd"
## Independent allocation/readback evidence only. No terrain, publication,
## navigation, shadow, GL-enumerated-capability or formal adoption authority.
const MEMORY_ROOT := "res://build/world_map_v15_whole_framebuffer_memory/"
const PARENT_PATH := "res://scripts/dev/diagnose_world_v15_backend_caps.gd"
const PARENT_SHA := "73cc260391873fa7f167a8a29c0099b20b9375de787e90c88fd870dfc40100c7"
const NVIDIA_QUERY := "C:/Windows/System32/nvidia-smi.exe"
const POWERSHELL_QUERY := "C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
const SQUARE := Vector2i(8192, 8192)
const WHOLE := Vector2i(24576, 16384)
const MIB := 1024 * 1024
const GIB := 1024 * MIB
const SCOPE := "WHOLE_FRAMEBUFFER_MEMORY_NOT_TERRAIN_OR_PROTOCOL_APPROVAL"

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if "--verify-world-v15-whole-framebuffer-memory" not in args or DisplayServer.get_name() == "headless":
		push_error("Explicit GPU memory-fixture flag required; no headless allocation.")
		await _finish(2)
		return
	output = MEMORY_ROOT + "%d_%d/" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) != OK:
		await _finish(1)
		return
	var result: Dictionary = {
		"schema_version": 1, "scope": SCOPE,
		"executed_fixture_path": get_script().resource_path,
		"executed_fixture_sha256": FileAccess.get_sha256(get_script().resource_path),
		"parent_fixture_path": PARENT_PATH, "parent_fixture_sha256": FileAccess.get_sha256(PARENT_PATH),
		"engine_pid": OS.get_process_id(), "godot_version": Engine.get_version_info(),
		"display_server": DisplayServer.get_name(),
		"configured_renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method", "UNKNOWN"),
		"whole_requested": "--allow-whole-native-allocation" in args,
		"whole_viewport_allocated": false, "whole_feasibility_verified": false,
		"terrain_or_capture_protocol_approved": false,
		"gl_max_texture_size": {"available": false, "value": null},
		"gl_max_renderbuffer_size": {"available": false, "value": null},
		"allocation_sequence": [[8192, 8192], "release", "guard", [24576, 16384], "release"],
		"no_resize_no_crop_no_ssaa_downgrade": true
	}
	if FileAccess.get_sha256(PARENT_PATH).to_lower() != PARENT_SHA:
		await _memory_finish(result, "REFUSED_PARENT_SOURCE_CHANGED", 2)
		return
	for method: String in ["get_video_adapter_name", "get_video_adapter_vendor", "get_video_adapter_api_version"]:
		if RenderingServer.has_method(method): result[method] = RenderingServer.call(method)
	var baseline: Dictionary = _memory_snapshot("baseline_before_square")
	result["baseline"] = baseline
	# A small conservative floor protects even the explicitly bounded fixture.
	if not bool(baseline.get("valid", false)) or int(baseline.get("vram_free_bytes", 0)) < GIB or int(baseline.get("host_free_bytes", 0)) < 2 * GIB:
		await _memory_finish(result, "REFUSED_SQUARE_MEMORY_OR_QUERY", 2)
		return
	var square: Dictionary = await _memory_native(SQUARE)
	result["square"] = square
	if not bool(square.get("passed", false)):
		await _memory_finish(result, "SQUARE_ACTUAL_FAILED", 1)
		return
	var metrics: Dictionary = _memory_deltas(square)
	result["square_measured_deltas"] = metrics
	var estimate: Dictionary = {
		"pixel_ratio": 6, "method": "actual square peak deltas times six; minimum 8GiB readback RAM",
		"vram_estimate_bytes": int(metrics.get("vram_peak_delta_bytes", 0)) * 6,
		"vram_headroom_bytes": GIB,
		"ram_readback_requirement_bytes": maxi(8 * GIB, int(metrics.get("process_peak_delta_bytes", 0)) * 6)
	}
	result["whole_estimate"] = estimate
	if not bool(result.whole_requested):
		await _memory_finish(result, "SQUARE_PASS_WHOLE_NOT_REQUESTED", 0)
		return
	# The square was completely released before this fresh guard snapshot.
	var guard: Dictionary = _memory_snapshot("after_square_release_before_whole_guard")
	result["whole_guard_snapshot"] = guard
	var safe: bool = bool(metrics.get("valid", false)) and bool(guard.get("valid", false)) and int(guard.get("vram_free_bytes", 0)) >= int(estimate.vram_estimate_bytes) + GIB and int(guard.get("host_free_bytes", 0)) >= int(estimate.ram_readback_requirement_bytes)
	result["whole_safety_guard_passed"] = safe
	if not safe:
		await _memory_finish(result, "REFUSED_WHOLE_MEMORY_SAFETY_NO_DOWNGRADE", 2)
		return
	result["whole_viewport_allocated"] = true
	var whole: Dictionary = await _memory_native(WHOLE)
	result["whole"] = whole
	result["whole_measured_deltas"] = _memory_deltas(whole)
	result["whole_feasibility_verified"] = bool(whole.get("passed", false))
	await _memory_finish(result, "WHOLE_FRAMEBUFFER_ACTUAL_PASS" if result.whole_feasibility_verified else "WHOLE_FRAMEBUFFER_ACTUAL_FAILED", 0 if result.whole_feasibility_verified else 1)

func _memory_snapshot(stage: String) -> Dictionary:
	var record: Dictionary = {"stage": stage, "valid": false, "ticks_usec": Time.get_ticks_usec(), "engine_static_memory_bytes": OS.get_static_memory_usage()}
	if not FileAccess.file_exists(NVIDIA_QUERY) or not FileAccess.file_exists(POWERSHELL_QUERY):
		record["reason"] = "Fixed read-only query executable unavailable"
		return record
	var gpu_output: Array = []
	var gpu_args := PackedStringArray(["--query-gpu=index,uuid,name,memory.total,memory.used,memory.free", "--format=csv,noheader,nounits"])
	record["gpu_query"] = {"path": NVIDIA_QUERY, "args": gpu_args}
	var gpu_exit: int = OS.execute(NVIDIA_QUERY, gpu_args, gpu_output, true, false)
	var gpu_text: String = "".join(gpu_output).strip_edges()
	record["gpu_query_exit"] = gpu_exit
	record["gpu_raw_output"] = gpu_text
	var rows: PackedStringArray = gpu_text.split("\n", false)
	if gpu_exit != 0 or rows.size() != 1:
		record["reason"] = "Cannot bind a unique real GPU memory row; no guessed adapter"
		return record
	var columns: PackedStringArray = rows[0].split(",")
	if columns.size() != 6:
		record["reason"] = "Unexpected fixed GPU query schema"
		return record
	for i in [0, 3, 4, 5]:
		if not columns[i].strip_edges().is_valid_int(): return record
	var total: int = int(columns[3].strip_edges()) * MIB
	var used: int = int(columns[4].strip_edges()) * MIB
	var free: int = int(columns[5].strip_edges()) * MIB
	if total <= 0 or used < 0 or free < 0 or used > total or free > total: return record
	record["gpu_index"] = int(columns[0].strip_edges())
	record["gpu_uuid"] = columns[1].strip_edges()
	record["gpu_name"] = columns[2].strip_edges()
	record["vram_total_bytes"] = total
	record["vram_used_bytes"] = used
	record["vram_free_bytes"] = free
	# Read only OS memory and this fixture PID. Never enumerate or stop editors.
	var query: String = "$os=Get-CimInstance Win32_OperatingSystem; $p=Get-Process -Id %d -ErrorAction Stop; [pscustomobject]@{host_free_bytes=([int64]$os.FreePhysicalMemory*1024);host_total_bytes=([int64]$os.TotalVisibleMemorySize*1024);process_working_set_bytes=[int64]$p.WorkingSet64;process_private_bytes=[int64]$p.PrivateMemorySize64;process_peak_working_set_bytes=[int64]$p.PeakWorkingSet64}|ConvertTo-Json -Compress" % OS.get_process_id()
	var host_output: Array = []
	var host_exit: int = OS.execute(POWERSHELL_QUERY, PackedStringArray(["-NoProfile", "-NonInteractive", "-Command", query]), host_output, true, false)
	var host_text: String = "".join(host_output).strip_edges()
	record["host_query_exit"] = host_exit
	record["host_raw_output"] = host_text
	var host: Variant = JSON.parse_string(host_text)
	if host_exit != 0 or not host is Dictionary: return record
	for key: String in ["host_free_bytes", "host_total_bytes", "process_working_set_bytes", "process_private_bytes", "process_peak_working_set_bytes"]:
		if not typeof(host.get(key)) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(host[key])) or float(host[key]) < 0 or float(host[key]) != floorf(float(host[key])): return record
		record[key] = int(host[key])
	if int(record.host_total_bytes) <= 0 or int(record.host_free_bytes) > int(record.host_total_bytes): return record
	record["valid"] = true
	return record

func _memory_native(size: Vector2i) -> Dictionary:
	var id: String = "native_" + str(size.x) + "x" + str(size.y)
	var record: Dictionary = {"scope": SCOPE, "id": id, "requested_canvas": [size.x, size.y], "passed": false, "readback_resized_or_cropped": false}
	var before: Dictionary = _memory_snapshot(id + "_before_allocation")
	record["baseline"] = before
	if not bool(before.get("valid", false)): return record
	active_view = SubViewport.new()
	active_view.size = size
	active_view.msaa_3d = Viewport.MSAA_DISABLED
	active_view.own_world_3d = true
	active_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(active_view)
	var world := Node3D.new()
	active_view.add_child(world)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0, 0, 0, 1)
	environment.environment = settings
	world.add_child(environment)
	var view_height := 2.0
	var view_width: float = view_height * float(size.x) / float(size.y)
	var colors: Array[Color] = [Color(.8, .03, .03, 1), Color(.03, .8, .03, 1), Color(.03, .03, .8, 1), Color(.8, .8, .03, 1)]
	for index in 4:
		_axis_quad(world, Vector2(view_width * .5, view_height * .5), Vector3((-1.0 if index % 2 == 0 else 1.0) * view_width * .25, (1.0 if index < 2 else -1.0) * view_height * .25, 0), colors[index])
	_axis_quad(world, Vector2(view_width * .2, view_height * .2), Vector3(0, 0, .01), Color(.8, .03, .8, 1))
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = view_height
	camera.position = Vector3(0, 0, 10)
	world.add_child(camera)
	camera.current = true
	for tick in 8:
		await process_frame
		await RenderingServer.frame_post_draw
	record["allocated"] = _memory_snapshot(id + "_allocated_before_readback")
	var allocated: Dictionary = record.allocated
	var readback_floor: int = 8 * GIB if size == WHOLE else 2 * GIB
	if not bool(allocated.get("valid", false)) or allocated.get("gpu_uuid") != before.get("gpu_uuid") or int(allocated.get("host_free_bytes", 0)) < readback_floor:
		record["reason"] = "Actual allocated-stage query/RAM guard refused before native readback"
		settings = null
		await _release_view()
		record["released"] = _memory_snapshot(id + "_released_after_readback_guard_refusal")
		return record
	record["actual_viewport_size"] = [active_view.size.x, active_view.size.y]
	record["msaa_enum"] = active_view.msaa_3d
	record["camera"] = {"projection": camera.projection, "keep_aspect": camera.keep_aspect, "size": camera.size, "position": [0, 0, 10]}
	var first: Image = active_view.get_texture().get_image()
	record["first_readback_memory"] = _memory_snapshot(id + "_first_readback")
	await process_frame
	await RenderingServer.frame_post_draw
	var second: Image = active_view.get_texture().get_image()
	record["two_readbacks_memory"] = _memory_snapshot(id + "_two_readbacks")
	if first != null and second != null:
		first.convert(Image.FORMAT_RGBA8)
		second.convert(Image.FORMAT_RGBA8)
		record["actual_raw_canvas"] = [first.get_width(), first.get_height()]
		record["actual_repeat_raw_canvas"] = [second.get_width(), second.get_height()]
		var dimensions_exact: bool = first.get_size() == size and second.get_size() == size
		var first_bytes: PackedByteArray = first.get_data()
		var second_bytes: PackedByteArray = second.get_data()
		record["byte_comparison_peak_memory"] = _memory_snapshot(id + "_two_images_and_two_RGBA_buffers")
		var repeat_exact: bool = first_bytes == second_bytes
		first_bytes.clear()
		second_bytes.clear()
		var witnesses: Array[Dictionary] = []
		var colors_valid := false
		if dimensions_exact:
			var points: Array[Vector2i] = [Vector2i(1, 1), Vector2i(size.x - 2, 1), Vector2i(1, size.y - 2), Vector2i(size.x - 2, size.y - 2), size / 2]
			var samples: Array[Color] = []
			for index in points.size():
				var color: Color = first.get_pixelv(points[index])
				samples.append(color)
				witnesses.append({"id": ["top_left_red", "top_right_green", "bottom_left_blue", "bottom_right_yellow", "center_magenta"][index], "pixel": [points[index].x, points[index].y], "raw_rgba": [color.r, color.g, color.b, color.a]})
			colors_valid = samples[0].r > .3 and samples[0].g < .3 and samples[0].b < .3 and samples[1].g > .3 and samples[1].r < .3 and samples[1].b < .3 and samples[2].b > .3 and samples[2].r < .3 and samples[2].g < .3 and samples[3].r > .3 and samples[3].g > .3 and samples[3].b < .3 and samples[4].r > .3 and samples[4].b > .3 and samples[4].g < .3
			for color: Color in samples:
				if color.a < .99: colors_valid = false
		var path: String = output + id + "_raw.png"
		var repeat_path: String = output + id + "_raw_repeat.png"
		var saved: bool = not FileAccess.file_exists(path) and not FileAccess.file_exists(repeat_path) and first.save_png(path) == OK and second.save_png(repeat_path) == OK
		record["dimensions_exact"] = dimensions_exact
		record["raw_repeat_byte_exact"] = repeat_exact
		record["five_native_color_witnesses_passed"] = colors_valid
		record["witnesses"] = witnesses
		record["images"] = [{"path": path, "sha256": FileAccess.get_sha256(path)}, {"path": repeat_path, "sha256": FileAccess.get_sha256(repeat_path)}]
		record["after_save_memory"] = _memory_snapshot(id + "_after_source_PNG_save")
		record["passed"] = dimensions_exact and repeat_exact and colors_valid and saved
	else:
		record["reason"] = "Actual native framebuffer readback missing"
	first = null
	second = null
	settings = null
	var view_ref: WeakRef = weakref(active_view)
	await _release_view()
	record["actual_viewport_node_released"] = view_ref.get_ref() == null
	record["released"] = _memory_snapshot(id + "_released_all_images_and_viewport")
	var deltas: Dictionary = _memory_deltas(record)
	record["memory_query_sequence_valid"] = bool(deltas.get("valid", false))
	record["passed"] = bool(record.passed) and bool(record.memory_query_sequence_valid) and bool(record.actual_viewport_node_released)
	return record

func _memory_deltas(record: Dictionary) -> Dictionary:
	var baseline: Dictionary = record.get("baseline", {})
	var release: Dictionary = record.get("released", {})
	var valid: bool = bool(baseline.get("valid", false)) and bool(release.get("valid", false))
	var gpu_peak := 0
	var ram_peak := 0
	for key: String in ["allocated", "first_readback_memory", "two_readbacks_memory", "byte_comparison_peak_memory", "after_save_memory"]:
		var sample: Dictionary = record.get(key, {})
		valid = valid and bool(sample.get("valid", false)) and sample.get("gpu_uuid") == baseline.get("gpu_uuid")
		gpu_peak = maxi(gpu_peak, int(sample.get("vram_used_bytes", 0)) - int(baseline.get("vram_used_bytes", 0)))
		ram_peak = maxi(ram_peak, int(sample.get("process_private_bytes", 0)) - int(baseline.get("process_private_bytes", 0)))
	valid = valid and gpu_peak > 0 and release.get("gpu_uuid") == baseline.get("gpu_uuid")
	return {"valid": valid, "vram_peak_delta_bytes": gpu_peak, "process_peak_delta_bytes": ram_peak, "vram_release_delta_bytes": int(release.get("vram_used_bytes", 0)) - int(baseline.get("vram_used_bytes", 0)), "process_release_delta_bytes": int(release.get("process_private_bytes", 0)) - int(baseline.get("process_private_bytes", 0)), "measurement_includes_other_live_GPU_processes": true, "gl_enumerated_limit_known": false}

func _memory_finish(result: Dictionary, status: String, code: int) -> void:
	result["status"] = status
	result["proposed_exit_code_not_external_OS_evidence"] = code
	if not _write_result(result): code = 1
	print("WHOLE_FRAMEBUFFER_MEMORY_DIAGNOSTIC ", status, " ", output, " scope=", SCOPE)
	await _finish(code)
