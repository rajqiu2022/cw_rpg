extends SceneTree

const EXPECTED_ORDER: Array[String] = [
	"road_ambush",
	"forest_beast",
	"cave_alpha_wolf",
	"ruin_outer_guard",
	"caravan_road_ambush",
	"zhao_wuji_showdown",
]

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var plan := load("res://data/chapters/chapter_1_content_plan.tres") as ChapterContentPlan
	_check(plan != null, "第一章内容计划可加载")
	if plan != null:
		var actual_order: Array[String] = []
		var roles: Dictionary = {}
		var has_optional_team := false
		for group: Dictionary in plan.story_battle_groups:
			var group_id := String(group.get("id", ""))
			actual_order.append(group_id)
			var role := String(group.get("pacing_role", ""))
			_check(not group_id.is_empty() and not role.is_empty(), "战斗节点拥有ID和节奏角色")
			_check(not roles.has(role), "第一章节奏角色不重复：%s" % role)
			roles[role] = true
			var level_min := int(group.get("recommended_level_min", 0))
			var level_max := int(group.get("recommended_level_max", 0))
			var turns_min := int(group.get("target_turns_min", 0))
			var turns_max := int(group.get("target_turns_max", 0))
			_check(level_min >= 1 and level_max >= level_min, "%s建议等级区间有效" % group_id)
			_check(turns_min >= 2 and turns_max >= turns_min and turns_max <= 10, "%s目标回合区间有效" % group_id)
			_check(not String(group.get("purpose", "")).is_empty(), "%s说明玩家体验目的" % group_id)
			_check(not String(group.get("rest_after", "")).is_empty(), "%s说明战后休整点" % group_id)
			_check(not String(group.get("reward_role", "")).is_empty(), "%s说明奖励作用" % group_id)
			var enemy_ids: Array = group.get("enemy_ids", []) as Array
			_check(not enemy_ids.is_empty() and enemy_ids.size() <= 3, "%s敌人编队为1至3人" % group_id)
			for raw_enemy_id: Variant in enemy_ids:
				var enemy_id := String(raw_enemy_id)
				_check(ResourceLoader.exists("res://data/enemies/%s.tres" % enemy_id), "%s敌人资源存在" % enemy_id)
			if not bool(group.get("required", true)) and enemy_ids.size() == 2:
				has_optional_team = true
		_check(actual_order == EXPECTED_ORDER, "第一章战斗按教学、野外、精英、守门、可选群战、Boss排序")
		_check(has_optional_team, "第一章存在一场可选双目标战用于群攻教学")

	var zhao := load("res://data/enemies/boss_zhao_wuji.tres") as EnemyDef
	_check(zhao != null and &"zhao_broken_gate_strike" in zhao.skill_ids, "赵无忌拥有单体绝招")
	_check(zhao != null and &"zhao_black_wind_sweep" in zhao.skill_ids, "赵无忌拥有群体刀势")
	var inner_source := FileAccess.get_file_as_string("res://data/scenes/ch1_s3_ruin_inner.tres")
	_check(not inner_source.contains("required_level") and not inner_source.contains("min_level"), "赵无忌内堂不设置硬等级门槛")
	_check(FileAccess.file_exists("res://../docs/chapter-1-battle-pacing-v1.md"), "第一章战斗节奏文档存在")

	print("[Ch1BattlePacing20260821] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[Ch1BattlePacing20260821] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
