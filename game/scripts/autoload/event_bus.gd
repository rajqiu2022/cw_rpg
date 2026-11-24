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

@warning_ignore_start("unused_signal") # EventBus signals are emitted/subscribed from other scripts.
signal enemy_defeated(enemy_id: StringName)
signal battle_started(enemy_id: StringName)
signal battle_ended(victory: bool, fled: bool)
signal damage_calculated(breakdown: DamageBreakdown)

signal item_picked_up(item_id: StringName, count: int)
signal item_used(item_id: StringName)
signal item_dropped(item_id: StringName, count: int)
signal item_read_requested(item_id: StringName)
signal status_cured(cure_type: StringName)  ## "poison" / "weak" / "all" — 战斗中解除状态
signal gold_changed(new_amount: int)

signal equipment_changed(slot: int, item_id: StringName)

signal scene_entered(scene_id: StringName)
signal weather_changed(weather_id: StringName, strength: float)
signal hotspot_triggered(scene_id: StringName, hotspot_label: String)
signal npc_talked_to(npc_id: StringName)
signal companion_joined(companion_id: StringName, display_name: String)
signal dialog_spar_requested(action_payload: String)
signal field_cutscene_requested(cutscene_id: StringName)

signal flag_set(flag_name: StringName, value: Variant)

signal evidence_acquired(evidence_id: StringName)
signal evidence_verified(evidence_id: StringName)
signal testimony_heard(testimony_id: StringName)
signal testimony_verified(testimony_id: StringName)
signal faction_trust_changed(faction_id: StringName, value: int)
signal companion_trust_changed(companion_id: StringName, value: int)
signal bond_event_added(companion_id: StringName, event_id: StringName)
signal city_outcome_changed(city_id: StringName, outcome_key: StringName, value: Variant)
signal method_flag_changed(flag_id: StringName, value: Variant)

signal quest_accepted(quest_id: StringName)
signal quest_progressed(quest_id: StringName)
signal quest_completed(quest_id: StringName)
signal quest_failed(quest_id: StringName)

signal player_leveled_up(new_level: int)
signal skill_learned(skill_id: StringName, display_name: String)
signal internal_art_equipped(character_id: StringName, skill_id: StringName)
signal training_points_changed(total: int, available: int)
signal reputation_changed(value: int, title: String)
signal toast_requested(text: String)

signal dialog_started(dialog_id: StringName)
signal dialog_ended(dialog_id: StringName)

signal ui_requested(panel_id: StringName)

signal chapter_completed(chapter: int)

signal bgm_changed(bgm_path: String)
signal sfx_requested(sfx_path: String, volume_offset: float)
signal audio_volume_changed(kind: StringName, linear: float)
@warning_ignore_restore("unused_signal")
