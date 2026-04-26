class_name EnemyDef
extends Resource

## 敌人模板。BattleController 启动时根据 enemy_id 加载对应 .tres，
## 再 spawn 出运行时的 CharacterStats 实例。

@export var enemy_id: StringName = ""
@export var display_name: String = ""
@export var portrait_path: String = ""

@export var level: int = 1
@export var max_hp: int = 80
@export var max_mp: int = 0
@export var attack: int = 14
@export var defense: int = 6
@export var speed: int = 8

@export var skill_ids: Array[StringName] = []   ## 引用 res://data/skills/<id>.tres

@export_category("AI Behavior")
## 简单决策：power_skill_threshold = 自身 HP 高于该比例时优先放招；
## 0.5 = HP > 50% 时倾向使用强力招式
@export var aggression: float = 0.6

@export_category("Drops")
@export var drop_gold_min: int = 20
@export var drop_gold_max: int = 50
@export var drop_exp: int = 25
@export var drop_items: Array[StringName] = []          ## 必掉物品 id
@export var drop_random: Array[Dictionary] = []
## 例：[{"item_id": "healing_pill_minor", "chance": 0.3, "count": 1}]


func to_runtime_stats() -> CharacterStats:
	## 把模板"实例化"成战斗用的 CharacterStats。
	var s := CharacterStats.new()
	s.character_id = String(enemy_id)
	s.display_name = display_name
	s.portrait_path = portrait_path
	s.level = level
	s.max_hp = max_hp
	s.hp = max_hp
	s.max_mp = max_mp
	s.mp = max_mp
	s.attack = attack
	s.defense = defense
	s.speed = speed
	s.skills = skill_ids.duplicate()
	return s
