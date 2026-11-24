extends SceneTree

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_validate_building_occluder()
	_validate_main_route()
	_validate_side_quest_feedback_and_revisits()
	_validate_side_offer_catalog()
	_finish()


func _validate_building_occluder() -> void:
	var scene := load("res://data/scenes/linxi_village_center.tres") as SceneScript
	_check(scene != null and scene.map_layout != null, "林西村中心加载分层地图")
	if scene == null or scene.map_layout == null:
		return
	var occluder := _find_entry(scene.map_layout.occluders, "southeast_house_foreground")
	_check(not occluder.is_empty(), "截图所示屋顶拥有独立建筑前景")
	var fade_region: PackedVector2Array = occluder.get("fade_region", PackedVector2Array())
	_check(Geometry2D.is_point_in_polygon(Vector2(0.72, 0.78), fade_region), "角色进入屋檐遮挡区时触发半透明")
	_check(is_equal_approx(float(occluder.get("actor_faded_alpha", 1.0)), 0.46), "仅角色淡出到可辨透明度")
	_check(scene.background_path.ends_with("bg_linxi_village_center_25d_v2_three_routes.png"), "林西村中心使用原始完整地图作为底图")
	_check(String(occluder.get("mask_texture_path", "")) != "" and String(occluder.get("mask_texture_path", "")) != scene.background_path, "遮挡层以独立clean plate识别建筑轮廓")
	_check(bool(occluder.get("isolate_difference", false)), "建筑前景以新旧底图差分隔离，不叠加周围地面")
	var occluder_source := FileAccess.get_file_as_string("res://scripts/field/dynamic_occluder_2d.gd")
	_check(occluder_source.contains("difference_threshold") and occluder_source.contains("building_mask"), "运行时差分材质只保留建筑像素")
	_check(occluder_source.contains("modulate = Color.WHITE"), "建筑前景始终保持不透明")
	var field_source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	_check(field_source.contains("set_building_overlap(player_is_under_building"), "屋檐区域只改变角色透明度")


func _validate_main_route() -> void:
	var village := load("res://data/scenes/ch1_s2_qingfeng.tres") as SceneScript
	var forest := load("res://data/scenes/ch1_s3_zhuwei_forest.tres") as SceneScript
	_check(village != null and forest != null, "竹尾村与后山密林场景可加载")
	if village == null or forest == null:
		return
	var intro := load("res://data/dialogs/ch1_s2_intro.tres") as DialogScript
	var scout := load("res://data/dialogs/ch1_s2_patrol_scout.tres") as DialogScript
	var report := load("res://data/dialogs/ch1_s2_guard_report.tres") as DialogScript
	var cave_clue := load("res://data/dialogs/ch1_zhuwei_cave_clue.tres") as DialogScript
	_check(_dialog_accepts(intro, &"q_ch1_main_village_inquiry"), "进入竹尾村自动接取村内调查")
	var scout_start := scout.get_entry_node() if scout != null else null
	_check(scout_start != null and _node_sets_flag(scout_start, "zhuwei_scout_clue"), "与镖师交谈即取得主线线索")
	_check(scout_start != null and scout_start.accept_quest == &"", "主线线索不再依赖接受清匪支线")
	_check(_dialog_sets_flag(report, "zhuwei_village_inquiry_done"), "向守村人汇总三份消息后解锁密林")
	_check(_dialog_accepts(report, &"q_ch1_main_zhuwei_wilds"), "汇总线索后自动衔接后山主线")
	var forest_portal := _find_entry(village.map_layout.portals, "to_zhuwei_forest")
	_check(String(forest_portal.get("require_flag", "")) == "zhuwei_village_inquiry_done", "密林出口只依赖已完成的村内调查")
	var cave_portal := _find_entry(forest.map_layout.portals, "enter_beast_cave")
	_check(String(cave_portal.get("require_flag", "")) == "defeated_linxi_wild_beast", "击退林中猛兽后开放洞窟")
	_check(String(cave_portal.get("locked_label", "")) == "洞穴里极其阴冷，危机四伏，还是暂时不要进入！", "洞窟使用剧情化锁定提示")
	_check(_dialog_sets_flag(cave_clue, "clue_west_ruin_supply_route"), "洞窟送货记录解锁废宅")
	_check(_dialog_accepts(cave_clue, &"q_ch1_main_west_ruin_trace"), "洞窟调查自动衔接废宅主线")
	var ruin_portal := _find_entry(village.map_layout.portals, "to_west_ruin")
	_check(String(ruin_portal.get("require_flag", "")) == "clue_west_ruin_supply_route", "废宅只在取得洞窟送货线索后开放")
	var field_source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	_check(not field_source.contains("出口未解锁：%s"), "锁定出口不再附加生硬的未解锁前缀")


func _validate_side_quest_feedback_and_revisits() -> void:
	var field_source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	var quest_source := FileAccess.get_file_as_string("res://scripts/autoload/quest_manager.gd")
	var npc_source := FileAccess.get_file_as_string("res://scripts/field/npc_node.gd")
	_check(field_source.contains("EventBus.quest_accepted.connect(_on_quest_accepted)"), "Field监听支线接取事件")
	_check(field_source.contains("接收任务："), "接取任务显示正式提示")
	_check(field_source.contains("func _build_active_side_quest_followup"), "未配置专属变体的支线NPC也不会重复初次邀约")
	_check(quest_source.contains("def.kind == QuestDef.Kind.SIDE and get_tracked_side_quest() == null"), "首个支线自动成为当前追踪")
	_check(npc_source.contains("require_quest_active") and npc_source.contains("require_quest_completed"), "NPC对话变体支持任务状态")
	var village := load("res://data/scenes/ch1_s2_qingfeng.tres") as SceneScript
	for expected in [
		{"npc": "vegetable_vendor", "dialog": "ch1_s2_vegetable_vendor_waiting", "quest": "q_ch1_side_12_forest_medicine"},
		{"npc": "patrol_scout", "dialog": "ch1_s2_patrol_scout_waiting", "quest": "q_ch1_side_08_mountain_patrol"},
		{"npc": "patrol_scout", "dialog": "ch1_s2_bandit_cave_waiting", "quest": "q_ch1_side_10_bandit_cave"},
	]:
		var npc := _find_npc(village.npcs, expected["npc"])
		_check(_has_active_quest_variant(npc, expected["dialog"], expected["quest"]), "%s接任务后改用进行中对话" % expected["npc"])
		_check(ResourceLoader.exists("res://data/dialogs/%s.tres" % expected["dialog"]), "%s进行中对话资源存在" % expected["npc"])
	var crying_wait := FileAccess.get_file_as_string("res://data/dialogs/ch1_s2_crying_woman_waiting.tres")
	_check(crying_wait.contains("有消息了吗") and crying_wait.contains("还没有找到"), "救人支线复访包含NPC询问与主角回应")
	var herb_wait := FileAccess.get_file_as_string("res://data/dialogs/ch1_s2_vegetable_vendor_waiting.tres")
	_check(herb_wait.contains("有消息了吗") and herb_wait.contains("仍在寻找"), "采药支线复访包含NPC询问与主角回应")

	var quest_manager := root.get_node_or_null("QuestManager")
	_check(quest_manager != null, "QuestManager可用于追踪规则实测")
	if quest_manager != null:
		quest_manager.call("reset_for_new_game")
		_check(bool(quest_manager.call("accept", &"q_ch1_side_12_forest_medicine")), "可接取第一条支线")
		_check(StringName(quest_manager.get("tracked_side_quest_id")) == &"q_ch1_side_12_forest_medicine", "没有追踪目标时自动追踪新支线")
		_check(bool(quest_manager.call("accept", &"q_ch1_side_08_mountain_patrol")), "可继续接取第二条支线")
		_check(StringName(quest_manager.get("tracked_side_quest_id")) == &"q_ch1_side_12_forest_medicine", "新支线不会覆盖玩家已有追踪")
		var npc_scene := load("res://scenes/npc_node.tscn") as PackedScene
		var runtime_npc := npc_scene.instantiate() as NPCNode if npc_scene != null else null
		_check(runtime_npc != null, "NPC运行节点可实例化")
		if runtime_npc != null:
			runtime_npc.dialog_id = "ch1_s2_vegetable_vendor"
			runtime_npc.dialog_variants.assign([{"dialog_id": "ch1_s2_vegetable_vendor_waiting", "require_quest_active": "q_ch1_side_12_forest_medicine"}])
			root.add_child(runtime_npc)
			_check(String(runtime_npc.call("_resolve_dialog_id")) == "ch1_s2_vegetable_vendor_waiting", "运行时复访会切换到任务进行中对话")
			runtime_npc.free()


func _validate_side_offer_catalog() -> void:
	var directory := DirAccess.open("res://data/dialogs")
	_check(directory != null, "支线对话目录可审计")
	if directory == null:
		return
	var offer_count := 0
	directory.list_dir_begin()
	var file_name := directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.ends_with(".tres"):
			var dialog := load("res://data/dialogs/%s" % file_name) as DialogScript
			if dialog != null:
				for node: DialogNode in dialog.nodes:
					if node == null or node.accept_quest == &"":
						continue
					var quest := load("res://data/quests/%s.tres" % String(node.accept_quest)) as QuestDef
					if quest == null or quest.kind != QuestDef.Kind.SIDE:
						continue
					offer_count += 1
					var same_node_completion := node.complete_quest == node.accept_quest
					_check(not same_node_completion or String(node.accept_quest).begins_with("q_secret_"), "%s不会在同一节点接取并立即完成普通支线" % file_name)
		file_name = directory.get_next()
	directory.list_dir_end()
	_check(offer_count >= 25, "全章节支线接取节点已纳入重复对话审计")


func _find_entry(entries: Array, entry_id: String) -> Dictionary:
	for raw_entry: Variant in entries:
		if raw_entry is Dictionary and String((raw_entry as Dictionary).get("id", "")) == entry_id:
			return raw_entry as Dictionary
	return {}


func _find_npc(entries: Array, npc_id: String) -> Dictionary:
	for raw_entry: Variant in entries:
		if raw_entry is Dictionary and String((raw_entry as Dictionary).get("npc_id", "")) == npc_id:
			return raw_entry as Dictionary
	return {}


func _has_active_quest_variant(npc: Dictionary, dialog_id: String, quest_id: String) -> bool:
	for raw_variant: Variant in npc.get("dialog_variants", []):
		if not raw_variant is Dictionary:
			continue
		var variant := raw_variant as Dictionary
		if String(variant.get("dialog_id", "")) == dialog_id and String(variant.get("require_quest_active", "")) == quest_id:
			return true
	return false


func _dialog_accepts(dialog: DialogScript, quest_id: StringName) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		if node != null and node.accept_quest == quest_id:
			return true
	return false


func _dialog_sets_flag(dialog: DialogScript, flag_key: String) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		if node != null and _node_sets_flag(node, flag_key):
			return true
	return false


func _node_sets_flag(node: DialogNode, flag_key: String) -> bool:
	for entry: Dictionary in node.set_flags:
		if String(entry.get("key", "")) == flag_key and bool(entry.get("value", true)):
			return true
	return false


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _finish() -> void:
	print("[Ch1ZhuweiQuestRelease20260818] checks=%d failed=%d" % [checks, failures.size()])
	for failure in failures:
		push_error("[Ch1ZhuweiQuestRelease20260818] %s" % failure)
	quit(1 if not failures.is_empty() else 0)
