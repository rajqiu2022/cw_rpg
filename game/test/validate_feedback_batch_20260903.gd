extends SceneTree

const WORLD_SCENE := "res://data/scenes/world_map_jianghu.tres"
const LINXI_SCENE := "res://data/scenes/linxi_village_scrollmap.tres"

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_validate_field_protagonist_scale()
	_validate_world_map_art_and_navigation()
	await _validate_reading_button()
	print("[FeedbackBatch20260903] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[FeedbackBatch20260903] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _validate_field_protagonist_scale() -> void:
	var scene := load(LINXI_SCENE) as SceneScript
	_check(scene != null, "林西南坊场景可加载")
	if scene == null:
		return
	# Current protagonist and reviewed NPC strips use the same 160px cell. The
	# scene multiplier therefore must compensate for Player.VISUAL_SCALE.
	var protagonist_effective_scale := Player.VISUAL_SCALE * scene.player_visual_scale
	var tallest_ordinary_npc_scale := scene.npc_visual_scale
	_check(protagonist_effective_scale >= tallest_ordinary_npc_scale, "主角有效缩放不小于场景内1.0倍率NPC")
	_check(scene.player_visual_scale >= 0.69, "林西南坊主角已从旧0.60比例恢复")


func _validate_world_map_art_and_navigation() -> void:
	var scene := load(WORLD_SCENE) as SceneScript
	_check(scene != null and scene.map_layout != null, "江湖大地图资源可加载")
	if scene == null or scene.map_layout == null:
		return
	var background := Image.load_from_file(ProjectSettings.globalize_path(scene.background_path))
	var mask := Image.load_from_file(ProjectSettings.globalize_path(scene.map_layout.walkable_mask_path))
	_check(background != null and background.get_size() == Vector2i(2304, 1536), "重绘地图使用性能更稳的2304×1536运行尺寸")
	_check(mask != null and mask.get_size() == Vector2i(2304, 1536), "道路蒙版与地图同尺寸")
	if mask == null:
		return
	for point: Vector2 in [Vector2(0.190, 0.650), Vector2(0.360, 0.755), Vector2(0.835, 0.555)]:
		_check(_walkable(mask, point), "v8关键连接路可走：%s" % point)
	for point: Vector2 in [Vector2(0.565, 0.270), Vector2(0.620, 0.300)]:
		_check(not _walkable(mask, point), "洛阳建筑区没有直穿道路：%s" % point)


func _validate_reading_button() -> void:
	var panel := preload("res://scenes/ui/reading_panel.tscn").instantiate() as ReadingPanel
	root.add_child(panel)
	await process_frame
	var close_button := panel.get_node_or_null("ReadablePanelArt/CloseReader") as Button
	_check(close_button != null, "残页阅读界面合卷按钮存在")
	if close_button != null:
		_check(close_button.size.x >= 250.0 and close_button.size.y >= 64.0, "合卷按钮尺寸不再过小")
		_check(close_button.get_theme_font_size("font_size") >= 22, "合卷文字清晰且不会挤压")
		_check(close_button.position.x >= 0.0 and close_button.position.x + close_button.size.x <= 960.0, "合卷按钮未超出正式面板")
	panel.queue_free()


func _walkable(mask: Image, point: Vector2) -> bool:
	var x := clampi(roundi(point.x * float(mask.get_width() - 1)), 0, mask.get_width() - 1)
	var y := clampi(roundi(point.y * float(mask.get_height() - 1)), 0, mask.get_height() - 1)
	var sample := mask.get_pixel(x, y)
	return sample.a >= 0.5 and maxf(sample.r, maxf(sample.g, sample.b)) >= 0.5


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
