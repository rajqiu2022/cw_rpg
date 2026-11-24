extends SceneTree

const CONTRACT := preload("res://scripts/dev/world_native_pair_landmark_contract_v12.gd")
const FIELD_PATH := "res://scenes/field_walkable.tscn"
const PREVIEW_FIELD_PATH := "res://scripts/dev/world_native_pair_landmark_field_v7.gd"


var field: Control
var return_anchor := Vector2.ZERO
var navigation_before: Dictionary


func _initialize() -> void:
	call_deferred("_start_preview")


func _start_preview() -> void:
	if not await start_preview():
		return
	print("[WorldLandmarkPreview] WASD/方向键移动，空格或近距点击城池/渡口入口；Esc退出。开发预览不提供保存。")


func start_preview() -> bool:
	# Native injected pointer events need the same physical and logical window size.
	root.size = Vector2i(1920, 1080)
	var art: Variant=JSON.parse_string(FileAccess.get_file_as_string(CONTRACT.PREFIX+"art.json"))
	if not art is Dictionary or art.get("version")!="v12" or art.get("status")!="ISOLATED_VISUAL_CANDIDATE" or art.get("current_outputs_not_ready",false):
		push_error("Refuse failed/partial v12 outputs before Field: native cast / actual foot contracts are not ready")
		quit(1)
		return false
	var winding: Variant=art.get("mesh_winding",{})
	var repeats: Variant=art.get("capture_repeats",{})
	if not winding is Dictionary or not winding.get("only_index_changed",false) or not winding.get("exact_triangle_swap_asserted",false) or not repeats is Dictionary or not repeats.get("on_exact",false) or not repeats.get("off_exact",false):
		push_error("Refuse v12 missing index-only front-facing mesh or stable actual native ON/OFF evidence")
		quit(1)
		return false
	var ground_shadow := Image.new()
	if ground_shadow.load_png_from_buffer(FileAccess.get_file_as_bytes(CONTRACT.PREFIX+"shadow.png"))!=OK or ground_shadow.get_size()!=Vector2i(CONTRACT.WORLD_SIZE) or ground_shadow.get_format()!=Image.FORMAT_RGBA8 or ground_shadow.get_used_rect().size==Vector2i.ZERO:
		push_error("Refuse empty/unreadable native v12 ground shadow capture before Field")
		quit(1)
		return false
	for path in [CONTRACT.PREFIX + "visual.png", CONTRACT.PREFIX + "walk.png", CONTRACT.ROOT + "bridge_stone_eastwest_front_rail_v7.png"]:
		if not ResourceLoader.exists(path):
			push_error("Build/import isolated v12 terrain and bridge front rail first: " + path)
			quit(1)
			return false
	# The deck sprite alone is not a valid preview. Every runtime foreground
	# must be readable and retain the exact source canvas for pixel alignment.
	var source := Image.new()
	var source_path := CONTRACT.ROOT+"landmark_bailu_ferry_v1.png"
	if not FileAccess.file_exists(source_path) or source.load_png_from_buffer(FileAccess.get_file_as_bytes(source_path))!=OK:
		push_error("Unreadable ferry source canvas: "+source_path)
		quit(1)
		return false
	var foreground_suffixes: Array[String]=["ferry_pavilion_foreground.png"]
	for part in CONTRACT.RAIL_PARTS:
		foreground_suffixes.append("ferry_rail_"+String(part["name"])+".png")
	for suffix in foreground_suffixes:
		var path: String = CONTRACT.PREFIX+String(suffix)
		var mask := Image.new()
		if not FileAccess.file_exists(path) or mask.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK or mask.get_size()!=source.get_size():
			push_error("Missing/unreadable or canvas-mismatched v12 ferry foreground: "+path)
			quit(1)
			return false
	var entities: Array[Dictionary]=CONTRACT.entity_metadata()
	if entities.size()!=10:
		push_error("v12 requires ten distinct validated native entity contracts")
		quit(1)
		return false
	for data in entities:
		if not data.get("sourcebody_valid",false) or not data.get("sourcebody_repeat_exact",false):
			push_error("Refuse v12 invalid or unstable sourcebody capture")
			quit(1)
			return false
		var entity := Image.new()
		var texture_path: String=data["texture_path"]
		if not ResourceLoader.exists(texture_path) or entity.load_png_from_buffer(FileAccess.get_file_as_bytes(texture_path))!=OK or entity.get_size()!=Vector2i(data["size"][0],data["size"][1]):
			push_error("Missing/unreadable native v12 sprite: "+texture_path)
			quit(1)
			return false
		var body_path: String=data.get("sourcebody_path","")
		var body_repeat: String=data.get("sourcebody_repeat_path","")
		var sourcebody := Image.new()
		if body_path!=CONTRACT.PREFIX+"sourcebody_"+String(data["id"])+".png" or body_repeat!=CONTRACT.PREFIX+"sourcebody_"+String(data["id"])+"_repeat.png" or not FileAccess.file_exists(body_path) or not FileAccess.file_exists(body_repeat) or sourcebody.load_png_from_buffer(FileAccess.get_file_as_bytes(body_path))!=OK or sourcebody.get_size()!=Vector2i(CONTRACT.WORLD_SIZE) or sourcebody.get_format()!=Image.FORMAT_RGBA8 or sourcebody.get_used_rect().size==Vector2i.ZERO or sourcebody.get_used_rect().size.x>=CONTRACT.WORLD_SIZE.x/2 or sourcebody.get_used_rect().size.y>=CONTRACT.WORLD_SIZE.y/2 or sourcebody.get_pixel(0,0).a!=0.0 or FileAccess.get_sha256(body_path)!=FileAccess.get_sha256(body_repeat):
			push_error("Refuse v12 unreadable, nonlocal or nonrepeatable actual sourcebody: "+body_path)
			quit(1)
			return false
	if not ResourceLoader.exists(CONTRACT.PREFIX+"shadow.png"):
		push_error("v12 requires both rocks, eight individually sorted low herbs and native ground shadow output")
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




