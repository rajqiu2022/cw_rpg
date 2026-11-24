extends RefCounted
## NEW joint sibling from readonly v15_overview_input_probe.gd; no historical result reuse.
## Actual M input and current candidate UI. No direct panel.open/close call,
## preview replacement, parent FULL inheritance or visual approval claim.
var tree: SceneTree
var driver: RefCounted
var report_check: Callable
var clear_foot: Callable

func configure(owner: SceneTree, input: RefCounted, check: Callable, independent_fullfoot: Callable) -> void:
	tree = owner
	driver = input
	report_check = check
	clear_foot = independent_fullfoot

func _check(ok: bool, label: String) -> void:
	if report_check.is_valid(): report_check.call(ok, label)

func run(field: Node, definition: SceneScript) -> Dictionary:
	var evidence: Dictionary = {"scope": "ACTUAL_M_INPUT_OVERVIEW_NOT_PIXEL_VISUAL_APPROVAL", "version": 15, "opened": false, "closed": false}
	_check(is_instance_valid(field) and definition != null and definition.scene_id in [&"world_map_jianghu_v15",&"world_map_jianghu"] and definition.map_layout != null and definition.map_layout.schema_version == 15, "M probe uses actual v15 candidate Field")
	if not is_instance_valid(field) or definition == null: return evidence
	var player: Node2D = field.get("_player") as Node2D
	_check(is_instance_valid(player) and clear_foot.is_valid() and bool(clear_foot.call(player.position)), "M begins on independently legal complete feet")
	if not is_instance_valid(player) or not clear_foot.is_valid(): return evidence
	var origin: Vector2 = player.position
	var router: Node = tree.root.get_node("SceneRouter")
	var current_id: StringName = router.call("get_current_field_id")
	var expected_world_position: Variant = router.call("get_world_map_position_for_scene", current_id, definition.scene_id)
	_check(expected_world_position is Vector2, "actual navigation supplies current M player position")
	var preview_path: String = definition.background_path
	if definition.streamed_background != null:
		var preview: String = definition.streamed_background.get_preview_path(false)
		if not preview.is_empty(): preview_path = preview
	_check(preview_path.begins_with("res://art/maps/world_map_v15_complete_v6/") and FileAccess.file_exists(preview_path), "M uses current new v15 original overview path, not cached v14/v5 preview")
	await driver.call("key", KEY_M)
	await driver.call("completed_actor_stage")
	var panel: Control = field.get("_world_map_panel") as Control
	_check(panel != null and panel.is_visible_in_tree(), "real M key opens ordinary world overview")
	if panel == null or not panel.is_visible_in_tree(): return evidence
	evidence.opened = true
	var map_texture: TextureRect = panel.get("map_texture") as TextureRect
	var map_rect: Control = panel.get("map_rect") as Control
	_check(map_texture != null and map_texture.texture != null and map_texture.texture.resource_path == preview_path, "actual overview TextureRect binds expected current source")
	_check(map_rect != null and map_rect.size.x > 0 and map_rect.size.y > 0, "actual overview map area has real nonzero layout")
	if map_rect != null:
		var labels: Array[Label] = []
		var markers: Array[Sprite2D] = []
		for child: Node in map_rect.get_children():
			if child.is_queued_for_deletion() or not child.has_meta("world_map_runtime"): continue
			if child is Label: labels.append(child)
			elif child is Sprite2D: markers.append(child)
		_check(labels.size() == 16 and definition.map_layout.portals.size() == 16, "actual M includes exactly all sixteen published entrances")
		var assigned: Dictionary = {}
		var label_records: Array[Dictionary] = []
		for portal: Dictionary in definition.map_layout.portals:
			var foot: Variant = portal.get("pos")
			_check(foot is Vector2, "overview portal has actual projected normalized foot")
			if not foot is Vector2: continue
			var ferry: bool = String(portal.get("travel_mode", "")) == "ferry"
			var expected_text: String = String(portal.get("label", portal.get("id", ""))) + (" · 渡口" if ferry else "")
			var width: float = 132.0 if ferry else 96.0
			var expected: Vector2 = foot * map_rect.size + Vector2(-width * .5, 18)
			var found: Label
			for label: Label in labels:
				if not assigned.has(label.get_instance_id()) and label.text == expected_text and label.position.distance_to(expected) < .01:
					found = label
					break
			_check(found != null, "M label belongs to exact actual portal and projected position: " + String(portal.get("id", "")))
			if found != null:
				assigned[found.get_instance_id()] = true
				label_records.append({"id": portal.get("id"), "text": found.text, "position": [found.position.x, found.position.y]})
		_check(markers.size() == 1, "M has one actual player marker, no stale prior-world marker")
		if markers.size() == 1 and expected_world_position is Vector2:
			var marker: Sprite2D = markers[0]
			var expected: Vector2 = expected_world_position * map_rect.size + Vector2(0, -29)
			_check(marker.position.distance_to(expected) < .01 and marker.texture is AtlasTexture, "M player marker uses real coordinate and visible current-frame atlas")
			evidence["player_marker"] = {"position": [marker.position.x, marker.position.y], "world_position": [expected_world_position.x, expected_world_position.y]}
		evidence["labels"] = label_records
	evidence["preview_path"] = preview_path
	evidence["preview_sha256"] = FileAccess.get_sha256(preview_path) if FileAccess.file_exists(preview_path) else ""
	await driver.call("key", KEY_M)
	await driver.call("completed_actor_stage")
	_check(is_instance_valid(panel) and not panel.visible, "second actual M key closes the ordinary overview")
	_check(tree.current_scene == field and player.position == origin and bool(clear_foot.call(player.position)), "overview input neither changes scene nor displaces legal world feet")
	_check(bool(player.get("can_move")), "normal exploration is available after closing M")
	evidence.closed = is_instance_valid(panel) and not panel.visible
	evidence["origin_px"] = [origin.x, origin.y]
	evidence["actual_end_px"] = [player.position.x, player.position.y]
	return evidence

func release() -> void:
	tree = null
	driver = null
	report_check = Callable()
	clear_foot = Callable()


