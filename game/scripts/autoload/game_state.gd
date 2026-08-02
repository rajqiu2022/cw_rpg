extends Node

## 全局游戏状态。挂在 autoload，整个生命周期常驻内存。
## 仅放跨场景的"会话级"数据；持久化交给 SaveManager。

signal player_changed
signal party_changed
signal gold_changed(new_amount: int)

var player: CharacterStats
var party: Array[CharacterStats] = []
var gold: int = 0
var current_chapter: int = 1
var flags: Dictionary = {}
var player_faction: StringName = &""
## 已研读招式的熟练层数。每层为对应招式提供 2% 威力加成，最多 3 层。
var skill_mastery: Dictionary = {}

const FACTION_SKILLS := {
	"wudang": [&"wudang_taiji_chushi", &"wudang_taiji_sixiang", &"wudang_xuanwu_ge", &"wudang_xuanwu_xinjing"],
	"huashan": [&"huashan_yijian", &"huashan_poyun", &"huashan_zixia_ninggang", &"huashan_zixia_shengong"],
	"gufeng": [&"gufeng_kaishan_yidao", &"gufeng_fuhu", &"gufeng_jingang_buhuai", &"gufeng_jingang_li"],
	"lingyue": [&"lingyue_lingbo_yizhi", &"lingyue_hanshuang_zhen", &"lingyue_tayue_lingbo", &"lingyue_yuehua_yin"],
	"mingwu": [&"mingwu_saofeng", &"mingwu_wuyin_sanshi", &"mingwu_mingwu_bu", &"mingwu_yinying_jue"],
}

func _ready() -> void:
	_init_default_player()
	EventBus.flag_set.connect(_on_flag_set)


func _on_flag_set(flag: StringName, _value: Variant) -> void:
	match String(flag):
		"master_training_done":
			for sid in [&"linxi_basic_sword_two", &"linxi_inner_breath"]:
				if sid not in player.skills:
					player.skills.append(sid)
			player_changed.emit()
		"got_linxi_jiu":
			player.max_hp += 100
			player.hp += 100
			player.max_mp += 50
			player.mp += 50
			player_changed.emit()

func _init_default_player() -> void:
	var stats: CharacterStats = CharacterStats.new()
	stats.character_id = "protagonist"
	stats.display_name = "冷孤云"
	stats.portrait_path = "res://art/characters/protagonist_neutral.png"
	stats.level = 1

	## 七项核心属性默认值（v1）
	stats.strength = 8
	stats.agility = 7
	stats.inner_power = 8
	stats.insight = 6
	stats.vitality = 10
	stats.inner_pool = 8
	stats.guard = 7
	stats.refresh_derived_stats(true)

	var skill_ids: Array[StringName] = [&"basic_attack", &"linxi_basic_sword_one", &"defend"]
	stats.skills = skill_ids
	player = stats
	party = [stats] as Array[CharacterStats]

func add_gold(amount: int) -> void:
	gold = max(0, gold + amount)
	emit_signal("gold_changed", gold)
	EventBus.gold_changed.emit(gold)

func reset_for_new_game() -> void:
	flags.clear()
	player_faction = &""
	skill_mastery.clear()
	gold = 0
	current_chapter = 1
	_init_default_player()
	emit_signal("player_changed")
	emit_signal("party_changed")


func get_skill_mastery(skill_id: StringName) -> int:
	return clampi(int(skill_mastery.get(String(skill_id), 0)), 0, 3)


func practice_skill(skill_id: StringName) -> bool:
	if player == null or skill_id not in player.skills:
		return false
	var current := get_skill_mastery(skill_id)
	if current >= 3:
		return false
	skill_mastery[String(skill_id)] = current + 1
	player_changed.emit()
	return true


func select_faction(faction_id: StringName) -> bool:
	if String(faction_id) not in ["wudang", "huashan", "gufeng", "lingyue", "mingwu"]:
		return false
	if String(player_faction) != "" and player_faction != faction_id:
		return false
	player_faction = faction_id
	flags["player_faction"] = String(faction_id)
	flags["joined_faction"] = true
	for id in ["wudang", "huashan", "gufeng", "lingyue", "mingwu"]:
		flags["joined_%s" % id] = id == String(faction_id)
	for skill_id in FACTION_SKILLS.get(String(faction_id), []):
		if skill_id not in player.skills:
			player.skills.append(skill_id)
	player_changed.emit()
	return true
