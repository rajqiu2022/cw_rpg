extends SceneTree

const WORLD_LAYOUT := "res://data/maps/world_map_jianghu_layout_v10.tres"
const WORLD_SCENE := "res://data/scenes/world_map_jianghu.tres"

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_validate_world_single_source()
	_validate_first_zhuwei_departure()
	_validate_later_scene_contracts()
	print("[WorldMapSceneStandards20260822] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[WorldMapSceneStandards20260822] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _validate_world_single_source() -> void:
	var layout := load(WORLD_LAYOUT) as WalkableMapLayout
	var scene := load(WORLD_SCENE) as SceneScript
	_check(layout != null and scene != null, "世界地图v9资源可加载")
	if layout == null or scene == null:
		return
	_check(scene.map_layout == layout, "运行世界地图直接引用v9拓扑")
	_check(layout.schema_version == 9 and not layout.walkable_mask_path.is_empty(), "道路使用同源像素导航蒙版")
	_check(layout.walkable_regions.size() < 100, "兜底道路不再膨胀为数百栅格矩形")
	var mask := Image.load_from_file(ProjectSettings.globalize_path(layout.walkable_mask_path))
	_check(mask != null and mask.get_size() == Vector2i(2304, 1536), "世界地图道路蒙版尺寸正确")
	if mask != null:
		for connector_probe: Vector2 in [Vector2(746.0 / 1920.0, 495.0 / 1280.0), Vector2(776.0 / 1920.0, 568.0 / 1280.0), Vector2(1173.0 / 1920.0, 837.0 / 1280.0)]:
			_check(_mask_walkable(mask, connector_probe), "v9关键连接路已纳入可行走区域：%s" % connector_probe)
		for city_probe: Vector2 in [Vector2(0.565, 0.270), Vector2(0.620, 0.300)]:
			_check(not _mask_walkable(mask, city_probe), "洛阳建筑区不允许道路直穿：%s" % city_probe)
	_check(String(_entry(layout.portals, "bailu_ferry").get("travel_mode", "")) == "ferry", "白鹿渡使用乘船换乘")
	_check(String(_entry(layout.portals, "east_sea_port").get("travel_mode", "")) == "ferry", "东海埠使用乘船换乘")
	for portal: Dictionary in layout.portals:
		var pos: Vector2 = portal.get("pos", Vector2(-1.0, -1.0))
		_check(mask != null and _mask_walkable(mask, pos), "世界入口位于可行走官道：%s" % String(portal.get("id", "?")))
	var map_panel_source := FileAccess.get_file_as_string("res://scripts/ui/world_map_panel.gd")
	_check(map_panel_source.contains("WORLD_SCENE_PATH") and map_panel_source.contains("world_scene.map_layout.portals"), "M地图读取运行世界拓扑")
	_check(map_panel_source.contains("PLAYER_MARKER_PATH") and map_panel_source.contains("get_world_map_position_for_scene"), "M地图显示当前主角位置")
	_check(map_panel_source.contains("var marker := Sprite2D.new()") and not map_panel_source.contains("marker_style"), "当前位置使用无底框全身小人")
	_check(not map_panel_source.contains("const LOCATIONS"), "M地图不再维护旧坐标副本")
	var map_panel_scene := FileAccess.get_file_as_string("res://scenes/ui/world_map_panel.tscn")
	_check('[node name="CloseBtn" type="TextureButton"' in map_panel_scene, "M地图右上角使用统一X纹理按钮")
	_check("btn_x_normal.png" in map_panel_source and "btn_x_hover.png" in map_panel_source and "btn_x_pressed.png" in map_panel_source, "M地图X按钮具备统一三态资源")
	var router_source := FileAccess.get_file_as_string("res://scripts/autoload/scene_router.gd")
	_check(router_source.contains("WORLD_MAP_REGION_PORTALS") and router_source.contains("world_scene.map_layout.portals"), "城市返回点通过门户ID解析")


func _validate_first_zhuwei_departure() -> void:
	var road := load("res://data/maps/ch1_s1_road_layout_v5.tres") as WalkableMapLayout
	_check(road != null, "林西山道布局可加载")
	if road == null:
		return
	var intro := _entry(road.portals, "exit_to_zhuwei_intro")
	var direct := _entry(road.portals, "exit_to_zhuwei")
	_check(String(intro.get("action", "")) == "dialog:ch1_road_to_zhuwei", "首次离开播放竹尾村自述")
	_check(String(intro.get("hide_flag", "")) == "ready_for_zhuwei", "首次自述完成后永久隐藏")
	_check(String(direct.get("target_scene", "")) == "ch1_s2_qingfeng", "再次离开直接进入竹尾村")
	_check(String(direct.get("require_flag", "")) == "ready_for_zhuwei", "直接出口只在首次自述后出现")


func _validate_later_scene_contracts() -> void:
	for chapter: int in [2, 3, 4]:
		var dir := DirAccess.open("res://data/scenes")
		for file_name: String in dir.get_files() if dir != null else []:
			if not file_name.begins_with("ch%d_" % chapter) or not file_name.ends_with(".tres"):
				continue
			var scene := load("res://data/scenes/%s" % file_name) as SceneScript
			_check(scene != null and scene.is_walkable and scene.map_layout != null, "后期场景拥有正式行走轮廓：%s" % file_name)
	var docks := load("res://data/scenes/ch4_s2_canal_docks.tres") as SceneScript
	_check(docks != null and docks.background_path.ends_with("bg_luoyang_city_composite_v2_2304.png"), "洛阳码头使用现行城市母图分区")
	var field_source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	_check(field_source.contains('action == "world_map"') and field_source.contains('portal["action"] = "world_map"'), "返回大地图的旧热点转换为出口箭头")


func _inside_any(pos: Vector2, regions: Array[PackedVector2Array]) -> bool:
	for region: PackedVector2Array in regions:
		if Geometry2D.is_point_in_polygon(pos, region):
			return true
	return false


func _mask_walkable(mask: Image, pos: Vector2) -> bool:
	var x := clampi(roundi(pos.x * float(mask.get_width() - 1)), 0, mask.get_width() - 1)
	var y := clampi(roundi(pos.y * float(mask.get_height() - 1)), 0, mask.get_height() - 1)
	var sample := mask.get_pixel(x, y)
	return sample.a >= 0.5 and maxf(sample.r, maxf(sample.g, sample.b)) >= 0.5


func _entry(entries: Array[Dictionary], id: String) -> Dictionary:
	for entry: Dictionary in entries:
		if String(entry.get("id", "")) == id:
			return entry
	return {}


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
