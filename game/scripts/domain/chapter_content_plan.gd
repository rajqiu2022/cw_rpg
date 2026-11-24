class_name ChapterContentPlan
extends Resource

## Release content contract for one chapter. The values are production targets,
## not a timer forced on the player; validation keeps authored content deep
## enough for the intended main-route and completionist playtimes.
@export var chapter: int = 1
@export var title: String = ""
@export var main_scene_ids: Array[StringName] = []
@export var main_quest_ids: Array[StringName] = []
@export var side_quest_ids: Array[StringName] = []
## 本章旧草案任务的生产决策。每项至少包含 quest_id / decision / reason，
## decision 使用 implemented / merge / migrate，避免未接入资源长期悬空。
@export var side_quest_decisions: Array[Dictionary] = []
@export var leveling_scene_ids: Array[StringName] = []
@export var story_battle_groups: Array[Dictionary] = []
@export var estimated_main_minutes: int = 60
@export var estimated_completionist_minutes: int = 120
