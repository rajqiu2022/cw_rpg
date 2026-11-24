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

## Field HUD only: a short, spoiler-free destination such as
## "林西村 · 师徒院落". Long narrative descriptions remain in the quest log.
@export var tracker_hint: String = ""

## Optional spoiler-safe investigation log. Each entry is
## {"trigger":"flag_set:key"|"evidence_acquired:id", "text":"..."}.
## The quest panel shows only records whose trigger has actually occurred.
@export var progress_records: Array[Dictionary] = []

## 完成条件（满足任意一条即可，MVP 简化）。语法：
##   "enemy_defeated:boss_zhao_wuji"
##   "scene_entered:ch1_s2_qingfeng"
##   "flag_set:rescued_husband"
##   "item_picked_up:iron_sword"
@export var completion_triggers: Array[String] = []

@export_category("Long Chain")
## 任一触发发生时自动接取任务，用于跨章节奇遇，不需要在每个场景硬编码 accept_quest。
@export var auto_accept_triggers: Array[String] = []
## 开启后必须满足全部 completion_triggers；默认任务仍保持“任一条件完成”的旧行为。
@export var require_all_completion_triggers: bool = false
## 开放世界奇遇可在任意章节接取与结算；starts/completes字段仅保留为内容索引提示，不参与运行门控。
@export var chapter_independent: bool = false
@export_range(1, 8, 1) var starts_in_chapter: int = 1
@export_range(1, 8, 1) var completes_in_chapter: int = 1
## 仅供任务日志/验证描述跨章里程碑，不用于 HUD 剧透。
@export var milestone_labels: Array[String] = []

@export_category("Rewards")
@export var reward_gold: int = 0
@export var reward_exp: int = 0
## 物品奖励：[{"item_id": "iron_sword", "count": 1}]
@export var reward_items: Array[Dictionary] = []
## 武学奖励。统一经过 GameState.learn_skill，悟性不足时进入待领悟列表。
@export var reward_skills: Array[StringName] = []
## 门派限定武学奖励。key 为 faction id，value 为 Array[StringName]。
## 用于后期门派绝学，避免玩家从其他门派剧情中串学。
@export var reward_skills_by_faction: Dictionary = {}
## 条件武学奖励。key 为进度 flag，value 为 Array[StringName]；
## 适合门派分支、解谜路线等不应仅由门派 ID 决定的奖励。
@export var reward_skills_by_flag: Dictionary = {}


func get_description(status: Status) -> String:
	match status:
		Status.NOT_STARTED: return desc_not_started
		Status.IN_PROGRESS: return desc_in_progress
		Status.COMPLETED:   return desc_completed
		_: return desc_in_progress


func get_tracker_hint() -> String:
	return tracker_hint.strip_edges()
