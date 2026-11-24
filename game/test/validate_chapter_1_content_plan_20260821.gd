extends SceneTree

const PLAN_PATH := "res://data/chapters/chapter_1_content_plan.tres"
const LEGACY_QUEST_IDS := {
	&"q_ch1_main_01_thug": true,
	&"q_ch1_main_02_qingfeng": true,
	&"q_ch1_side_yuewuxing": true,
}

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var plan := ResourceLoader.load(PLAN_PATH) as ChapterContentPlan
	_check(plan != null, "第一章内容计划可以加载")
	if plan != null:
		_check(plan.chapter == 1 and plan.title == "林西村下山", "章节编号与现行标题正确")
		_check(plan.main_scene_ids.size() == 8, "第一章登记8张现行主场景")
		_check(plan.main_quest_ids.size() == 9, "第一章登记9段现行主线")
		_check(plan.side_quest_ids.size() == 9, "第一章登记9条当前可玩支线")
		_check(plan.side_quest_decisions.size() == 4, "四条历史支线草案均有明确生产决策")
		_validate_side_quest_decisions(plan.side_quest_decisions)
		_check(plan.leveling_scene_ids.size() == 2, "第一章登记山道和后山两张练级地图")
		_check(plan.story_battle_groups.size() == 6, "第一章登记六个关键战斗节点")
		_check(plan.estimated_main_minutes >= 60, "第一章主路线生产预算不少于60分钟")
		_check(plan.estimated_completionist_minutes >= 120, "第一章全探索生产预算不少于120分钟")
		_validate_resource_ids(plan.main_scene_ids, "scenes")
		_validate_resource_ids(plan.main_quest_ids, "quests")
		_validate_resource_ids(plan.side_quest_ids, "quests")
		for quest_id: StringName in plan.main_quest_ids + plan.side_quest_ids:
			_check(not LEGACY_QUEST_IDS.has(quest_id), "内容计划不包含兼容旧任务 %s" % quest_id)
		for group: Dictionary in plan.story_battle_groups:
			var enemy_ids: Array = group.get("enemy_ids", []) as Array
			var group_id := String(group.get("id", "未命名战斗"))
			var expected_sizes := {
				"road_ambush": 1,
				"forest_beast": 2,
				"cave_alpha_wolf": 3,
				"ruin_outer_guard": 2,
				"caravan_road_ambush": 2,
				"zhao_wuji_showdown": 3,
			}
			var expected_size := int(expected_sizes.get(group_id, 0))
			_check(enemy_ids.size() == expected_size, "%s忠实记录当前敌人配置" % group_id)
			for enemy_id_variant: Variant in enemy_ids:
				var enemy_id := String(enemy_id_variant)
				_check(ResourceLoader.exists("res://data/enemies/%s.tres" % enemy_id), "关键战斗敌人存在：%s" % enemy_id)

	var forest := ResourceLoader.load("res://data/scenes/ch1_s3_zhuwei_forest.tres") as SceneScript
	_check(forest != null, "第一章后山密林可加载")
	if forest != null:
		_check(forest.npcs.is_empty(), "后山密林不再运行时生成悦无星旧线NPC")
		_check(forest.hotspots.is_empty(), "后山密林不再暴露旧版悦无星热点")
	var forest_source := FileAccess.get_file_as_string("res://data/scenes/ch1_s3_zhuwei_forest.tres")
	_check(not forest_source.contains("yuewuxing") and not forest_source.contains("悦无"), "第一章场景资源不再引用第二章人物旧线")

	print("[Chapter1ContentPlan20260821] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[Chapter1ContentPlan20260821] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _validate_resource_ids(ids: Array[StringName], folder: String) -> void:
	for resource_id: StringName in ids:
		_check(ResourceLoader.exists("res://data/%s/%s.tres" % [folder, String(resource_id)]), "%s资源存在：%s" % [folder, resource_id])


func _validate_side_quest_decisions(decisions: Array[Dictionary]) -> void:
	var indexed: Dictionary = {}
	for decision: Dictionary in decisions:
		indexed[String(decision.get("quest_id", ""))] = decision
	_check(String((indexed.get("q_ch1_side_02_cliff_herb", {}) as Dictionary).get("decision", "")) == "implemented", "悬崖采药确认保留并接入第一章")
	_check(int((indexed.get("q_ch1_side_04_tiger_hunt", {}) as Dictionary).get("target_chapter", 0)) == 5, "独猎猛虎迁至第五章雪岭狩猎")
	_check(String((indexed.get("q_ch1_side_05_ancestral_theft", {}) as Dictionary).get("replacement_id", "")) == "q_ch6_side_02_home_belongings", "祠堂失窃并入第六章旧居遗物")
	_check(String((indexed.get("q_ch1_side_07_village_duel", {}) as Dictionary).get("replacement_id", "")) == "q_ch1_side_09_martial_hall", "村口试剑并入现有武馆试剑")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
