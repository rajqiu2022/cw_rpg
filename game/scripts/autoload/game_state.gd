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

func _ready() -> void:
	_init_default_player()

func _init_default_player() -> void:
	var stats := CharacterStats.new()
	stats.character_id = "protagonist"
	stats.display_name = "冷孤云"
	stats.portrait_path = "res://art/characters/protagonist_neutral.png"
	stats.level = 1

	## 七项核心属性默认值（v1）
	stats.strength = 8
	stats.agility = 7
	stats.inner_power = 8
	stats.insight = 6
	stats.vitality = 8
	stats.inner_pool = 8
	stats.guard = 7
	stats.refresh_derived_stats(true)

	var skill_ids: Array[StringName] = [&"basic_attack", &"palm_strike", &"defend"]
	stats.skills = skill_ids
	player = stats
	party = [stats] as Array[CharacterStats]

func add_gold(amount: int) -> void:
	gold = max(0, gold + amount)
	emit_signal("gold_changed", gold)
	EventBus.gold_changed.emit(gold)

func reset_for_new_game() -> void:
	flags.clear()
	gold = 0
	current_chapter = 1
	_init_default_player()
	emit_signal("player_changed")
	emit_signal("party_changed")
