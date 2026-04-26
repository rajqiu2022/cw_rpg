extends Control

## 极简回合制战斗控制器。
## 主角 vs 单个敌人，速度比较先后手。可被后续 PartyBattle 复用核心 API。

enum State { INTRO, PLAYER_TURN, EXECUTE, ENEMY_TURN, RESOLVE, ENDED }

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
var _player_defending: bool = false

func _ready() -> void:
	_player = GameState.player
	_enemy = _build_enemy(SceneRouter.get_battle_payload().get("enemy_id", "default_thug"))

	_bind_portraits()
	_refresh_hud()

	btn_attack.pressed.connect(func(): _player_action_attack())
	btn_skill.pressed.connect(func(): _player_action_skill())
	btn_defend.pressed.connect(func(): _player_action_defend())
	btn_flee.pressed.connect(func(): _player_action_flee())

	_log("[b]遭遇战开始[/b]  ——  %s vs %s" % [_player.display_name, _enemy.display_name])
	await get_tree().create_timer(0.5).timeout
	_begin_round()

func _build_enemy(enemy_id: String) -> CharacterStats:
	## 临时：只支持 default_thug。后续从 res://data/enemies/<id>.tres 加载。
	var s := CharacterStats.new()
	s.character_id = enemy_id
	s.display_name = "无名匪徒"
	s.portrait_path = "res://art/characters/enemy_thug_angry.png"
	s.level = 1
	s.max_hp = 80
	s.hp = 80
	s.attack = 14
	s.defense = 6
	s.speed = 8
	return s

func _bind_portraits() -> void:
	player_portrait.texture = load(_player.portrait_path)
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
	btn_skill.disabled = _player.mp < 5

func _begin_round() -> void:
	if _player.speed >= _enemy.speed:
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

func _set_buttons_enabled(enabled: bool) -> void:
	for b in [btn_attack, btn_skill, btn_defend, btn_flee]:
		b.disabled = not enabled
	if enabled:
		btn_skill.disabled = _player.mp < 5

# --- Player Actions ---

func _player_action_attack() -> void:
	if _state != State.PLAYER_TURN: return
	_set_buttons_enabled(false)
	_state = State.EXECUTE
	var dmg: int = _enemy.take_damage(_roll_damage(_player.attack))
	_log("→ 你出拳，对 %s 造成 [color=#ff6e6e]%d[/color] 点伤害" % [_enemy.display_name, dmg])
	_refresh_hud()
	await _post_action()

func _player_action_skill() -> void:
	if _state != State.PLAYER_TURN: return
	if _player.mp < 5: return
	_set_buttons_enabled(false)
	_state = State.EXECUTE
	_player.mp -= 5
	var dmg: int = _enemy.take_damage(_roll_damage(int(_player.attack * 1.6)))
	_log("→ 你施展 [b]排云掌[/b]，对 %s 造成 [color=#ffb14a]%d[/color] 点伤害" % [_enemy.display_name, dmg])
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

# --- Flow ---

func _post_action() -> void:
	action_panel.visible = false
	if _enemy.is_dead():
		_end_battle(true, false)
		return
	await get_tree().create_timer(0.7).timeout
	await _do_enemy_turn()
	if _state != State.ENDED:
		_enter_player_turn()
		_set_buttons_enabled(true)

func _do_enemy_turn() -> void:
	_state = State.ENEMY_TURN
	_log("\n[color=#88aaff]——敌人的回合——[/color]")
	await get_tree().create_timer(0.5).timeout
	var raw: int = _roll_damage(_enemy.attack)
	if _player_defending:
		raw = int(raw * 0.5)
	var dmg: int = _player.take_damage(raw)
	_log("← %s 反击，对你造成 [color=#ff6e6e]%d[/color] 点伤害" % [_enemy.display_name, dmg])
	_refresh_hud()
	if _player.is_dead():
		_end_battle(false, false)

func _end_battle(victory: bool, fled: bool) -> void:
	_state = State.ENDED
	action_panel.visible = false
	if fled:
		await get_tree().create_timer(1.0).timeout
		SceneRouter.go_main_menu()
		return
	await get_tree().create_timer(1.2).timeout
	if victory:
		var gold: int = 30 + randi_range(0, 20)
		var exp: int = 25
		GameState.add_gold(gold)
		_player.gain_exp(exp)
		SceneRouter.go_victory(gold, exp)
	else:
		SceneRouter.go_defeat()

# --- Helpers ---

func _roll_damage(base_attack: int) -> int:
	## 80%-120% 浮动
	return int(base_attack * randf_range(0.8, 1.2))

func _log(line: String) -> void:
	battle_log.append_text(line + "\n")
