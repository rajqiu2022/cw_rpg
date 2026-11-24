extends SceneTree

const HIGH_RISK_SCENES: Array[StringName] = [
	&"ch5_s1_relief_road",
	&"ch5_s3_snow_pass",
	&"ch5_s4_abandoned_mine",
	&"ch6_s4_baishui_convoy_route",
	&"ch7_s3_lieyun_outpost_outer_ward",
	&"ch8_s2_mistwood_blockade",
	&"ch8_s4_alliance_mechanism_gallery",
	&"openworld_yanmen_pass",
]
const BASIC_VFX_IDS: Array[StringName] = [
	&"basic_sword", &"basic_blade", &"basic_staff", &"basic_palm", &"basic_hidden",
]

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_validate_high_risk_formations()
	_validate_runtime_solo_override()
	_validate_weapon_specific_basic_vfx()
	if failures.is_empty():
		print("[HighEncounterBasicVfx20260912] PASS checks=%d" % checks)
		quit(0)
		return
	for failure: String in failures:
		push_error("[HighEncounterBasicVfx20260912] %s" % failure)
	print("[HighEncounterBasicVfx20260912] FAIL checks=%d failures=%d" % [checks, failures.size()])
	quit(1)


func _validate_high_risk_formations() -> void:
	for scene_id: StringName in HIGH_RISK_SCENES:
		var scene := load("res://data/scenes/%s.tres" % String(scene_id)) as SceneScript
		_check(scene != null, "%s 可加载" % scene_id)
		if scene == null:
			continue
		_check(scene.encounter_allow_full_group_for_solo, "%s 允许高级区完整三敌编队" % scene_id)
		var sizes: Array[int] = []
		var weights: Dictionary = {}
		for group: Dictionary in scene.encounter_groups:
			var enemy_ids: Array = group.get("enemy_ids", [])
			var size := enemy_ids.size()
			sizes.append(size)
			weights[size] = float(group.get("weight", 0.0))
			_check(size >= 1 and size <= 3, "%s 编队人数限定为1至3" % scene_id)
		_check(1 in sizes and 2 in sizes and 3 in sizes, "%s 同时配置1/2/3人遭遇" % scene_id)
		_check(float(weights.get(2, 0.0)) > float(weights.get(1, 0.0)), "%s 双敌为最常见遭遇" % scene_id)
		_check(float(weights.get(2, 0.0)) > float(weights.get(3, 0.0)), "%s 三敌为低概率高压遭遇" % scene_id)


func _validate_runtime_solo_override() -> void:
	var router := root.get_node_or_null("SceneRouter")
	var game_state := root.get_node_or_null("GameState")
	_check(router != null and game_state != null, "SceneRouter 与 GameState 可用")
	if router == null or game_state == null:
		return
	var original_party: Array[CharacterStats] = []
	for member: CharacterStats in game_state.party:
		original_party.append(member)
	var solo := CharacterStats.new()
	solo.character_id = "probe_solo"
	var solo_party: Array[CharacterStats] = [solo]
	game_state.party = solo_party
	var authored: Array[StringName] = [&"a", &"b", &"c"]
	var protected_group: Array[StringName] = router.call("_adapt_authored_group_to_party", authored)
	var high_risk_group: Array[StringName] = router.call("_adapt_authored_group_to_party", authored, true)
	_check(protected_group.size() == 2, "普通区域仍保护单人队伍，不强制1v3")
	_check(high_risk_group.size() == 3, "高级区域单人游历也可能真实遭遇三敌")
	game_state.party = original_party


func _validate_weapon_specific_basic_vfx() -> void:
	var controller: Node = load("res://scripts/battle/battle_controller.gd").new()
	var expected := {
		&"sword": &"basic_sword",
		&"blade": &"basic_blade",
		&"staff": &"basic_staff",
		&"palm": &"basic_palm",
		&"hidden": &"basic_hidden",
	}
	var hashes: Dictionary = {}
	for style: StringName in expected:
		var stats := CharacterStats.new()
		stats.character_id = "vfx_probe_%s" % String(style)
		stats.weapon_specialty = style
		var resolved := StringName(controller.call("_basic_attack_vfx_id", stats))
		_check(resolved == expected[style], "%s 普通攻击映射到 %s" % [style, expected[style]])
	var enemy_stats := CharacterStats.new()
	enemy_stats.character_id = "enemy_staff_probe"
	var enemy_def := EnemyDef.new()
	enemy_def.skill_ids = [&"basic_attack", &"examiner_staff_sweep"]
	_check(StringName(controller.call("_basic_attack_vfx_id", enemy_stats, enemy_def)) == &"basic_staff", "敌人可由招式契约推断棍系普通攻击")
	controller.queue_free()

	for vfx_id: StringName in BASIC_VFX_IDS:
		_check(BattleVfxPlayer.has_effect(vfx_id), "%s 已注册" % vfx_id)
		var config := BattleVfxPlayer.get_effect_config(vfx_id)
		var sheet_path := String(config.get("sheet", ""))
		_check(ResourceLoader.exists(sheet_path), "%s 图集可导入" % vfx_id)
		if not sheet_path.is_empty():
			var hash := FileAccess.get_sha256(sheet_path)
			_check(not hashes.has(hash), "%s 使用独立图集，不与其他武器复用" % vfx_id)
			hashes[hash] = vfx_id
	_check(BattleVfxPlayer.get_effect_config(&"basic_palm").get("sheet", "") != BattleVfxPlayer.get_effect_config(&"basic_sword").get("sheet", ""), "拳掌与剑普通攻击不再共用掌印")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
