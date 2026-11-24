class_name CharacterStats
extends Resource

## 角色面板。纯数据，不含战斗逻辑。
## v1：新增七项核心属性，旧 attack/defense/speed 作为兼容派生字段保留。

@export var character_id: String = ""
@export var display_name: String = ""
@export var portrait_path: String = "":
	get:
		# The hero has a fixed story identity, including when reading old saves.
		if character_id == "protagonist":
			return "res://art/characters/protagonist_bust.tres"
		return portrait_path
@export var role_title: String = ""
@export var origin: String = ""
@export var biography: String = ""
@export var weapon_specialty: StringName = &""
@export var fixed_martial_arts: bool = false
## 当前运转的心法。习得/提升心法的常驻属性不会因换装消失；
## 这里只决定战斗中的流派与指定招式装备加成，每名角色最多一门。
@export var equipped_internal_art: StringName = &""
@export var battle_actor_path: String = ""
@export var battle_sprite_root: String = ""
@export var battle_sprite_prefix: String = ""
@export var battle_actor_scale: float = 0.42

@export var level: int = 1
@warning_ignore("shadowed_global_identifier") # Kept for save-data compatibility ("exp").
@export var exp: int = 0

## 七项核心属性（玩家面板主显示）
@export var strength: int = 8      ## 筋骨
@export var agility: int = 7       ## 机敏
@export var inner_power: int = 8   ## 内劲
@export var insight: int = 6       ## 悟性
@export var vitality: int = 8      ## 生命
@export var inner_pool: int = 8    ## 内力
@export var guard: int = 7         ## 防御

@export var max_hp: int = 100
@export var hp: int = 100
@export var max_mp: int = 30
@export var mp: int = 30

## 独立于核心属性的永久上限来源；存档恢复是覆盖，不是再次发奖。
## 同一来源可合法使用多次，applications 仅作溯源，不参与数值计算。
@export var permanent_resource_bonuses: Dictionary = {}

## 兼容字段：战斗系统当前仍有部分逻辑直接使用
@export var attack: int = 10
@export var defense: int = 5
@export var speed: int = 10

@export var skills: Array[StringName] = []

func is_dead() -> bool:
	return hp <= 0

func take_damage(amount: int) -> int:
	## amount 必须是 BattleFormula 已结算防御后的最终伤害；防御只能扣一次。
	if amount <= 0:
		return 0
	var dealt: int = max(1, amount)
	hp = max(0, hp - dealt)
	return dealt

func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)

func gain_exp(amount: int) -> bool:
	## 前四章采用平滑曲线：Lv1->2 需80，之后每级增加40。
	if amount <= 0:
		return false
	exp += amount
	var leveled_up := false
	while exp >= exp_required_for_next_level():
		exp -= exp_required_for_next_level()
		level += 1
		_apply_levelup()
		leveled_up = true
		if Engine.get_main_loop() is SceneTree and (Engine.get_main_loop() as SceneTree).root.has_node("EventBus"):
			var event_bus := (Engine.get_main_loop() as SceneTree).root.get_node("EventBus")
			event_bus.emit_signal("player_leveled_up", level)
	return leveled_up


func exp_required_for_next_level() -> int:
	return 80 + max(0, level - 1) * 40

func set_recruitment_level(target_level: int) -> void:
	target_level = maxi(1, target_level)
	_apply_level_growth(target_level - level)
	level = target_level
	exp = 0
	refresh_derived_stats(true)

func refresh_derived_stats(refill: bool = false) -> void:
	max_hp = _calc_max_hp() + get_permanent_resource_bonus("max_hp")
	max_mp = _calc_max_mp() + get_permanent_resource_bonus("max_mp")
	attack = _calc_attack()
	defense = _calc_defense()
	speed = _calc_speed()
	if refill:
		hp = max_hp
		mp = max_mp
	else:
		hp = clamp(hp, 0, max_hp)
		mp = clamp(mp, 0, max_mp)


func add_permanent_resource_bonus(source_id: StringName, hp_bonus: int, mp_bonus: int) -> void:
	if String(source_id).is_empty() or hp_bonus < 0 or mp_bonus < 0 or (hp_bonus == 0 and mp_bonus == 0):
		return
	var key := String(source_id)
	var previous: Dictionary = permanent_resource_bonuses.get(key, {})
	permanent_resource_bonuses[key] = {
		"max_hp": int(previous.get("max_hp", 0)) + hp_bonus,
		"max_mp": int(previous.get("max_mp", 0)) + mp_bonus,
		"applications": int(previous.get("applications", 0)) + 1,
	}
	refresh_derived_stats(false)


func get_permanent_resource_bonus(stat: String) -> int:
	var total := 0
	for raw: Variant in permanent_resource_bonuses.values():
		if raw is Dictionary:
			total += _nonnegative_bonus_int(raw.get(stat, 0))
	return total


func restore_permanent_resource_bonuses(raw: Variant) -> void:
	permanent_resource_bonuses = {}
	if not (raw is Dictionary):
		return
	for key: Variant in raw:
		if not (key is String or key is StringName) or String(key).is_empty() or not (raw[key] is Dictionary):
			continue
		var entry: Dictionary = raw[key]
		var hp_bonus := _nonnegative_bonus_int(entry.get("max_hp", 0))
		var mp_bonus := _nonnegative_bonus_int(entry.get("max_mp", 0))
		if hp_bonus > 0 or mp_bonus > 0:
			permanent_resource_bonuses[String(key)] = {
				"max_hp": hp_bonus, "max_mp": mp_bonus,
				"applications": _nonnegative_bonus_int(entry.get("applications", 0)),
			}


func preserve_legacy_saved_capacities(saved_hp: int, saved_mp: int) -> void:
	## v12及以前：仅保留完整核心属性能证明的已保存正差额。
	## 不猜林西酒次数；已被旧重算抹掉的奖励没有证据，不能补发。
	var hp_bonus := maxi(0, saved_hp - _calc_max_hp())
	var mp_bonus := maxi(0, saved_mp - _calc_max_mp())
	if hp_bonus > 0 or mp_bonus > 0:
		permanent_resource_bonuses["legacy_saved_capacity"] = {
			"max_hp": hp_bonus, "max_mp": mp_bonus, "applications": 0,
		}


static func _nonnegative_bonus_int(value: Variant) -> int:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return 0
	if not is_finite(float(value)):
		return 0
	return maxi(0, int(value))

func has_core_attributes() -> bool:
	return strength > 0 and agility > 0 and inner_power > 0 and insight > 0 and vitality > 0 and inner_pool > 0 and guard > 0

func infer_core_attributes_from_legacy() -> void:
	## 老存档兼容：把旧三维/血蓝估算回七属性，不改现有战斗数值。
	strength = max(1, int(round(float(attack) / 2.0)))
	guard = max(1, defense)
	agility = max(1, speed - 2)
	inner_power = max(1, int(round(float(attack) / 4.0)))
	insight = max(1, int(round(float(agility) / 2.0)) + 3)
	vitality = max(1, int(round(float(max_hp - 60) / 7.0)))
	inner_pool = max(1, int(round(float(max_mp - 12) / 3.0)))

func _apply_levelup() -> void:
	_apply_level_growth(1)
	refresh_derived_stats(true)

func _apply_level_growth(levels: int) -> void:
	strength = maxi(1, strength + levels)
	agility = maxi(1, agility + levels)
	inner_power = maxi(1, inner_power + levels)
	insight = maxi(1, insight + levels)
	vitality = maxi(1, vitality + levels * 2)
	inner_pool = maxi(1, inner_pool + levels * 2)
	guard = maxi(1, guard + levels)

func _calc_max_hp() -> int:
	return 80 + vitality * 8 + strength * 3

func _calc_max_mp() -> int:
	## 悟性只服务于武学学习与研读，不参与战斗派生值。
	return 20 + inner_pool * 6 + inner_power * 2

func _calc_attack() -> int:
	## 有效攻击 = 筋骨×2 + 内劲×1（不含装备加成，装备在战斗层叠加）
	return max(1, strength * 2 + inner_power)

func _calc_defense() -> int:
	## 有效防御 = 防御×2 + 筋骨×1
	return max(1, guard * 2 + strength)

func _calc_speed() -> int:
	## 有效速度 = 机敏×2；悟性不再影响先手。
	return max(1, agility * 2)
