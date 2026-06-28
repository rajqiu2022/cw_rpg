class_name StatusEffectDef
extends Resource

## 状态异常模板定义。
##
## 每种状态效果（中毒/虚弱/爆发/眩晕/冰冻）对应一个 .tres 文件。
## BattleController 在战斗运行时依据此模板管理状态实例。
##
## 字段设计遵守 battle-memory.md 要求：
##   - status id / display name / duration rule / stack rule
##   - per-turn effect / remove condition / UI text / save persistence

enum Kind { POISON, WEAK, BURST, STUN, FREEZE }
enum StackRule { REPLACE, EXTEND }

@export var status_id: StringName = ""
@export var display_name: String = ""
@export var kind: Kind = Kind.POISON

## 默认持续回合。BUFF 型（爆发）不易被解除；DEBUFF 型可被物品解除。
@export var default_duration: int = 3
@export var is_debuff: bool = true

## 眩晕/冰冻类效果会跳过回合
@export var skip_turn: bool = false

## stack_rule:
##   REPLACE — 新施加覆盖旧回合数（取最大值）
##   EXTEND  — 新施加累加回合数
@export var stack_rule: StackRule = StackRule.REPLACE

## 每回合效果：
##   kind=POISON:  effect_value 为 max_hp 比例 DOT（0.05 = 5%）
##   kind=WEAK:    防御减半 + 伤害 -30%（effect_value 不使用）
##   kind=BURST:   暴击率 +50%（effect_value 不使用）
##   kind=STUN:    跳过回合（effect_value 不使用）
##   kind=FREEZE:  跳过回合 + 受击时额外承受 20% 伤害（effect_value 不使用）
@export var effect_value: float = 0.0

## 解除条件（当前所有异常均为 duration 到期自动解除，解毒丹/破虚散手动解除）
@export var remove_by_duration: bool = true

## UI 显示用的简短标签（如 "毒" / "弱" / "暴"）
@export var ui_label: String = ""

## save persistence rule：存档时是否保留（中毒等负面通常不跨存档保留）
@export var persist_across_save: bool = false
