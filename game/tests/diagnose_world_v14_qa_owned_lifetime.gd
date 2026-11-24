extends "res://tests/test_world_map_v14_production_20261002.gd"

## Bounded inheritance/planner/GLTF lifecycle controls, NOT a world-map test.
## Root runs distinct fresh --verbose processes for --mode=empty|planner|gltf.
var lifetime_mode := "empty"
var lifetime_report: Dictionary = {}
var lifetime_refs: Array[Dictionary] = []
var lifetime_seen: Dictionary = {}
var lifetime_out := ""

func _initialize() -> void:
	call_deferred("_run_lifetime")

func _track_lifetime(resource: Object) -> void:
	if resource == null or lifetime_seen.has(resource.get_instance_id()): return
	lifetime_seen[resource.get_instance_id()] = true
	lifetime_refs.append({"id": resource.get_instance_id(), "class": resource.get_class(), "path": (resource as Resource).resource_path if resource is Resource else "", "weak": weakref(resource)})

func _prepare_lifetime_control() -> void:
	if lifetime_mode == "planner":
		pathfinder = FullFootPlanningGrid.new()
		pathfinder.build(Vector2(64, 64), func(_point: Vector2) -> bool: return true)
		_track_lifetime(pathfinder.graph)
	elif lifetime_mode == "gltf":
		# Only two unique source models. No per-instance geometry scan, derived
		# LOD, renderer, terrain, Field, material mutations, or GPU captures.
		for source: String in ["res://art/external/polyhaven/boulder_01/boulder_01_1k.gltf", "res://art/external/polyhaven/tree_small_02/tree_small_02_1k.gltf"]:
			var document := GLTFDocument.new()
			var state := GLTFState.new()
			_check(document.append_from_file(source, state) == OK, "bounded original GLTF loads: " + source)
			var imported := document.generate_scene(state)
			_check(imported != null, "bounded original GLTF owns real imported nodes")
			if imported == null: continue
			var nodes: Array[MeshInstance3D] = []
			_collect_source_meshes(imported, nodes)
			var entries: Array[Dictionary] = []
			for node: MeshInstance3D in nodes:
				_track_lifetime(node.mesh)
				var materials: Array = []
				for surface in node.mesh.get_surface_count():
					var material := node.get_active_material(surface) as BaseMaterial3D
					materials.append(material)
					_track_lifetime(material)
					if material != null:
						for slot in [BaseMaterial3D.TEXTURE_ALBEDO, BaseMaterial3D.TEXTURE_NORMAL, BaseMaterial3D.TEXTURE_ROUGHNESS, BaseMaterial3D.TEXTURE_METALLIC, BaseMaterial3D.TEXTURE_AMBIENT_OCCLUSION]: _track_lifetime(material.get_texture(slot))
				entries.append({"mesh": node.mesh, "active_materials": materials})
			original_model_cache[source + ":raw"] = entries
			imported.free()

func _run_lifetime() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--mode="): lifetime_mode = argument.trim_prefix("--mode=")
	_check(lifetime_mode in ["empty", "planner", "gltf"], "explicit finite lifecycle control mode")
	lifetime_out = "res://build/world_map_v14_qa/owned_lifetime_%s_%d/" % [lifetime_mode.validate_filename(), Time.get_unix_time_from_system()]
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(lifetime_out)) == OK, "unique diagnostic JSON directory")
	_prepare_lifetime_control()
	# The preparation stack must return before any final WeakRef/exit judgment.
	call_deferred("_finish_lifetime")

func _finish_lifetime() -> void:
	pathfinder = null
	world_pathfinder = null
	original_model_cache.clear()
	derived_mesh_cache.clear()
	material_recipe_cache.clear()
	lifetime_seen.clear()
	var cursors := root.get_node_or_null("CursorManager")
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	if cursors != null:
		for key: String in ["_arrow", "_hand", "_wait"]: cursors.set(key, null)
	for frame in 8: await process_frame
	var observations: Array = []
	var alive := 0
	for entry: Dictionary in lifetime_refs:
		var live := is_instance_valid((entry.weak as WeakRef).get_ref())
		if live: alive += 1
		observations.append({"id": entry.id, "class": entry.get("class"), "path": entry.path, "alive_after_owned_cache_clear": live})
	lifetime_refs.clear()
	lifetime_report = {"scope": "BOUNDED_QA_INHERITANCE_LIFETIME_NOT_FULL_MAP", "mode": lifetime_mode, "script_path": get_script().resource_path, "script_sha256": FileAccess.get_sha256(get_script().resource_path), "base_script_sha256": FileAccess.get_sha256("res://tests/test_world_map_v14_production_20261002.gd"), "tracked_resources": observations.size(), "alive_after_clear": alive, "observations": observations, "setup_checks": checks, "setup_failures": failed, "production_approved": false, "exit_resource_status": "must be independently read from actual --verbose stderr; absence is not asserted by this JSON"}
	var file := FileAccess.open(lifetime_out + "result.json", FileAccess.WRITE)
	_check(file != null, "write unique lifecycle diagnostic result")
	if file != null:
		file.store_string(JSON.stringify(lifetime_report, "\t"))
		file.close()
	print("[OwnedLifetimeDiagnostic] mode=%s tracked=%d alive=%d setup_failures=%d result=%s; NOT_FULL_MAP" % [lifetime_mode, observations.size(), alive, failed, lifetime_out + "result.json"])
	quit(0 if failed == 0 else 1)
