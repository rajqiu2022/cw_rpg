extends SceneTree
## Read-only parse/preflight check, not gameplay or art approval.
var _failed := false
var _checks := 0

func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)

func _initialize() -> void:
	_check.call_deferred()

func _layout_snapshot(layout: WalkableMapLayout) -> Dictionary:
	var result: Dictionary = {}
	for property: Dictionary in layout.get_property_list():
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0: continue
		var name := String(property.name)
		var value: Variant = layout.get(name)
		result[name] = value.duplicate(true) if value is Array or value is Dictionary else value
	return result

func _assert_shell_unchanged(scene: SceneScript, original_layout: WalkableMapLayout, background: String, snapshot: Dictionary, label: String) -> void:
	_expect(is_same(scene.map_layout, original_layout), "Original shell layout identity changed: " + label)
	_expect(scene.background_path == background, "Original shell background changed: " + label)
	for name: String in snapshot:
		var current: Variant = scene.map_layout.get(name)
		if current != snapshot[name]:
			print("OUTSKIRTS_SHELL_MUTATION scene=%s field=%s before=%s after=%s" % [label, name, str(snapshot[name]), str(current)])
		_expect(current == snapshot[name], "Original shell layout field changed: %s/%s" % [label, name])

func _check() -> void:
	var paths := ["world/outskirts_native_contract", "world/outskirts_modular_overlap", "field/outskirts_exit_zone", "autoload/scene_router", "field/field_walkable_controller", "autoload/dialog_player", "dev/world_map_v15_publication_gate"]
	for path: String in paths:
		var script := load("res://scripts/%s.gd" % path) as GDScript
		_expect(script != null and script.can_instantiate(), "Outskirts source cannot compile: " + path)
	var helper := load("res://scripts/world/outskirts_native_contract.gd") as GDScript
	if helper != null and helper.can_instantiate():
		_expect(helper.root_for_args(PackedStringArray()) == helper.ROOT, "Default art root changed")
		_expect(helper.root_for_args(PackedStringArray(["--outskirts-candidate-preview"])) == helper.ROOT, "Original candidate root changed")
		_expect(helper.root_for_args(PackedStringArray(["--outskirts-visual-v4"])) == "", "Visual v4 single flag must fail closed")
		_expect(helper.root_for_args(PackedStringArray(["--outskirts-candidate-preview", "--outskirts-visual-v4"])) == helper.V4_PREVIEW_ROOT, "Dual flags must select only fixed v4 root")
		var args := OS.get_cmdline_user_args()
		var selected: String = helper.active_root()
		var preview := args.has("--outskirts-candidate-preview")
		var router := root.get_node("SceneRouter")
		var before: Dictionary = router.call("get_navigation_state")
		var bound_candidates := 0
		var refused_candidates := 0
		for biome: String in ["bamboo", "forest", "marsh"]:
			var id: StringName = helper.ENTRIES[biome].scene
			var scene := load("res://data/scenes/%s.tres" % id) as SceneScript
			var dialog := load("res://data/dialogs/outskirts_%s_discovery.tres" % biome) as DialogScript
			_expect(scene != null and dialog != null and dialog.blocked_story_flag == StringName("outskirts_%s_material_found" % biome), "Outskirts authored scene/dialog missing: " + biome)
			if scene == null or scene.map_layout == null: continue
			_expect(ResourceLoader.exists(scene.bgm_path), "Outskirts BGM unavailable: " + scene.bgm_path)
			var original_background := scene.background_path
			var original_layout := scene.map_layout
			var original_layout_state := _layout_snapshot(original_layout)
			# Diagnose the engine's ordinary duplication policy independently of the
			# production fix. This probe never clears or appends either array.
			var ordinary_copy := scene.duplicate(true) as SceneScript
			print("OUTSKIRTS_DUPLICATE_POLICY biome=%s same_layout=%s same_objects_array=%s" % [biome, is_same(ordinary_copy.map_layout, scene.map_layout), is_same(ordinary_copy.map_layout.visual_objects, scene.map_layout.visual_objects)])
			var data: Dictionary = helper.authoring_contract(biome)
			var candidate: SceneScript = helper.materialize(scene)
			_assert_shell_unchanged(scene, original_layout, original_background, original_layout_state, biome)
			if candidate != null:
				_expect(not is_same(candidate.map_layout, scene.map_layout), "Candidate layout aliases the original external resource: " + biome)
				for name: String in ["visual_objects", "walkable_mask_tiles", "walkable_probes", "blocked_probes", "portals"]:
					_expect(not is_same(candidate.map_layout.get(name), scene.map_layout.get(name)), "Candidate array aliases original: %s/%s" % [biome, name])
			if not preview or selected.is_empty():
				_expect(data.is_empty() and candidate == null, "Unadopted or invalid-flag outskirts unexpectedly accessible: " + biome)
			elif data.is_empty():
				# Missing/unverified art is an expected closed candidate, not a passed
				# field. Never substitute the original root or mutate navigation state.
				refused_candidates += 1
				_expect(candidate == null, "Missing candidate fell back to a previous art root: " + biome)
				print("OUTSKIRTS_CANDIDATE_REFUSED biome=%s path=%s NOT_READY_NOT_FIELD_PASS" % [biome, helper.contract_path(biome)])
			else:
				bound_candidates += 1
				_expect(candidate != null, "Verified candidate could not materialize safe anchors: " + biome)
				var expected_prefix := selected + biome + "/"
				var graph: Dictionary = data.get("capture_graph", {})
				for pair: Array in [["height_rf", "terrain_height.rf"], ["terrain_mesh", "terrain_mesh.res"], ["camera_contract", "capture_camera.json"]]:
					_expect(String(graph.get(pair[0], {}).get("path", "")) == expected_prefix + pair[1], "Candidate graph crosses art roots: " + biome)
				if candidate != null:
					_expect(candidate.background_path == expected_prefix + "ground.png" and candidate.streamed_background == null, "Candidate background not bound to selected root: " + biome)
					_expect(candidate.map_layout.walkable_mask_path == expected_prefix + "walk.png" and candidate.map_layout.walkable_mask_tiles.is_empty(), "Candidate nav not bound to selected root: " + biome)
					for object: Dictionary in candidate.map_layout.visual_objects:
						_expect(String(object.get("texture", "")).begins_with(expected_prefix + "entities/"), "Candidate entity crosses art roots: " + biome)
				var source := load("res://data/scenes/%s.tres" % helper.ENTRIES[biome].source) as SceneScript
				if source == null or source.map_layout == null:
					_expect(false, "Candidate source scene/layout missing: " + biome)
					continue
				var source_layout := source.map_layout
				var source_background := source.background_path
				var source_layout_state := _layout_snapshot(source_layout)
				var linked: SceneScript = helper.materialize(source)
				_assert_shell_unchanged(source, source_layout, source_background, source_layout_state, String(source.scene_id))
				_expect(linked != null and linked != source, "Candidate source entry not materialized: " + biome)
				if linked != null:
					_expect(not is_same(linked.map_layout, source.map_layout), "Source overlay layout aliases original: " + biome)
					_expect(not is_same(linked.map_layout.visual_objects, source.map_layout.visual_objects) and not is_same(linked.map_layout.portals, source.map_layout.portals), "Source overlay arrays alias original: " + biome)
					for object: Dictionary in linked.map_layout.visual_objects:
						if object.get("id", "") == "outskirts_%s_routepost" % biome:
							_expect(String(object.get("texture", "")).begins_with(expected_prefix + "entities/"), "Source routepost crosses art roots: " + biome)
		for path_key: String in helper._contracts:
			_expect(path_key.begins_with(selected) and path_key.ends_with("/art_contract.json"), "Contract cache not keyed by selected full path")
		_expect(router.call("get_navigation_state") == before, "Read-only candidate checks changed navigation state")
		print("OUTSKIRTS_CANDIDATE_BINDING root=%s bound=%d refused=%d NO_FIELD_OR_VISUAL_APPROVAL" % [selected, bound_candidates, refused_candidates])
	print("OUTSKIRTS_SYSTEM_SOURCE_COMPILE scripts=%d checks=%d failed=%s no_player_save_read_or_written no_gameplay_approval" % [paths.size(), _checks, _failed])
	quit(1 if _failed else 0)
