extends SceneTree

const ROOTS := ["res://art/ui/skill/icons_semantic_v1/", "res://art/ui/skill/icons_semantic_v2/"]
const EXPECTED_GROUPS := {
	"basic": [&"basic_attack"],
	"sword": [&"huashan_jianduan_qianshan", &"huashan_lanhui_sandie", &"huashan_poyun", &"huashan_qunfeng_luozhao", &"huashan_yijian", &"linxi_basic_sword_one", &"linxi_basic_sword_two", &"qinghe_swallow_sword", &"shadow_swallow_piercing_sword", &"wanxiang_breaking_sword", &"wudang_raozhirou_sword", &"wudang_rouyun_sword", &"wudang_taiji_sword"],
	"blade": [&"gufeng_fuhu", &"gufeng_kaishan_yidao", &"gufeng_liedi", &"heavy_swing", &"snow_pass_returning_blade", &"zhao_black_wind_sweep", &"zhao_broken_gate_strike"],
	"staff": [&"examiner_staff_sweep", &"heaven_pillar_staff", &"rolling_cloud_staff_storm", &"tang_staff_breaker", &"tang_staff_sweep", &"lingyue_hanshuang_wan_zhen", &"lingyue_hanshuang_zhen", &"lingyue_lingbo_yizhi"],
	"palm": [&"canghai_zhenyue_palms", &"canglong_three_turns", &"circling_breath_palm", &"palm_strike", &"wudang_mianzhang", &"wudang_taiji_chushi", &"wudang_taiji_liangyi", &"wudang_taiji_sixiang"],
	"hidden": [&"bamboo_rain_piercing_shot", &"blood_shadow_scattering_darts"],
	"needles": [&"ch8_su_teapot_meridian_rain", &"toxic_needle"],
	"footwork": [&"lingyue_tayue_lingbo", &"mingwu_mingwu_bu"],
	"shadow_dagger": [&"mingwu_saofeng", &"mingwu_wuyin_sanshi", &"mingwu_yinying_duoming"],
	"inner_breath": [&"gufeng_jingang_li", &"huashan_zixia_shengong", &"jingang_tempered_meridians", &"lingyue_yuehua_yin", &"linxi_guarded_breath", &"linxi_inner_breath", &"mingwu_yinying_jue", &"wudang_xuanwu_xinjing", &"xuanshuang_hidden_current"],
	"guard": [&"cold_ridge_guard_breath", &"defend", &"gufeng_jingang_buhuai", &"huashan_zixia_ninggang", &"qinghe_jade_guard", &"wudang_xuanwu_ge", &"zhuwei_bamboo_guard_art"],
	"healing": [&"herbal_breathing_guide", &"qinghe_returning_breath"],
	"redirect": [&"huilan_redirecting_art", &"luoshui_returning_origin"],
}

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	var audited: Dictionary = {}
	for group: String in EXPECTED_GROUPS:
		for skill_id: StringName in EXPECTED_GROUPS[group]:
			var skill := load("res://data/skills/%s.tres" % String(skill_id)) as Skill
			_check(skill != null, "%s loads" % skill_id)
			if skill == null:
				continue
			audited[skill_id] = true
			_check(ROOTS.any(func(root: String): return skill.icon_path.begins_with(root)), "%s uses the reviewed semantic icon family" % skill_id)
			_check(ResourceLoader.exists(skill.icon_path), "%s icon exists" % skill_id)
			var filename := skill.icon_path.get_file().to_lower()
			_check(filename.contains(group), "%s icon matches %s semantics" % [skill_id, group])
			var texture := load(skill.icon_path) as Texture2D
			_check(texture != null and texture.get_width() == 256 and texture.get_height() == 256, "%s icon is 256x256" % skill_id)
	var skill_files := DirAccess.get_files_at("res://data/skills")
	var skill_count := 0
	for file_name in skill_files:
		if file_name.ends_with(".tres"):
			skill_count += 1
	_check(skill_count == 66 and audited.size() == skill_count, "all 66 martial arts are semantically audited")
	var panel_source := FileAccess.get_file_as_string("res://scripts/ui/skill_panel.gd")
	_check(panel_source.contains("func _resolved_skill_icon_path"), "basic attack icon resolves from current weapon")
	_check(panel_source.contains("Inventory.get_equipped(Equipment.Slot.WEAPON)"), "basic attack icon follows the equipped weapon")
	_check(not panel_source.contains("GameState.player.weapon_specialty"), "unequipped basic attack no longer pretends a stored weapon specialty is equipped")
	_check(panel_source.contains('icon_skill_basic_unarmed_v1.png'), "explicit unarmed specialty uses a dedicated basic fist icon")
	var basic_attack := load("res://data/skills/basic_attack.tres") as Skill
	var linxi_sword := load("res://data/skills/linxi_basic_sword_one.tres") as Skill
	var legendary_palm := load("res://data/skills/canghai_zhenyue_palms.tres") as Skill
	_check(basic_attack != null and linxi_sword != null and basic_attack.icon_path != linxi_sword.icon_path, "basic sword attack does not reuse Linxi sword icon")
	_check(basic_attack != null and legendary_palm != null and basic_attack.icon_path != legendary_palm.icon_path, "basic attack does not reuse legendary palm icon")
	_finish()


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _finish() -> void:
	print("[SkillIconSemantics20260817] checks=%d failed=%d" % [checks, failures.size()])
	for failure in failures:
		push_error("[SkillIconSemantics20260817] %s" % failure)
	quit(1 if not failures.is_empty() else 0)
