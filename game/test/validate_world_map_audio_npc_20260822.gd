extends SceneTree

const WORLD_LAYOUT := "res://data/maps/world_map_jianghu_layout_v10.tres"
const WORLD_SCENE := "res://data/scenes/world_map_jianghu.tres"
const NPC_CATALOG := preload("res://data/npcs/npc_catalog.tres")
const LEGENDARY_TITLE_SFX := "res://art/audio/free/sfx_legendary_title_reveal_v2.wav"
const LEFT_AUTHORED_ASSETS := [
	"npc_linxi_south_militia_coach_idle_down_4f_v2_runtime.png",
	"npc_wulin_examiner_idle_down_4f.png",
]

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_validate_world_map_topology()
	_validate_bidirectional_gates()
	_validate_npc_scale_and_facing()
	_validate_audio_and_battle_arenas()
	print("[WorldMapAudioNpc20260822] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[WorldMapAudioNpc20260822] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _validate_world_map_topology() -> void:
	var layout := load(WORLD_LAYOUT) as WalkableMapLayout
	var scene := load(WORLD_SCENE) as SceneScript
	_check(layout != null and scene != null, "世界地图v4资源可加载")
	if layout == null or scene == null:
		return
	_check(layout.design_size == Vector2i(2304, 1536), "世界地图使用兼顾多屏探索与小游戏性能的2304×1536尺寸")
	_check(ResourceLoader.exists(layout.walkable_mask_path), "世界地图运行时使用像素道路蒙版")
	_check(not layout.walkable_mask_path.is_empty(), "世界地图使用像素道路蒙版而非逐帧多边形遍历")
	var image := Image.load_from_file(ProjectSettings.globalize_path(scene.background_path))
	_check(image != null and image.get_size() == Vector2i(2304, 1536), "世界地图运行底图尺寸与逻辑尺寸一致")
	var mask := Image.load_from_file(ProjectSettings.globalize_path(layout.walkable_mask_path))
	_check(mask != null and mask.get_size() == layout.design_size, "世界地图道路蒙版尺寸正确")

	var linxi := _entry(layout.portals, "linxi_village")
	var zhuwei := _entry(layout.portals, "zhuwei_village")
	var mingwu := _entry(layout.portals, "mingwu")
	var linxi_pos: Vector2 = linxi.get("pos", Vector2.ZERO)
	var zhuwei_pos: Vector2 = zhuwei.get("pos", Vector2.ONE)
	var mingwu_pos: Vector2 = mingwu.get("pos", Vector2.ZERO)
	_check(linxi_pos.distance_to(zhuwei_pos) < 0.15, "林西村与竹尾村为相邻村落")
	_check(mingwu_pos.x > 0.75 and mingwu_pos.distance_to(linxi_pos) > 0.55, "茗雾山迁至东南且不再隔开两村")

	for portal: Dictionary in layout.portals:
		var pos: Vector2 = portal.get("pos", Vector2(-1.0, -1.0))
		_check(mask != null and _mask_walkable(mask, pos), "门户位于可行走道路：%s" % String(portal.get("id", "?")))
	for probe: Dictionary in layout.walkable_probes:
		_check(mask != null and _mask_walkable(mask, probe.get("pos", Vector2.ZERO)), "通行探针有效：%s" % String(probe.get("id", "?")))
	for probe: Dictionary in layout.blocked_probes:
		_check(mask != null and not _mask_walkable(mask, probe.get("pos", Vector2.ZERO)), "山林水域探针被阻挡：%s" % String(probe.get("id", "?")))


func _validate_bidirectional_gates() -> void:
	var world := load(WORLD_LAYOUT) as WalkableMapLayout
	if world == null:
		return
	var pairs := [
		{"portal": "linxi_village", "layout": "res://data/maps/linxi_village_scrollmap_layout_v1.tres", "exit": "linxi_to_world_map"},
		{"portal": "zhuwei_village", "layout": "res://data/maps/ch1_s2_qingfeng_layout_v2.tres", "exit": "zhuwei_to_world_map"},
	]
	for pair: Dictionary in pairs:
		var world_portal := _entry(world.portals, String(pair.portal))
		var city := load(String(pair.layout)) as WalkableMapLayout
		var city_exit := _entry(city.portals if city != null else [], String(pair.exit))
		var target_pos: Vector2 = world_portal.get("target_pos", Vector2.ZERO)
		var exit_pos: Vector2 = city_exit.get("pos", Vector2.ONE)
		_check(target_pos.distance_to(exit_pos) <= 0.08, "世界地图返回同一城门内侧：%s" % String(pair.portal))
		_check(city_exit.get("target_pos", Vector2.ZERO) == world_portal.get("pos", Vector2.ONE), "城门离开点与世界入口锚点一致：%s" % String(pair.portal))

	var router_source := FileAccess.get_file_as_string("res://scripts/autoload/scene_router.gd")
	_check(router_source.contains("WORLD_MAP_REGION_PORTALS") and router_source.contains("get_world_map_position_for_scene"), "SceneRouter从世界布局读取区域锚点")


func _validate_npc_scale_and_facing() -> void:
	var zhuwei := load("res://data/scenes/ch1_s2_qingfeng.tres") as SceneScript
	_check(zhuwei != null, "竹尾村主街可加载")
	if zhuwei != null:
		for npc: Dictionary in zhuwei.npcs:
			var profile: NPCProfile = NPC_CATALOG.find(StringName(npc.get("npc_id", "")), zhuwei.scene_id)
			var scale := float(npc.get("scale", 1.0))
			var sprite_path := String(npc.get("walk_sprite_path", npc.get("sprite_path", "")))
			if profile != null:
				scale = profile.sprite_scale
				if profile.walk_sprite_path != "":
					sprite_path = profile.walk_sprite_path
				elif sprite_path.is_empty() and profile.sprite_path != "":
					sprite_path = profile.sprite_path
			var body_height := _first_frame_alpha_height(sprite_path) * scale
			_check(body_height >= 119.0 and body_height <= 126.0, "竹尾NPC有效身高归一：%s=%.1f" % [String(npc.get("npc_id", "?")), body_height])

	var scene_dir := DirAccess.open("res://data/scenes")
	if scene_dir == null:
		_check(false, "可扫描场景NPC朝向")
		return
	for file_name: String in scene_dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var scene := load("res://data/scenes/%s" % file_name) as SceneScript
		if scene == null:
			continue
		for npc: Dictionary in scene.npcs:
			var sprite_path := String(npc.get("sprite_path", ""))
			for authored_name: String in LEFT_AUTHORED_ASSETS:
				if sprite_path.ends_with(authored_name):
					_check(String(npc.get("conversation_base_facing", "")) == "left", "左向原图已声明对话基础朝向：%s/%s" % [String(scene.scene_id), String(npc.get("npc_id", "?"))])


func _validate_audio_and_battle_arenas() -> void:
	_check(ResourceLoader.exists(LEGENDARY_TITLE_SFX), "绝学题字音效已接入")
	var legendary_source := FileAccess.get_file_as_string("res://scripts/battle/legendary_skill_cinematic.gd")
	_check(legendary_source.contains("emit_signal(\"sfx_requested\", LEGENDARY_TITLE_SFX"), "绝学题字动画触发独立音效")
	var unique_bgm: Dictionary = {}
	var scene_dir := DirAccess.open("res://data/scenes")
	for file_name: String in scene_dir.get_files() if scene_dir != null else []:
		if not file_name.ends_with(".tres"):
			continue
		var scene := load("res://data/scenes/%s" % file_name) as SceneScript
		if scene == null:
			continue
		_check(not scene.bgm_path.is_empty() and ResourceLoader.exists(scene.bgm_path), "场景配乐存在：%s" % String(scene.scene_id))
		unique_bgm[scene.bgm_path] = true
	_check(unique_bgm.size() >= 8, "探索场景至少使用8种配乐主题")
	var router_source := FileAccess.get_file_as_string("res://scripts/autoload/scene_router.gd")
	_check(router_source.contains("return &\"village_square\"") and router_source.contains("return &\"sect_courtyard\"") and router_source.contains("return &\"river_skirmish\""), "场景类型会选择村镇、门派和河谷战场")
	var battle_source := FileAccess.get_file_as_string("res://scripts/battle/battle_controller.gd")
	for path: String in [
		"res://art/backgrounds/bg_battle_bamboo_day_v1.png",
		"res://art/backgrounds/bg_battle_river_valley_day_v1.png",
		"res://art/backgrounds/bg_battle_mountain_gate_day_v1.png",
		"res://art/backgrounds/battle_arenas_v2/bg_battle_outskirts_road_v1.jpg",
	]:
		_check(ResourceLoader.exists(path) and battle_source.contains(path), "战斗场景图已接入：%s" % path.get_file())


func _first_frame_alpha_height(path: String) -> float:
	if path.is_empty() or not FileAccess.file_exists(path):
		return 0.0
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.get_height() <= 0:
		return 0.0
	var frame_width := mini(image.get_height(), image.get_width())
	var frame := image.get_region(Rect2i(0, 0, frame_width, image.get_height()))
	return float(frame.get_used_rect().size.y)


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
