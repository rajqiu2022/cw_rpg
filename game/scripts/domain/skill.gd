class_name Skill
extends Resource

## 技能。战斗系统依赖这个 Resource 描述行为。
##
## v1 新增：
##   - school: 门派归属，用于装备加成和内功互补匹配
##   - is_passive: 被动技能（习得即永久生效）
##   - complemented_by: 互补内功 skill_id，学了该内功后本外功获得加成
##   - complement_bonus_power: 互补时 power 额外加值
##   - complement_bonus_desc: 互补效果 UI 描述

enum Target { ENEMY_SINGLE, ENEMY_ALL, ALLY_SINGLE, ALLY_ALL, SELF }
enum Kind { ATTACK, HEAL, BUFF, DEBUFF }

@export var skill_id: StringName = ""
@export var display_name: String = ""
@export var icon_path: String = ""
@export var description: String = ""

@export var kind: Kind = Kind.ATTACK
@export var target: Target = Target.ENEMY_SINGLE
@export var mp_cost: int = 0
@export var power: int = 100  ## 100 = 普通攻击基线
@export var hit_count: int = 1
@export var animation_id: StringName = &"default"

## 门派与互补（v1 新增）
@export var school: String = ""  ## "gufeng" / "huashan" / "lingyue" / "mingwu" / "wudang" / "generic"
@export var is_passive: bool = false  ## 被动技（如 金刚力、月华引），习得后永久生效，不占技能槽
@export var complemented_by: String = ""  ## 互补内功 skill_id；空字符串表示无互补需求
@export var complement_bonus_power: int = 0  ## 互补时 power 额外加值（如 +15 表示 power 从 150 变 165）
@export var complement_bonus_desc: String = ""  ## 互补效果 UI 描述（如 "暴击伤害提升至 1.8 倍"）
