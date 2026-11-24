extends Node
## Entrance UI stays above world art, not above the independent HUD/modal canvases.
## Display layers and local wayfinding only; physics and routing stay put.

const VISUAL_NAMES: Array[StringName] = [&"MarkerVisual", &"Prompt", &"Indicator"]
const WORLD_OVERLAY_Z := 4096
const LINXI_CENTER := &"linxi_village_center"
const ROAD_SIGN := "res://art/modules/prop/prop_zhuwei_road_sign.png"
const THEME := preload("res://scripts/ui/wuxia_theme.gd")

var _visuals: Array[WeakRef] = []
var _visual_ids: Dictionary = {}
var _late_depth_corrections := 0


func _ready() -> void:
	# Existing world-name refinements can run during a later field attach and
	# lower Prompt to 4095. Check only our registered display nodes afterwards.
	process_priority = 1000
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_adopt_existing_zones")


func _adopt_existing_zones() -> void:
	for node: Node in get_tree().get_nodes_in_group("exit_zone"):
		_adopt_zone(node)


func _on_node_added(node: Node) -> void:
	if node is ExitZone:
		call_deferred("_adopt_weak_zone", weakref(node))
	elif VISUAL_NAMES.has(node.name) and node.get_parent() is ExitZone:
		# Also cover a display child installed after its Area2D entered the tree.
		call_deferred("_adopt_weak_zone", weakref(node.get_parent()))


func _adopt_weak_zone(reference: WeakRef) -> void:
	var zone: Node = reference.get_ref() as Node
	if is_instance_valid(zone) and zone.is_inside_tree() and not zone.is_queued_for_deletion():
		_adopt_zone(zone)


func _adopt_zone(zone: Node) -> void:
	if not zone is ExitZone:
		return
	apply_zone_depth(zone)
	_apply_linxi_wayfinding(zone)
	for child_name: StringName in VISUAL_NAMES:
		var visual: CanvasItem = zone.get_node_or_null(NodePath(String(child_name))) as CanvasItem
		if not is_instance_valid(visual) or visual.is_queued_for_deletion():
			continue
		var id: int = visual.get_instance_id()
		if not _visual_ids.has(id):
			_visual_ids[id] = true
			_visuals.append(weakref(visual))


func _apply_linxi_wayfinding(zone: ExitZone) -> void:
	if zone.destination_name != "前往村外山道" or zone.has_meta("linxi_wayfinding"):
		return
	var field := get_tree().current_scene
	if not is_instance_valid(field) or not field.has_method("get_world_town_debug"):
		return
	var debug: Dictionary = field.get_world_town_debug()
	if debug.get("id") != LINXI_CENTER:
		return
	zone.set_meta("linxi_wayfinding", true)
	# Face up the actual northeastern road, with text on the clear left side.
	zone.marker_rotation_degrees = 180.0
	if zone.marker_visual != null:
		zone.marker_visual.rotation_degrees = zone.marker_rotation_degrees
	zone.destination_label_side = -1.0
	zone.configure_marker(zone.position, field.get("_world_size"), zone._marker_anchor_offset + Vector2(0, 40))
	var world := field.get("world_container") as Node2D
	if world == null or world.has_node("LinxiMountainWayfinding"):
		return
	var wayfinding := Node2D.new()
	wayfinding.name = "LinxiMountainWayfinding"
	world.add_child(wayfinding)
	var foot := Vector2(2385, 1595)
	var town: Node = field.get("native_town")
	_add_linxi_sign(wayfinding, foot, town.foot_depth(foot.y), "北往村外山道 · 通竹尾村")


func _add_linxi_sign(parent: Node2D, foot: Vector2, depth: int, text: String) -> void:
	var signpost := Sprite2D.new()
	signpost.texture = load(ROAD_SIGN) as Texture2D
	signpost.scale = Vector2.ONE * 0.39
	signpost.position = foot - Vector2(0, signpost.texture.get_height() * signpost.scale.y * 0.5)
	signpost.z_as_relative = false
	signpost.z_index = depth
	parent.add_child(signpost)
	var label := Label.new()
	label.text = text
	label.position = signpost.position + Vector2(-140, -91)
	label.size = Vector2(280, 31)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_as_relative = false
	label.z_index = WORLD_OVERLAY_Z
	THEME.style_label(label, 23, THEME.GOLD_LIGHT)
	parent.add_child(label)


static func apply_zone_depth(zone: Node) -> int:
	if not zone is ExitZone:
		return 0
	var count := 0
	for child_name: StringName in VISUAL_NAMES:
		var visual: CanvasItem = zone.get_node_or_null(NodePath(String(child_name))) as CanvasItem
		if not is_instance_valid(visual) or visual.is_queued_for_deletion():
			continue
		visual.z_as_relative = false
		visual.z_index = WORLD_OVERLAY_Z
		count += 1
	return count


func _process(_delta: float) -> void:
	# No tree/group scan per frame. Preserve all inherited transforms, clipping,
	# visibility, alpha, animation and hover materials; only repair later z writes.
	for index: int in range(_visuals.size() - 1, -1, -1):
		var visual: CanvasItem = _visuals[index].get_ref() as CanvasItem
		if not is_instance_valid(visual) or visual.is_queued_for_deletion():
			_visuals.remove_at(index)
			continue
		if visual.z_as_relative or visual.z_index != WORLD_OVERLAY_Z:
			visual.z_as_relative = false
			visual.z_index = WORLD_OVERLAY_Z
			_late_depth_corrections += 1
	# IDs are rebuilt only after a display node was freed; object IDs are not a
	# source of ownership or scene identity, merely duplicate-registration guards.
	if _visual_ids.size() != _visuals.size():
		_visual_ids.clear()
		for reference: WeakRef in _visuals:
			var visual: CanvasItem = reference.get_ref() as CanvasItem
			if is_instance_valid(visual):
				_visual_ids[visual.get_instance_id()] = true


func get_debug_state() -> Dictionary:
	return {
		"world_overlay_z": WORLD_OVERLAY_Z,
		"registered_visual_count": _visuals.size(),
		"late_depth_corrections": _late_depth_corrections,
		"changes_physics_or_routing": false,
		"changes_parent_or_transform": false,
	}
