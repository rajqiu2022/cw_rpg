class_name Skill
extends Resource

## 技能。后续战斗系统依赖这个 Resource 描述行为。

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
