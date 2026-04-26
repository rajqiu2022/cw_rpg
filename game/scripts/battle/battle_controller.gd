extends Control

## 极简回合制战斗控制器（数据驱动版本）。
##
## 核心改造点（v0.2.0）：
##   - 敌人从 res://data/enemies/<id>.tres 加载（EnemyDef）
##   - 玩家技能从 res://data/skills/<id>.tres 加载（Skill）
##   - 装备加成自动叠加到攻击/防御/速度
##   - 战利品按 EnemyDef.drop_* 配置，金币/经验/物品自动入包
##   - 关键事件广播 EventBus（QuestManager/成就系统将订阅）
##
## 后续（M5/M6）会扩展为：动态技能槽 UI、状态异常系统、敌人 AI 决策树。

enum State { INTRO, PLAYER_TURN, EXECUTE, ENEMY_TURN, RESOLVE, ENDED }

const SKILL_DIR := "res://data/skills/"
const ENEMY_DIR := "res://data/enemies/"

@onready var player_portrait: TextureRect = %PlayerPortrait
@onready var enemy_portrait: TextureRect = %EnemyPortrait
@onready var player_name: Label = %PlayerName
@onready var enemy_name: Label = %EnemyName
@onready var player_hp_bar: ProgressBar = %PlayerHPBar
@onready var enemy_hp_bar: ProgressBar = %EnemyHPBar
@onready var player_mp_bar: ProgressBar = %PlayerMPBar
@onready var player_hp_label: Label = %PlayerHPLabel
@onready var enemy_hp_label: Label = %EnemyHPLabel
@onready var battle_log: RichTextLabel = %BattleLog
@onready var action_panel: VBoxContainer = %ActionPanel
@onready var btn_attack: Button = %BtnAttack
@onready var btn_skill: Button = %BtnSkill
@onready var btn_defend: Button = %BtnDefend
@onready var btn_flee: Button = %BtnFlee

var _state: State = State.INTRO
var _player: CharacterStats
var _enemy: CharacterStats
var _enemy_def: EnemyDef
var _player_defending: bool = false

# 已加载技能缓存
var _skill_attack: Skill
var _skill_palm: Skill
var _skill_defend: Skill


func _ready() -> void:
	_player = GameState.player

	var payload := SceneRouter.get_battle_payload()
	var enemy_id := String(payload.get("enemy_id", "thug_lone"))
	_enemy_def = _load_enemy(enemy_id)
	_enemy = _enemy_def.to_runtime_stats()

	_skill_attack = _load_skill(&"basic_attack")
	_skill_palm = _load_skill(&"palm_strike")
	_skill_defend = _load_skill(&"defend")

	_bind_portraits()
	_refresh_hud()

	if _skill_palm != null:
		btn_skill.text = "%s (-%d MP)" % [_skill_palm.display_name, _skill_palm.mp_cost]

	btn_attack.pressed.connect(func(): _player_action_skill_use(_skill_attack))
	btn_skill.pressed.connect(func(): _player_action_skill_use(_skill_palm))
	btn_defend.pressed.connect(func(): _player_action_defend())
	btn_flee.pressed.connect(func(): _player_action_flee())

	EventBus.battle_started.emit(StringName(enemy_id))

	_log("[b]遭遇战开始[/b]  ——  %s vs %s" % [_player.display_name, _enemy.display_name])
	_log("（提示：装备 %d / %d，攻 +%d 防 +%d）" % [
		1 if Inventory.equipped_weapon else 0,
		1 if Inventory.equipped_armor else 0,
		Inventory.get_atk_bonus(),
		Inventory.get_def_bonus(),
	])
	await get_tree().create_timer(0.5).timeout
	_begin_round()


# --- 数据加载 ---

func _load_enemy(enemy_id: String) -> EnemyDef:
	var path := "%s%s.tres" % [ENEMY_DIR, enemy_id]
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is EnemyDef:
			return res
	push_warning("[Battle] enemy not found: %s, using fallback" % enemy_id)
	var fallback := EnemyDef.new()
	fallback.enemy_id = StringName(enemy_id)
	fallback.display_name = "未知之敌"
	fallback.portrait_path = "res://art/characters/enemy_thug_angry.png"
	fallback.max_hp = 60
	fallback.attack = 10
	fallback.defense = 4
	fallback.speed = 6
	return fallback


func _load_skill(skill_id: StringName) -> Skill:
	var path := "%s%s.tres" % [SKILL_DIR, String(skill_id)]
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is Skill:
			return res
	push_warning("[Battle] skill not found: %s" % skill_id)
	return null


# --- UI ---

func _bind_portraits() -> void:
	if ResourceLoader.exists(_player.portrait_path):
		player_portrait.texture = load(_player.portrait_path)
	if ResourceLoader.exists(_enemy.portrait_path):
		enemy_portrait.texture = load(_enemy.portrait_path)
	enemy_portrait.flip_h = true
	player_name.text = _player.display_name
	enemy_name.text = _enemy.display_name


func _refresh_hud() -> void:
	player_hp_bar.max_value = _player.max_hp
	player_hp_bar.value = _player.hp
	player_hp_label.text = "%d / %d" % [_player.hp, _player.max_hp]
	player_mp_bar.max_value = _player.max_mp
	player_mp_bar.value = _player.mp
	enemy_hp_bar.max_value = _enemy.max_hp
	enemy_hp_bar.value = _enemy.hp
	enemy_hp_label.text = "%d / %d" % [_enemy.hp, _enemy.max_hp]
	btn_skill.disabled = _skill_palm == null or _player.mp < _skill_palm.mp_cost


# --- 回合调度 ---

func _begin_round() -> void:
	if _player_effective_speed() >= _enemy.speed:
		_enter_player_turn()
	else:
		await _do_enemy_turn()
		if _state != State.ENDED:
			_enter_player_turn()


func _enter_player_turn() -> void:
	_state = State.PLAYER_TURN
	_player_defending = false
	action_panel.visible = true
	_log("\n[color=#c8a04a]——你的回合——[/color]")
	_set_buttons_enabled(true)


func _set_buttons_enabled(enabled: bool) -> void:
	for b in [btn_attack, btn_skill, btn_defend, btn_flee]:
		b.disabled = not enabled
	if enabled:
		btn_skill.disabled = _skill_palm == null or _player.mp < _skill_palm.mp_cost


# --- 玩家动作 ---

func _player_action_skill_use(skill: Skill) -> void:
	if _state != State.PLAYER_TURN: return
	if skill == null: return
	if _player.mp < skill.mp_cost: return

	_set_buttons_enabled(false)
	_state = State.EXECUTE
	_player.mp = max(0, _player.mp - skill.mp_cost)

	var atk: int = _player_effective_attack()
	var raw: int = _roll_damage(int(atk * skill.power / 100.0))
	var dmg: int = _enemy.take_damage(raw)

	if skill.skill_id == &"basic_attack":
		_log("→ 你出拳，对 %s 造成 [color=#ff6e6e]%d[/color] 伤害" % [_enemy.display_name, dmg])
	else:
		_log("→ 你施展 [b]%s[/b]，对 %s 造成 [color=#ffb14a]%d[/color] 伤害" % [
			skill.display_name, _enemy.display_name, dmg
		])

	_refresh_hud()
	await _post_action()


func _player_action_defend() -> void:
	if _state != State.PLAYER_TURN: return
	_set_buttons_enabled(false)
	_state = State.EXECUTE
	_player_defending = true
	_log("→ 你摆出防御姿态，本回合受到伤害减半")
	await _post_action()


func _player_action_flee() -> void:
	if _state != State.PLAYER_TURN: return
	_set_buttons_enabled(false)
	if randf() < 0.5:
		_log("→ 你成功逃离战场")
		_end_battle(false, true)
	else:
		_log("→ 逃跑失败！")
		_state = State.EXECUTE
		await _post_action()


# --- 流程 ---

func _post_action() -> void:
	action_panel.visible = false
	if _enemy.is_dead():
		_end_battle(true, false)
		return
	await get_tree().create_timer(0.7).timeout
	await _do_enemy_turn()
	if _state != State.ENDED:
		_enter_player_turn()


func _do_enemy_turn() -> void:
	_state = State.ENEMY_TURN
	_log("\n[color=#88aaff]——敌人的回合——[/color]")
	await get_tree().create_timer(0.5).timeout

	# M1 暂用最简策略：80% 普攻、20% 选另一招
	var skill_id := _enemy_choose_skill()
	var skill := _load_skill(skill_id)
	var raw_atk: int = _enemy.attack
	var skill_power: float = (skill.power if skill != null else 100) / 100.0
	var raw: int = _roll_damage(int(raw_atk * skill_power))

	if _player_defending:
		raw = int(raw * 0.5)

	var def_total: int = _player.defense + Inventory.get_def_bonus()
	var dealt: int = max(1, raw - def_total / 2)
	_player.hp = max(0, _player.hp - dealt)

	if skill != null and skill.skill_id != &"basic_attack":
		_log("← %s 使出 [b]%s[/b]，对你造成 [color=#ff6e6e]%d[/color] 伤害" % [
			_enemy.display_name, skill.display_name, dealt
		])
	else:
		_log("← %s 反击，对你造成 [color=#ff6e6e]%d[/color] 伤害" % [_enemy.display_name, dealt])

	_refresh_hud()
	if _player.is_dead():
		_end_battle(false, false)


func _enemy_choose_skill() -> StringName:
	var pool: Array[StringName] = _enemy.skills
	if pool.is_empty():
		return &"basic_attack"
	# 简单倾向：HP 高时偏好后一个（更强）；HP 低时基础攻
	var hp_ratio: float = float(_enemy.hp) / max(1, _enemy.max_hp)
	if pool.size() >= 2 and hp_ratio > _enemy_def.aggression and randf() < 0.6:
		return pool[1]
	return pool[0]


func _end_battle(victory: bool, fled: bool) -> void:
	_state = State.ENDED
	action_panel.visible = false
	if fled:
		EventBus.battle_ended.emit(false, true)
		await get_tree().create_timer(1.0).timeout
		SceneRouter.go_main_menu()
		return

	await get_tree().create_timer(1.2).timeout
	if victory:
		var loot := _settle_drops(_enemy_def)
		EventBus.enemy_defeated.emit(_enemy_def.enemy_id)
		EventBus.battle_ended.emit(true, false)
		_player.gain_exp(loot.exp)
		SceneRouter.go_victory(loot.gold, loot.exp)
	else:
		EventBus.battle_ended.emit(false, false)
		SceneRouter.go_defeat()


func _settle_drops(def: EnemyDef) -> Dictionary:
	var gold := randi_range(def.drop_gold_min, def.drop_gold_max)
	GameState.add_gold(gold)

	for item_id in def.drop_items:
		Inventory.add_item(item_id, 1)
		_log("[color=#a0e0a0]获得物品：%s[/color]" % String(item_id))

	for entry in def.drop_random:
		var iid: StringName = StringName(entry.get("item_id", ""))
		var chance: float = float(entry.get("chance", 0.0))
		var count: int = int(entry.get("count", 1))
		if String(iid) != "" and randf() < chance:
			Inventory.add_item(iid, count)
			_log("[color=#a0e0a0]获得物品：%s × %d[/color]" % [String(iid), count])

	# M1 验收：打印背包 + 战利品摘要到控制台，方便确认数据驱动闭环
	print("[M1 Smoke] enemy=%s gold=+%d exp=+%d slots=%d weapon=%s" % [
		def.enemy_id,
		gold,
		def.drop_exp,
		Inventory.slots.size(),
		Inventory.equipped_weapon.item_id if Inventory.equipped_weapon else "(none)",
	])
	for s in Inventory.slots:
		var it: Item = s.get("item")
		if it != null:
			print("    - %s × %d" % [it.display_name, int(s.get("count", 0))])

	return {
		"gold": gold,
		"exp": def.drop_exp,
	}


# --- Helpers ---

func _player_effective_attack() -> int:
	return _player.attack + Inventory.get_atk_bonus()


func _player_effective_speed() -> int:
	return _player.speed + Inventory.get_speed_bonus()


func _roll_damage(base_attack: int) -> int:
	## 80% - 120% 浮动
	return int(base_attack * randf_range(0.8, 1.2))


func _log(line: String) -> void:
	battle_log.append_text(line + "\n")
