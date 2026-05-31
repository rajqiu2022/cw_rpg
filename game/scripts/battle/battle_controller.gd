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
const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const BATTLE_HUD_ATLAS_PATH := "res://art/ui/cold_wuxia/v1/ui_cold_wuxia_battle_hud_v1.png"
const ATTR_ICON_ATLAS_PATH := "res://art/ui/cold_wuxia/v1/ui_cold_wuxia_attribute_icons_v1.png"
const BATTLE_FRAME_REGIONS := {
	"enemy": Rect2(762, 29, 334, 386),
	"player": Rect2(1130, 29, 335, 387),
	"log": Rect2(55, 417, 1410, 231),
}
const ATTR_ICON_REGIONS := {
	"筋骨": Rect2(37, 55, 203, 204),
	"机敏": Rect2(290, 55, 201, 204),
	"内劲": Rect2(544, 55, 200, 204),
	"悟性": Rect2(794, 55, 195, 203),
	"生命": Rect2(1033, 55, 197, 204),
	"内力": Rect2(1281, 55, 196, 204),
	"防御": Rect2(38, 293, 202, 207),
}

@onready var battle_background: TextureRect = $Background
@onready var dim_layer: ColorRect = $Dim
@onready var log_panel: PanelContainer = $LogPanel
@onready var player_portrait: TextureRect = %PlayerPortrait
@onready var enemy_portrait: TextureRect = %EnemyPortrait
@onready var player_name: Label = %PlayerName
@onready var enemy_name: Label = %EnemyName
@onready var enemy_hud: VBoxContainer = $EnemyHUD
@onready var player_hud: VBoxContainer = $PlayerHUD
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

var _player_mp_label: Label = null
var _turn_label: Label = null
var _command_title: Label = null
var _player_status_label: Label = null
var _enemy_status_label: Label = null

var _state: State = State.INTRO
var _player: CharacterStats
var _enemy: CharacterStats
var _enemy_def: EnemyDef
var _player_defending: bool = false
var _player_poison_turns: int = 0
var _player_weak_turns: int = 0
var _enemy_poison_turns: int = 0
var _enemy_weak_turns: int = 0
var _player_burst_turns: int = 0  ## 爆发：暴击率+50%
var _enemy_burst_turns: int = 0

# 互补系统临时状态
var _complement_poison_boost: bool = false  ## 凌月互补：本轮中毒伤害+50%
var _complement_reflect_active: bool = false  ## 武当互补：受击时反射 15%

# 动态技能列表
var _player_skills: Array[Skill] = []
var _current_skill_index: int = 1
var _action_icon_atlas: Texture2D = null


func _ready() -> void:
	_player = GameState.player

	var payload := SceneRouter.get_battle_payload()
	var enemy_id: String = String(payload.get("enemy_id", "thug_lone"))
	_enemy_def = _load_enemy(enemy_id)
	_enemy = _enemy_def.to_runtime_stats()

	# 动态加载玩家所有技能
	for sid in _player.skills:
		var sk := _load_skill(sid)
		if sk != null:
			_player_skills.append(sk)

	_bind_portraits()
	_apply_visual_style()
	_apply_hud_art_overlays()
	_apply_action_button_icons()
	_refresh_hud()
	_refresh_skill_button()

	btn_attack.pressed.connect(func(): _player_action_skill_use(0))
	btn_skill.pressed.connect(func(): _player_action_skill_use(_current_skill_index))
	btn_defend.pressed.connect(func(): _player_action_defend())
	btn_flee.pressed.connect(func(): _player_action_flee())

	EventBus.battle_started.emit(StringName(enemy_id))
	EventBus.status_cured.connect(_on_status_cured)

	_log("[b]遭遇战开始[/b]  ——  %s vs %s" % [_player.display_name, _enemy.display_name])
	_log("（提示：已装备 %d 件，攻 +%d 防 +%d）" % [
		Inventory.equipped.size(),
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
	var fallback: EnemyDef = EnemyDef.new()
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


func _build_formal_battle_layout() -> void:
	player_hud.offset_left = 48
	player_hud.offset_top = -178
	player_hud.offset_right = 530
	player_hud.offset_bottom = -38
	enemy_hud.offset_left = -530
	enemy_hud.offset_top = 34
	enemy_hud.offset_right = -48
	enemy_hud.offset_bottom = 158
	log_panel.offset_left = -430
	log_panel.offset_top = -118
	log_panel.offset_right = 430
	log_panel.offset_bottom = 132
	action_panel.offset_left = -310
	action_panel.offset_top = -356
	action_panel.offset_right = -48
	action_panel.offset_bottom = -44

	if _turn_label == null:
		_turn_label = Label.new()
		_turn_label.name = "TurnLabel"
		_turn_label.layout_mode = 1
		_turn_label.anchor_left = 0.5
		_turn_label.anchor_right = 0.5
		_turn_label.offset_left = -190
		_turn_label.offset_top = 28
		_turn_label.offset_right = 190
		_turn_label.offset_bottom = 74
		_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_turn_label.text = "遭遇战"
		add_child(_turn_label)

	if _player_mp_label == null:
		_player_mp_label = Label.new()
		_player_mp_label.name = "PlayerMPLabel"
		_player_mp_label.text = "0 / 0"
		player_hud.add_child(_player_mp_label)

	if _player_status_label == null:
		_player_status_label = Label.new()
		_player_status_label.name = "PlayerStatusLabel"
		_player_status_label.text = "状态：正常"
		player_hud.add_child(_player_status_label)

	if _enemy_status_label == null:
		_enemy_status_label = Label.new()
		_enemy_status_label.name = "EnemyStatusLabel"
		_enemy_status_label.text = "状态：正常"
		enemy_hud.add_child(_enemy_status_label)

	if _command_title == null:
		_command_title = Label.new()
		_command_title.name = "CommandTitle"
		_command_title.text = "出招"
		_command_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		action_panel.add_child(_command_title)
		action_panel.move_child(_command_title, 0)


func _apply_visual_style() -> void:
	battle_background.modulate = Color(0.62, 0.72, 0.78, 0.88)
	dim_layer.color = Color(0.005, 0.010, 0.016, 0.36)
	log_panel.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.040, 0.060, 0.074, 0.94), UI_THEME.GOLD, 16, 2))
	UI_THEME.style_rich_text(battle_log, 18)
	UI_THEME.style_label(player_name, 28, UI_THEME.GOLD_LIGHT)
	UI_THEME.style_label(enemy_name, 28, Color(0.95, 0.62, 0.68, 1.0))
	UI_THEME.style_label(player_hp_label, 16, UI_THEME.TEXT, false)
	UI_THEME.style_label(enemy_hp_label, 16, UI_THEME.TEXT, false)
	if _player_mp_label != null:
		UI_THEME.style_label(_player_mp_label, 15, Color(0.76, 0.90, 1.0, 1.0), false)
	if _turn_label != null:
		UI_THEME.style_label(_turn_label, 28, UI_THEME.GOLD_LIGHT)
	if _command_title != null:
		UI_THEME.style_label(_command_title, 24, UI_THEME.GOLD_LIGHT)
	if _player_status_label != null:
		UI_THEME.style_label(_player_status_label, 15, UI_THEME.JADE, false)
	if _enemy_status_label != null:
		UI_THEME.style_label(_enemy_status_label, 15, Color(0.95, 0.62, 0.68, 1.0), false)
	UI_THEME.style_progress(player_hp_bar, Color(0.58, 0.14, 0.20, 1.0))
	UI_THEME.style_progress(enemy_hp_bar, Color(0.58, 0.14, 0.20, 1.0))
	UI_THEME.style_progress(player_mp_bar, Color(0.28, 0.62, 0.78, 1.0))
	for b in [btn_attack, btn_skill, btn_defend, btn_flee]:
		UI_THEME.style_button(b, 21, UI_THEME.BLUE_STEEL)
	btn_attack.text = "普通攻击"
	btn_defend.text = "防御架势"
	btn_flee.text = "撤离"
	btn_attack.add_theme_stylebox_override("normal", UI_THEME.button_style(Color(0.055, 0.090, 0.095, 0.96), UI_THEME.JADE))
	btn_defend.add_theme_stylebox_override("normal", UI_THEME.button_style(Color(0.045, 0.070, 0.090, 0.96), UI_THEME.BLUE_STEEL))
	btn_flee.add_theme_stylebox_override("normal", UI_THEME.button_style(Color(0.100, 0.050, 0.060, 0.94), UI_THEME.CRIMSON))
	action_panel.add_theme_constant_override("separation", 14)


func _refresh_hud() -> void:
	player_hp_bar.max_value = _player.max_hp
	player_hp_bar.value = _player.hp
	player_hp_label.text = "%d / %d" % [_player.hp, _player.max_hp]
	var status_texts: Array[String] = []
	if _player_poison_turns > 0: status_texts.append("中毒%d" % _player_poison_turns)
	if _player_stun_turns > 0: status_texts.append("眩晕")
	if _player_freeze_turns > 0: status_texts.append("冰冻")
	if _player_weak_turns > 0: status_texts.append("虚弱%d" % _player_weak_turns)
	if _player_defending: status_texts.append("防御")
	if status_texts.size() > 0:
		player_hp_label.text += "  [%s]" % ", ".join(status_texts)
	player_mp_bar.max_value = _player.max_mp
	player_mp_bar.value = _player.mp
	enemy_hp_bar.max_value = _enemy.max_hp
	enemy_hp_bar.value = _enemy.hp
	enemy_hp_label.text = "%d / %d" % [_enemy.hp, _enemy.max_hp]
	var enemy_status: Array[String] = []
	if _enemy_poison_turns > 0: enemy_status.append("中毒")
	if _enemy_stun_turns > 0: enemy_status.append("眩晕")
	if _enemy_freeze_turns > 0: enemy_status.append("冰冻")
	if _enemy_weak_turns > 0: enemy_status.append("虚弱")
	if enemy_status.size() > 0:
		enemy_hp_label.text += "  [%s]" % ", ".join(enemy_status)
	btn_skill.disabled = _player_skills.size() <= 1 or _player.mp < _player_skills[_current_skill_index].mp_cost


func _apply_hud_art_overlays() -> void:
	if not ResourceLoader.exists(BATTLE_HUD_ATLAS_PATH):
		return
	var atlas := load(BATTLE_HUD_ATLAS_PATH) as Texture2D
	if atlas == null:
		return
	_attach_hud_overlay("EnemyHudFrame", atlas, BATTLE_FRAME_REGIONS["enemy"], enemy_hud, Vector2(26, 20), Color(1, 1, 1, 0.90))
	_attach_hud_overlay("PlayerHudFrame", atlas, BATTLE_FRAME_REGIONS["player"], player_hud, Vector2(26, 22), Color(1, 1, 1, 0.90))
	_attach_hud_overlay("BattleLogFrame", atlas, BATTLE_FRAME_REGIONS["log"], log_panel, Vector2(18, 14), Color(1, 1, 1, 0.82))


func _attach_hud_overlay(name: String, atlas: Texture2D, region: Rect2, target: Control, pad: Vector2, tint: Color) -> void:
	if target == null:
		return
	var overlay := get_node_or_null(name) as TextureRect
	if overlay == null:
		overlay = TextureRect.new()
		overlay.name = name
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		overlay.stretch_mode = TextureRect.STRETCH_SCALE
		overlay.z_index = -5
		add_child(overlay)
	var tex: AtlasTexture = AtlasTexture.new()
	tex.atlas = atlas
	tex.region = region
	overlay.texture = tex
	overlay.modulate = tint
	overlay.layout_mode = 1
	overlay.anchor_left = target.anchor_left
	overlay.anchor_top = target.anchor_top
	overlay.anchor_right = target.anchor_right
	overlay.anchor_bottom = target.anchor_bottom
	overlay.offset_left = target.offset_left - pad.x
	overlay.offset_top = target.offset_top - pad.y
	overlay.offset_right = target.offset_right + pad.x
	overlay.offset_bottom = target.offset_bottom + pad.y


func _apply_action_button_icons() -> void:
	if _action_icon_atlas == null and ResourceLoader.exists(ATTR_ICON_ATLAS_PATH):
		_action_icon_atlas = load(ATTR_ICON_ATLAS_PATH)
	if _action_icon_atlas == null:
		return
	_apply_button_icon(btn_attack, "筋骨", UI_THEME.GOLD)
	_apply_button_icon(btn_skill, "内劲", UI_THEME.JADE)
	_apply_button_icon(btn_defend, "防御", UI_THEME.BLUE_STEEL)
	_apply_button_icon(btn_flee, "机敏", UI_THEME.CRIMSON)


func _apply_button_icon(btn: Button, icon_key: String, accent: Color) -> void:
	if btn == null:
		return
	UI_THEME.style_button(btn, 22, accent)
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var icon := _build_button_icon_texture(icon_key, 26)
	if icon != null:
		btn.icon = icon


func _build_button_icon_texture(icon_key: String, icon_size: int) -> Texture2D:
	if _action_icon_atlas == null:
		return null
	var region: Rect2 = ATTR_ICON_REGIONS.get(icon_key, Rect2())
	if region.size.x <= 0 or region.size.y <= 0:
		return null
	var atlas_img := _action_icon_atlas.get_image()
	if atlas_img == null:
		return null
	var src_rect := Rect2i(int(region.position.x), int(region.position.y), int(region.size.x), int(region.size.y))
	var img := Image.create(src_rect.size.x, src_rect.size.y, false, Image.FORMAT_RGBA8)
	img.blit_rect(atlas_img, src_rect, Vector2i.ZERO)
	img.resize(icon_size, icon_size, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)


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
	_complement_reflect_active = false  # 重置上回合的互补状态
	if await _apply_player_status_at_turn_start():
		return
	action_panel.visible = true
	_log("\n[color=#c8a04a]——你的回合——[/color]")
	_set_buttons_enabled(true)


func _set_buttons_enabled(enabled: bool) -> void:
	for b in [btn_attack, btn_skill, btn_defend, btn_flee]:
		b.disabled = not enabled
	if enabled:
		btn_skill.disabled = _player_skills.size() <= 1 or _player.mp < _player_skills[_current_skill_index].mp_cost


# --- 玩家动作 ---

func _player_action_skill_use(skill_idx: int) -> void:
	if _state != State.PLAYER_TURN: return
	if skill_idx < 0 or skill_idx >= _player_skills.size(): return
	var skill: Skill = _player_skills[skill_idx]
	if _player.mp < skill.mp_cost: return

	_set_buttons_enabled(false)
	_state = State.EXECUTE
	_player.mp = max(0, _player.mp - skill.mp_cost)

	# ── 内功互补 + 装备加成 ──
	var extra_power: int = 0
	var complement_active: bool = false
	var crit_mult_bonus: float = 0.0

	if skill.school != "" and skill.school != "generic":
		# 装备技能加成
		var gear_bonus := Inventory.get_equipped_skill_bonus(skill.school)
		extra_power += gear_bonus["power"]
		crit_mult_bonus += gear_bonus["crit_mult"]

		# 内功互补检测
		if skill.complemented_by != "":
			for sid in _player.skills:
				if sid == skill.complemented_by:
					complement_active = true
					extra_power += skill.complement_bonus_power
					break

	var power_mult: float = (skill.power + extra_power) / 100.0

	# 华山互补：暴击倍率加成
	if complement_active and skill.school == "huashan":
		crit_mult_bonus += 0.3

	# 凌月互补：中毒伤害 +50%（在敌人回合中毒结算时生效）
	_complement_poison_boost = complement_active and skill.school == "lingyue"

	# 茗雾互补：对残血敌人额外伤害
	var mingwu_bonus_applied := false
	if complement_active and skill.school == "mingwu":
		var enemy_hp_ratio: float = float(_enemy.hp) / max(1, _enemy.max_hp)
		if enemy_hp_ratio < 0.5:
			power_mult *= 1.2
			mingwu_bonus_applied = true

	# 武当互补：反射标记（在 _post_action 中处理）
	_complement_reflect_active = complement_active and skill.school == "wudang"

	# 互补效果日志
	if complement_active and skill.complement_bonus_desc != "":
		_log("  [color=#c8a04a][互补] %s[/color]" % skill.complement_bonus_desc)
	if mingwu_bonus_applied:
		_log("  [color=#c8a04a][影杀] 敌人HP<50%，伤害+20%[/color]")

	# BUFF 型技能：不造成伤害，施加爆发/防御等自身效果
	if skill.kind == Skill.Kind.BUFF:
		_apply_player_buff(skill)
		_refresh_hud()
		_current_skill_index = skill_idx
		await _post_action()
		return

	var atk: int = _player_effective_attack()
	# 使用修正后的 power_mult 和 crit_mult_bonus 计算伤害
	var raw: int = _calc_damage_ext(atk, power_mult, _enemy.defense, true, crit_mult_bonus)
	var dmg: int = _enemy.take_damage(raw)

	if skill.skill_id == &"basic_attack":
		_log("→ 你出招，对 %s 造成 [color=#ff6e6e]%d[/color] 伤害" % [_enemy.display_name, dmg])
	else:
		_log("→ 你施展 [b]%s[/b]，对 %s 造成 [color=#ffb14a]%d[/color] 伤害" % [
			skill.display_name, _enemy.display_name, dmg
		])

	_try_apply_player_debuff(skill.skill_id)

	# 自 buff 型攻击技（造成伤害 + 自身爆发）
	match String(skill.skill_id):
		"mingwu_saofeng", "mingwu_wuyin_sanshi":
			_player_burst_turns = max(_player_burst_turns, 1)
			_log("  [color=#ffb14a][爆发] 暴击率 +50%%，持续 1 回合[/color]")

	_refresh_hud()
	_current_skill_index = skill_idx
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
	if _turn_label != null:
		_turn_label.text = "敌方回合"
	_log("\n[color=#88aaff]——敌人的回合——[/color]")

	# 敌人状态检查
	if _enemy_weak_turns > 0:
		_enemy_weak_turns -= 1
		if _enemy_weak_turns <= 0:
			_log("  %s 虚弱状态已解除。" % _enemy.display_name)

	if _enemy_burst_turns > 0:
		_enemy_burst_turns -= 1

	# 敌人中毒伤害
	if _enemy_poison_turns > 0:
		var dot: int = maxi(3, int(round(float(_enemy.max_hp) * 0.05)))
		# 凌月互补：中毒伤害 +50%
		if _complement_poison_boost:
			dot = int(dot * 1.5)
		_enemy.hp = max(0, _enemy.hp - dot)
		_enemy_poison_turns -= 1
		_log("  %s 中毒发作，损失 %d 点生命。" % [_enemy.display_name, dot])
		if _enemy.is_dead():
			_refresh_hud()
			_end_battle(true, false)
			return

	await get_tree().create_timer(0.5).timeout

	var skill_id := _enemy_choose_skill()
	var skill := _load_skill(skill_id)
	var atk: int = _enemy.attack
	var power_mult: float = (skill.power if skill != null else 100) / 100.0
	var dmg: int = _calc_damage(atk, power_mult, _player.defense + Inventory.get_def_bonus(), false)

	if _player_defending:
		dmg = int(dmg * 0.5)

	# 武当互补：玄武心经护体反射 15%
	if _complement_reflect_active:
		var reflect: int = int(dmg * 0.15)
		if reflect > 0:
			_enemy.hp = max(0, _enemy.hp - reflect)
			_log("  [color=#88aaff][玄武护体] 反弹 %d 伤害[/color]" % reflect)
			if _enemy.is_dead():
				_refresh_hud()
				_end_battle(true, false)
				return
		_complement_reflect_active = false

	_player.hp = max(0, _player.hp - dmg)

	if skill != null and skill.skill_id != &"basic_attack":
		_log("← %s 使出 [b]%s[/b]，对你造成 [color=#ff6e6e]%d[/color] 伤害" % [
			_enemy.display_name, skill.display_name, dmg
		])
	else:
		_log("← %s 攻击，对你造成 [color=#ff6e6e]%d[/color] 伤害" % [_enemy.display_name, dmg])

	_try_apply_enemy_debuff(skill_id)
	_refresh_hud()
	if _player.is_dead():
		_end_battle(false, false)


func _enemy_choose_skill() -> StringName:
	var pool: Array[StringName] = _enemy.skills
	if pool.is_empty():
		return &"basic_attack"
	# 简单倾向：高血更爱施加异常，低血偶尔重斩。
	var hp_ratio: float = float(_enemy.hp) / max(1, _enemy.max_hp)
	if pool.size() >= 2 and hp_ratio > _enemy_def.aggression and randf() < 0.55:
		return pool[1]
	if pool.size() >= 3 and hp_ratio < 0.45 and randf() < 0.45:
		return pool[2]
	return pool[0]


func _try_apply_enemy_debuff(skill_id: StringName) -> void:
	match String(skill_id):
		"toxic_needle":
			if randf() < 0.55:
				_player_poison_turns = max(_player_poison_turns, 3)
				_log("[color=#72d2a6]你中了毒针！中毒，3 回合持续掉血。[/color]")
		"heavy_swing":
			if randf() < 0.3:
				_player_weak_turns = max(_player_weak_turns, 2)
				_log("[color=#cc8844]你被重击震伤！虚弱，攻防降低 2 回合。[/color]")


func _apply_player_status_at_turn_start() -> bool:
	# 虚弱：倒计时
	if _player_weak_turns > 0:
		_player_weak_turns -= 1
		if _player_weak_turns <= 0:
			_log("[color=#aaffaa]虚弱状态已解除。[/color]")

	# 爆发：倒计时
	if _player_burst_turns > 0:
		_player_burst_turns -= 1
		if _player_burst_turns <= 0:
			_log("[color=#ffb14a]爆发状态结束。[/color]")

	# 中毒：扣血
	if _player_poison_turns > 0:
		var dot: int = maxi(4, int(round(float(_player.max_hp) * 0.05)))
		_player.hp = max(0, _player.hp - dot)
		_player_poison_turns -= 1
		_log("[color=#72d2a6]中毒发作，损失 %d 点生命。[/color]" % dot)
		_refresh_hud()
		if _player.is_dead():
			_end_battle(false, false)
			return true

	return false


func _end_battle(victory: bool, fled: bool) -> void:
	_state = State.ENDED
	action_panel.visible = false
	if fled:
		EventBus.battle_ended.emit(false, true)
		await get_tree().create_timer(1.0).timeout
		var payload := SceneRouter.get_battle_payload()
		var return_scene: StringName = payload.get("return_scene", &"")
		if String(return_scene) != "":
			SceneRouter.go_field_smart(return_scene)
		else:
			SceneRouter.go_main_menu()
		return

	await get_tree().create_timer(1.2).timeout
	if victory:
		var loot := _settle_drops(_enemy_def)
		# 自动写入 "defeated_<enemy_id>" flag，便于 hotspot 自动隐藏
		var flag_key := "defeated_%s" % String(_enemy_def.enemy_id)
		GameState.flags[flag_key] = true
		EventBus.flag_set.emit(StringName(flag_key), true)
		EventBus.enemy_defeated.emit(_enemy_def.enemy_id)
		EventBus.battle_ended.emit(true, false)
		_player.gain_exp(loot.exp)
		if _is_chapter_boss(_enemy_def.enemy_id):
			SceneRouter.go_chapter_end(GameState.current_chapter)
		else:
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
	print("[M1 Smoke] enemy=%s gold=+%d exp=+%d slots=%d equipped=%d" % [
		def.enemy_id,
		gold,
		def.drop_exp,
		Inventory.slots.size(),
		Inventory.equipped.size(),
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
	var legacy_atk: int = _player.attack + Inventory.get_atk_bonus()
	var core_atk: int = (_player.strength * 2 + _player.inner_power) + (Inventory.get_strength_bonus() * 2 + Inventory.get_inner_power_bonus())
	return max(legacy_atk, core_atk)


func _player_effective_speed() -> int:
	var legacy_spd: int = _player.speed + Inventory.get_speed_bonus()
	var core_spd: int = (_player.agility * 2 + _player.insight) + (Inventory.get_agility_bonus() * 2 + Inventory.get_insight_bonus())
	return max(legacy_spd, core_spd)


func _calc_damage(base_atk: int, power_mult: float, target_def: int, is_player: bool) -> int:
	return _calc_damage_ext(base_atk, power_mult, target_def, is_player, 0.0)


## 扩展伤害计算，支持暴击倍率加成（用于互补/装备加成系统）。
func _calc_damage_ext(base_atk: int, power_mult: float, target_def: int, is_player: bool, crit_mult_bonus: float) -> int:
	## 统一伤害计算：浮动 + 暴击 + 防御减免 + 虚弱系数
	var raw: int = int(base_atk * power_mult * randf_range(0.85, 1.15))

	# 暴击判定 (5% + 悟性加成 + 爆发 +50%)
	var crit_chance: float = 0.05
	if is_player:
		crit_chance += _player.insight * 0.005
		if _player_burst_turns > 0:
			crit_chance += 0.50
	elif _enemy_burst_turns > 0:
		crit_chance += 0.50
	if randf() < crit_chance:
		var crit_mult: float = 1.5 + crit_mult_bonus
		raw = int(raw * crit_mult)
		if crit_mult_bonus > 0.01:
			_log("  [color=#ffb14a][b]暴击！(×%.1f)[/b][/color]" % crit_mult)
		else:
			_log("  [color=#ffb14a][b]暴击！[/b][/color]")

	# 防御减免（虚弱时防御降为 50%）
	var effective_def: int = target_def
	if not is_player and _enemy_weak_turns > 0:
		effective_def = int(target_def * 0.5)
	elif is_player and _player_weak_turns > 0:
		effective_def = int(target_def * 0.5)
	var dealt: int = max(1, raw - effective_def)

	# 虚弱状态：输出伤害降低 30%
	if is_player and _player_weak_turns > 0:
		dealt = int(dealt * 0.7)
	elif not is_player and _enemy_weak_turns > 0:
		dealt = int(dealt * 0.7)

	# 受伤虚弱系数（双向）
	var source_hp_ratio: float
	if is_player:
		source_hp_ratio = float(_player.hp) / max(1, _player.max_hp)
	else:
		source_hp_ratio = float(_enemy.hp) / max(1, _enemy.max_hp)

	var weakness: float = 1.0
	if source_hp_ratio < 0.7: weakness = 0.85
	if source_hp_ratio < 0.5: weakness = 0.65
	if source_hp_ratio < 0.3: weakness = 0.45
	if source_hp_ratio < 0.1: weakness = 0.25

	return int(dealt * weakness)


func _try_apply_player_debuff(skill_id: StringName) -> void:
	## 玩家技能附加状态效果（中毒/虚弱/爆发）
	match String(skill_id):
		# ── 虚弱类 ──
		"gufeng_fuhu":
			if randf() < 0.25:
				_enemy_weak_turns = max(_enemy_weak_turns, 2)
				_log("  [color=#cc8844]敌人虚弱！攻防降低，持续 2 回合。[/color]")
		"gufeng_liedi":
			if randf() < 0.50:
				_enemy_weak_turns = max(_enemy_weak_turns, 2)
				_log("  [color=#cc8844]裂地震伤！敌人虚弱，攻防降低 2 回合。[/color]")
		"huashan_poyun":
			if randf() < 0.30:
				_enemy_weak_turns = max(_enemy_weak_turns, 2)
				_log("  [color=#cc8844]破云穿空！敌人虚弱，攻防降低 2 回合。[/color]")

		# ── 中毒类 ──
		"lingyue_hanshuang_zhen":
			if randf() < 0.30:
				_enemy_poison_turns = max(_enemy_poison_turns, 3)
				_log("  [color=#72d2a6]寒霜淬毒！敌人中毒，持续 3 回合。[/color]")
		"lingyue_hanshuang_wan_zhen":
			_enemy_poison_turns = max(_enemy_poison_turns, 3)
			_enemy_weak_turns = max(_enemy_weak_turns, 2)
			_log("  [color=#72d2a6]万针淬毒！敌人中毒 3 回合 + 虚弱 2 回合。[/color]")

		# ── 装备触发中毒 ──
		"apply_poison_from_gear":
			if randf() < 0.15:
				_enemy_poison_turns = max(_enemy_poison_turns, 3)
				_log("  [color=#72d2a6]淬毒！敌人中毒，持续 3 回合。[/color]")
		"apply_weak_from_gear":
			if randf() < 0.25:
				_enemy_weak_turns = max(_enemy_weak_turns, 2)
				_log("  [color=#cc8844]重击震伤！敌人虚弱，持续 2 回合。[/color]")

		_:
			pass

	# 重置互补临时状态
	_complement_poison_boost = false


func _on_status_cured(cure_type: StringName) -> void:
	## 战斗中使用了状态解除物品
	match String(cure_type):
		"poison":
			_player_poison_turns = 0
			_log("[color=#aaffaa]中毒已解除！[/color]")
		"weak":
			_player_weak_turns = 0
			_log("[color=#aaffaa]虚弱已解除！[/color]")
		"all":
			_player_poison_turns = 0
			_player_weak_turns = 0
			_log("[color=#aaffaa]所有负面状态已清除！[/color]")
	_refresh_hud()


func _apply_player_buff(skill: Skill) -> void:
	## 执行 BUFF 型技能：施加爆发或防御姿态
	var sid := String(skill.skill_id)
	match sid:
		"defend":
			_player_defending = true
			_log("→ 你摆出防御姿态，本回合受到伤害减半")
			return
		"huashan_zixia_shengong", "huashan_zixia_ninggang", "lingyue_tayue_lingbo":
			_player_burst_turns = max(_player_burst_turns, 3)
			_log("→ 你施展 [b]%s[/b]！暴击率 +50%%，持续 3 回合。[color=#ffb14a][爆发][/color]" % skill.display_name)
		"gufeng_jingang_buhuai", "wudang_xuanwu_ge":
			_player_weak_turns = 0
			_player_defending = true
			_log("→ 你施展 [b]%s[/b]！虚弱清除 + 本回合防御。[color=#88aaff][守御][/color]" % skill.display_name)
		"mingwu_mingwu_bu":
			_player_burst_turns = max(_player_burst_turns, 1)
			_log("→ 你施展 [b]%s[/b]！本回合暴击率 +50%%。[color=#ffb14a][爆发][/color]" % skill.display_name)
		"mingwu_saofeng", "mingwu_wuyin_sanshi":
			_player_burst_turns = max(_player_burst_turns, 1)
			_log("→ 你施展 [b]%s[/b]！暴击率 +50%%，持续 1 回合。[color=#ffb14a][爆发][/color]" % skill.display_name)
		_:
			_log("→ 你施展 [b]%s[/b]" % skill.display_name)


func _refresh_skill_button() -> void:
	## 更新技能按钮显示当前可切换的技能
	if _player_skills.size() > 1:
		var sk: Skill = _player_skills[_current_skill_index]
		btn_skill.text = "%s (-%d MP)" % [sk.display_name, sk.mp_cost]
	else:
		btn_skill.text = "(无可用技能)"


func _roll_damage(base_attack: int) -> int:
	## 80% - 120% 浮动（保留兼容旧代码）
	return int(base_attack * randf_range(0.8, 1.2))


func _is_chapter_boss(enemy_id: StringName) -> bool:
	return String(enemy_id).begins_with("boss_")


func _log(line: String) -> void:
	battle_log.append_text(line + "\n")
