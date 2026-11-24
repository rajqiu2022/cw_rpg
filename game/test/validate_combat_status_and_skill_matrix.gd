extends SceneTree

const SKILL_DIR := "res://data/skills"
const REQUIRED_CATEGORIES := [&"sword", &"blade", &"staff", &"palm", &"hidden"]
const REQUIRED_QUALITIES := [Skill.Quality.UNCOMMON, Skill.Quality.RARE, Skill.Quality.EPIC, Skill.Quality.LEGENDARY]

var failures: PackedStringArray = []


func _init() -> void:
	var matrix: Dictionary = {}
	for category in REQUIRED_CATEGORIES:
		matrix[category] = {}
	var dir := DirAccess.open(SKILL_DIR)
	_check(dir != null, "技能目录可读取")
	if dir != null:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while not file_name.is_empty():
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var skill := load("%s/%s" % [SKILL_DIR, file_name]) as Skill
				_check(skill != null, "技能资源可加载：%s" % file_name)
				if skill != null:
					_check_skill(skill, matrix)
			file_name = dir.get_next()
		dir.list_dir_end()

	for category in REQUIRED_CATEGORIES:
		for quality in REQUIRED_QUALITIES:
			_check((matrix[category] as Dictionary).has(quality), "%s 类具备品质 %d 的攻击招式" % [String(category), quality])

	_check_status(&"bleed", "res://art/ui/status/icons_v1/icon_status_bleed_v1.png")
	_check_status(&"internal_injury", "res://art/ui/status/icons_v1/icon_status_internal_injury_v1.png")
	_check_status(&"internal_lock", "res://art/ui/status/icons_v1/icon_status_internal_lock_v1.png")
	_check_skill_contract(&"blood_shadow_scattering_darts", &"bleed", 3)
	_check_skill_contract(&"rolling_cloud_staff_storm", &"weaken", 2)
	_check_internal_skill(&"circling_breath_palm", 14)
	_check_internal_skill(&"canghai_zhenyue_palms", 36)

	if failures.is_empty():
		print("PASS validate_combat_status_and_skill_matrix")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_skill(skill: Skill, matrix: Dictionary) -> void:
	_check(skill.base_hit_chance >= 0.80 and skill.base_hit_chance <= 1.0, "%s 命中率在80%%至100%%" % skill.skill_id)
	if skill.skill_id == &"basic_attack":
		_check(skill.get_martial_category() == &"any" or skill.get_martial_category() == &"", "普通攻击不归入掌法或其他武器页")
		return
	if skill.skill_id == &"defend":
		return
	if skill.kind == Skill.Kind.HEAL or (skill.kind == Skill.Kind.BUFF and skill.fixed_damage <= 0 and skill.get_attack_scaling() <= 0):
		_check(skill.is_internal_art, "%s 无伤害增益归为心法" % skill.skill_id)
		_check(skill.get_martial_category() == &"", "%s 心法不归入兵器分类" % skill.skill_id)
		return
	var category := skill.get_martial_category()
	if skill.kind == Skill.Kind.ATTACK and matrix.has(category) and skill.quality in REQUIRED_QUALITIES:
		(matrix[category] as Dictionary)[skill.quality] = true


func _check_status(status_id: StringName, expected_icon: String) -> void:
	var status := load("res://data/status_effects/%s.tres" % status_id) as StatusEffectDef
	_check(status != null, "%s 状态资源可加载" % status_id)
	if status == null:
		return
	_check(status.icon_path == expected_icon and ResourceLoader.exists(status.icon_path), "%s 状态具备正式图标" % status_id)
	_check(not status.tooltip_text.is_empty(), "%s 状态具备说明" % status_id)


func _check_skill_contract(skill_id: StringName, status_id: StringName, duration: int) -> void:
	var skill := load("res://data/skills/%s.tres" % skill_id) as Skill
	_check(skill != null, "%s 招式存在" % skill_id)
	if skill != null:
		_check(skill.inflicted_status == status_id and skill.status_duration == duration, "%s 正确施加 %s" % [skill_id, status_id])


func _check_internal_skill(skill_id: StringName, minimum_gain: int) -> void:
	var skill := load("res://data/skills/%s.tres" % skill_id) as Skill
	_check(skill != null, "%s 内功招式存在" % skill_id)
	if skill != null:
		_check(skill.damage_type == Skill.DamageType.INTERNAL and skill.internal_injury_gain >= minimum_gain, "%s 可累积内伤" % skill_id)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
