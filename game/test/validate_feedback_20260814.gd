extends Node

var _checked := 0
var _failed := 0


func _ready() -> void:
	_validate_linxi_center()
	_validate_south_district()
	_validate_zhuwei_routes()
	_validate_shop_art()
	_validate_quest_detail_contract()
	print("[Feedback20260814] checked=%d failed=%d" % [_checked, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _validate_linxi_center() -> void:
	var scene := load("res://data/scenes/linxi_village_center.tres") as SceneScript
	_check(scene != null, "Linxi center loads")
	if scene == null:
		return
	var qinghe := _find_npc(scene.npcs, "shen_qinghe_recruit")
	_check(not qinghe.is_empty(), "Shen Qinghe exists")
	_check(String(qinghe.get("sprite_path", "")).ends_with("npc_shen_qinghe_idle_down_25d_4f_v1_runtime.png"), "Shen Qinghe uses her portrait-matched dedicated sprite")
	var qinghe_pos := Vector2(qinghe.get("pos", Vector2.ZERO))
	_check(qinghe_pos.x >= 0.79 and qinghe_pos.y >= 0.48 and qinghe_pos.y <= 0.56, "Shen Qinghe stands on the authored east-side road")
	if scene.map_layout != null:
		_check(not _point_in_any_blocker(qinghe_pos, scene.map_layout.blockers), "Shen Qinghe does not stand inside a building blocker")
	var dialog := load("res://data/dialogs/linxi_companion_shen_qinghe.tres") as DialogScript
	_check(dialog != null and dialog.get_entry_node() != null, "Shen Qinghe recruitment dialog loads")
	if dialog != null and dialog.get_entry_node() != null:
		var opening: String = dialog.get_entry_node().text
		_check(not opening.contains("外出") and not opening.contains("下山") and not opening.contains("竹尾"), "opening does not know the protagonist's travel plan in advance")
	var peddler := _find_npc(scene.npcs, "linxi_peddler")
	_check(String(peddler.get("sprite_path", "")).ends_with("v3_runtime.png"), "Linxi peddler uses the raw-source rebuilt full-body strip")
	_validate_strip_bottom_margin(String(peddler.get("sprite_path", "")), 4, 6, 16)


func _validate_south_district() -> void:
	var scene := load("res://data/scenes/linxi_village_scrollmap.tres") as SceneScript
	_check(scene != null, "south district loads")
	if scene == null:
		return
	_check(scene.npc_visual_scale >= 0.64, "south district NPC scale is no longer undersized")
	_check(scene.camera_zoom <= 1.11, "south district no longer over-zooms its large background")
	var coach := _find_npc(scene.npcs, "linxi_south_militia_coach")
	_check(float(coach.get("scale", 0.0)) >= 1.0, "militia coach uses readable scale")
	_check(String(coach.get("interaction_action", "")).begins_with("spar:"), "militia coach supports spar interaction")
	var peddler := _find_npc(scene.npcs, "linxi_south_peddler")
	_check(String(peddler.get("sprite_path", "")).ends_with("v3_runtime.png"), "south district peddler uses the rebuilt full-body strip")


func _validate_zhuwei_routes() -> void:
	var scene := load("res://data/scenes/ch1_s2_qingfeng.tres") as SceneScript
	_check(scene != null and scene.map_layout != null, "Zhuwei main street layout loads")
	if scene == null or scene.map_layout == null:
		return
	var forest := _find_entry(scene.map_layout.portals, "to_zhuwei_forest")
	_check(not forest.is_empty(), "forest portal exists")
	_check(Vector2(forest.get("pos", Vector2.ZERO)).x >= 0.92, "forest marker is on the right map edge")
	var clearance := _find_entry(scene.map_layout.walkable_probes, "zhuwei_forest_edge_clearance")
	_check(Vector2(clearance.get("pos", Vector2.ZERO)).x >= 0.98, "right-edge route has a walkable clearance probe")
	var road := load("res://data/scenes/ch1_s1_road.tres") as SceneScript
	_check(road != null and road.background_path.ends_with("bg_ch1_s1_road_cave_entry_v2.png"), "village road uses the background with a visible cave entrance")


func _validate_shop_art() -> void:
	for path in [
		"res://art/ui/shop/buttons_v2/shop_rect_normal.png",
		"res://art/ui/shop/buttons_v2/shop_rect_hover.png",
		"res://art/ui/shop/buttons_v2/shop_rect_pressed.png",
	]:
		var texture := load(path) as Texture2D
		_check(texture != null, "%s loads" % path.get_file())
		if texture != null:
			_check(texture.get_size() == Vector2(512, 128), "%s keeps the 4:1 rectangular button ratio" % path.get_file())


func _validate_quest_detail_contract() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/quest_panel.gd")
	_check(not source.contains("[b]%s[/b]"), "quest detail title does not use blurry bold BBCode")
	_check(source.contains("ITEM_DETAIL_TIP") and source.contains("_show_reward_item_detail"), "reward icons open the shared item detail tip")
	_check(source.contains("get_global_transform_with_canvas") and not source.contains("panel.to_local"), "reward detail positioning uses Control canvas transforms")
	_check(source.contains("reward_text.text = \"\\n\".join(reward_lines)"), "gold and experience rewards use aligned separate lines")
	var tip_texture := load("res://art/ui/quest/detail_panel_v2.png") as Texture2D
	_check(tip_texture != null, "reward detail tip uses the formal shared panel art")


func _validate_strip_bottom_margin(resource_path: String, frames: int, minimum: int, maximum: int) -> void:
	var absolute := ProjectSettings.globalize_path(resource_path)
	var image := Image.load_from_file(absolute)
	_check(not image.is_empty(), "full-body runtime strip loads")
	if image.is_empty():
		return
	_check(image.get_width() % frames == 0, "full-body strip divides into equal frames")
	var frame_width: int = image.get_width() / frames
	for frame in range(frames):
		var max_y := -1
		for y in range(image.get_height()):
			for x in range(frame * frame_width, (frame + 1) * frame_width):
				if image.get_pixel(x, y).a > 0.02:
					max_y = maxi(max_y, y)
		var margin := image.get_height() - 1 - max_y
		_check(max_y >= 0 and margin >= minimum and margin <= maximum, "frame %d keeps %d..%d px foot clearance" % [frame, minimum, maximum])


func _find_npc(entries: Array[Dictionary], npc_id: String) -> Dictionary:
	return _find_entry(entries, npc_id, "npc_id")


func _find_entry(entries: Array, entry_id: String, key: String = "id") -> Dictionary:
	for value in entries:
		var entry: Dictionary = value
		if String(entry.get(key, "")) == entry_id:
			return entry
	return {}


func _point_in_any_blocker(point: Vector2, blockers: Array[Dictionary]) -> bool:
	for blocker in blockers:
		var pos: Vector2 = blocker.get("pos", Vector2.ZERO)
		var half: Vector2 = blocker.get("size", Vector2.ZERO) * 0.5
		if Rect2(pos - half, half * 2.0).has_point(point):
			return true
	return false


func _check(condition: bool, message: String) -> void:
	_checked += 1
	if condition:
		return
	_failed += 1
	push_error("[Feedback20260814] %s" % message)
