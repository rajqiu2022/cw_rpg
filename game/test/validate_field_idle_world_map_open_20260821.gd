extends SceneTree

const FIELD_ROOT := "res://art/characters/weapon_variants/lengguyun/v7_idle_stable"
const STYLES := ["sword", "dao", "staff", "palm", "hidden"]
const DIRECTIONS := ["down", "up", "left", "right"]
const OPEN_CITY_PORTALS := ["linxi_village", "zhuwei_village", "lingyue", "wudang", "luoyang"]
const CAVE_WARNING := "洞穴里阴暗湿冷，未知风险，暂时不进为妙。"

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_validate_player_idle_feet()
	_validate_zhuwei_npc_motion()
	_validate_cave_warning()
	_validate_open_world_cities()
	print("[FieldIdleWorldMapOpen20260821] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[FieldIdleWorldMapOpen20260821] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _validate_player_idle_feet() -> void:
	for style: String in STYLES:
		for direction: String in DIRECTIONS:
			var path := "%s/%s/lengguyun_%s_idle_%s_25d_4f.png" % [FIELD_ROOT, style, style, direction]
			_check(ResourceLoader.exists(path), "站立条带存在：%s/%s" % [style, direction])
			if not ResourceLoader.exists(path):
				continue
			var image := Image.load_from_file(ProjectSettings.globalize_path(path))
			_check(image != null and image.get_size() == Vector2i(640, 160), "站立条带保持4×160规格：%s/%s" % [style, direction])
			if image == null:
				continue
			var foot_hashes: Array[int] = []
			for frame_index in range(4):
				var frame := image.get_region(Rect2i(frame_index * 160, 105, 160, 55))
				foot_hashes.append(hash(frame.get_data()))
			_check(foot_hashes.all(func(value: int) -> bool: return value == foot_hashes[0]), "静止时双脚不再循环走步：%s/%s" % [style, direction])


func _validate_zhuwei_npc_motion() -> void:
	var scene := load("res://data/scenes/ch1_s2_qingfeng.tres") as SceneScript
	_check(scene != null, "竹尾村主街可加载")
	if scene == null:
		return
	var escort := _find_npc(scene.npcs, "patrol_scout")
	var partner := _find_npc(scene.npcs, "patrol_scout_partner")
	var guard := _find_npc(scene.npcs, "guard")
	_check(String(escort.get("sprite_path", "")) != String(partner.get("sprite_path", "")), "两名镖师使用不同身份资源")
	_check(String(escort.get("walk_sprite_path", "")).ends_with("npc_escort_guard_walk_right_8f_v1_runtime.png"), "巡逻镖师使用真实8帧行走条带")
	_check(String(partner.get("movement_mode", "")) == "idle" and not partner.has("walk_sprite_path"), "镖局枪手固定驻守，不再与同伴反向巡逻")
	_check(float(guard.get("idle_frame_seconds", 0.0)) >= 0.9, "村口守卫转头间隔放慢到可读节奏")
	_check(float(partner.get("idle_frame_seconds", 0.0)) >= 0.9, "驻守枪手头部动作同样放慢")

	var walk_path := String(escort.get("walk_sprite_path", ""))
	var walk := Image.load_from_file(ProjectSettings.globalize_path(walk_path))
	_check(walk != null and walk.get_size() == Vector2i(1280, 160), "镖师walk为8×160运行条带")
	if walk != null:
		var frame_hashes: Dictionary = {}
		for index in range(8):
			var frame := walk.get_region(Rect2i(index * 160, 0, 160, 160))
			frame_hashes[hash(frame.get_data())] = true
		_check(frame_hashes.size() == 8, "镖师8帧脚步互不重复")

	var npc_source := FileAccess.get_file_as_string("res://scripts/field/npc_node.gd")
	_check(npc_source.contains("walk_frame_seconds") and npc_source.contains("idle_frame_seconds"), "NPC站立与行走使用独立切帧速度")


func _validate_cave_warning() -> void:
	var road := load("res://data/maps/ch1_s1_road_layout_v5.tres") as WalkableMapLayout
	var bandit_cave := _find_entry(road.portals if road != null else [], "bandit_cave_entry")
	var forest := load("res://data/maps/ch1_s3_zhuwei_forest_layout_v2.tres") as WalkableMapLayout
	var beast_cave := _find_entry(forest.portals if forest != null else [], "enter_beast_cave")
	_check(String(bandit_cave.get("locked_label", "")) == CAVE_WARNING, "山寨洞口使用阴暗湿冷风险提示")
	var beast_warning := String(beast_cave.get("locked_label", ""))
	_check(beast_warning.contains("阴冷") and beast_warning.contains("危机四伏"), "后山密林洞窟使用世界内风险提示")


func _validate_open_world_cities() -> void:
	var world := load("res://data/maps/world_map_jianghu_layout_v10.tres") as WalkableMapLayout
	_check(world != null, "江湖大地图布局可加载")
	if world == null:
		return
	for portal_id: String in OPEN_CITY_PORTALS:
		var portal := _find_entry(world.portals, portal_id)
		_check(not portal.is_empty(), "世界地图城市入口存在：%s" % portal_id)
		_check(String(portal.get("require_flag", "")).is_empty(), "城市入口无需章节旗标：%s" % portal_id)
		_check(not String(portal.get("target_scene", "")).is_empty(), "城市入口拥有真实目标场景：%s" % portal_id)

	var linxi_exit := _find_entry((load("res://data/maps/linxi_village_scrollmap_layout_v1.tres") as WalkableMapLayout).portals, "linxi_to_world_map")
	var zhuwei_exit := _find_entry((load("res://data/maps/ch1_s2_qingfeng_layout_v2.tres") as WalkableMapLayout).portals, "zhuwei_to_world_map")
	_check(String(linxi_exit.get("require_flag", "")).is_empty(), "新游戏可从林西村直接进入世界地图")
	_check(String(zhuwei_exit.get("require_flag", "")).is_empty(), "竹尾村可随时返回世界地图")

	var gated_scenes := {
		"ch2_s1_zhuwei_market": "chapter1_complete",
		"ch3_s1_wulin_assembly": "chapter2_complete",
		"ch4_s1_luoyang_yamen": "chapter3_complete",
	}
	for scene_id: String in gated_scenes:
		var scene := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
		_check(scene != null and String(scene.on_enter_require_flag) == gated_scenes[scene_id], "%s提前游历时不自动启动主线" % scene_id)

	for dialog_id: String in ["ch2_market_gatekeeper_early_visit", "ch3_assembly_early_visit"]:
		var dialog := load("res://data/dialogs/%s.tres" % dialog_id) as DialogScript
		_check(dialog != null, "提前游历对白存在：%s" % dialog_id)
		if dialog != null:
			for node: DialogNode in dialog.nodes:
				_check(node.accept_quest == &"" and node.complete_quest == &"", "提前游历对白不接取或完成主线：%s/%s" % [dialog_id, node.node_id])


func _find_npc(entries: Array[Dictionary], npc_id: String) -> Dictionary:
	for entry: Dictionary in entries:
		if String(entry.get("npc_id", "")) == npc_id:
			return entry
	return {}


func _find_entry(entries: Array[Dictionary], entry_id: String) -> Dictionary:
	for entry: Dictionary in entries:
		if String(entry.get("id", "")) == entry_id:
			return entry
	return {}


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
