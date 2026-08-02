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
## Never use dialogue portraits on the battle field. This is a full-body combat
## stance while the dedicated idle set is being expanded.
const PLAYER_BATTLE_ACTOR_PATH := "res://art/characters/battle_lengguyun_ready_v2.png"
const FALLBACK_ENEMY_BATTLE_ACTOR_PATH := "res://art/characters/battle_thug_lone_v2.png"
const BATTLE_ARENA_PATHS := {
	&"bamboo_platforms": "res://art/backgrounds/bg_battle_bamboo_day_v1.png",
	&"river_skirmish": "res://art/backgrounds/bg_battle_river_valley_v2.png",
	&"courtyard_wedge": "res://art/backgrounds/bg_battle_mountain_gate_v2.png",
}
const LEGACY_BATTLE_ACTOR_SCALE := 0.48
const PLAYER_ATTACK_FRAME_PATHS := [
	"res://art/sprites/battle/lengguyun_sword_attack_v3_f01.png",
	"res://art/sprites/battle/lengguyun_sword_attack_v3_f02.png",
	"res://art/sprites/battle/lengguyun_sword_attack_v3_f03.png",
]
const PLAYER_HIT_FRAME_PATHS := [
	"res://art/sprites/battle/lengguyun_hurt_v3_full.png",
]
const PLAYER_DEFEAT_FRAME_PATHS := [
	"res://art/sprites/battle/lengguyun_defeat_v3_full.png",
]
const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const INVENTORY_PANEL_SCENE := preload("res://scenes/ui/inventory_panel.tscn")
const BATTLE_HUD_ATLAS_PATH := "res://art/ui/frame/ui_cold_wuxia_battle_hud_v1.png"
const BATTLE_COMMAND_NORMAL_PATH := "res://art/ui/battle/formal/battle_button_normal_v2.png"
const BATTLE_COMMAND_HOVER_PATH := "res://art/ui/battle/formal/battle_button_hover_v2.png"
const BATTLE_COMMAND_PRESSED_PATH := "res://art/ui/battle/formal/battle_button_pressed_v2.png"
const BATTLE_LOG_PANEL_PATH := "res://art/ui/battle/formal/battle_log_panel_v2.png"
const ATTR_ICON_ATLAS_PATH := "res://art/ui/icon/ui_cold_wuxia_attribute_icons_v1.png"
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
@onready var battle_vfx_layer: BattleVfxPlayer = %BattleVfxLayer
@onready var log_panel: PanelContainer = $LogPanel
@onready var player_portrait: TextureRect = %PlayerPortrait
@onready var enemy_portrait: TextureRect = %EnemyPortrait
@onready var player_actor: BattleActor = $PlayerActor
@onready var enemy_actor: BattleActor = $EnemyActor
@onready var formation_view: BattleFormationView = $FormationView
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
@onready var btn_equip: Button = %BtnEquip
@onready var btn_defend: Button = %BtnDefend
@onready var btn_flee: Button = %BtnFlee
@onready var btn_item: Button = %BtnItem
var _item_popup: PopupMenu = null
var _skill_popup: PopupPanel = null
var _skill_list: VBoxContainer = null
var _equip_popup: PopupMenu = null
var _battle_inventory_panel: Control = null
var _player_action_points: int = 1
var _guard_grants_extra_action: bool = false

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
var _player_stun_turns: int = 0
var _player_freeze_turns: int = 0
var _enemy_poison_turns: int = 0
var _enemy_weak_turns: int = 0
var _enemy_stun_turns: int = 0
var _enemy_freeze_turns: int = 0
var _player_burst_turns: int = 0  ## 爆发：暴击率+50%
var _enemy_burst_turns: int = 0

# 互补系统临时状态
var _complement_poison_boost: bool = false  ## 凌月互补：本轮中毒伤害+50%
var _complement_reflect_active: bool = false  ## 武当互补：受击时反射 15%

# 动态技能列表
var _player_skills: Array[Skill] = []
var _current_skill_index: int = 1
var _action_icon_atlas: Texture2D = null

# Team battle runtime. The legacy 1v1 path below remains unchanged.
var _team_mode: bool = false
var _team_allies: Array[BattleCombatant] = []
var _team_enemies: Array[BattleCombatant] = []
var _team_turn_queue: Array[BattleCombatant] = []
var _team_active_unit: BattleCombatant = null
var _team_pending_skill_index: int = -1
var _team_player_party_payload: Array[Dictionary] = []


func _ready() -> void:
	_player = GameState.player
	if AudioManager != null:
		AudioManager.play_bgm(AudioManager.DEFAULT_BATTLE_BGM)

	var payload := SceneRouter.get_battle_payload()
	var enemy_id: String = String(payload.get("enemy_id", "thug_lone"))
	_enemy_def = _load_enemy(enemy_id)
	_enemy = _enemy_def.to_runtime_stats()
	_apply_battle_arena(payload)
	formation_view.actor_created.connect(_on_team_actor_created)
	_setup_team_formation(payload)

	# 动态加载玩家所有技能
	for sid in _player.skills:
		var sk := _load_skill(sid)
		if sk != null:
			_player_skills.append(sk)

	_bind_portraits()
	if _team_mode:
		# Portrait binding is still needed for legacy 1v1, but it must not
		# re-enable the old full-screen actor art in a formation battle.
		player_portrait.visible = false
		enemy_portrait.visible = false
		player_actor.visible = false
		enemy_actor.visible = false
	_build_formal_battle_layout()
	_apply_visual_style()
	_apply_hud_art_overlays()
	_apply_action_button_icons()
	_refresh_hud()
	_refresh_skill_button()

	btn_attack.pressed.connect(func(): _player_action_skill_use(0))
	btn_skill.pressed.connect(_show_skill_popup)
	btn_equip.pressed.connect(_open_battle_inventory)
	btn_defend.pressed.connect(func(): _player_action_defend())
	btn_flee.pressed.connect(func(): _player_action_flee())
	btn_item.pressed.connect(_open_battle_inventory)
	for action_button in [btn_attack, btn_skill, btn_equip, btn_defend, btn_flee, btn_item]:
		action_button.pressed.connect(func(): AudioManager.play_ui_confirm())
	_create_item_popup()
	_create_skill_popup()
	_create_equip_popup()
	btn_skill.text = "\u62db\u5f0f"
	btn_equip.text = "\u80cc\u5305"
	btn_item.text = "\u80cc\u5305"
	btn_equip.visible = false

	EventBus.battle_started.emit(StringName(enemy_id))
	EventBus.status_cured.connect(_on_status_cured)
	player_actor.sound_requested.connect(_on_actor_sound_requested.bind(false))
	enemy_actor.sound_requested.connect(_on_actor_sound_requested.bind(true))
	formation_view.target_selected.connect(_on_team_target_selected)

	_log("[b]遭遇战开始[/b]  ——  %s vs %s" % [_player.display_name, _enemy.display_name])
	_log("（提示：已装备 %d 件，攻 +%d 防 +%d）" % [
		Inventory.equipped.size(),
		Inventory.get_atk_bonus(),
		Inventory.get_def_bonus(),
	])
	if _team_mode:
		await formation_view.play_team_enter()
	else:
		await player_actor.play_enter(true)
		await enemy_actor.play_enter(false)
	await get_tree().create_timer(0.5).timeout
	_begin_round()


func _apply_battle_arena(payload: Dictionary) -> void:
	var arena_id := StringName(payload.get("battle_arena", &"bamboo_platforms"))
	if not BATTLE_ARENA_PATHS.has(arena_id):
		arena_id = &"bamboo_platforms"
	var path: String = BATTLE_ARENA_PATHS[arena_id]
	var arena_texture := load(path) as Texture2D
	if arena_texture != null:
		battle_background.texture = arena_texture
	formation_view.set_formation_profile(arena_id)


func _setup_team_formation(payload: Dictionary) -> void:
	if formation_view == null:
		return
	var raw_ids: Variant = payload.get("enemy_ids", [])
	var enemy_ids: Array[StringName] = []
	if raw_ids is Array:
		for raw_id in raw_ids:
			enemy_ids.append(StringName(raw_id))
	if enemy_ids.is_empty():
		formation_view.visible = false
		return
	_team_mode = true
	_team_player_party_payload = _build_player_party_payload(payload)
	var enemy_scale: float = 0.30 if enemy_ids.size() > 1 else 0.42

	# Build a presentation entry for every member; runtime target resolution uses
	# the independent BattleCombatant instances created below.
	var enemy_entries: Array[Dictionary] = []
	for index in range(enemy_ids.size()):
		var id := enemy_ids[index]
		var unit_key := StringName("%s_%d" % [String(id), index + 1])
		var def := _load_enemy(String(id))
		var texture: Texture2D = null
		if ResourceLoader.exists(def.battle_actor_path):
			texture = load(def.battle_actor_path) as Texture2D
		enemy_entries.append({
			"unit_id": unit_key,
			"display_name": def.display_name,
			"texture": texture,
			"scale": enemy_scale,
			"hp": def.max_hp,
			"max_hp": def.max_hp,
			"attack_frames": _load_enemy_attack_frames(def),
			"hit_frames": _load_texture_frames(def.hit_frame_paths),
			"defeat_frames": _load_texture_frames(def.defeat_frame_paths),
		})
	var ally_entries: Array[Dictionary] = []
	var ally_scale: float = 0.30 if _team_player_party_payload.size() > 1 else 0.42
	for party_entry in _team_player_party_payload:
		var player_texture: Texture2D = null
		var actor_path := str(party_entry.get("actor_path", PLAYER_BATTLE_ACTOR_PATH))
		if ResourceLoader.exists(actor_path):
			player_texture = load(actor_path) as Texture2D
		party_entry["texture"] = player_texture
		if actor_path == PLAYER_BATTLE_ACTOR_PATH:
			party_entry["attack_frames"] = _load_player_attack_frames()
			party_entry["hit_frames"] = _load_player_hit_frames()
			party_entry["defeat_frames"] = _load_player_defeat_frames()
		else:
			party_entry["attack_frames"] = _load_texture_frames(PackedStringArray(party_entry.get("attack_frame_paths", [])))
			party_entry["hit_frames"] = _load_texture_frames(PackedStringArray(party_entry.get("hit_frame_paths", [])))
			party_entry["defeat_frames"] = _load_texture_frames(PackedStringArray(party_entry.get("defeat_frame_paths", [])))
		party_entry["scale"] = ally_scale
		ally_entries.append(party_entry)
	formation_view.build_formations(
		ally_entries,
		enemy_entries,
	)
	formation_view.visible = true
	enemy_hud.visible = false
	player_hud.visible = false
	player_actor.visible = false
	enemy_actor.visible = false
	player_portrait.visible = false
	enemy_portrait.visible = false
	# The large legacy combat log conceals the lower formation platforms.
	# Multi-unit battles communicate turns through status labels and the turn cue.
	log_panel.visible = false
	if _team_player_party_payload.size() > 1:
		_setup_team_runtime(enemy_ids, _team_player_party_payload)


func _build_player_party_payload(payload: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = [{
		"unit_id": &"player",
		"display_name": _player.display_name,
		"actor_path": PLAYER_BATTLE_ACTOR_PATH,
		"scale": 0.42,
		"hp": _player.hp,
		"max_hp": _player.max_hp,
		"mp": _player.mp,
		"max_mp": _player.max_mp,
		"attack": _player.attack,
		"defense": _player.defense,
		"speed": _player.speed,
	}]
	var raw_party: Variant = payload.get("player_party", [])
	if raw_party is Array:
		for raw_entry in raw_party:
			if raw_entry is Dictionary:
				result.append(raw_entry.duplicate(true))
	return result


func _setup_team_runtime(enemy_ids: Array[StringName], party_entries: Array[Dictionary]) -> void:
	_team_allies.clear()
	_team_enemies.clear()
	for entry in party_entries:
		var ally := BattleCombatant.new()
		var unit_id: StringName = StringName(entry.get("unit_id", "ally"))
		var stats: CharacterStats = _build_party_stats(entry, unit_id == &"player")
		ally.configure_from_stats(unit_id, BattleCombatant.Team.ALLY, stats)
		ally.battle_actor_path = str(entry.get("actor_path", PLAYER_BATTLE_ACTOR_PATH))
		ally.actor_scale = float(entry.get("scale", 0.42))
		_team_allies.append(ally)
	for index in range(enemy_ids.size()):
		var unit_id := enemy_ids[index]
		var def := _load_enemy(String(unit_id))
		var enemy_unit := BattleCombatant.new()
		var unit_key := StringName("%s_%d" % [String(unit_id), index + 1])
		enemy_unit.configure_from_stats(unit_key, BattleCombatant.Team.ENEMY, def.to_runtime_stats())
		enemy_unit.definition_id = unit_id
		enemy_unit.battle_actor_path = def.battle_actor_path
		enemy_unit.actor_scale = 0.42
		enemy_unit.audio_cues = {
		&"ready": def.ready_sfx_path,
		&"attack": def.attack_sfx_path,
		&"hit": def.hit_sfx_path,
		&"defeat": def.defeat_sfx_path,
		}
		_team_enemies.append(enemy_unit)
	_sync_team_health()


func _build_party_stats(entry: Dictionary, is_main_player: bool) -> CharacterStats:
	if is_main_player:
		return _player
	var stats := CharacterStats.new()
	stats.character_id = str(entry.get("unit_id", "ally"))
	stats.display_name = str(entry.get("display_name", "同伴"))
	stats.portrait_path = str(entry.get("portrait_path", ""))
	stats.max_hp = int(entry.get("max_hp", 120))
	stats.hp = int(entry.get("hp", stats.max_hp))
	stats.max_mp = int(entry.get("max_mp", 30))
	stats.mp = int(entry.get("mp", stats.max_mp))
	stats.attack = int(entry.get("attack", 16))
	stats.defense = int(entry.get("defense", 8))
	stats.speed = int(entry.get("speed", 10))
	stats.skills = _player.skills.duplicate()
	return stats


func _on_team_actor_created(actor: BattleActor, enemy_side: bool) -> void:
	actor.sound_requested.connect(_on_team_actor_sound_requested.bind(enemy_side))


func _on_team_actor_sound_requested(cue: StringName, enemy_side: bool) -> void:
	if not _team_mode:
		return
	var unit: BattleCombatant = _team_find_unit_for_actor_side(cue, enemy_side)
	# Action sounds are data-driven. Empty paths are valid until the audio pass.
	if unit != null:
		var path: String = unit.get_audio_path(cue)
		if path.is_empty():
			path = _default_sfx_for_cue(cue)
		EventBus.sfx_requested.emit(path, 0.0)


func _team_find_unit_for_actor_side(_cue: StringName, enemy_side: bool) -> BattleCombatant:
	# The actor signal currently carries only its side; the side's active unit is
	# the only unit allowed to animate during a turn.
	if _team_active_unit != null and ((_team_active_unit.team == BattleCombatant.Team.ENEMY) == enemy_side):
		return _team_active_unit
	return null


func _on_actor_sound_requested(cue: StringName, enemy_side: bool) -> void:
	var path := ""
	if enemy_side:
		path = _enemy_def.attack_sfx_path if cue == &"attack" else _enemy_def.hit_sfx_path
	if path.is_empty():
		path = _default_sfx_for_cue(cue)
	EventBus.sfx_requested.emit(path, 0.0)


func _default_sfx_for_cue(cue: StringName) -> String:
	match cue:
		&"attack": return AudioManager.DEFAULT_ATTACK_SFX
		&"skill": return AudioManager.DEFAULT_SKILL_SFX
		&"hit": return AudioManager.DEFAULT_HIT_SFX
		&"defend": return AudioManager.DEFAULT_DEFEND_SFX
		&"victory": return AudioManager.DEFAULT_VICTORY_SFX
		&"defeat": return AudioManager.DEFAULT_DEFEAT_SFX
		&"ready": return ""
		_: return ""


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


func _play_skill_sfx(path: String) -> void:
	EventBus.sfx_requested.emit(path if not path.is_empty() else AudioManager.DEFAULT_SKILL_SFX, 0.0)


# --- UI ---

func _bind_portraits() -> void:
	if ResourceLoader.exists(_player.portrait_path):
		player_portrait.texture = load(_player.portrait_path)
	if ResourceLoader.exists(_enemy.portrait_path):
		enemy_portrait.texture = load(_enemy.portrait_path)
	enemy_portrait.flip_h = true
	player_portrait.visible = false
	enemy_portrait.visible = false
	var player_actor_texture: Texture2D = null
	if ResourceLoader.exists(PLAYER_BATTLE_ACTOR_PATH):
		player_actor_texture = load(PLAYER_BATTLE_ACTOR_PATH) as Texture2D
	var enemy_actor_texture: Texture2D = null
	if ResourceLoader.exists(_enemy_def.battle_actor_path):
		enemy_actor_texture = load(_enemy_def.battle_actor_path) as Texture2D
	elif ResourceLoader.exists(FALLBACK_ENEMY_BATTLE_ACTOR_PATH):
		enemy_actor_texture = load(FALLBACK_ENEMY_BATTLE_ACTOR_PATH) as Texture2D
	player_actor.configure(
		player_actor_texture,
		true,
		_load_player_attack_frames(),
		_load_player_hit_frames(),
		_load_player_defeat_frames()
	)
	enemy_actor.configure(
		enemy_actor_texture,
		_enemy_def.battle_actor_flip_h,
		_load_enemy_attack_frames(_enemy_def),
		_load_texture_frames(_enemy_def.hit_frame_paths),
		_load_texture_frames(_enemy_def.defeat_frame_paths)
	)
	player_actor.scale = Vector2.ONE * LEGACY_BATTLE_ACTOR_SCALE
	enemy_actor.scale = Vector2.ONE * LEGACY_BATTLE_ACTOR_SCALE * maxf(0.5, _enemy_def.battle_actor_scale)
	player_name.text = _player.display_name
	enemy_name.text = _enemy.display_name


func _load_player_attack_frames() -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	for path in PLAYER_ATTACK_FRAME_PATHS:
		if ResourceLoader.exists(path):
			var texture := load(path) as Texture2D
			if texture != null:
				frames.append(texture)
	return frames


func _load_enemy_attack_frames(def: EnemyDef) -> Array[Texture2D]:
	if def == null:
		return []
	return _load_texture_frames(def.attack_frame_paths)


func _action_frames_for(animation_id: StringName, fallback: Array[Texture2D], player_style: bool = true) -> Array[Texture2D]:
	if not player_style:
		return fallback
	var paths := PackedStringArray()
	match animation_id:
		&"sword_arc", &"linxi_sword_one":
			paths = PackedStringArray(PLAYER_ATTACK_FRAME_PATHS)
		&"heavy_cleave":
			paths = PackedStringArray(PLAYER_ATTACK_FRAME_PATHS)
		&"crimson_palm":
			paths = PackedStringArray(["res://art/sprites/battle/lengguyun_palm_strike_f01.png", "res://art/sprites/battle/lengguyun_palm_strike_f02.png", "res://art/sprites/battle/lengguyun_palm_strike_f03.png"])
		&"staff_sweep":
			paths = PackedStringArray(["res://art/sprites/battle/lengguyun_staff_sweep_f01.png", "res://art/sprites/battle/lengguyun_staff_sweep_f02.png", "res://art/sprites/battle/lengguyun_staff_sweep_f03.png"])
	if paths.is_empty():
		return fallback
	var loaded := _load_texture_frames(paths)
	return fallback if loaded.is_empty() else loaded


func _load_player_hit_frames() -> Array[Texture2D]:
	return _load_texture_frames(PackedStringArray(PLAYER_HIT_FRAME_PATHS))


func _load_player_defeat_frames() -> Array[Texture2D]:
	return _load_texture_frames(PackedStringArray(PLAYER_DEFEAT_FRAME_PATHS))


func _load_texture_frames(paths: PackedStringArray) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	for path in paths:
		if ResourceLoader.exists(path):
			var texture := load(path) as Texture2D
			if texture != null:
				frames.append(texture)
	return frames


func _build_formal_battle_layout() -> void:
	# Keep the legacy 1v1 presentation aligned with the team formation contract:
	# compact full-body units, allies lower-left, enemies upper-right.
	player_actor.offset_left = 70
	player_actor.offset_top = 430
	player_actor.offset_right = 530
	player_actor.offset_bottom = 990
	enemy_actor.offset_left = -570
	enemy_actor.offset_top = 130
	enemy_actor.offset_right = -110
	enemy_actor.offset_bottom = 690
	player_hud.offset_left = 48
	player_hud.offset_top = -178
	player_hud.offset_right = 530
	player_hud.offset_bottom = -38
	enemy_hud.offset_left = -530
	enemy_hud.offset_top = 34
	enemy_hud.offset_right = -48
	enemy_hud.offset_bottom = 158
	# The turn feed is supporting information, not a modal. Keep it clear of the
	# lower-left party formation and let the arena remain readable.
	log_panel.offset_left = 180
	log_panel.offset_top = 175
	log_panel.offset_right = 600
	log_panel.offset_bottom = 460
	action_panel.offset_left = -310
	action_panel.offset_top = -420
	action_panel.offset_right = -48
	action_panel.offset_bottom = -44

	if _turn_label == null:
		_turn_label = Label.new()
		_turn_label.name = "TurnLabel"
		_turn_label.layout_mode = 1
		_turn_label.anchor_left = 1.0
		_turn_label.anchor_right = 1.0
		_turn_label.offset_left = 180
		_turn_label.offset_top = 112
		_turn_label.offset_right = 600
		_turn_label.offset_bottom = 192
		_turn_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
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
	# Battle art is authored with its own daylight and contrast. UI panels carry
	# their own readability treatment, so the arena should remain un-tinted.
	battle_background.modulate = Color.WHITE
	dim_layer.color = Color(0.005, 0.010, 0.016, 0.06)
	log_panel.self_modulate = Color(1.0, 1.0, 1.0, 0.90)
	var log_frame := _generated_texture_style(BATTLE_LOG_PANEL_PATH, 76.0, 76.0, 34.0, 34.0)
	if log_frame != null:
		log_panel.add_theme_stylebox_override("panel", log_frame)
	else:
		log_panel.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.025, 0.045, 0.060, 0.72), Color(0.34, 0.66, 0.68, 0.86), 7, 1))
	UI_THEME.style_rich_text(battle_log, 15)
	UI_THEME.style_label(player_name, 28, UI_THEME.GOLD_LIGHT)
	UI_THEME.style_label(enemy_name, 28, Color(0.95, 0.62, 0.68, 1.0))
	UI_THEME.style_label(player_hp_label, 16, UI_THEME.TEXT, false)
	UI_THEME.style_label(enemy_hp_label, 16, UI_THEME.TEXT, false)
	if _player_mp_label != null:
		UI_THEME.style_label(_player_mp_label, 15, Color(0.76, 0.90, 1.0, 1.0), false)
	if _turn_label != null:
		UI_THEME.style_label(_turn_label, 18, UI_THEME.GOLD_LIGHT)
	if _command_title != null:
		UI_THEME.style_label(_command_title, 24, UI_THEME.GOLD_LIGHT)
	if _player_status_label != null:
		UI_THEME.style_label(_player_status_label, 15, UI_THEME.JADE, false)
	if _enemy_status_label != null:
		UI_THEME.style_label(_enemy_status_label, 15, Color(0.95, 0.62, 0.68, 1.0), false)
	UI_THEME.style_progress(player_hp_bar, Color(0.58, 0.14, 0.20, 1.0))
	UI_THEME.style_progress(enemy_hp_bar, Color(0.58, 0.14, 0.20, 1.0))
	UI_THEME.style_progress(player_mp_bar, Color(0.28, 0.62, 0.78, 1.0))
	for b in [btn_attack, btn_skill, btn_equip, btn_defend, btn_flee, btn_item]:
		UI_THEME.style_button(b, 19, UI_THEME.BLUE_STEEL)
		_apply_generated_command_style(b)
	btn_attack.text = "普通攻击"
	btn_defend.text = "防御架势"
	btn_flee.text = "撤离"
	action_panel.add_theme_constant_override("separation", 14)


func _refresh_hud() -> void:
	player_actor.set_health(_player.hp, _player.max_hp, _player.is_dead())
	enemy_actor.set_health(_enemy.hp, _enemy.max_hp, _enemy.is_dead())
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
	btn_skill.disabled = not _has_available_active_skill()


func _apply_hud_art_overlays() -> void:
	if not ResourceLoader.exists(BATTLE_HUD_ATLAS_PATH):
		return
	var atlas := load(BATTLE_HUD_ATLAS_PATH) as Texture2D
	if atlas == null:
		return
	_attach_hud_overlay("EnemyHudFrame", atlas, BATTLE_FRAME_REGIONS["enemy"], enemy_hud, Vector2(26, 20), Color(1, 1, 1, 0.90))
	_attach_hud_overlay("PlayerHudFrame", atlas, BATTLE_FRAME_REGIONS["player"], player_hud, Vector2(26, 22), Color(1, 1, 1, 0.90))


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


func _generated_texture_style(path: String, left: float, right: float, top: float, bottom: float) -> StyleBox:
	if not ResourceLoader.exists(path):
		return null
	var texture := load(path) as Texture2D
	if texture == null:
		return null
	var style: StyleBoxTexture = StyleBoxTexture.new() as StyleBoxTexture
	style.texture = texture
	style.texture_margin_left = left
	style.texture_margin_right = right
	style.texture_margin_top = top
	style.texture_margin_bottom = bottom
	style.content_margin_left = left * 0.5
	style.content_margin_right = right * 0.5
	style.content_margin_top = top * 0.42
	style.content_margin_bottom = bottom * 0.42
	return style


func _apply_generated_command_style(button: Button) -> void:
	if button == null:
		return
	var normal := _generated_texture_style(BATTLE_COMMAND_NORMAL_PATH, 64.0, 64.0, 30.0, 30.0)
	var hover := _generated_texture_style(BATTLE_COMMAND_HOVER_PATH, 64.0, 64.0, 30.0, 30.0)
	var pressed := _generated_texture_style(BATTLE_COMMAND_PRESSED_PATH, 64.0, 64.0, 30.0, 30.0)
	if normal == null or hover == null or pressed == null:
		return
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)


func _apply_button_icon(btn: Button, icon_key: String, accent: Color) -> void:
	if btn == null:
		return
	UI_THEME.style_button(btn, 22, accent)
	_apply_generated_command_style(btn)
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

func _begin_team_round() -> void:
	_team_turn_queue.clear()
	for unit in _team_allies + _team_enemies:
		if unit.alive and unit.stats != null and not unit.stats.is_dead():
			_team_turn_queue.append(unit)
	_team_turn_queue.sort_custom(_sort_team_units)
	_team_take_next_turn()


func _team_take_next_turn() -> void:
	if _team_all_dead(_team_enemies) or _team_enemies.is_empty():
		_team_finish(true)
		return
	if _team_all_dead(_team_allies):
		_team_finish(false)
		return
	if _team_turn_queue.is_empty():
		_begin_team_round()
		return
	_team_active_unit = _team_turn_queue.pop_front()
	if _team_active_unit == null or not _team_active_unit.alive:
		_team_take_next_turn()
		return
	formation_view.set_active_unit(_team_active_unit.unit_id)
	if await _team_apply_turn_start_status(_team_active_unit):
		await _team_after_action()
		return
	if _team_active_unit.team == BattleCombatant.Team.ALLY:
		_team_active_unit.action_points = 2 if _team_active_unit.guard_grants_extra_action else 1
		_team_active_unit.guard_grants_extra_action = false
		_state = State.PLAYER_TURN
		_turn_label.text = "我方回合 · %s\n选择招式、道具或防御架势" % _team_active_unit.display_name
		action_panel.visible = true
		_update_action_point_label(_team_active_unit.action_points)
		_turn_label.text = "\u6211\u65b9\u56de\u5408 \u00b7 %s\n\u884c\u52a8\u673a\u4f1a %d / %d\n\u9009\u62e9\u62db\u5f0f\u3001\u80cc\u5305\u6216\u9632\u5fa1" % [
			_team_active_unit.display_name,
			_team_active_unit.action_points,
			2 if _team_active_unit.action_points > 1 else 1,
		]
		_set_buttons_enabled(true)
		_log("\n[color=#c8a04a]—— %s 行动 ——[/color]" % _team_active_unit.display_name)
	else:
		_state = State.ENEMY_TURN
		_do_team_enemy_turn()


func _team_player_action_skill_use(skill_idx: int, forced_target: StringName = &"") -> void:
	if _state != State.PLAYER_TURN or _team_active_unit == null:
		return
	if skill_idx < 0 or skill_idx >= _player_skills.size():
		return
	var skill: Skill = _player_skills[skill_idx]
	var active_stats := _team_active_unit.stats
	if active_stats == null or not _can_use_skill(skill, active_stats):
		return
	var living_targets := _team_living_enemies()
	if forced_target == &"" and skill.target != Skill.Target.ENEMY_ALL and living_targets.size() > 1:
		_team_pending_skill_index = skill_idx
		_set_buttons_enabled(false)
		action_panel.visible = false
		var target_ids: Array[StringName] = []
		for target in living_targets:
			target_ids.append(target.unit_id)
		formation_view.show_target_selection(target_ids)
		_log("请选择目标：%s" % skill.display_name)
		return
	formation_view.clear_target_selection()
	_set_buttons_enabled(false)
	_state = State.EXECUTE
	active_stats.mp = max(0, active_stats.mp - skill.mp_cost)
	var targets: Array[BattleCombatant] = []
	if forced_target != &"":
		var selected := _team_find_enemy(forced_target)
		if selected != null:
			targets.append(selected)
	elif skill.target != Skill.Target.ENEMY_ALL and not living_targets.is_empty():
		targets.append(living_targets[0])
	else:
		targets.append_array(living_targets)
	if skill.kind == Skill.Kind.BUFF:
		var active_actor := _team_actor(_team_active_unit.unit_id)
		if active_actor != null:
			await active_actor.play_cast()
		_play_skill_sfx(skill.cast_sfx_path)
		await _team_finish_player_action()
		return
	for target in targets:
		var target_actor := _team_actor(target.unit_id)
		var active_actor := _team_actor(_team_active_unit.unit_id)
		if active_actor == null or target_actor == null:
			continue
		var is_protagonist: bool = _team_active_unit.unit_id == &"player"
		active_actor.set_action_frames(_action_frames_for(skill.animation_id, active_actor.default_attack_frames, is_protagonist))
		await active_actor.play_attack_approach(target_actor, skill.skill_id != &"basic_attack")
		if skill.skill_id != &"basic_attack":
			_play_skill_sfx(skill.cast_sfx_path)
		await battle_vfx_layer.play_for_skill(skill.animation_id, target_actor, active_actor)
		if skill.skill_id != &"basic_attack":
			_play_skill_sfx(skill.impact_sfx_path)
		var damage := _calc_damage_ext(_team_attack_value(_team_active_unit), float(skill.power) / 100.0, target.stats.defense, true, 0.0)
		var dealt := target.stats.take_damage(damage)
		await target_actor.play_hit(dealt)
		await active_actor.play_attack_recover()
		_log("→ %s 对 %s 造成 [color=#ffb14a]%d[/color] 伤害" % [skill.display_name, target.display_name, dealt])
		if target.stats.is_dead():
			target.alive = false
			await target_actor.play_defeat()
	_refresh_hud()
	_sync_team_health()
	await _team_finish_player_action()


func _on_team_target_selected(unit_id: StringName) -> void:
	if _team_pending_skill_index < 0:
		return
	var skill_index := _team_pending_skill_index
	_team_pending_skill_index = -1
	_team_player_action_skill_use(skill_index, unit_id)


func _do_team_enemy_turn() -> void:
	var targets := _team_living_allies()
	if targets.is_empty():
		_team_finish(false)
		return
	var enemy := _team_active_unit
	var def := _load_enemy(String(enemy.definition_id))
	var skill_id := _enemy_choose_skill_for(def, enemy.stats)
	var skill := _load_skill(skill_id)
	var target := targets[0]
	var attacker := _team_actor(enemy.unit_id)
	var defender := _team_actor(target.unit_id)
	if attacker == null or defender == null:
		_team_after_action()
		return
	attacker.set_action_frames(_action_frames_for(skill.animation_id if skill != null else &"sword_arc", attacker.default_attack_frames, false))
	await attacker.play_attack_approach(defender, skill != null and skill.skill_id != &"basic_attack")
	if skill != null:
		if skill.skill_id != &"basic_attack":
			_play_skill_sfx(skill.cast_sfx_path)
		await battle_vfx_layer.play_for_skill(skill.animation_id, defender, attacker)
		if skill.skill_id != &"basic_attack":
			_play_skill_sfx(skill.impact_sfx_path)
	var power := float(skill.power if skill != null else 100) / 100.0
	var damage := _calc_damage(_team_attack_value(enemy), power, target.stats.defense, false)
	if int(target.status_effects.get("guard", 0)) > 0:
		damage = maxi(1, int(round(float(damage) * 0.5)))
		target.status_effects.erase("guard")
	var dealt := target.stats.take_damage(damage)
	await defender.play_hit(dealt)
	await attacker.play_attack_recover()
	_log("← %s 对 %s 造成 [color=#ff6e6e]%d[/color] 伤害" % [enemy.display_name, target.display_name, dealt])
	_team_apply_status(target, skill_id)
	if target.stats.is_dead():
		target.alive = false
		await defender.play_defeat()
	_refresh_hud()
	_sync_team_health()
	await _team_after_action()


func _team_apply_status(target: BattleCombatant, skill_id: StringName) -> void:
	match String(skill_id):
		"toxic_needle":
			target.status_effects["poison"] = 3
			_log("[color=#72d2a6]%s 陷入中毒（3回合）[/color]" % target.display_name)
		"heavy_swing":
			target.status_effects["weaken"] = 2
			_log("[color=#cc8844]%s 陷入虚弱（2回合）[/color]" % target.display_name)
	_sync_team_health()


func _team_apply_turn_start_status(unit: BattleCombatant) -> bool:
	if unit == null or not unit.alive:
		return true
	if int(unit.status_effects.get("poison", 0)) > 0:
		var poison_damage: int = maxi(4, int(round(float(unit.stats.max_hp) * 0.05)))
		unit.stats.hp = max(0, unit.stats.hp - poison_damage)
		unit.status_effects["poison"] = int(unit.status_effects["poison"]) - 1
		_log("[color=#72d2a6]%s 中毒发作，受到%d点伤害[/color]" % [unit.display_name, poison_damage])
		var poison_actor := _team_actor(unit.unit_id)
		if poison_actor != null:
			await poison_actor.play_hit(poison_damage)
		if unit.stats.is_dead():
			unit.alive = false
			if poison_actor != null:
				await poison_actor.play_defeat()
			_sync_team_health()
			return true
	if int(unit.status_effects.get("weaken", 0)) > 0:
		unit.status_effects["weaken"] = int(unit.status_effects["weaken"]) - 1
	var skipped: bool = false
	if int(unit.status_effects.get("stun", 0)) > 0:
		unit.status_effects["stun"] = int(unit.status_effects["stun"]) - 1
		skipped = true
		_log("[color=#e0ca74]%s 眩晕，本回合无法行动[/color]" % unit.display_name)
	if int(unit.status_effects.get("freeze", 0)) > 0:
		unit.status_effects["freeze"] = int(unit.status_effects["freeze"]) - 1
		skipped = true
		_log("[color=#9edaff]%s 冰冻，本回合无法行动[/color]" % unit.display_name)
	_sync_team_health()
	return skipped


func _team_after_action() -> void:
	formation_view.clear_active_unit()
	action_panel.visible = false
	await get_tree().create_timer(0.35).timeout
	_team_take_next_turn()


func _team_finish_player_action() -> void:
	if _team_active_unit == null:
		return
	_team_active_unit.action_points = max(0, _team_active_unit.action_points - 1)
	if _team_active_unit.action_points > 0:
		_state = State.PLAYER_TURN
		action_panel.visible = true
		_update_action_point_label(_team_active_unit.action_points)
		_set_buttons_enabled(true)
		_log("  [color=#c8a04a]\u5269\u4f59\u884c\u52a8\u673a\u4f1a %d \u6b21[/color]" % _team_active_unit.action_points)
		return
	await _team_after_action()


func _team_living_enemies() -> Array[BattleCombatant]:
	return _team_enemies.filter(func(unit: BattleCombatant) -> bool: return unit.alive)


func _team_find_enemy(unit_id: StringName) -> BattleCombatant:
	for unit in _team_enemies:
		if unit.unit_id == unit_id and unit.alive:
			return unit
	return null


func _team_living_allies() -> Array[BattleCombatant]:
	return _team_allies.filter(func(unit: BattleCombatant) -> bool: return unit.alive)


func _sync_team_health() -> void:
	if formation_view == null:
		return
	for unit in _team_allies + _team_enemies:
		if unit.stats != null:
			formation_view.update_unit_health(unit.unit_id, unit.stats.hp, unit.stats.max_hp, not unit.alive)
			formation_view.update_unit_status(unit.unit_id, unit.status_summary())


func _team_actor(unit_id: StringName) -> BattleActor:
	return formation_view.get_actor(unit_id) if formation_view != null else null


func _team_speed(unit: BattleCombatant) -> int:
	return unit.stats.speed + Inventory.get_speed_bonus() if unit.team == BattleCombatant.Team.ALLY else unit.stats.speed


func _team_effective_attack(stats: CharacterStats) -> int:
	var legacy_atk: int = stats.attack + Inventory.get_atk_bonus()
	var core_atk: int = stats.strength * 2 + stats.inner_power
	return max(legacy_atk, core_atk)


func _team_attack_value(unit: BattleCombatant) -> int:
	if unit == null or unit.stats == null:
		return 0
	var value: int = _team_effective_attack(unit.stats)
	if int(unit.status_effects.get("weaken", 0)) > 0:
		value = maxi(1, int(round(float(value) * 0.75)))
	return value


func _sort_team_units(a: BattleCombatant, b: BattleCombatant) -> bool:
	return _team_speed(a) > _team_speed(b)


func _team_all_dead(units: Array[BattleCombatant]) -> bool:
	if units.is_empty():
		return true
	for unit in units:
		if unit.alive:
			return false
	return true


func _enemy_choose_skill_for(def: EnemyDef, stats: CharacterStats) -> StringName:
	var pool := stats.skills
	if pool.is_empty():
		return &"basic_attack"
	var ratio: float = float(stats.hp) / max(1, stats.max_hp)
	if pool.size() >= 2 and ratio > def.aggression and randf() < 0.55:
		return pool[1]
	return pool[0]


func _team_finish(victory: bool) -> void:
	_state = State.ENDED
	action_panel.visible = false
	if victory:
		for enemy in _team_enemies:
			if not enemy.alive:
				continue
			var actor := _team_actor(enemy.unit_id)
			if actor != null:
				await actor.play_defeat()
		EventBus.battle_ended.emit(true, false)
		SceneRouter.go_victory(0, _enemy_def.drop_exp)
	else:
		EventBus.battle_ended.emit(false, false)
		SceneRouter.go_defeat()

func _begin_round() -> void:
	if _team_mode:
		_begin_team_round()
		return
	if _player_effective_speed() >= _enemy.speed:
		_enter_player_turn()
	else:
		await _do_enemy_turn()
		if _state != State.ENDED:
			_enter_player_turn()


func _enter_player_turn() -> void:
	_state = State.PLAYER_TURN
	_player_action_points = 2 if _guard_grants_extra_action else 1
	_guard_grants_extra_action = false
	_player_defending = false
	_complement_reflect_active = false  # 重置上回合的互补状态
	if await _apply_player_status_at_turn_start():
		return
	action_panel.visible = true
	_log("\n[color=#c8a04a]——你的回合——[/color]")
	_update_action_point_label(_player_action_points)
	_set_buttons_enabled(true)


func _set_buttons_enabled(enabled: bool) -> void:
	for b in [btn_attack, btn_skill, btn_equip, btn_defend, btn_flee, btn_item]:
		b.disabled = not enabled
	if enabled:
		btn_skill.disabled = not _has_available_active_skill()
		btn_item.disabled = not _has_usable_battle_item()


func _update_action_point_label(action_points: int) -> void:
	if _command_title != null:
		_command_title.text = "\u884c\u52a8\u673a\u4f1a %d / %d" % [action_points, 2 if action_points > 1 else 1]


# --- 玩家动作 ---

func _player_action_skill_use(skill_idx: int) -> void:
	if _team_mode:
		_team_player_action_skill_use(skill_idx)
		return
	if _state != State.PLAYER_TURN: return
	if skill_idx < 0 or skill_idx >= _player_skills.size(): return
	var skill: Skill = _player_skills[skill_idx]
	if not _can_use_skill(skill): return

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

	var mastery_bonus := GameState.get_skill_mastery(skill.skill_id) * 2
	var power_mult: float = (skill.power + extra_power + mastery_bonus) / 100.0
	if mastery_bonus > 0:
		_log("  [color=#9fd3d0][熟练] %s 威力 +%d%%[/color]" % [skill.display_name, mastery_bonus])

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
		await player_actor.play_cast()
		_play_skill_sfx(skill.cast_sfx_path)
		await battle_vfx_layer.play_for_skill(skill.animation_id, player_actor, enemy_actor)
		_apply_player_buff(skill)
		_refresh_hud()
		_current_skill_index = skill_idx
		await _post_action()
		return

	var atk: int = _player_effective_attack()
	# 使用修正后的 power_mult 和 crit_mult_bonus 计算伤害
	var raw: int = _calc_damage_ext(atk, power_mult, _enemy.defense, true, crit_mult_bonus)
	player_actor.set_action_frames(_action_frames_for(skill.animation_id, player_actor.default_attack_frames, true))
	await player_actor.play_attack_approach(enemy_actor, skill.skill_id != &"basic_attack")
	if skill.skill_id != &"basic_attack":
		_play_skill_sfx(skill.cast_sfx_path)
	await battle_vfx_layer.play_for_skill(skill.animation_id, enemy_actor, player_actor)
	if skill.skill_id != &"basic_attack":
		_play_skill_sfx(skill.impact_sfx_path)
	var dmg: int = _enemy.take_damage(raw)
	await enemy_actor.play_hit(dmg)
	await player_actor.play_attack_recover()

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
	if _team_mode:
		await _team_player_action_defend()
		return
	_set_buttons_enabled(false)
	_state = State.EXECUTE
	_player_defending = true
	_guard_grants_extra_action = true
	await player_actor.play_defend()
	_log("→ 你摆出防御姿态，本回合受到伤害减半")
	await _post_action()


func _team_player_action_defend() -> void:
	if _team_active_unit == null:
		return
	_set_buttons_enabled(false)
	_state = State.EXECUTE
	_team_active_unit.guard_grants_extra_action = true
	_team_active_unit.status_effects["guard"] = 1
	var actor := _team_actor(_team_active_unit.unit_id)
	if actor != null:
		await actor.play_defend()
	_log("-> %s takes a guarded stance" % _team_active_unit.display_name)
	await _team_finish_player_action()


func _player_action_flee() -> void:
	if _state != State.PLAYER_TURN: return
	if _team_mode:
		_set_buttons_enabled(false)
		_team_finish(false)
		return
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
	_player_action_points = max(0, _player_action_points - 1)
	if _player_action_points > 0:
		_state = State.PLAYER_TURN
		action_panel.visible = true
		_update_action_point_label(_player_action_points)
		_set_buttons_enabled(true)
		_log("  [color=#c8a04a]\u5269\u4f59\u884c\u52a8\u673a\u4f1a %d \u6b21[/color]" % _player_action_points)
		return
	await get_tree().create_timer(0.7).timeout
	await _do_enemy_turn()
	if _state != State.ENDED:
		_enter_player_turn()


func _do_enemy_turn() -> void:
	_state = State.ENEMY_TURN
	if _turn_label != null:
		_turn_label.text = "敌方回合\n正在观察对手行动"
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
	enemy_actor.set_action_frames(_action_frames_for(skill.animation_id if skill != null else &"sword_arc", enemy_actor.default_attack_frames, false))
	await enemy_actor.play_attack_approach(player_actor, skill != null and skill.skill_id != &"basic_attack")
	if skill != null:
		if skill.skill_id != &"basic_attack":
			_play_skill_sfx(skill.cast_sfx_path)
		await battle_vfx_layer.play_for_skill(skill.animation_id, player_actor, enemy_actor)
		if skill.skill_id != &"basic_attack":
			_play_skill_sfx(skill.impact_sfx_path)

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
	await player_actor.play_hit(dmg)
	await enemy_actor.play_attack_recover()

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
		await player_actor.play_defeat()
		EventBus.battle_ended.emit(false, true)
		await get_tree().create_timer(1.0).timeout
		var payload := SceneRouter.get_battle_payload()
		var return_scene: StringName = payload.get("return_scene", &"")
		if String(return_scene) != "":
			SceneRouter.go_field_smart(return_scene)
		else:
			SceneRouter.go_main_menu()
		return

	if victory:
		await enemy_actor.play_defeat()
		await player_actor.play_victory()
	else:
		await player_actor.play_defeat()
		await enemy_actor.play_victory()
	await get_tree().create_timer(0.45).timeout
	if victory:
		var loot := _settle_drops(_enemy_def)
		# 自动写入 "defeated_<enemy_id>" flag，便于 hotspot 自动隐藏
		var flag_key := "defeated_%s" % String(_enemy_def.enemy_id)
		GameState.flags[flag_key] = true
		EventBus.flag_set.emit(StringName(flag_key), true)
		EventBus.enemy_defeated.emit(_enemy_def.enemy_id)
		EventBus.battle_ended.emit(true, false)
		_player.gain_exp(loot.exp)
		if _is_chapter_boss(_enemy_def):
			var boss_flag_key := "chapter_boss_defeated_%s" % String(_enemy_def.enemy_id)
			GameState.flags[boss_flag_key] = true
			EventBus.flag_set.emit(StringName(boss_flag_key), true)
		SceneRouter.go_victory(loot.gold, loot.exp)
	else:
		EventBus.battle_ended.emit(false, false)
		SceneRouter.go_defeat()


func _settle_drops(def: EnemyDef) -> Dictionary:
	var gold := randi_range(def.drop_gold_min, def.drop_gold_max)
	GameState.add_gold(gold)

	for item_id in def.drop_items:
		Inventory.add_item(item_id, 1)
		_log("[color=#6fc8ff]获得物品：%s[/color]" % String(item_id))

	for entry in def.drop_random:
		var iid: StringName = StringName(entry.get("item_id", ""))
		var chance: float = float(entry.get("chance", 0.0))
		var count: int = int(entry.get("count", 1))
		if String(iid) != "" and randf() < chance:
			Inventory.add_item(iid, count)
			_log("[color=#6fc8ff]获得物品：%s × %d[/color]" % [String(iid), count])

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
	if _player_skills.size() > 1 and _current_skill_index >= 0 and _current_skill_index < _player_skills.size():
		var sk: Skill = _player_skills[_current_skill_index]
		var atk: int = _player_effective_attack()
		var dmg_low: int = int(atk * sk.power * 0.85 / 100.0)
		var dmg_high: int = int(atk * sk.power * 1.15 / 100.0)
		btn_skill.text = "%s ⚔%d-%d (-%d MP)" % [sk.display_name, dmg_low, dmg_high, sk.mp_cost]
	else:
		btn_skill.text = "(无可用技能)"


func _has_available_active_skill(stats: CharacterStats = null) -> bool:
	if stats == null:
		stats = _player
	for skill in _player_skills:
		if not skill.is_passive and _can_use_skill(skill, stats):
			return true
	return false


func _has_usable_battle_item() -> bool:
	for entry in Inventory.slots:
		var item: Item = entry.get("item")
		if item != null and int(entry.get("count", 0)) > 0 and item.category == Item.Category.CONSUMABLE and item.can_use(true):
			return true
	return false


func _required_weapon_for_skill(skill: Skill) -> StringName:
	if skill.required_weapon_type != &"":
		return skill.required_weapon_type
	var id := String(skill.skill_id)
	if id.begins_with("gufeng_") and id != "gufeng_jingang_buhuai" and id != "gufeng_jingang_li":
		return &"blade"
	if id.begins_with("huashan_") or id.begins_with("wudang_") or id == "linxi_basic_sword_one":
		return &"sword"
	return &""


func _weapon_type_for_equipment(equipment: Equipment) -> StringName:
	if equipment == null:
		return &""
	if equipment.weapon_type != &"":
		return equipment.weapon_type
	var id := String(equipment.item_id).to_lower()
	if "blade" in id or "axe" in id:
		return &"blade"
	if "sword" in id:
		return &"sword"
	if "staff" in id or "stick" in id:
		return &"staff"
	return &""


func _can_use_skill(skill: Skill, stats: CharacterStats = null) -> bool:
	if stats == null:
		stats = _player
	if skill == null or skill.is_passive or stats == null or stats.mp < skill.mp_cost:
		return false
	var required := _required_weapon_for_skill(skill)
	if required == &"":
		return true
	var weapon := Inventory.get_equipped(Equipment.Slot.WEAPON)
	return _weapon_type_for_equipment(weapon) == required


func _create_skill_popup() -> void:
	_skill_popup = PopupPanel.new()
	_skill_popup.name = "SkillSelector"
	_skill_popup.exclusive = true
	var panel_style := _generated_texture_style("res://art/ui/battle/candidates/battle_skill_panel_frame_v1.png", 76.0, 76.0, 58.0, 58.0)
	if panel_style != null:
		_skill_popup.add_theme_stylebox_override("panel", panel_style)
	else:
		_skill_popup.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.018, 0.035, 0.050, 0.90), Color(0.34, 0.70, 0.72, 0.96), 8, 1))
	add_child(_skill_popup)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	_skill_popup.add_child(content)
	var title := Label.new()
	title.text = "选择招式"
	title.custom_minimum_size = Vector2(0.0, 42.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.94, 0.80, 0.43, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.03, 1.0))
	title.add_theme_constant_override("outline_size", 3)
	content.add_child(title)
	var separator := HSeparator.new()
	content.add_child(separator)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(704, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	_skill_list = VBoxContainer.new()
	_skill_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skill_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_skill_list)


func _show_skill_popup() -> void:
	if _state != State.PLAYER_TURN:
		return
	if _skill_popup == null or _skill_list == null:
		return
	for child in _skill_list.get_children():
		child.queue_free()
	var stats := _team_active_unit.stats if _team_mode and _team_active_unit != null else _player
	var shown_count := 0
	for skill_index in _player_skills.size():
		var skill: Skill = _player_skills[skill_index]
		if skill.is_passive:
			continue
		var option := Button.new()
		option.custom_minimum_size = Vector2(660, 76)
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.text = ""
		option.flat = false
		UI_THEME.style_button(option, 18, UI_THEME.JADE)
		_apply_generated_command_style(option)
		option.disabled = not _can_use_skill(skill, stats)
		option.tooltip_text = skill.description
		option.pressed.connect(_on_skill_selected.bind(skill_index))
		var item_content := VBoxContainer.new()
		item_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		item_content.offset_left = 32.0
		item_content.offset_top = 9.0
		item_content.offset_right = -32.0
		item_content.offset_bottom = -10.0
		item_content.add_theme_constant_override("separation", 4)
		option.add_child(item_content)
		var headline := HBoxContainer.new()
		headline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item_content.add_child(headline)
		var name_label := Label.new()
		name_label.text = skill.display_name
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", UI_THEME.GOLD_LIGHT)
		name_label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.03, 0.96))
		name_label.add_theme_constant_override("outline_size", 2)
		headline.add_child(name_label)
		var cost_label := Label.new()
		cost_label.text = "内力 %d" % skill.mp_cost
		cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cost_label.add_theme_font_size_override("font_size", 14)
		cost_label.add_theme_color_override("font_color", Color(0.54, 0.92, 0.86, 1.0))
		headline.add_child(cost_label)
		var description_label := Label.new()
		description_label.text = skill.description
		description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.add_theme_font_size_override("font_size", 14)
		description_label.add_theme_color_override("font_color", Color(0.86, 0.93, 0.94, 1.0))
		item_content.add_child(description_label)
		_skill_list.add_child(option)
		shown_count += 1
	if shown_count == 0:
		return
	_skill_popup.popup_centered(Vector2i(760, 500))


func _on_skill_selected(skill_index: int) -> void:
	if _skill_popup != null:
		_skill_popup.hide()
	_player_action_skill_use(skill_index)


func _battle_equipment() -> Array[Equipment]:
	var result: Array[Equipment] = []
	for entry in Inventory.slots:
		var item: Item = entry.get("item")
		if item is Equipment:
			result.append(item as Equipment)
	return result


func _create_equip_popup() -> void:
	_equip_popup = PopupMenu.new()
	_equip_popup.name = "EquipPopup"
	add_child(_equip_popup)
	_equip_popup.id_pressed.connect(_on_equip_selected)


func _show_equip_popup() -> void:
	if _state != State.PLAYER_TURN:
		return
	_equip_popup.clear()
	var equipment_list := _battle_equipment()
	for index in equipment_list.size():
		var equipment := equipment_list[index]
		var current := Inventory.get_equipped(equipment.slot)
		var equipped_mark := " *" if current != null and current.item_id == equipment.item_id else ""
		_equip_popup.add_item("%s%s" % [equipment.display_name, equipped_mark], index)
	if equipment_list.is_empty():
		return
	_equip_popup.position = get_global_mouse_position()
	_equip_popup.popup()


func _open_battle_inventory() -> void:
	if _state != State.PLAYER_TURN:
		return
	if _battle_inventory_panel == null:
		_battle_inventory_panel = INVENTORY_PANEL_SCENE.instantiate() as Control
		_battle_inventory_panel.name = "BattleInventoryPanel"
		add_child(_battle_inventory_panel)
		_battle_inventory_panel.closed.connect(_on_battle_inventory_closed)
	_set_buttons_enabled(false)
	_battle_inventory_panel.call("open")


func _on_battle_inventory_closed() -> void:
	if _state == State.PLAYER_TURN:
		_set_buttons_enabled(true)


func _on_equip_selected(index: int) -> void:
	if _state != State.PLAYER_TURN:
		return
	var equipment_list := _battle_equipment()
	if index < 0 or index >= equipment_list.size():
		return
	var equipment := equipment_list[index]
	if Inventory.get_equipped(equipment.slot) != null and Inventory.get_equipped(equipment.slot).item_id == equipment.item_id:
		return
	_set_buttons_enabled(false)
	_state = State.EXECUTE
	if not Inventory.equip(equipment.item_id):
		_state = State.PLAYER_TURN
		_set_buttons_enabled(true)
		return
	_log("-> %s" % equipment.display_name)
	_refresh_hud()
	if _team_mode:
		_sync_team_health()
		await _team_finish_player_action()
	else:
		await _post_action()


func _roll_damage(base_attack: int) -> int:
	## 80% - 120% 浮动（保留兼容旧代码）
	return int(base_attack * randf_range(0.8, 1.2))


func _is_chapter_boss(def: EnemyDef) -> bool:
	return def != null and def.is_chapter_boss


func _create_item_popup() -> void:
	_item_popup = PopupMenu.new()
	_item_popup.name = "ItemPopup"
	add_child(_item_popup)
	_item_popup.id_pressed.connect(_on_item_selected)


func _show_item_popup() -> void:
	if _state != State.PLAYER_TURN:
		return
	_item_popup.clear()
	var consumables: Array[Dictionary] = []
	for s in Inventory.slots:
		var item: Item = s.get("item")
		if item == null or item.category != Item.Category.CONSUMABLE or not item.can_use(true):
			continue
		consumables.append(s)
	if consumables.is_empty():
		_log("[color=#888]没有可用道具[/color]")
		return
	for i in consumables.size():
		var entry: Dictionary = consumables[i]
		var it: Item = entry["item"]
		var cnt: int = entry["count"]
		var label: String = "%s x%d" % [it.display_name, cnt]
		_item_popup.add_item(label, i)
	_item_popup.position = get_global_mouse_position()
	_item_popup.popup()


func _on_item_selected(id: int) -> void:
	if _state != State.PLAYER_TURN:
		return
	var consumables: Array[Dictionary] = []
	for s in Inventory.slots:
		var item: Item = s.get("item")
		if item == null or item.category != Item.Category.CONSUMABLE or not item.can_use(true):
			continue
		consumables.append(s)
	if id < 0 or id >= consumables.size():
		return
	var entry: Dictionary = consumables[id]
	var it: Item = entry["item"]
	if entry["count"] <= 0:
		return
	if _team_mode:
		_team_use_item(it)
		return
	_set_buttons_enabled(false)
	_state = State.EXECUTE
	Inventory.remove_item(it.item_id, 1)
	var hp_healed := 0
	var mp_healed := 0
	if it.heal_hp > 0:
		var before: int = _player.hp
		_player.hp = min(_player.max_hp, _player.hp + it.heal_hp)
		hp_healed = _player.hp - before
	if it.heal_mp > 0:
		var before: int = _player.mp
		_player.mp = min(_player.max_mp, _player.mp + it.heal_mp)
		mp_healed = _player.mp - before
	var parts: Array[String] = []
	if hp_healed > 0:
		parts.append("[color=#ff6b6b]HP +%d[/color]" % hp_healed)
	if mp_healed > 0:
		parts.append("[color=#64b5f6]MP +%d[/color]" % mp_healed)
	_log("-> 使用 [b]%s[/b] %s" % [it.display_name, " ".join(parts)])
	_refresh_hud()
	await _post_action()


func _team_use_item(item: Item) -> void:
	if _team_active_unit == null or _team_active_unit.stats == null:
		return
	if not item.can_use(true) or not Inventory.remove_item(item.item_id, 1):
		_log("[color=#888]该道具无法在战斗中使用[/color]")
		return
	_set_buttons_enabled(false)
	_state = State.EXECUTE
	var stats := _team_active_unit.stats
	var hp_before: int = stats.hp
	var mp_before: int = stats.mp
	stats.hp = min(stats.max_hp, stats.hp + item.heal_hp)
	stats.mp = min(stats.max_mp, stats.mp + item.heal_mp)
	_log("→ %s 使用 [color=#c0c8d0]%s[/color]：[color=#ff6b6b]HP +%d[/color] [color=#64b5f6]MP +%d[/color]" % [
		_team_active_unit.display_name,
		item.display_name,
		stats.hp - hp_before,
		stats.mp - mp_before,
	])
	_sync_team_health()
	await _team_finish_player_action()


func _log(line: String) -> void:
	battle_log.append_text(line + "\n")
