extends Node

## 全局信号枢纽。
##
## 任何"游戏事件"都从这里广播；监听者（QuestManager / Inventory / SaveManager 等）
## 在 _ready 中订阅。这层抽象避免了"任务系统反向耦合到战斗/场景代码"的灾难。
##
## 用法：
##   EventBus.enemy_defeated.emit(&"thug_lone")
##   EventBus.flag_set.emit(&"rescued_husband", true)
##
## 监听任务完成条件触发请配合 QuestManager 的 trigger 字符串解析逻辑。

signal enemy_defeated(enemy_id: StringName)
signal battle_started(enemy_id: StringName)
signal battle_ended(victory: bool, fled: bool)

signal item_picked_up(item_id: StringName, count: int)
signal item_used(item_id: StringName)
signal item_dropped(item_id: StringName, count: int)
signal gold_changed(new_amount: int)

signal equipment_changed(slot: int, item_id: StringName)

signal scene_entered(scene_id: StringName)
signal hotspot_triggered(scene_id: StringName, hotspot_label: String)
signal npc_talked_to(npc_id: StringName)

signal flag_set(flag_name: StringName, value: Variant)

signal quest_accepted(quest_id: StringName)
signal quest_progressed(quest_id: StringName)
signal quest_completed(quest_id: StringName)
signal quest_failed(quest_id: StringName)

signal player_leveled_up(new_level: int)

signal dialog_started(dialog_id: StringName)
signal dialog_ended(dialog_id: StringName)

signal chapter_completed(chapter: int)
