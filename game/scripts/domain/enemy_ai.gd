class_name EnemyAI
extends RefCounted

## 敌人决策树（M6）。
##
## 根据当前战况（自身 HP、玩家 HP、技能池、侵略性）为敌人选择最优技能。
##
## 决策层级：
##   1. 保命：自身 HP < 25% 且拥有 buff/defend 技能时优先自保
##   2. 压制：自身 HP > aggression 阈值且玩家 HP < 40% 时用强力技能终结
##   3. 消耗：玩家 HP > 50% 时优先用带 DOT/debuff 的技能建立优势
##   4. 狂暴：玩家 HP < 25% 时用最高威力技能赌击杀
##   5. 默认：普攻

const POISON_SKILLS := ["toxic_needle"]
const WEAK_SKILLS := ["heavy_swing", "gufeng_fuhu", "gufeng_liedi"]
const BUFF_SKILLS := ["defend", "huashan_zixia_shengong", "huashan_zixia_ninggang", "lingyue_tayue_lingbo", "gufeng_jingang_buhuai", "wudang_xuanwu_ge", "mingwu_mingwu_bu"]
const CHASE_SKILLS := ["gufeng_kaishan_yidao", "mingwu_yinying_duoming", "huashan_jianduan_qianshan"]

var _rng := RandomNumberGenerator.new()


func choose_skill(skill_pool: Array[StringName], enemy_hp_ratio: float, enemy_aggression: float, player_hp_ratio: float) -> StringName:
	if skill_pool.is_empty():
		return &"basic_attack"

	_rng.randomize()
	var roll: float = _rng.randf()
	var pool_size: int = skill_pool.size()

	# 1. 保命：HP < 25%，有 buff/defend 技能优先
	if enemy_hp_ratio < 0.25:
		var buff_idx := _find_skill_in_pool(skill_pool, BUFF_SKILLS)
		if buff_idx >= 0 and roll < 0.55:
			return skill_pool[buff_idx]

	# 2. 压制追击：自身血高 + 敌人残血 → 用斩杀技能
	if enemy_hp_ratio > enemy_aggression and player_hp_ratio < 0.40:
		var chase_idx := _find_skill_in_pool(skill_pool, CHASE_SKILLS)
		if chase_idx >= 0 and roll < 0.50:
			return skill_pool[chase_idx]
		if pool_size >= 2 and roll < 0.60:
			return skill_pool[1]

	# 3. 消耗：玩家血多时优先 DOT/debuff
	if player_hp_ratio > 0.50:
		var dot_idx := _find_skill_in_pool(skill_pool, POISON_SKILLS)
		if dot_idx >= 0 and roll < 0.45:
			return skill_pool[dot_idx]
		var debuff_idx := _find_skill_in_pool(skill_pool, WEAK_SKILLS)
		if debuff_idx >= 0 and roll < 0.40:
			return skill_pool[debuff_idx]

	# 4. 狂暴：玩家残血（< 25%）赌击杀
	if player_hp_ratio < 0.25:
		if pool_size >= 3 and roll < 0.50:
			return skill_pool[2]  # 第三技能通常威力最高
		if pool_size >= 2:
			return skill_pool[1]

	# 5. 默认
	if pool_size >= 2 and enemy_hp_ratio > enemy_aggression and roll < 0.55:
		return skill_pool[1]
	if pool_size >= 3 and enemy_hp_ratio < 0.45 and roll < 0.45:
		return skill_pool[2]
	return skill_pool[0]


func _find_skill_in_pool(pool: Array[StringName], candidates: Array) -> int:
	for i in pool.size():
		var sid := String(pool[i])
		for c in candidates:
			if sid == c:
				return i
	return -1
