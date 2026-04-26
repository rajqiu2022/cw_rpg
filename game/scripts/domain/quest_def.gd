class_name QuestDef
extends Resource

## 任务定义。运行时在 QuestManager 里追踪状态。
## MVP 任务模型：接受 → 进行中 → 完成（或失败）。
## 完成条件用字符串列表表达，由 EventBus 事件触发匹配。

enum Status { NOT_STARTED, IN_PROGRESS, COMPLETED, FAILED }
enum Kind { MAIN, SIDE }

@export var quest_id: StringName = ""
@export var title: String = ""
@export var kind: Kind = Kind.SIDE

## 各状态下显示的描述（任务面板用）
@export var desc_not_started: String = ""
@export var desc_in_progress: String = ""
@export var desc_completed: String = ""

## 完成条件（满足任意一条即可，MVP 简化）。语法：
##   "enemy_defeated:boss_zhao_wuji"
##   "scene_entered:ch1_s2_qingfeng"
##   "flag_set:rescued_husband"
##   "item_picked_up:iron_sword"
@export var completion_triggers: Array[String] = []

@export_category("Rewards")
@export var reward_gold: int = 0
@export var reward_exp: int = 0
## 物品奖励：[{"item_id": "iron_sword", "count": 1}]
@export var reward_items: Array[Dictionary] = []


func get_description(status: Status) -> String:
	match status:
		Status.NOT_STARTED: return desc_not_started
		Status.IN_PROGRESS: return desc_in_progress
		Status.COMPLETED:   return desc_completed
		_: return desc_in_progress
