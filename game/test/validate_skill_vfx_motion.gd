extends SceneTree

const EXPECTED_MOTION := {
	&"canglong_three_turns": Skill.MotionStyle.SHADOW_FLURRY,
	&"wanxiang_breaking_sword": Skill.MotionStyle.SHADOW_FLURRY,
	&"huashan_poyun": Skill.MotionStyle.DASH_THROUGH,
	&"huashan_jianduan_qianshan": Skill.MotionStyle.DASH_THROUGH,
	&"qinghe_swallow_sword": Skill.MotionStyle.DASH_THROUGH,
	&"shadow_swallow_piercing_sword": Skill.MotionStyle.DASH_THROUGH,
	&"mingwu_saofeng": Skill.MotionStyle.DASH_THROUGH,
	&"mingwu_wuyin_sanshi": Skill.MotionStyle.SHADOW_FLURRY,
	&"mingwu_yinying_duoming": Skill.MotionStyle.SHADOW_FLURRY,
}
const SHARED_BOSS_VFX: Array[StringName] = [&"ch8_su_teapot_meridian_rain"]

var _checks := 0
var _failed := 0


func _initialize() -> void:
	var directory := DirAccess.open("res://data/skills")
	_check(directory != null, "skill directory opens")
	if directory == null:
		_finish()
		return
	var active_count := 0
	var explicit_motion_count := 0
	var animation_ids: Dictionary = {}
	for file_name in directory.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var skill := load("res://data/skills/%s" % file_name) as Skill
		_check(skill != null, "%s loads" % file_name)
		if skill == null:
			continue
		if skill.skill_id in SHARED_BOSS_VFX:
			_check(skill.animation_id == &"toxic_needle", "%s intentionally reuses the boss-only needle VFX" % skill.skill_id)
		else:
			_check(skill.animation_id == skill.skill_id, "%s owns its dedicated VFX id" % skill.skill_id)
			_check(not animation_ids.has(skill.animation_id), "%s VFX id is unique" % skill.skill_id)
			animation_ids[skill.animation_id] = true
		if not skill.is_passive:
			active_count += 1
			_check(not skill.animation_id.is_empty(), "%s active skill has VFX" % skill.skill_id)
		if not skill.animation_id.is_empty():
			_check(BattleVfxPlayer.has_effect(skill.animation_id), "%s VFX id is registered" % skill.skill_id)
			if BattleVfxPlayer.has_effect(skill.animation_id):
				var sheet_path := str(BattleVfxPlayer.get_effect_config(skill.animation_id).get("sheet", ""))
				_check(ResourceLoader.exists(sheet_path), "%s VFX sheet exists" % skill.skill_id)
		if skill.motion_style >= Skill.MotionStyle.DASH_THROUGH:
			explicit_motion_count += 1
			_check(not skill.is_passive, "%s displacement is active" % skill.skill_id)
			_check(skill.delivery == Skill.Delivery.MELEE, "%s displacement is melee" % skill.skill_id)
		if EXPECTED_MOTION.has(skill.skill_id):
			_check(skill.motion_style == EXPECTED_MOTION[skill.skill_id], "%s motion style matches design" % skill.skill_id)
	_check(active_count == 50, "all 50 active and boss skills audited")
	_check(animation_ids.size() == 59, "all 59 skills have unique VFX ids")
	_check(explicit_motion_count == EXPECTED_MOTION.size(), "all 9 displacement skills configured")
	_finish()


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failed += 1
		push_error("[SkillVfxMotion] FAIL: %s" % label)


func _finish() -> void:
	print("[SkillVfxMotion] checks=%d failed=%d" % [_checks, _failed])
	quit(1 if _failed else 0)
