extends SceneTree

const SCHOOLS := ["wudang", "huashan", "gufeng", "lingyue", "mingwu"]
const REQUIRED_SKILLS := {
	"wudang": ["wudang_raozhirou_sword", "wudang_rouyun_sword", "wudang_taiji_sword", "wudang_taiji_chushi", "wudang_mianzhang", "wudang_taiji_sixiang", "wudang_taiji_liangyi", "wudang_xuanwu_ge", "wudang_xuanwu_xinjing"],
	"huashan": ["huashan_yijian", "huashan_poyun", "huashan_qunfeng_luozhao", "huashan_lanhui_sandie", "huashan_jianduan_qianshan", "huashan_zixia_ninggang", "huashan_zixia_shengong"],
	"gufeng": ["gufeng_kaishan_yidao", "gufeng_fuhu", "gufeng_jingang_buhuai", "gufeng_jingang_li"],
	"lingyue": ["lingyue_lingbo_yizhi", "lingyue_hanshuang_zhen", "lingyue_tayue_lingbo", "lingyue_yuehua_yin"],
	"mingwu": ["mingwu_saofeng", "mingwu_wuyin_sanshi", "mingwu_mingwu_bu", "mingwu_yinying_jue"],
}

func _initialize() -> void:
	var failures: Array[String] = []
	var skill_count := 0
	var skill_ids: Dictionary = {}
	var quality_counts: Array[int] = [0, 0, 0, 0, 0]
	for filename in DirAccess.get_files_at("res://data/skills"):
		if not filename.ends_with(".tres"):
			continue
		var skill: Skill = load("res://data/skills/%s" % filename)
		if skill == null:
			failures.append("skill failed to load: %s" % filename)
			continue
		skill_count += 1
		if skill_ids.has(skill.skill_id):
			failures.append("duplicate skill id: %s" % skill.skill_id)
		skill_ids[skill.skill_id] = true
		if skill.quality < Skill.Quality.COMMON or skill.quality > Skill.Quality.LEGENDARY:
			failures.append("skill %s quality out of range: %d" % [skill.skill_id, skill.quality])
		else:
			quality_counts[skill.quality] += 1
		var is_damage_skill := skill.kind == Skill.Kind.ATTACK or skill.kind == Skill.Kind.DEBUFF
		if is_damage_skill and (skill.fixed_damage <= 0 or skill.get_attack_scaling() < 0):
			failures.append("damage skill %s needs fixed_damage > 0 and non-negative scaling" % skill.skill_id)
		if not is_damage_skill and (skill.fixed_damage != 0 or skill.get_attack_scaling() != 0):
			failures.append("non-damage skill %s carries attack damage fields" % skill.skill_id)
		if skill.kind == Skill.Kind.HEAL and skill.get_effect_value() <= 0:
			failures.append("healing skill %s needs an independent effect_value" % skill.skill_id)
		if skill.power != 0:
			failures.append("skill %s still uses deprecated power=%d" % [skill.skill_id, skill.power])
	if skill_count != 66:
		failures.append("expected 66 skills, got %d" % skill_count)
	if quality_counts != [3, 12, 18, 18, 15]:
		failures.append("unexpected quality distribution: %s" % str(quality_counts))

	var faction_skill_count := 0
	for school in SCHOOLS:
		var school_skills: Array = REQUIRED_SKILLS[school]
		for skill_id in school_skills:
			faction_skill_count += 1
			var path := "res://data/skills/%s.tres" % skill_id
			if not ResourceLoader.exists(path):
				failures.append("missing faction skill: %s" % skill_id)
				continue
			var skill: Resource = load(path)
			if String(skill.school) != school:
				failures.append("skill %s has school %s, expected %s" % [skill_id, skill.school, school])
			if skill.description == "":
				failures.append("skill %s has empty description" % skill_id)

	var equipment_count := 0
	var equipment_ids: Dictionary = {}
	var equipment_names: Dictionary = {}
	for filename in DirAccess.get_files_at("res://data/equipment"):
		if filename.ends_with(".tres"):
			equipment_count += 1
			var eq: Equipment = load("res://data/equipment/%s" % filename)
			if eq == null or eq.slot < 0 or eq.slot > 5:
				failures.append("invalid equipment slot: %s" % filename)
				continue
			var equipment_id := String(eq.item_id)
			var equipment_name := String(eq.display_name).strip_edges()
			if equipment_ids.has(equipment_id):
				failures.append("duplicate equipment id: %s (%s, %s)" % [equipment_id, equipment_ids[equipment_id], filename])
			equipment_ids[equipment_id] = filename
			if equipment_name.is_empty():
				failures.append("equipment has empty display name: %s" % filename)
			elif equipment_names.has(equipment_name):
				failures.append("duplicate equipment display name: %s (%s, %s)" % [equipment_name, equipment_names[equipment_name], filename])
			equipment_names[equipment_name] = filename
			if eq.slot == Equipment.Slot.WEAPON:
				if String(eq.weapon_type).is_empty():
					failures.append("weapon has no explicit type: %s" % filename)
				if eq.crit_chance_bonus < 0.0 or eq.crit_chance_bonus > 0.5:
					failures.append("weapon crit chance out of range: %s" % filename)
				if eq.get_weapon_skill_scaling_bonus() <= 0:
					failures.append("weapon has no corresponding technique bonus: %s" % filename)
	if equipment_count != 124:
		failures.append("expected 124 equipment resources, got %d" % equipment_count)
	_validate_progression_equipment(failures)

	var item_count := 0
	var item_ids: Dictionary = {}
	var item_names: Dictionary = {}
	for filename in DirAccess.get_files_at("res://data/items"):
		if filename.ends_with(".tres"):
			item_count += 1
			var item: Resource = load("res://data/items/%s" % filename)
			if item == null:
				failures.append("item failed to load: %s" % filename)
				continue
			var item_id := String(item.item_id)
			var item_name := String(item.display_name).strip_edges()
			if item_ids.has(item_id) or equipment_ids.has(item_id):
				failures.append("duplicate inventory item id: %s" % item_id)
			item_ids[item_id] = filename
			if item_name.is_empty():
				failures.append("item has empty display name: %s" % filename)
			elif item_names.has(item_name):
				failures.append("duplicate item display name: %s (%s, %s)" % [item_name, item_names[item_name], filename])
			item_names[item_name] = filename
			if item.readable:
				if not item.is_key_item():
					failures.append("readable lore item must be KEY_ITEM: %s" % item_id)
				if not item.is_readable() or item.read_title.strip_edges().is_empty():
					failures.append("readable item lacks title/body: %s" % item_id)
				if item.read_content.strip_edges().length() < 60:
					failures.append("readable item body is too short: %s" % item_id)

	print("[ContentCompleteness] skills=%d faction_skills=%d quality=%s equipment=%d items=%d failed=%d" % [skill_count, faction_skill_count, str(quality_counts), equipment_count, item_count, failures.size()])
	for failure in failures:
		push_error("[ContentCompleteness] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _validate_progression_equipment(failures: Array[String]) -> void:
	var purple_gauntlets := load("res://data/equipment/xuantong_fist_gauntlets.tres") as Equipment
	if purple_gauntlets == null:
		failures.append("purple fist gauntlets failed to load")
	else:
		if purple_gauntlets.quality != 3 or purple_gauntlets.slot != Equipment.Slot.WEAPON or purple_gauntlets.weapon_type != &"palm" or purple_gauntlets.martial_style != &"palm":
			failures.append("purple fist gauntlets must be quality 3 palm weapon equipment")
		if purple_gauntlets.atk_bonus != 15 or purple_gauntlets.inner_bonus != 2 or purple_gauntlets.guard_bonus != 2:
			failures.append("purple fist gauntlets stats drifted from the chapter-4 budget")
		if not ResourceLoader.exists(purple_gauntlets.icon_path):
			failures.append("purple fist gauntlets icon is missing")

	var orange_sword := load("res://data/equipment/zhouju_bronze_sword.tres") as Equipment
	if orange_sword == null:
		failures.append("orange sword failed to load")
	else:
		if orange_sword.quality != 4 or orange_sword.slot != Equipment.Slot.WEAPON or orange_sword.weapon_type != &"sword":
			failures.append("orange sword must be quality 4 sword equipment")
		if orange_sword.atk_bonus != 66 or orange_sword.skill_bonus_school != "linxi" or orange_sword.get_skill_scaling_bonus() != 24 or not is_equal_approx(orange_sword.crit_chance_bonus, 0.28):
			failures.append("orange sword stats drifted from the late-game offensive budget")
		if not ResourceLoader.exists(orange_sword.icon_path):
			failures.append("orange sword icon is missing")

	var canal_quest := load("res://data/quests/q_ch4_side_06_canal_grudge.tres") as QuestDef
	var tomb_quest := load("res://data/quests/q_ch5_side_03_ancient_tomb_trap.tres") as QuestDef
	if canal_quest == null or not _quest_rewards(canal_quest, "xuantong_fist_gauntlets"):
		failures.append("chapter-4 canal quest does not reward the purple fist gauntlets")
	if tomb_quest == null or not _quest_rewards(tomb_quest, "zhouju_bronze_sword"):
		failures.append("chapter-5 tomb quest does not reward the orange sword")


func _quest_rewards(quest: QuestDef, item_id: String) -> bool:
	for reward: Dictionary in quest.reward_items:
		if String(reward.get("item_id", "")) == item_id and int(reward.get("count", 0)) > 0:
			return true
	return false
