extends SceneTree

const CONTRACT := preload("res://scripts/dev/world_native_pair_landmark_contract_v7.gd")
const FIELD_PATH := "res://scenes/field_walkable.tscn"
const PREVIEW_FIELD_PATH := "res://scripts/dev/world_native_pair_landmark_field_v7.gd"


var field: Control
var return_anchor := Vector2.ZERO
var navigation_before: Dictionary


func _initialize() -> void:
	call_deferred("_start_preview")


func _start_preview() -> void:
	await start_preview()
	print("[WorldLandmarkPreview] WASD/方向键移动，空格或近距点击城池/渡口入口；Esc退出。开发预览不提供保存。")


func start_preview() -> bool:
	# Native injected pointer events need the same physical and logical window size.
	root.size = Vector2i(1920, 1080)
	for path in [CONTRACT.PREFIX + "visual.png", CONTRACT.PREFIX + "walk.png", CONTRACT.ROOT + "bridge_stone_eastwest_front_rail_v7.png"]:
		if not ResourceLoader.exists(path):
			push_error("Build/import isolated v7 terrain and bridge front rail first: " + path)
			quit(1)
			return false
	navigation_before = root.get_node("SceneRouter").get_navigation_state()
	set_auto_accept_quit(false)
	root.close_requested.connect(func():
		restore_preview_state()
		quit())
	# Prevent the global debug console from opening write-capable gameplay panels.
	var gm := root.get_node_or_null("GMConsole")
	if gm != null:
		gm.process_mode = Node.PROCESS_MODE_DISABLED
		if gm is CanvasLayer:
			gm.visible = false
		for child in gm.get_children():
			if child is CanvasLayer:
				child.visible = false
	var packed := load(FIELD_PATH) as PackedScene
	field = packed.instantiate()
	field.set_script(load(PREVIEW_FIELD_PATH))
	field.set("definition", CONTRACT.make_scene())
	field.set("on_preview_exit", _preview_exit)
	root.add_child(field)
	current_scene = field
	for tick in range(10):
		await process_frame
	return true


func _preview_exit(target: String, target_spawn: Vector2, source_anchor: Vector2) -> void:
	if target == String(CONTRACT.LAB_ID):
		field.apply_preview(CONTRACT.make_scene(), return_anchor)
		return
	var original := load("res://data/scenes/%s.tres" % target) as SceneScript
	if original == null or not target in ["ch4_s0_luoyang_gate", "openworld_bailu_ferry"]:
		push_error("Preview refuses unrelated target: " + target)
		return
	return_anchor = source_anchor
	var copy := original.duplicate(true) as SceneScript
	copy.on_enter_dialog = null
	copy.npcs.clear()
	copy.hotspots.clear()
	copy.trigger_zones.clear()
	copy.encounter_enemy_ids.clear()
	copy.encounter_groups.clear()
	copy.is_settlement = true
	copy.map_layout.interactions.clear()
	copy.map_layout.portals = [{"id": "preview_return", "pos": original.player_spawn, "size": Vector2(0.05, 0.05),
		"target_scene": String(CONTRACT.LAB_ID), "target_pos": return_anchor,
		"label": "返回制作候选路线", "show_destination_label": true}]
	field.apply_preview(copy, target_spawn)


func restore_preview_state() -> void:
	var router := root.get_node_or_null("SceneRouter") if root != null else null
	if router != null and not navigation_before.is_empty():
		router.restore_navigation_state(navigation_before)
