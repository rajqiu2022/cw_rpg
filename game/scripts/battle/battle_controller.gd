extends Control

const WILDERNESS_ELITE := preload("res://scripts/battle/wilderness_elite.gd")

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
const EnemySignatureFrames := preload("res://art/characters/combat_forms_20261112/enemy_frames.gd")
const StoryBossTactics := preload("res://scripts/battle/story_boss_tactics.gd")
const POISON_STATUS := preload("res://data/status_effects/poison.tres")
const VENOM_STATUS := preload("res://data/status_effects/venom.tres")

const SKILL_DIR := "res://data/skills/"
const ENEMY_DIR := "res://data/enemies/"
const ENEMY_VANISH_SFX := "res://art/audio/battle/sfx_enemy_vanish_20261111.wav"
## Never use dialogue portraits on the battle field. This is a full-body combat
## stance while the dedicated idle set is being expanded.
const PLAYER_BATTLE_ROOT := "res://art/sprites/battle/standard_v5/lengguyun"
const PLAYER_BATTLE_ACTOR_PATH := PLAYER_BATTLE_ROOT + "/lengguyun_ready_01.png"
const PLAYER_BATTLE_VARIANT_ROOT := "res://art/sprites/battle/weapon_variants_v3/lengguyun"
const FALLBACK_ENEMY_BATTLE_ROOT := "res://art/sprites/battle/standard_v2/thug_lone"
const FALLBACK_ENEMY_BATTLE_PREFIX := "thug_lone"
const FALLBACK_ENEMY_BATTLE_ACTOR_PATH := FALLBACK_ENEMY_BATTLE_ROOT + "/thug_lone_ready_01.png"
const BATTLE_ARENA_PATHS := {
	&"zhuwei_ruin_hall": "res://art/backgrounds/bg_battle_zhuwei_ruin_hall_20261116.png",
	&"bamboo_platforms": "res://art/backgrounds/bg_battle_bamboo_day_v1.png",
	&"river_skirmish": "res://art/backgrounds/bg_battle_river_valley_day_v1.png",
	&"courtyard_wedge": "res://art/backgrounds/bg_battle_mountain_gate_day_v1.png",
	&"village_square": "res://art/backgrounds/battle_arenas_v2/bg_battle_village_square_v3.jpg",
	&"city_street": "res://art/backgrounds/battle_arenas_v2/bg_battle_city_street_v1.jpg",
	&"outskirts_road": "res://art/backgrounds/battle_arenas_v2/bg_battle_outskirts_road_v1.jpg",
	&"cave_depths": "res://art/backgrounds/battle_arenas_v2/bg_battle_cave_depths_v1.jpg",
	&"sect_courtyard": "res://art/backgrounds/battle_arenas_v2/bg_battle_sect_courtyard_v1.jpg",
	&"snow_peak": "res://art/backgrounds/battle_arenas_v2/bg_battle_snow_peak_v1.jpg",
	&"grassland": "res://art/backgrounds/battle_arenas_v2/bg_battle_grassland_v1.jpg",
	&"mingwu_sanctum": "res://art/backgrounds/bg_battle_mingwu_rear_sanctum_v1.png",
}
const BATTLE_ARENA_BGM := {
	&"bamboo_platforms": "res://art/audio/bgm/wuxia_20261011/battle_spar.wav",
	&"river_skirmish": "res://art/audio/bgm/wuxia_20261011/battle_river.wav",
	&"courtyard_wedge": "res://art/audio/bgm/wuxia_20261011/battle_mountain.wav",
	&"village_square": "res://art/audio/bgm/wuxia_20261011/battle_village.wav",
	&"city_street": "res://art/audio/bgm/wuxia_20261011/battle_village.wav",
	&"outskirts_road": "res://art/audio/bgm/wuxia_20261011/battle_mountain.wav",
	&"cave_depths": "res://art/audio/bgm/wuxia_20261011/battle_mountain.wav",
	&"sect_courtyard": "res://art/audio/bgm/wuxia_20261011/battle_spar.wav",
	&"snow_peak": "res://art/audio/bgm/wuxia_20261011/battle_mountain.wav",
	&"grassland": "res://art/audio/bgm/wuxia_20261011/battle_river.wav",
	&"mingwu_sanctum": "res://art/audio/bgm/wuxia_20261011/battle_boss.wav",
}
const BATTLE_BOSS_BGM := "res://art/audio/bgm/wuxia_20261011/battle_boss.wav"
const BATTLE_CHARACTER_SCALE_TRIAL := 1.30
const LEGACY_BATTLE_ACTOR_SCALE := 0.48 * BATTLE_CHARACTER_SCALE_TRIAL
const PROTAGONIST_FORMATION_SCALE_FACTOR := 1.28
const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const INVENTORY_PANEL_SCENE := preload("res://scenes/ui/inventory_panel.tscn")
const FORMAL_CONFIRM_SCENE := preload("res://scenes/ui/formal_confirm_dialog.tscn")
const UI_LAYER_POLICY := preload("res://scripts/ui/ui_layer_policy.gd")
const BATTLE_HUD_ATLAS_PATH := "res://art/ui/frame/ui_cold_wuxia_battle_hud_v1.png"
## Battle UI V3 deliberately uses one restrained generated kit.  Mixing the
## older wide command art with the decorated candidate rows caused the text
## baseline to drift and made the action rail look like several unrelated UIs.
const BATTLE_COMMAND_NORMAL_PATH := "res://art/ui/battle/formal/v3/battle_command_button_v3.png"
const BATTLE_COMMAND_HOVER_PATH := "res://art/ui/battle/formal/v3/battle_command_button_v3.png"
const BATTLE_COMMAND_PRESSED_PATH := "res://art/ui/battle/formal/v3/battle_command_button_v3.png"
const BATTLE_LOG_PANEL_PATH := "res://art/ui/battle/formal/battle_log_panel_v3.png"
const BATTLE_SKILL_PANEL_PATH := "res://art/ui/battle/formal/v3/battle_skill_panel_v3.png"
const BATTLE_SKILL_ROW_PATH := "res://art/ui/battle/formal/v3/battle_skill_row_v3.png"
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
@onready var legendary_cinematic: LegendarySkillCinematic = %LegendarySkillCinematic
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
var _skill_popup: PopupPanel = null
var _skill_list: VBoxContainer = null
var _battle_inventory_panel: Control = null
var _flee_confirm_dialog: FormalConfirmDialog = null
var _player_action_points: int = 1
var _hud_canvas_layer: CanvasLayer = null
var _system_ui_canvas_layer: CanvasLayer = null

var _player_mp_label: Label = null
var _turn_label: Label = null
var _command_title: Label = null
var _player_status_label: Label = null
var _enemy_status_label: Label = null

var _state: State = State.INTRO
var _player: CharacterStats
var _enemy: CharacterStats
var _enemy_def: EnemyDef
var _last_enemy_vanish_sfx_ms: int = -1000
var _player_defending: bool = false
var _player_redirect_percent: int = 0
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
var _last_damage_was_critical: bool = false
var _last_attack_missed: bool = false
var last_damage_breakdown: DamageBreakdown = null

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
const OFFICE_PATROL_VICTORIES := ["dialog:ch7_pulse_wrist_won", "dialog:ch7_pulse_current_won"]
const OFFICE_FINAL_VICTORY := "dialog:ch7_inner_office_destroyers_victory"
var _office_victory_action := ""
var _story_boss_tactics := StoryBossTactics.new()


func _ready() -> void:
	_init_ui_canvas_layers()
	_player = GameState.player
	var payload := SceneRouter.get_battle_payload()
	if AudioManager != null:
		AudioManager.play_bgm(_battle_bgm_for_payload(payload), 0.08, _battle_bgm_context(payload))

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
	_refresh_hud()
	_refresh_skill_button()

	btn_attack.pressed.connect(func(): _player_action_skill_use(0))
	btn_skill.pressed.connect(_show_skill_popup)
	btn_equip.pressed.connect(_open_battle_inventory)
	btn_defend.pressed.connect(func(): _player_action_defend())
	btn_flee.pressed.connect(_request_player_flee)
	btn_item.pressed.connect(_open_battle_inventory)
	for action_button in [btn_attack, btn_skill, btn_equip, btn_defend, btn_flee, btn_item]:
		action_button.pressed.connect(func(): AudioManager.play_ui_confirm())
	_create_skill_popup()
	btn_skill.text = "\u62db\u5f0f"
	btn_equip.text = "\u80cc\u5305"
	btn_item.text = "\u80cc\u5305"
	btn_equip.visible = false
	_flee_confirm_dialog = FORMAL_CONFIRM_SCENE.instantiate() as FormalConfirmDialog
	_flee_confirm_dialog.name = "BattleFleeConfirmation"
	_flee_confirm_dialog.confirmed.connect(_player_action_flee)
	_system_ui_canvas_layer.add_child(_flee_confirm_dialog)

	EventBus.battle_started.emit(StringName(enemy_id))
	EventBus.status_cured.connect(_on_status_cured)
	EventBus.equipment_changed.connect(_on_battle_equipment_changed)
	player_actor.sound_requested.connect(_on_actor_sound_requested.bind(false))
	enemy_actor.retain_on_defeat = true
	enemy_actor.sound_requested.connect(_on_actor_sound_requested.bind(true))
	formation_view.target_selected.connect(_on_team_target_selected)

	var opening_label := "切磋开始" if _is_sparring_battle() else "遭遇战开始"
	_log("[color=#e5c06b]%s[/color]  ——  %s 对阵 %s" % [opening_label, _player.display_name, _enemy.display_name])
	_log("（提示：已装备 %d 件，攻 +%d 防 +%d）" % [
		Inventory.equipped.size(),
		Inventory.get_atk_bonus(),
		Inventory.get_def_bonus(),
	])
	if _team_mode:
		for ally in _team_allies:
			var injury := int(ally.status_effects.get("internal_injury", 0))
			if injury > 0:
				_log("%s 带伤入阵，内伤 %d/100。" % [ally.display_name, injury])
		if _team_enemies.any(func(foe: BattleCombatant) -> bool: return foe.enemy_definition.poison_weapons):
			_log("[color=#a4c987]烬茶社的刀、针、镖都淬了毒。丹砂佩可减轻毒伤，青木护元诀能护住全队。[/color]")
		for foe in _team_enemies:
			var trait_def := foe.enemy_definition
			match trait_def.finisher_affliction:
				"venom":
					_log("%s · 青烟烈毒：隐影夺命命中挂毒三回合，每次损失一成二最大气血。防御可减为普通毒，丹砂佩、解毒丹和回春引可应对。" % foe.display_name)
				"seal":
					_log("%s · 截脉封针：封针散手命中积累100内伤，防御时减半。冰心玉可护脉，回春引或清心露可解封。" % foe.display_name)
			if trait_def.breakable_armor > 0:
				_log("%s · %s：防御额外 +%d，破甲可卸去这层防御。" % [foe.display_name, trait_def.trait_caption, trait_def.breakable_armor])
			if trait_def.evasion_penalty > 0.0:
				_log("%s · %s：对其命中率降低 %d 个百分点，必中可识破身法。" % [foe.display_name, trait_def.trait_caption, roundi(trait_def.evasion_penalty * 100)])
		await formation_view.play_team_enter()
	else:
		await player_actor.play_enter(true)
		await enemy_actor.play_enter(false)
	await get_tree().create_timer(0.5).timeout
	_begin_round()


func _init_ui_canvas_layers() -> void:
	_hud_canvas_layer = UI_LAYER_POLICY.ensure_canvas_layer(
		self,
		&"HudCanvasLayer",
		UI_LAYER_POLICY.HUD_LAYER
	)
	_system_ui_canvas_layer = UI_LAYER_POLICY.ensure_canvas_layer(
		self,
		&"SystemUICanvasLayer",
		UI_LAYER_POLICY.SYSTEM_LAYER
	)
	for node in [enemy_hud, player_hud, log_panel, action_panel]:
		UI_LAYER_POLICY.move_to_canvas(node, _hud_canvas_layer)


func _apply_battle_arena(payload: Dictionary) -> void:
	var arena_id: StringName = StringName(payload.get("battle_arena", &"bamboo_platforms"))
	if not BATTLE_ARENA_PATHS.has(arena_id):
		arena_id = &"bamboo_platforms"
	var path: String = BATTLE_ARENA_PATHS[arena_id]
	var arena_texture := load(path) as Texture2D
	if arena_texture != null:
		battle_background.texture = arena_texture
	# Unmarked arenas still use five authored logical anchors. Rotating between
	# three safe subsets makes one-to-four-unit encounters look organic without
	# ever allowing a combatant to overlap the command rail.
	formation_view.set_formation_profile(arena_id, randi_range(0, 2))


func _battle_bgm_for_payload(payload: Dictionary) -> String:
	if StringName(payload.get("battle_mode", &"")) == &"sparring":
		return String(BATTLE_ARENA_BGM[&"bamboo_platforms"])
	if _payload_has_chapter_boss(payload):
		return BATTLE_BOSS_BGM
	var arena_id := StringName(payload.get("battle_arena", &"bamboo_platforms"))
	return String(BATTLE_ARENA_BGM.get(arena_id, AudioManager.DEFAULT_BATTLE_BGM))


func _battle_bgm_context(payload: Dictionary) -> String:
	var enemy_key := String(payload.get("enemy_id", ""))
	var raw_ids: Variant = payload.get("enemy_ids", [])
	if raw_ids is Array and not raw_ids.is_empty():
		var parts: PackedStringArray = []
		for raw_id: Variant in raw_ids:
			parts.append(String(raw_id))
		enemy_key = ",".join(parts)
	return "battle:%s:%s:%s" % [
		String(payload.get("battle_arena", "bamboo_platforms")),
		String(payload.get("return_scene", "")),
		enemy_key,
	]


func _payload_has_chapter_boss(payload: Dictionary) -> bool:
	var enemy_ids: Array[StringName] = []
	var raw_ids: Variant = payload.get("enemy_ids", [])
	if raw_ids is Array:
		for raw_id: Variant in raw_ids:
			enemy_ids.append(StringName(String(raw_id)))
	var single_id := StringName(String(payload.get("enemy_id", "")))
	if not single_id.is_empty() and single_id not in enemy_ids:
		enemy_ids.append(single_id)
	for enemy_id: StringName in enemy_ids:
		var path := "%s%s.tres" % [ENEMY_DIR, String(enemy_id)]
		if not ResourceLoader.exists(path):
			continue
		var enemy_def := load(path) as EnemyDef
		if enemy_def != null and enemy_def.is_chapter_boss:
			return true
	return false


func _setup_team_formation(payload: Dictionary) -> void:
	if formation_view == null:
		return
	var raw_ids: Variant = payload.get("enemy_ids", [])
	var enemy_ids: Array[StringName] = []
	if raw_ids is Array:
		for raw_id in raw_ids:
			enemy_ids.append(StringName(raw_id))
	if enemy_ids.is_empty():
		var single_enemy_id: StringName = StringName(payload.get("enemy_id", &""))
		if not single_enemy_id.is_empty():
			enemy_ids.append(single_enemy_id)
	if enemy_ids.is_empty():
		formation_view.visible = false
		return
	_team_mode = true
	_team_player_party_payload = _build_player_party_payload(payload)
	var extra_allies := 0 if bool(payload.get("solo_player", false)) else maxi(0, _team_player_party_payload.size() - 1)
	# Both sides share one count-dependent baseline. The weapon-variant protagonist
	# frames contain a 300 px body while companions are 330-350 px, so normalize
	# the protagonist by 1.28 before applying the shared count scale. This uses
	# visible-alpha area rather than height alone: the slim protagonist frame has
	# ~23.7k opaque pixels versus ~37.5k for an ordinary bandit.
	var formation_count: int = maxi(enemy_ids.size(), _team_player_party_payload.size())
	var formation_base_scale: float = (0.46 if formation_count <= 1 else (0.42 if formation_count <= 3 else 0.36)) * BATTLE_CHARACTER_SCALE_TRIAL

	# Build a presentation entry for every member; runtime target resolution uses
	# the independent BattleCombatant instances created below.
	var enemy_entries: Array[Dictionary] = []
	for index in range(enemy_ids.size()):
		var id := enemy_ids[index]
		var unit_key := StringName("%s_%d" % [String(id), index + 1])
		var def := _load_enemy(String(id))
		var scaled_stats := def.to_runtime_stats(extra_allies)
		var texture: Texture2D = null
		if ResourceLoader.exists(def.battle_actor_path):
			texture = load(def.battle_actor_path) as Texture2D
		elif ResourceLoader.exists(FALLBACK_ENEMY_BATTLE_ACTOR_PATH):
			texture = load(FALLBACK_ENEMY_BATTLE_ACTOR_PATH) as Texture2D
		enemy_entries.append({
			"unit_id": unit_key,
			"display_name": def.display_name,
			"enemy_level": def.level,
			"wild_elite": WILDERNESS_ELITE.is_elite(id),
			"boss_caption": "狼王-Boss" if id == &"zhuwei_cave_wolf" else def.trait_caption,
			"texture": texture,
			"scale": formation_base_scale * def.get_battle_actor_scale(0.96),
			"status_lift": def.battle_actor_status_lift,
			"flip_h": def.battle_actor_flip_h,
			"authored_face_right": def.battle_actor_flip_h,
			"hp": scaled_stats.max_hp,
			"max_hp": scaled_stats.max_hp,
			"mp": def.max_mp,
			"max_mp": def.max_mp,
			"ready_frames": _load_enemy_frames(def, &"ready"),
			"move_frames": _load_enemy_frames(def, &"move"),
			"attack_frames": _load_enemy_attack_frames(def),
			"hit_frames": _load_enemy_frames(def, &"hit"),
			"defeat_frames": _load_enemy_frames(def, &"defeat"),
			"idle_motion_strength": 0.30 if id in [&"companion_tang_xingzhou_spar", &"zhuwei_cave_wolf"] else 0.70,
			"idle_motion_speed": 0.52 if id == &"zhuwei_cave_wolf" else 1.0,
		})
	var ally_entries: Array[Dictionary] = []
	for party_entry in _team_player_party_payload:
		var player_texture: Texture2D = null
		var actor_path: String = str(party_entry.get("actor_path", PLAYER_BATTLE_ACTOR_PATH))
		if ResourceLoader.exists(actor_path):
			player_texture = load(actor_path) as Texture2D
		party_entry["texture"] = player_texture
		if StringName(party_entry.get("unit_id", &"")) == &"player":
			party_entry["ready_frames"] = _load_player_frames("ready")
			party_entry["move_frames"] = _load_player_frames("move")
			party_entry["attack_frames"] = _load_player_attack_frames()
			party_entry["hit_frames"] = _load_player_hit_frames()
			party_entry["defeat_frames"] = _load_player_defeat_frames()
		else:
			var sprite_root: String = str(party_entry.get("battle_sprite_root", ""))
			var sprite_prefix: String = str(party_entry.get("battle_sprite_prefix", ""))
			if not sprite_root.is_empty() and not sprite_prefix.is_empty():
				var ready_root := sprite_root
				if StringName(party_entry.get("unit_id", &"")) == &"tang_xingzhou":
					ready_root = "res://art/sprites/battle/companions_v2/tang_xingzhou"
				party_entry["ready_frames"] = _load_standard_frames(ready_root, sprite_prefix, "ready")
				party_entry["move_frames"] = _load_standard_frames(sprite_root, sprite_prefix, "move")
				party_entry["attack_frames"] = _load_standard_frames(sprite_root, sprite_prefix, "attack")
				party_entry["hit_frames"] = _load_standard_frames(sprite_root, sprite_prefix, "hit")
				party_entry["defeat_frames"] = _load_standard_frames(sprite_root, sprite_prefix, "defeat")
			else:
				party_entry["attack_frames"] = _load_texture_frames(PackedStringArray(party_entry.get("attack_frame_paths", [])))
				party_entry["hit_frames"] = _load_texture_frames(PackedStringArray(party_entry.get("hit_frame_paths", [])))
				party_entry["defeat_frames"] = _load_texture_frames(PackedStringArray(party_entry.get("defeat_frame_paths", [])))
		if not party_entry.has("idle_motion_strength"):
			party_entry["idle_motion_strength"] = 0.30 if String(party_entry.get("display_name", "")) == "唐行舟" else 0.70
		# CharacterStats stores 0.42 as the standard companion scale. Preserve an
		# explicitly authored relative adjustment while using the same base scale.
		var authored_scale: float = float(party_entry.get("scale", 0.42))
		var protagonist_factor := PROTAGONIST_FORMATION_SCALE_FACTOR if StringName(party_entry.get("unit_id", &"")) == &"player" else 1.0
		party_entry["scale"] = formation_base_scale * authored_scale / 0.42 * protagonist_factor
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
	# Keep the compact, framed turn log visible for both single and team battles.
	log_panel.visible = true
	# Formation rendering and turn resolution share the same combatant list.
	# A 1v1 battle still uses formation mode, so it must initialize runtime units too.
	_setup_team_runtime(enemy_ids, _team_player_party_payload, extra_allies)


func _build_player_party_payload(payload: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var solo_player := bool(payload.get("solo_player", false)) or StringName(payload.get("battle_mode", &"")) == &"sparring"
	for member: CharacterStats in GameState.get_battle_party():
		if member == null:
			continue
		var is_player := member.character_id == "protagonist"
		if solo_player and not is_player:
			continue
		result.append({
			"unit_id": &"player" if is_player else StringName(member.character_id),
			"character_id": member.character_id,
			"display_name": member.display_name,
			"portrait_path": member.portrait_path,
			"actor_path": PLAYER_BATTLE_ACTOR_PATH if is_player else member.battle_actor_path,
			"battle_sprite_root": PLAYER_BATTLE_ROOT if is_player else member.battle_sprite_root,
			"battle_sprite_prefix": "lengguyun" if is_player else member.battle_sprite_prefix,
			"scale": member.battle_actor_scale,
			"idle_motion_strength": 0.30 if member.character_id == "tang_xingzhou" else 0.70,
			"stats_ref": member,
		})
	var raw_party: Variant = payload.get("player_party", [])
	if raw_party is Array:
		for raw_entry in raw_party:
			if result.size() >= GameState.BATTLE_PARTY_LIMIT:
				break
			if raw_entry is Dictionary:
				var raw_id := StringName(raw_entry.get("unit_id", "ally"))
				if result.all(func(existing: Dictionary) -> bool: return StringName(existing.get("unit_id", "")) != raw_id):
					result.append(raw_entry.duplicate(true))
	return result


func _setup_team_runtime(enemy_ids: Array[StringName], party_entries: Array[Dictionary], extra_allies: int = 0) -> void:
	_office_victory_action = SceneRouter.get_battle_payload().get("victory_action", "")
	var route_wounds: Dictionary = {}
	if _office_victory_action in OFFICE_PATROL_VICTORIES or _office_victory_action == OFFICE_FINAL_VICTORY:
		route_wounds = GameState.get_flag("ch7_office_injuries", {})
	_story_boss_tactics = StoryBossTactics.new()
	_team_allies.clear()
	_team_enemies.clear()
	for entry in party_entries:
		var ally := BattleCombatant.new()
		var unit_id: StringName = StringName(entry.get("unit_id", "ally"))
		var stats: CharacterStats = _build_party_stats(entry, unit_id == &"player")
		ally.configure_from_stats(unit_id, BattleCombatant.Team.ALLY, stats)
		ally.battle_actor_path = str(entry.get("actor_path", PLAYER_BATTLE_ACTOR_PATH))
		ally.actor_scale = float(entry.get("scale", 0.42))
		var injury := int(route_wounds.get(stats.character_id, 0))
		if injury > 0:
			ally.status_effects["internal_injury"] = injury
		_team_allies.append(ally)
	for index in range(enemy_ids.size()):
		var unit_id := enemy_ids[index]
		var def := _load_enemy(String(unit_id))
		var enemy_unit := BattleCombatant.new()
		var unit_key := StringName("%s_%d" % [String(unit_id), index + 1])
		enemy_unit.configure_from_stats(unit_key, BattleCombatant.Team.ENEMY, def.to_runtime_stats(extra_allies))
		enemy_unit.definition_id = unit_id
		enemy_unit.enemy_definition = def
		enemy_unit.battle_actor_path = def.battle_actor_path
		enemy_unit.actor_scale = 0.46 * BATTLE_CHARACTER_SCALE_TRIAL * def.get_battle_actor_scale(0.85)
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
	var stats_ref: Variant = entry.get("stats_ref")
	if stats_ref is CharacterStats:
		return stats_ref
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
	var raw_skills: Variant = entry.get("skills", [])
	if raw_skills is Array:
		for skill_id: Variant in raw_skills:
			stats.skills.append(StringName(skill_id))
	return stats


func _on_team_actor_created(actor: BattleActor, enemy_side: bool) -> void:
	actor.stepped_combat = actor.unit_id == &"tang_xingzhou" or String(actor.unit_id).begins_with("zhuwei_cave_wolf_") or String(actor.unit_id).begins_with("companion_tang_xingzhou_spar_")
	actor.sound_requested.connect(_on_team_actor_sound_requested.bind(actor, enemy_side))


func _on_team_actor_sound_requested(cue: StringName, actor: BattleActor, enemy_side: bool) -> void:
	if not _team_mode:
		return
	var unit: BattleCombatant = _team_find_unit_for_actor(actor, enemy_side)
	if enemy_side and cue == &"defeat":
		var enemy_def := _load_enemy(String(unit.definition_id)) if unit != null else null
		if not _is_nonlethal_story_boss(enemy_def):
			_play_enemy_vanish_sfx()
		return
	if unit != null:
		var path: String = unit.get_audio_path(cue)
		if path.is_empty() and cue == &"attack":
			var enemy_def := _load_enemy(String(unit.definition_id)) if enemy_side else null
			var style := _player_weapon_type() if unit.unit_id == &"player" and not enemy_side else _basic_attack_weapon_type(unit.stats, enemy_def)
			path = _weapon_attack_sfx(style)
		if path.is_empty():
			path = _default_sfx_for_cue(cue)
		EventBus.sfx_requested.emit(path, 0.0)


func _team_find_unit_for_actor(actor: BattleActor, enemy_side: bool) -> BattleCombatant:
	if actor != null and not actor.unit_id.is_empty():
		var units: Array[BattleCombatant] = _team_enemies if enemy_side else _team_allies
		for unit: BattleCombatant in units:
			if unit.unit_id == actor.unit_id:
				return unit
	return _team_find_unit_for_actor_side(&"", enemy_side)


func _team_find_unit_for_actor_side(_cue: StringName, enemy_side: bool) -> BattleCombatant:
	# The actor signal currently carries only its side; the side's active unit is
	# the only unit allowed to animate during a turn.
	if _team_active_unit != null and ((_team_active_unit.team == BattleCombatant.Team.ENEMY) == enemy_side):
		return _team_active_unit
	return null


func _on_actor_sound_requested(cue: StringName, enemy_side: bool) -> void:
	if enemy_side and cue == &"defeat":
		if not _is_nonlethal_story_boss(_enemy_def):
			_play_enemy_vanish_sfx()
		return
	var path := ""
	if enemy_side and _enemy_def != null:
		path = _enemy_def.attack_sfx_path if cue == &"attack" else _enemy_def.hit_sfx_path
	if path.is_empty() and cue == &"attack":
		var style := _basic_attack_weapon_type(_enemy, _enemy_def) if enemy_side else _player_weapon_type()
		path = _weapon_attack_sfx(style)
	if path.is_empty():
		path = _default_sfx_for_cue(cue)
	EventBus.sfx_requested.emit(path, 0.0)


func _play_enemy_vanish_sfx() -> void:
	if _is_sparring_battle():
		return
	# Group deaths emit synchronously; coalesce their identical disappearance cue.
	var now := Time.get_ticks_msec()
	if now - _last_enemy_vanish_sfx_ms < 120:
		return
	_last_enemy_vanish_sfx_ms = now
	EventBus.sfx_requested.emit(ENEMY_VANISH_SFX, -4.0)


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


func _has_distinct_hit_sfx(path: String) -> bool:
	return not path.is_empty() and path != AudioManager.DEFAULT_HIT_SFX


func _arm_skill_strike_audio(actor: BattleActor, skill: Skill) -> void:
	if actor == null or skill == null or skill.skill_id == &"basic_attack":
		return
	if skill.cast_sfx_path.is_empty() and actor.unit_id == &"player":
		var appearance := get_node_or_null("/root/LayeredAppearanceRuntime")
		if appearance != null and actor.HERO_COMBAT.uses_kaishan_poses(actor, appearance.manifest.get("clips", {})):
			return
	_play_skill_sfx(_skill_cast_sfx(skill))


func _skill_cast_sfx(skill: Skill) -> String:
	if not skill.cast_sfx_path.is_empty():
		return skill.cast_sfx_path
	var style := skill.required_weapon_type
	if style == &"" and not skill.is_internal_art and skill.kind in [Skill.Kind.ATTACK, Skill.Kind.DEBUFF]:
		style = skill.martial_category if skill.martial_category != &"" else skill.get_bonus_weapon_style()
	var path := _weapon_attack_sfx(style)
	return path if not path.is_empty() else AudioManager.PALM_ATTACK_SFX


func _weapon_attack_sfx(style: StringName) -> String:
	match Equipment.normalize_weapon_type(style):
		&"sword": return AudioManager.SWORD_ATTACK_SFX
		&"blade": return AudioManager.BLADE_ATTACK_SFX
		&"staff": return AudioManager.STAFF_ATTACK_SFX
		&"palm": return AudioManager.PALM_ATTACK_SFX
		_: return ""


func _skill_impact_sfx(skill: Skill) -> String:
	if not skill.impact_sfx_path.is_empty():
		return skill.impact_sfx_path
	if skill.required_weapon_type == &"sword" or skill.required_weapon_type == &"blade":
		return AudioManager.METAL_HIT_SFX
	return AudioManager.DEFAULT_HIT_SFX


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
		false,
		true,
		_load_player_frames("ready"),
		_load_player_frames("move"),
		_load_player_attack_frames(),
		_load_player_hit_frames(),
		_load_player_defeat_frames()
	)
	enemy_actor.configure(
		enemy_actor_texture,
		_enemy_def.battle_actor_flip_h,
		_enemy_def.battle_actor_flip_h,
		_load_enemy_frames(_enemy_def, &"ready"),
		_load_enemy_frames(_enemy_def, &"move"),
		_load_enemy_attack_frames(_enemy_def),
		_load_enemy_frames(_enemy_def, &"hit"),
		_load_enemy_frames(_enemy_def, &"defeat")
	)
	player_actor.scale = Vector2.ONE * LEGACY_BATTLE_ACTOR_SCALE
	if _enemy_def.enemy_id == &"zhuwei_cave_wolf":
		enemy_actor.set_idle_motion_profile(0.30, _enemy_def.enemy_id, 0.52)
		enemy_actor.stepped_combat = true
	# One frame = one body-height contract. Ordinary enemies use the player
	# baseline; bosses can opt into a modest authored multiplier in EnemyDef.
	enemy_actor.scale = Vector2.ONE * LEGACY_BATTLE_ACTOR_SCALE * _enemy_def.get_battle_actor_scale(0.85)
	player_name.text = _player.display_name
	enemy_name.text = "%s · %d级" % [_enemy.display_name, _enemy.level]
	if WILDERNESS_ELITE.is_elite(_enemy_def.enemy_id):
		enemy_name.text = "◆ 精英 · " + enemy_name.text


func _load_player_attack_frames() -> Array[Texture2D]:
	return _load_player_frames("attack")


func _load_enemy_attack_frames(def: EnemyDef) -> Array[Texture2D]:
	return _load_enemy_frames(def, &"attack")


func _load_enemy_frames(def: EnemyDef, state: StringName) -> Array[Texture2D]:
	var authored_paths: PackedStringArray = PackedStringArray()
	if def != null:
		match state:
			&"ready": authored_paths = def.ready_frame_paths
			&"move": authored_paths = def.move_frame_paths
			&"attack": authored_paths = def.attack_frame_paths
			&"hit": authored_paths = def.hit_frame_paths
			&"defeat": authored_paths = def.defeat_frame_paths
	var frames: Array[Texture2D] = _load_texture_frames(authored_paths)
	if not frames.is_empty():
		return frames
	if def != null and ResourceLoader.exists(def.battle_actor_path, "Texture2D"):
		# Keep the enemy's own silhouette through every animation state. The
		# actor already supports a lunge, recoil and fall without authored frames.
		if state == &"ready":
			return _load_texture_frames(PackedStringArray([def.battle_actor_path]))
		return frames
	return _load_standard_frames(FALLBACK_ENEMY_BATTLE_ROOT, FALLBACK_ENEMY_BATTLE_PREFIX, String(state))


func _action_frames_for(animation_id: StringName, fallback: Array[Texture2D], player_style: bool = true) -> Array[Texture2D]:
	if not player_style:
		return fallback
	match animation_id:
		&"sword_arc", &"linxi_sword_one", &"heavy_cleave", &"crimson_palm", &"staff_sweep":
			return _load_player_attack_frames()
		_:
			return fallback


func _player_action_pose(skill: Skill) -> String:
	if skill.skill_id == &"basic_attack":
		return "attack_fist" if _player_weapon_type() == &"palm" else ""
	if skill.get_bonus_weapon_style() == &"palm" or skill.martial_category == &"palm" or skill.animation_id == &"crimson_palm":
		return "attack_palm"
	return ""


func _load_player_hit_frames() -> Array[Texture2D]:
	return _load_player_frames("hit")


func _load_player_defeat_frames() -> Array[Texture2D]:
	return _load_player_frames("defeat")


func _player_weapon_type() -> StringName:
	var weapon := Inventory.get_equipped(Equipment.Slot.WEAPON)
	if weapon != null and weapon.weapon_type != &"":
		return _normalized_player_weapon_type(weapon.weapon_type)
	return &"palm"


func _basic_attack_weapon_type(stats: CharacterStats, enemy_def: EnemyDef = null) -> StringName:
	var style: StringName = &"" if enemy_def != null else &"palm"
	if stats != null:
		var equipped := Inventory.get_equipped_for(StringName(stats.character_id), Equipment.Slot.WEAPON)
		if equipped != null:
			style = Equipment.normalize_weapon_type(equipped.weapon_type)
		elif stats.weapon_specialty != &"":
			style = Equipment.normalize_weapon_type(stats.weapon_specialty)
	# EnemyDef does not historically declare a weapon type.  Infer it from the
	# first authored technique that has an explicit weapon/category contract.
	if style in [&"", &"palm"] and enemy_def != null:
		for skill_id: StringName in enemy_def.skill_ids:
			if skill_id == &"basic_attack":
				continue
			var authored_skill := _load_skill(skill_id)
			if authored_skill == null:
				continue
			var authored_style: StringName = authored_skill.required_weapon_type
			if authored_style == &"":
				authored_style = authored_skill.martial_category
			if authored_style != &"":
				style = Equipment.normalize_weapon_type(authored_style)
				break
	return style


func _basic_attack_vfx_id(stats: CharacterStats, enemy_def: EnemyDef = null) -> StringName:
	match _basic_attack_weapon_type(stats, enemy_def):
		&"sword": return &"basic_sword"
		&"blade", &"dao", &"axe": return &"basic_blade"
		&"staff": return &"basic_staff"
		&"hidden", &"throwing", &"ring", &"dagger": return &"basic_hidden"
		_: return &"basic_palm"


func _resolved_vfx_id(skill: Skill, stats: CharacterStats, enemy_def: EnemyDef = null) -> StringName:
	if skill == null:
		return _basic_attack_vfx_id(stats, enemy_def)
	if skill.skill_id == &"basic_attack":
		return _basic_attack_vfx_id(stats, enemy_def)
	return skill.animation_id


func _normalized_player_weapon_type(weapon_type: StringName) -> StringName:
	match weapon_type:
		&"blade", &"dao", &"axe":
			return &"dao"
		&"staff":
			return &"staff"
		&"palm":
			return &"palm"
		&"hidden", &"throwing", &"ring", &"dagger":
			return &"hidden"
		_:
			return &"sword"


func _load_player_frames(state_name: String) -> Array[Texture2D]:
	var weapon_type := _player_weapon_type()
	var root := "%s/%s" % [PLAYER_BATTLE_VARIANT_ROOT, String(weapon_type)]
	if weapon_type in [&"sword", &"dao"]:
		root = "res://art/sprites/battle/weapon_variants_v4/lengguyun/%s" % String(weapon_type)
	var prefix := "lengguyun_%s" % String(weapon_type)
	var frames := _load_standard_frames(root, prefix, state_name)
	if frames.size() == 4:
		return frames
	return _load_standard_frames(PLAYER_BATTLE_ROOT, "lengguyun", state_name)


func _on_battle_equipment_changed(slot: int, _item_id: StringName) -> void:
	if slot != Equipment.Slot.WEAPON:
		return
	# Battle inventory changes equipment after the formation has already been
	# built. Refresh both the legacy actor and the formation actor immediately;
	# otherwise the data changes while the visible combatant keeps the old weapon
	# until the next battle.
	_refresh_player_battle_weapon_actor(player_actor)
	if formation_view != null:
		_refresh_player_battle_weapon_actor(formation_view.get_actor(&"player"))


func _refresh_player_battle_weapon_actor(actor: BattleActor) -> void:
	if actor == null:
		return
	var ready_frames := _load_player_frames("ready")
	actor.configure(
		ready_frames[0] if not ready_frames.is_empty() else null,
		false,
		true,
		ready_frames,
		_load_player_frames("move"),
		_load_player_frames("attack"),
		_load_player_frames("hit"),
		_load_player_frames("defeat")
	)


func _load_standard_frames(root: String, prefix: String, state_name: String) -> Array[Texture2D]:
	var paths := PackedStringArray()
	for frame_index in range(1, 5):
		paths.append("%s/%s_%s_%02d.png" % [root, prefix, state_name, frame_index])
	return _load_texture_frames(paths)


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
	log_panel.anchor_left = 1.0
	log_panel.anchor_top = 1.0
	log_panel.anchor_right = 1.0
	log_panel.anchor_bottom = 1.0
	# The generated panel is a 3:2 frame. Keep the RichTextLabel inside this
	# single frame; do not place a second black panel or a floating title over it.
	log_panel.offset_left = -840
	log_panel.offset_top = -330
	log_panel.offset_right = -300
	log_panel.offset_bottom = -48
	action_panel.offset_left = -306
	action_panel.offset_top = -378
	action_panel.offset_right = -42
	action_panel.offset_bottom = -50

	if _turn_label == null:
		_turn_label = Label.new()
		_turn_label.name = "TurnLabel"
		_turn_label.layout_mode = 1
		_turn_label.anchor_left = 1.0
		_turn_label.anchor_right = 1.0
		_turn_label.offset_left = -820
		_turn_label.offset_top = -370
		_turn_label.offset_right = -300
		_turn_label.offset_bottom = -50
		_turn_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_turn_label.text = "遭遇战"
		_hud_canvas_layer.add_child(_turn_label)
	# Turn text is also written into BattleLog. Keeping this legacy label hidden
	# prevents a second text block from escaping the generated frame.
	_turn_label.visible = false

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
	log_panel.self_modulate = Color.WHITE
	log_panel.clip_contents = true
	battle_log.clip_contents = true
	battle_log.fit_content = false
	battle_log.scroll_active = true
	battle_log.scroll_following = true
	battle_log.add_theme_constant_override("line_separation", 5)
	var log_frame := _cropped_generated_texture_style(BATTLE_LOG_PANEL_PATH, 22.0, 72.0, 50.0, 44.0, 44.0)
	if log_frame != null:
		log_panel.add_theme_stylebox_override("panel", log_frame)
	else:
		log_panel.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.025, 0.045, 0.060, 0.72), Color(0.34, 0.66, 0.68, 0.86), 7, 1))
	UI_THEME.style_rich_text(battle_log, 18)
	# style_rich_text installs an opaque normal style. The generated frame is
	# the single panel here, so clear that duplicate inner background afterward.
	battle_log.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
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
		UI_THEME.style_button(b, 18, UI_THEME.TEXT)
		_apply_generated_command_style(b)
	btn_attack.text = "普通攻击"
	btn_defend.text = "防御架势"
	btn_flee.text = "切磋中" if _is_sparring_battle() else "撤离"
	action_panel.add_theme_constant_override("separation", 10)


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
	_refresh_command_button_visual(btn_skill)


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
		_hud_canvas_layer.add_child(overlay)
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
	# Formation battles hide the legacy single-target HUDs.  The decorative
	# overlays live directly under the HUD CanvasLayer, so they do not inherit
	# their target's visibility and used to remain as large empty orphan frames.
	overlay.visible = target.visible


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


func _cropped_generated_texture_style(path: String, inset: float, left: float, right: float, top: float, bottom: float) -> StyleBox:
	if not ResourceLoader.exists(path):
		return null
	var source: Texture2D = load(path) as Texture2D
	if source == null:
		return null
	var width: float = float(source.get_width()) - inset * 2.0
	var height: float = float(source.get_height()) - inset * 2.0
	if width <= 0.0 or height <= 0.0:
		return null
	var cropped: AtlasTexture = AtlasTexture.new()
	cropped.atlas = source
	cropped.region = Rect2(inset, inset, width, height)
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = cropped
	style.texture_margin_left = left
	style.texture_margin_right = right
	style.texture_margin_top = top
	style.texture_margin_bottom = bottom
	style.content_margin_left = 50.0
	style.content_margin_right = 34.0
	style.content_margin_top = 54.0
	style.content_margin_bottom = 28.0
	return style


func _apply_generated_command_style(button: Button) -> void:
	if button == null:
		return
	var normal := _generated_texture_style(BATTLE_COMMAND_NORMAL_PATH, 48.0, 48.0, 30.0, 30.0)
	var hover := _generated_texture_style(BATTLE_COMMAND_HOVER_PATH, 48.0, 48.0, 30.0, 30.0)
	var pressed := _generated_texture_style(BATTLE_COMMAND_PRESSED_PATH, 48.0, 48.0, 30.0, 30.0)
	if normal == null or hover == null or pressed == null:
		return
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_hover_color", UI_THEME.GOLD_LIGHT)
	button.add_theme_color_override("font_pressed_color", UI_THEME.JADE)
	button.icon = null
	if not button.has_meta("battle_hover_bound"):
		button.set_meta("battle_hover_bound", true)
		button.mouse_entered.connect(_refresh_command_button_visual.bind(button))
		button.mouse_exited.connect(_refresh_command_button_visual.bind(button))
		button.button_down.connect(_refresh_command_button_visual.bind(button))
		button.button_up.connect(_refresh_command_button_visual.bind(button))
	_refresh_command_button_visual(button)


func _refresh_command_button_visual(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	if button.disabled:
		button.modulate = Color(0.52, 0.56, 0.60, 0.78)
		return
	if button.button_pressed:
		button.modulate = Color(0.78, 1.0, 0.98, 1.0)
	elif button.is_hovered():
		button.modulate = Color(0.72, 1.0, 1.0, 1.0)
	else:
		button.modulate = Color.WHITE


func _apply_generated_skill_row_style(button: Button) -> void:
	if button == null:
		return
	var normal := _generated_texture_style(BATTLE_SKILL_ROW_PATH, 58.0, 58.0, 34.0, 34.0)
	if normal == null:
		return
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_hover_color", UI_THEME.GOLD_LIGHT)
	button.add_theme_color_override("font_pressed_color", UI_THEME.JADE)


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
		_cancel_boss_windup(_team_active_unit)
		await _team_after_action()
		return
	if _team_active_unit.team == BattleCombatant.Team.ALLY:
		_team_active_unit.action_points = 1
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
	var active_stats: CharacterStats = _team_active_unit.stats
	var active_skills := _skills_for_stats(active_stats)
	if skill_idx < 0 or skill_idx >= active_skills.size():
		return
	var skill: Skill = active_skills[skill_idx]
	if active_stats == null or not _can_use_skill(skill, active_stats):
		return
	var targets_allies := skill.target in [Skill.Target.ALLY_SINGLE, Skill.Target.ALLY_ALL, Skill.Target.SELF]
	var living_targets: Array[BattleCombatant] = _team_living_allies() if targets_allies else _team_living_enemies()
	if skill.target == Skill.Target.SELF:
		living_targets = [_team_active_unit]
	var is_group_target := skill.target in [Skill.Target.ENEMY_ALL, Skill.Target.ALLY_ALL, Skill.Target.SELF]
	if forced_target == &"" and not is_group_target and living_targets.size() > 1:
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
		var selected: BattleCombatant = _team_find_ally(forced_target) if targets_allies else _team_find_enemy(forced_target)
		if selected != null:
			targets.append(selected)
	elif not is_group_target and not living_targets.is_empty():
		targets.append(living_targets[0])
	else:
		targets.append_array(living_targets)
	var use_legendary_cinematic := _uses_legendary_cinematic(skill)
	if use_legendary_cinematic:
		await legendary_cinematic.play_intro(skill)
		# The title/mask is only the prelude. Restore the battlefield before the
		# actor starts moving, then keep the cinematic root alive for the later
		# authored full-screen impact.
		await legendary_cinematic.reveal_battlefield()
	if skill.kind == Skill.Kind.HEAL or skill.kind == Skill.Kind.BUFF:
		var active_actor: BattleActor = _team_actor(_team_active_unit.unit_id)
		if active_actor != null:
			_configure_actor_action_timing(active_actor, skill)
			_play_skill_sfx(_skill_cast_sfx(skill))
			await active_actor.play_cast()
		var support_actors := _team_actors_for_targets(targets)
		var simultaneous_support := targets.size() > 1 and skill.target == Skill.Target.ALLY_ALL
		if active_actor != null and not support_actors.is_empty():
			if simultaneous_support:
				await battle_vfx_layer.play_for_skill_group(skill.animation_id, support_actors, active_actor)
			else:
				await battle_vfx_layer.play_for_skill(skill.animation_id, support_actors[0], active_actor)
		# There are deliberately no awaits in this loop: every heal, cleanse and
		# buff is committed during the same impact frame.
		for target: BattleCombatant in targets:
			if target == null or not target.alive:
				continue
			var before := target.stats.hp
			if skill.skill_id == &"qinghe_returning_breath":
				_team_clear_ailments(target, ["poison", "venom", "internal_injury", "internal_lock"], skill.display_name)
			if skill.kind == Skill.Kind.HEAL or skill.active_effect_type == &"heal_guard":
				var effective_inner := active_stats.inner_power + Inventory.get_attribute_bonus_for(StringName(active_stats.character_id), &"get_inner_power_bonus")
				var heal_amount := maxi(1, skill.get_active_effect_value(_skill_mastery_for_stats(skill, active_stats)) + effective_inner * 4)
				target.stats.heal(heal_amount)
			if skill.kind == Skill.Kind.BUFF:
				_team_apply_player_buff(_team_active_unit, target, skill)
			if target.stats.hp > before:
				_log("→ %s 施展 [b]%s[/b]，%s 恢复 [color=#72d2a6]%d[/color] 气血" % [active_stats.display_name, skill.display_name, target.display_name, target.stats.hp - before])
			if skill.kind == Skill.Kind.BUFF:
				_log("→ %s 施展 [b]%s[/b]，%s 获得招式效果" % [active_stats.display_name, skill.display_name, target.display_name])
		_refresh_hud()
		_sync_team_health()
		if use_legendary_cinematic:
			await legendary_cinematic.finish()
		await _team_finish_player_action()
		return
	var active_actor: BattleActor = _team_actor(_team_active_unit.unit_id)
	if active_actor == null:
		if use_legendary_cinematic:
			await legendary_cinematic.finish()
		await _team_finish_player_action()
		return
	var is_protagonist: bool = _team_active_unit.unit_id == &"player"
	_configure_actor_action_timing(active_actor, skill)
	active_actor.set_action_frames(
		_action_frames_for(skill.animation_id, active_actor.default_attack_frames, is_protagonist),
		_player_action_pose(skill) if is_protagonist else ""
	)
	_arm_skill_strike_audio(active_actor, skill)
	if not _skill_uses_approach(skill) and not targets.is_empty():
		var cast_target_actor: BattleActor = _team_actor(targets[0].unit_id)
		if skill.delivery == Skill.Delivery.STATIONARY_AOE:
			await active_actor.play_stationary_attack(cast_target_actor, true)
		else:
			await active_actor.play_stationary_attack(cast_target_actor, skill.skill_id != &"basic_attack")
	var use_fullscreen_impact := use_legendary_cinematic and skill.target == Skill.Target.ENEMY_ALL and legendary_cinematic.has_fullscreen_effect(skill.skill_id) and not BattleVfxPlayer.has_dragon_wave(skill.animation_id)
	if use_fullscreen_impact:
		await legendary_cinematic.play_fullscreen_effect(skill.skill_id, _skill_impact_sfx(skill))
	var simultaneous_damage := targets.size() > 1 and skill.target == Skill.Target.ENEMY_ALL
	if simultaneous_damage:
		await _team_execute_player_group_damage(skill, targets, active_actor, use_fullscreen_impact)
	else:
		for target: BattleCombatant in targets:
			var target_actor: BattleActor = _team_actor(target.unit_id)
			if target_actor == null:
				continue
			if _skill_uses_approach(skill):
				await _play_skill_approach(active_actor, target_actor, skill)
			if not use_fullscreen_impact:
				_play_skill_sfx(_skill_impact_sfx(skill))
				await battle_vfx_layer.play_for_skill(_resolved_vfx_id(skill, active_stats), target_actor, active_actor)
			var damage: int = _calc_team_player_skill_damage(skill, _team_active_unit, target)
			var was_critical: bool = _last_damage_was_critical
			var attack_missed := _last_attack_missed
			var dealt: int = target.stats.take_damage(damage)
			if attack_missed:
				await target_actor.play_dodge(active_actor)
			elif dealt > 0:
				_team_apply_player_skill_status(_team_active_unit, target, skill)
				_team_apply_skill_status_data(_team_active_unit, target, skill)
				_team_apply_internal_injury(target, skill, _team_active_unit)
				_team_apply_internal_art_target_effect(_team_active_unit, target, skill)
				_team_apply_weapon_special(_team_active_unit, target)
				_team_apply_internal_art_self_effect(_team_active_unit, skill)
				await target_actor.play_hit(dealt, was_critical, _has_distinct_hit_sfx(target.get_audio_path(&"hit")), active_actor)
			if _skill_uses_approach(skill):
				await active_actor.play_attack_recover()
			if dealt > 0:
				_log("→ %s 对 %s 造成 [color=#ffb14a]%d[/color] 伤害" % [skill.display_name, target.display_name, dealt])
			else:
				_log("→ %s 未命中 %s" % [skill.display_name, target.display_name])
			if target.stats.is_dead():
				target.alive = false
				await target_actor.play_defeat()
	_refresh_hud()
	_sync_team_health()
	if use_legendary_cinematic:
		await legendary_cinematic.finish()
	await _team_finish_player_action()


func _on_team_target_selected(unit_id: StringName) -> void:
	if _team_pending_skill_index < 0:
		return
	var skill_index := _team_pending_skill_index
	_team_pending_skill_index = -1
	_team_player_action_skill_use(skill_index, unit_id)


func _team_execute_player_group_damage(skill: Skill, targets: Array[BattleCombatant], active_actor: BattleActor, use_fullscreen_impact: bool) -> void:
	var target_actors := _team_actors_for_targets(targets)
	if target_actors.is_empty():
		return
	if _skill_uses_approach(skill):
		await _play_skill_approach(active_actor, target_actors[int(target_actors.size() / 2)] as BattleActor, skill)
	if not use_fullscreen_impact:
		_play_skill_sfx(_skill_impact_sfx(skill))
		await battle_vfx_layer.play_for_skill_group(skill.animation_id, target_actors, active_actor)
	var hit_entries: Array[Dictionary] = []
	var defeated_actors: Array[BattleActor] = []
	var landed_any_hit := false
	# Damage, status and resource changes are all committed without an await.
	for target: BattleCombatant in targets:
		var target_actor := _team_actor(target.unit_id)
		if target_actor == null:
			continue
		var damage := _calc_team_player_skill_damage(skill, _team_active_unit, target)
		var was_critical := _last_damage_was_critical
		var attack_missed := _last_attack_missed
		var dealt := target.stats.take_damage(damage)
		if attack_missed:
			hit_entries.append({"actor": target_actor, "dodged": true, "source": active_actor})
		elif dealt > 0:
			landed_any_hit = true
			_team_apply_player_skill_status(_team_active_unit, target, skill)
			_team_apply_skill_status_data(_team_active_unit, target, skill)
			_team_apply_internal_injury(target, skill, _team_active_unit)
			_team_apply_internal_art_target_effect(_team_active_unit, target, skill)
			_team_apply_weapon_special(_team_active_unit, target)
			hit_entries.append({"actor": target_actor, "damage": dealt, "critical": was_critical, "source": active_actor, "hit_sfx_path": target.get_audio_path(&"hit")})
			_log("→ %s 对 %s 造成 [color=#ffb14a]%d[/color] 伤害" % [skill.display_name, target.display_name, dealt])
		else:
			_log("→ %s 未命中 %s" % [skill.display_name, target.display_name])
		if target.stats.is_dead():
			target.alive = false
			defeated_actors.append(target_actor)
	# 群攻只按一次招式结算自身回复，不能随命中目标数成倍回气回血。
	if landed_any_hit:
		_team_apply_internal_art_self_effect(_team_active_unit, skill)
	_sync_team_health()
	await _team_play_simultaneous_hits(hit_entries)
	await _team_play_simultaneous_defeats(defeated_actors)
	if _skill_uses_approach(skill):
		await active_actor.play_attack_recover()


func _team_actors_for_targets(targets: Array[BattleCombatant]) -> Array[Control]:
	var actors: Array[Control] = []
	for target: BattleCombatant in targets:
		var actor := _team_actor(target.unit_id)
		if actor != null:
			actors.append(actor)
	return actors


func _team_play_simultaneous_hits(entries: Array[Dictionary]) -> void:
	var longest := 0.0
	var played_sounds: Dictionary = {}
	for entry: Dictionary in entries:
		var actor := entry.get("actor") as BattleActor
		if actor == null:
			continue
		if bool(entry.get("dodged", false)):
			longest = maxf(longest, actor.start_dodge_reaction(entry.get("source") as Control))
		else:
			var path: String = entry.get("hit_sfx_path", "")
			var play_sound := _has_distinct_hit_sfx(path) and not played_sounds.has(path)
			if play_sound:
				played_sounds[path] = true
			longest = maxf(longest, actor.start_hit_reaction(int(entry.get("damage", 0)), bool(entry.get("critical", false)), play_sound, entry.get("source") as Control))
	if longest > 0.0:
		await get_tree().create_timer(longest).timeout


func _team_play_simultaneous_defeats(actors: Array[BattleActor]) -> void:
	var longest := 0.0
	for actor: BattleActor in actors:
		if actor != null:
			longest = maxf(longest, actor.start_defeat_reaction())
	if longest > 0.0:
		await get_tree().create_timer(longest).timeout


func _do_team_enemy_turn() -> void:
	var targets: Array[BattleCombatant] = _team_living_allies()
	if targets.is_empty():
		_team_finish(false)
		return
	var enemy: BattleCombatant = _team_active_unit
	var def: EnemyDef = _load_enemy(String(enemy.definition_id))
	var attacker: BattleActor = _team_actor(enemy.unit_id)
	if attacker == null:
		await _team_after_action()
		return
	var primary_target: BattleCombatant = targets[randi() % targets.size()]
	var skill_id: StringName
	if int(enemy.status_effects.get("internal_lock", 0)) > 0:
		_cancel_boss_windup(enemy)
		skill_id = &"basic_attack"
	elif not _is_sparring_battle() and StoryBossTactics.PROFILES.has(enemy.definition_id):
		var action := _story_boss_tactics.decide(enemy, _enemy_usable_skills(enemy.stats), primary_target.unit_id)
		skill_id = action.skill
		if action.phase_changed:
			_log("[color=#ffba83]%s 改换架势，攻势加紧！[/color]" % enemy.display_name)
		var boss_skill := _load_skill(skill_id)
		if action.beat != StoryBossTactics.Beat.WINDUP:
			attacker.clear_held_windup()
		match action.beat:
			StoryBossTactics.Beat.WINDUP:
				var target_name := "全体" if boss_skill.target == Skill.Target.ENEMY_ALL else primary_target.display_name
				var profile: Dictionary = StoryBossTactics.PROFILES[enemy.definition_id]
				var warning := "%s · %s" % [boss_skill.display_name, target_name]
				if boss_skill.skill_id == &"ch8_su_teapot_meridian_rain":
					warning = "壶雨封脉 · 防御避毒"
				formation_view.show_boss_warning(enemy.unit_id, warning)
				_log("[color=#ffba83]%s%s，下次行动将施展「%s」（%s）。[/color]" % [enemy.display_name, profile.cue, boss_skill.display_name, target_name])
				attacker.set_action_frames(EnemySignatureFrames.resolve(def.enemy_id, boss_skill, attacker.default_attack_frames))
				await attacker.play_boss_windup(_team_actor(primary_target.unit_id), _skill_uses_approach(boss_skill), skill_id == &"mingwu_counterseal_needles")
				await _team_after_action()
				return
			StoryBossTactics.Beat.RELEASE:
				formation_view.show_boss_warning(enemy.unit_id, "")
				if boss_skill.target != Skill.Target.ENEMY_ALL:
					primary_target = _team_find_ally(action.target)
				if primary_target == null or not primary_target.alive:
					_log("%s失去锁定目标，蓄势散去。" % enemy.display_name)
					await _team_after_action()
					return
				_log("[color=#ff9c72]%s 施展「%s」！[/color]" % [enemy.display_name, boss_skill.display_name])
			_:
				formation_view.show_boss_warning(enemy.unit_id, "")
	else:
		skill_id = _enemy_choose_skill_for(def, enemy.stats)
	var skill := _load_skill(skill_id)
	if skill != null:
		enemy.stats.mp = maxi(0, enemy.stats.mp - skill.mp_cost)
	var action_targets: Array[BattleCombatant] = []
	if skill != null and skill.target == Skill.Target.ENEMY_ALL:
		action_targets.append_array(targets)
	else:
		action_targets.append(primary_target)
	_configure_actor_action_timing(attacker, skill)
	attacker.set_action_frames(EnemySignatureFrames.resolve(def.enemy_id, skill, attacker.default_attack_frames))
	_arm_skill_strike_audio(attacker, skill)
	if not _skill_uses_approach(skill) and not action_targets.is_empty():
		var cast_target: BattleActor = _team_actor(action_targets[0].unit_id)
		await attacker.play_stationary_attack(cast_target, skill != null and skill.skill_id != &"basic_attack")
	var simultaneous_enemy_damage := skill != null and skill.target == Skill.Target.ENEMY_ALL and action_targets.size() > 1
	if simultaneous_enemy_damage:
		await _team_execute_enemy_group_damage(skill, skill_id, enemy, action_targets, attacker)
	else:
		for target: BattleCombatant in action_targets:
			var defender: BattleActor = _team_actor(target.unit_id)
			if defender == null:
				continue
			if _skill_uses_approach(skill):
				await _play_skill_approach(attacker, defender, skill)
			if skill != null:
				_play_skill_sfx(_skill_impact_sfx(skill))
				await battle_vfx_layer.play_for_skill(_resolved_vfx_id(skill, enemy.stats, def), defender, attacker)
			else:
				_play_skill_sfx(AudioManager.DEFAULT_HIT_SFX)
			var damage: int = _calc_team_enemy_skill_damage(skill, enemy, target)
			var was_critical: bool = _last_damage_was_critical
			var attack_missed := _last_attack_missed
			var guarded: bool = not attack_missed and int(target.status_effects.get("guard", 0)) > 0
			if guarded:
				damage = maxi(1, int(round(float(damage) * 0.5)))
				target.status_effects.erase("guard")
			var reflected_damage := 0
			var redirect_percent := int(target.status_effects.get("redirect_percent", 0))
			if not attack_missed and int(target.status_effects.get("redirect", 0)) > 0 and redirect_percent > 0:
				reflected_damage = maxi(1, int(round(float(damage) * float(redirect_percent) / 100.0)))
				damage = maxi(1, damage - reflected_damage)
				target.status_effects.erase("redirect")
				target.status_effects.erase("redirect_percent")
			var dealt: int = target.stats.take_damage(damage)
			if attack_missed:
				await defender.play_dodge(attacker)
			elif dealt > 0:
				await defender.play_hit(dealt, was_critical, false, attacker)
			if reflected_damage > 0:
				var reflected := enemy.stats.take_damage(reflected_damage)
				await attacker.play_hit(reflected, false, true, defender)
				_log("  [color=#72d2c9][回澜] %s 化去攻势并返还 %d 点伤害[/color]" % [target.display_name, reflected])
				if enemy.stats.is_dead():
					enemy.alive = false
			if _skill_uses_approach(skill):
				await attacker.play_attack_recover()
			if not enemy.alive and not _is_nonlethal_story_boss(def):
				await attacker.play_defeat()
			if dealt > 0:
				_team_enemy_hit_effects(enemy, target, skill, skill_id, dealt, guarded)
			else:
				_log("← %s 未命中 %s" % [enemy.display_name, target.display_name])
			if target.stats.is_dead():
				target.alive = false
				await defender.play_defeat()
	_refresh_hud()
	_sync_team_health()
	await _team_after_action()


func _cancel_boss_windup(unit: BattleCombatant) -> void:
	if not _story_boss_tactics.cancel(unit.unit_id):
		return
	var actor := _team_actor(unit.unit_id)
	if actor != null:
		actor.clear_held_windup()
	formation_view.show_boss_warning(unit.unit_id, "")
	if unit.alive:
		_log("[color=#ffba83]%s 的蓄势被打断。[/color]" % unit.display_name)


func _team_execute_enemy_group_damage(skill: Skill, skill_id: StringName, enemy: BattleCombatant, targets: Array[BattleCombatant], attacker: BattleActor) -> void:
	var target_actors := _team_actors_for_targets(targets)
	if target_actors.is_empty():
		return
	if _skill_uses_approach(skill):
		await _play_skill_approach(attacker, target_actors[int(target_actors.size() / 2)] as BattleActor, skill)
	_play_skill_sfx(_skill_impact_sfx(skill))
	await battle_vfx_layer.play_for_skill_group(skill.animation_id, target_actors, attacker)
	var hit_entries: Array[Dictionary] = []
	var defeated_actors: Array[BattleActor] = []
	var reflected_total := 0
	var is_teapot_rain := skill_id == &"ch8_su_teapot_meridian_rain"
	var opened_stance := false
	# Resolve every defender in one frame; animation waits happen only afterward.
	for target: BattleCombatant in targets:
		var defender := _team_actor(target.unit_id)
		if defender == null:
			continue
		var damage := _calc_team_enemy_skill_damage(skill, enemy, target)
		var was_critical := _last_damage_was_critical
		var attack_missed := _last_attack_missed
		var guarded: bool = not attack_missed and int(target.status_effects.get("guard", 0)) > 0
		if guarded:
			var received := 0.2 if is_teapot_rain else 0.5
			damage = maxi(1, roundi(float(damage) * received))
			opened_stance = opened_stance or is_teapot_rain
			target.status_effects.erase("guard")
		var reflected_damage := 0
		var redirect_percent := int(target.status_effects.get("redirect_percent", 0))
		if not attack_missed and int(target.status_effects.get("redirect", 0)) > 0 and redirect_percent > 0:
			reflected_damage = maxi(1, int(round(float(damage) * float(redirect_percent) / 100.0)))
			damage = maxi(1, damage - reflected_damage)
			target.status_effects.erase("redirect")
			target.status_effects.erase("redirect_percent")
		var dealt := target.stats.take_damage(damage)
		if attack_missed:
			hit_entries.append({"actor": defender, "dodged": true, "source": attacker})
		elif dealt > 0:
			hit_entries.append({"actor": defender, "damage": dealt, "critical": was_critical, "source": attacker})
			_team_enemy_hit_effects(enemy, target, skill, skill_id, dealt, guarded)
		else:
			_log("← %s 未命中 %s" % [enemy.display_name, target.display_name])
		if reflected_damage > 0:
			var reflected := enemy.stats.take_damage(reflected_damage)
			reflected_total += reflected
			_log("  [color=#72d2c9][回澜] %s 化去攻势并返还 %d 点伤害[/color]" % [target.display_name, reflected])
		if target.stats.is_dead():
			target.alive = false
			defeated_actors.append(defender)
	if opened_stance:
		enemy.status_effects["vulnerable"] = maxi(2, int(enemy.status_effects.get("vulnerable", 0)))
		enemy.status_effects["vulnerable_percent"] = maxi(45, int(enemy.status_effects.get("vulnerable_percent", 0)))
		_log("茶雨被架开，苏雾笙空门大露！此时追击伤害提高 45%，同时受装备与心法增幅的招式另加三成半。")
	_sync_team_health()
	await _team_play_simultaneous_hits(hit_entries)
	await _team_play_simultaneous_defeats(defeated_actors)
	if reflected_total > 0:
		await attacker.play_hit(reflected_total, false, true, target_actors[0])
	if _skill_uses_approach(skill):
		await attacker.play_attack_recover()
	if enemy.stats.is_dead():
		enemy.alive = false
		if not _is_nonlethal_story_boss(_load_enemy(String(enemy.definition_id))):
			await attacker.play_defeat()


func _skill_uses_approach(skill: Skill) -> bool:
	if skill == null:
		return true
	if skill.skill_id == &"basic_attack" and (not _team_mode or (_team_active_unit != null and _team_active_unit.unit_id == &"player")):
		var equipped := Inventory.get_equipped(Equipment.Slot.WEAPON)
		return equipped == null or Equipment.normalize_weapon_type(equipped.weapon_type) != &"hidden"
	if skill.motion_style == Skill.MotionStyle.STATIONARY:
		return false
	if skill.motion_style >= Skill.MotionStyle.APPROACH:
		return true
	return skill.delivery == Skill.Delivery.MELEE


func _uses_legendary_cinematic(skill: Skill) -> bool:
	return skill != null and not skill.is_passive and skill.quality == Skill.Quality.LEGENDARY and legendary_cinematic != null


func _play_skill_approach(actor: BattleActor, target: BattleActor, skill: Skill) -> void:
	if actor == null or target == null:
		return
	if actor.HERO_COMBAT.available(actor):
		await actor.play_attack_approach(target, skill != null and skill.skill_id != &"basic_attack")
		return
	if skill != null:
		if skill.skill_id == &"wolf_king_pounce":
			await actor.play_boss_pounce(target)
			return
		match skill.motion_style:
			Skill.MotionStyle.DASH_THROUGH:
				await actor.play_shadow_dash_through(target, true)
				return
			Skill.MotionStyle.SHADOW_FLURRY:
				var has_signature := actor.attack_frames != actor.default_attack_frames
				await actor.play_shadow_flurry(target, true, has_signature or skill.skill_id in [&"ch8_xueying_shadow_fan", &"fake_liuyun_return_cut"])
				return
	await actor.play_attack_approach(target, skill != null and skill.skill_id != &"basic_attack")


func _configure_actor_action_timing(actor: BattleActor, skill: Skill) -> void:
	if actor == null:
		return
	actor.action_skill = skill
	actor.legendary_choreography = actor.unit_id == &"player" and skill != null and skill.quality == Skill.Quality.LEGENDARY and skill.kind in [Skill.Kind.ATTACK, Skill.Kind.DEBUFF]
	if actor.unit_id == &"player":
		actor.set_action_time_scale(0.82)
		return
	if skill == null or skill.skill_id == &"basic_attack":
		actor.set_action_time_scale(1.12)
	elif skill.quality == Skill.Quality.LEGENDARY:
		actor.set_action_time_scale(1.42)
	elif skill.target in [Skill.Target.ENEMY_ALL, Skill.Target.ALLY_ALL] or skill.delivery == Skill.Delivery.STATIONARY_AOE:
		actor.set_action_time_scale(1.30)
	elif skill.motion_style in [Skill.MotionStyle.DASH_THROUGH, Skill.MotionStyle.SHADOW_FLURRY]:
		actor.set_action_time_scale(1.20)
	else:
		actor.set_action_time_scale(1.18)


func _team_enemy_hit_effects(enemy: BattleCombatant, target: BattleCombatant, skill: Skill, skill_id: StringName, dealt: int, guarded: bool) -> void:
	if enemy.enemy_definition != null and enemy.enemy_definition.poison_weapons:
		target.status_effects["poison"] = maxi(int(target.status_effects.get("poison", 0)), 3)
		_log("← %s 对 %s 造成 [color=#a4c987]%d 点毒伤[/color]，针毒留存三回合。" % [enemy.display_name, target.display_name, dealt])
		return
	_log("← %s 对 %s 造成 [color=#ff6e6e]%d[/color] 伤害" % [enemy.display_name, target.display_name, dealt])
	_team_apply_status(target, skill_id)
	if not (guarded and skill_id == &"ch8_su_teapot_meridian_rain"):
		_team_apply_skill_status_data(enemy, target, skill, guarded)
	_team_apply_internal_injury(target, skill, enemy)


func _team_apply_status(target: BattleCombatant, skill_id: StringName) -> void:
	match String(skill_id):
		"toxic_needle":
			target.status_effects["poison"] = 3
			_log("[color=#72d2a6]%s 陷入中毒（3回合）[/color]" % target.display_name)
		"heavy_swing":
			target.status_effects["weaken"] = 2
			_log("[color=#cc8844]%s 陷入虚弱（2回合）[/color]" % target.display_name)
	_sync_team_health()


func _team_apply_player_skill_status(source: BattleCombatant, target: BattleCombatant, skill: Skill) -> void:
	match String(skill.skill_id):
		"gufeng_fuhu":
			if randf() < 0.25: target.status_effects["weaken"] = 2
		"huashan_poyun":
			if randf() < 0.30: target.status_effects["weaken"] = 2
		"canghai_zhenyue_palms":
			target.status_effects["weaken"] = 2
		"mingwu_saofeng", "mingwu_wuyin_sanshi":
			source.status_effects["burst"] = 2 # Current action + one following action.
	_sync_team_health()


func _team_apply_skill_status_data(source: BattleCombatant, target: BattleCombatant, skill: Skill, guarded: bool = false) -> void:
	if target == null or skill == null:
		return
	var status_key := String(skill.inflicted_status)
	if source != null and source.enemy_definition != null and source.enemy_definition.finisher_affliction != "none":
		var profile: Dictionary = StoryBossTactics.PROFILES.get(source.definition_id, {})
		if skill.skill_id == profile.get("finisher", &""):
			match source.enemy_definition.finisher_affliction:
				"venom":
					if not guarded:
						status_key = "venom"
				"seal":
					_team_add_internal_injury(target, 50 if guarded else 100)
	if status_key.is_empty() or skill.status_duration <= 0:
		return
	if skill.status_chance > 0.0 and randf() > skill.status_chance:
		return
	target.status_effects[status_key] = maxi(int(target.status_effects.get(status_key, 0)), skill.status_duration)
	if status_key == "vulnerable":
		target.status_effects["vulnerable_percent"] = maxi(int(target.status_effects.get("vulnerable_percent", 0)), skill.get_effect_value() if skill.get_effect_value() > 0 else 20)
	elif status_key == "armor_break":
		var percent := clampi(skill.get_effect_value() if skill.get_effect_value() > 0 else 20, 1, 80)
		target.status_effects["armor_break_percent"] = maxi(int(target.status_effects.get("armor_break_percent", 0)), percent)
	var status_name: String = String({"venom": "烈毒", "poison": "中毒", "bleed": "流血", "weaken": "虚弱", "vulnerable": "易伤", "stun": "眩晕", "freeze": "冰冻", "armor_break": "破甲", "internal_lock": "封脉"}.get(status_key, status_key))
	_log("[color=#d98b8b]%s 陷入%s（%d回合）[/color]" % [target.display_name, status_name, skill.status_duration])


func _team_apply_internal_injury(target: BattleCombatant, skill: Skill, source: BattleCombatant = null) -> void:
	if target == null or skill == null or skill.damage_type != Skill.DamageType.INTERNAL:
		return
	var gain := skill.internal_injury_gain
	if gain <= 0:
		gain = 12 + clampi(skill.quality, 0, 4) * 4
	if source != null and source.team == BattleCombatant.Team.ALLY:
		gain += int(GameState.get_equipped_internal_art_bonus(source.stats, skill).get("internal_injury", 0))
	_team_add_internal_injury(target, gain, 90 if _office_victory_action in OFFICE_PATROL_VICTORIES and target.team == BattleCombatant.Team.ALLY else 100)


func _team_apply_internal_art_target_effect(source: BattleCombatant, target: BattleCombatant, skill: Skill) -> void:
	if source == null or source.team != BattleCombatant.Team.ALLY or source.stats == null or target == null or skill == null:
		return
	var bonus := GameState.get_equipped_internal_art_bonus(source.stats, skill)
	var status := StringName(bonus.get("target_status", &""))
	var duration := int(bonus.get("target_status_duration", 0))
	var chance := float(bonus.get("target_status_chance", 0.0))
	if status == &"" or duration <= 0 or chance <= 0.0 or randf() > chance:
		return
	target.status_effects[String(status)] = maxi(int(target.status_effects.get(String(status), 0)), duration)
	var value := int(bonus.get("target_status_value", 0))
	if status == &"armor_break":
		target.status_effects["armor_break_percent"] = maxi(int(target.status_effects.get("armor_break_percent", 0)), clampi(value if value > 0 else 20, 1, 80))
	elif status == &"vulnerable":
		target.status_effects["vulnerable_percent"] = maxi(int(target.status_effects.get("vulnerable_percent", 0)), clampi(value if value > 0 else 20, 1, 100))
	var names := {&"armor_break": "破防", &"vulnerable": "易伤", &"weaken": "虚弱", &"poison": "中毒", &"bleed": "流血"}
	var art := GameState.get_equipped_internal_art(source.stats)
	_log("[color=#c9a7ff][心法协同] %s令%s陷入%s（%d回合）[/color]" % [art.display_name if art != null else "心法", target.display_name, String(names.get(status, status)), duration])


func _team_apply_internal_art_self_effect(source: BattleCombatant, skill: Skill) -> void:
	if source == null or source.team != BattleCombatant.Team.ALLY or source.stats == null or skill == null:
		return
	var bonus := GameState.get_equipped_internal_art_bonus(source.stats, skill)
	var hp_restore := int(bonus.get("self_hp_restore", 0))
	var mp_restore := int(bonus.get("self_mp_restore", 0))
	var old_hp := source.stats.hp
	var old_mp := source.stats.mp
	if hp_restore > 0:
		source.stats.heal(hp_restore)
	if mp_restore > 0:
		source.stats.mp = mini(source.stats.max_mp, source.stats.mp + mp_restore)
	var healed := source.stats.hp - old_hp
	var restored_mp := source.stats.mp - old_mp
	if healed > 0 or restored_mp > 0:
		var parts := PackedStringArray()
		if healed > 0:
			parts.append("生命 +%d" % healed)
		if restored_mp > 0:
			parts.append("内力 +%d" % restored_mp)
		var art := GameState.get_equipped_internal_art(source.stats)
		_log("[color=#72d2a6][心法回息] %s：%s[/color]" % [art.display_name if art != null else source.display_name, "、".join(parts)])


func _charm_resistance(target: BattleCombatant, effect: StringName) -> float:
	if target.team == BattleCombatant.Team.ALLY:
		var charm := Inventory.get_equipped_for(StringName(target.stats.character_id), Equipment.Slot.ACCESSORY)
		if charm != null and charm.special_effect_type == effect:
			return clampf(charm.special_effect_value / 100.0, 0.0, 1.0)
	return 0.0


func _team_clear_ailments(target: BattleCombatant, keys: Array, treatment: String) -> void:
	var cleared := PackedStringArray()
	for key: String in keys:
		if int(target.status_effects.get(key, 0)) > 0:
			cleared.append(BattleFormationView.STATUS_VISUALS[key].name)
		target.status_effects.erase(key)
	if "vulnerable" in keys:
		target.status_effects.erase("vulnerable_percent")
	if "armor_break" in keys:
		target.status_effects.erase("armor_break_percent")
	if not cleared.is_empty():
		_log("%s 的%s已由%s解除。" % [target.display_name, "、".join(cleared), treatment])


func _team_add_internal_injury(target: BattleCombatant, gain: int, ceiling: int = 100) -> void:
	if target == null or gain <= 0:
		return
	if target.team == BattleCombatant.Team.ALLY:
		gain = roundi(gain * (1.0 - _charm_resistance(target, &"injury_resist")))
		var art := GameState.get_equipped_internal_art(target.stats)
		if art != null and art.incoming_injury_resist_percent > 0:
			gain = roundi(gain * (1.0 - art.incoming_injury_resist_percent / 100.0))
	var total := clampi(int(target.status_effects.get("internal_injury", 0)) + gain, 0, ceiling)
	target.status_effects["internal_injury"] = total
	_log("[color=#c9a7ff]%s 内伤累积至 %d/100[/color]" % [target.display_name, total])
	if total >= 100:
		target.status_effects["internal_injury"] = 0
		target.status_effects["internal_lock"] = 2
		_log("[color=#ff9e8a]%s 气脉闭塞，2回合无法施展招式[/color]" % target.display_name)


func _team_apply_weapon_special(source: BattleCombatant, target: BattleCombatant) -> void:
	if source == null or target == null or source.stats == null:
		return
	var weapon := Inventory.get_equipped_for(StringName(source.stats.character_id), Equipment.Slot.WEAPON)
	if weapon == null:
		return
	for affix: String in weapon.forge_affixes:
		var chance := 0.18 if affix == "bleed" else (0.16 if affix == "poison" else 0.0)
		if chance > 0.0 and randf() < chance:
			target.status_effects[affix] = maxi(int(target.status_effects.get(affix, 0)), 2)
			_log("[color=#dab58b]锻造效果 · %s[/color]" % ("锋痕：流血" if affix == "bleed" else "淬毒：中毒"))
	if weapon.special_effect_type == &"" or randf() >= weapon.special_effect_chance:
		return
	match weapon.special_effect_type:
		&"poison", &"bleed", &"weaken":
			var key := String(weapon.special_effect_type)
			target.status_effects[key] = maxi(int(target.status_effects.get(key, 0)), maxi(1, weapon.special_effect_duration))
		&"internal_injury":
			_team_add_internal_injury(target, maxi(1, weapon.special_effect_value))
		&"armor_break":
			target.status_effects["armor_break"] = maxi(int(target.status_effects.get("armor_break", 0)), maxi(1, weapon.special_effect_duration))
			target.status_effects["armor_break_percent"] = maxi(int(target.status_effects.get("armor_break_percent", 0)), clampi(weapon.special_effect_value, 1, 80))
		&"damage_boost":
			# 增伤在本次攻击结算后才被施加；额外保留一拍，避免
			# _team_after_action() 当场扣到 0，导致下一次攻击从未受益。
			source.status_effects["damage_boost"] = maxi(1, weapon.special_effect_duration) + 1
			source.status_effects["damage_boost_percent"] = clampi(weapon.special_effect_value if weapon.special_effect_value > 0 else 20, 1, 100)
		&"guard":
			source.status_effects["guard"] = maxi(1, weapon.special_effect_duration)
		&"heal":
			var before := source.stats.hp
			source.stats.heal(maxi(1, weapon.special_effect_value))
			_log("[color=#72d2a6]%s 回息，恢复 %d 点生命[/color]" % [source.display_name, source.stats.hp - before])
	if not weapon.special_effect_description.strip_edges().is_empty():
		var quality_colors := ["#c0c8d0", "#1eff00", "#4d8fff", "#b56cff", "#ff9b38"]
		var quality_color: String = quality_colors[clampi(weapon.quality, 0, quality_colors.size() - 1)]
		_log("[color=%s]◆ %s[/color]" % [quality_color, weapon.special_effect_description])
	_sync_team_health()


func _team_apply_player_buff(source: BattleCombatant, target: BattleCombatant, skill: Skill) -> void:
	var mastery := _skill_mastery_for_stats(skill, source.stats if source != null else null)
	var active_duration := skill.get_active_duration(mastery)
	match String(skill.skill_id):
		"qinghe_jade_guard":
			target.status_effects["guard"] = active_duration if active_duration > 0 else 1
			target.status_effects["poison_ward"] = 4 if source == target else 3
		"huashan_zixia_shengong", "huashan_zixia_ninggang", "lingyue_tayue_lingbo":
			source.status_effects["burst"] = active_duration + 1 if active_duration > 0 else 4 # Cast end decrements once.
		"gufeng_jingang_buhuai", "wudang_xuanwu_ge":
			target.status_effects.erase("weaken")
			target.status_effects["guard"] = active_duration if active_duration > 0 else 1
		"mingwu_mingwu_bu":
			source.status_effects["burst"] = 2
		"huilan_redirecting_art":
			target.status_effects["redirect"] = 1
			target.status_effects["redirect_percent"] = skill.get_active_effect_value(mastery)
		_:
			if skill.active_effect_type == &"damage_boost":
				# 主动运功自身占用一次行动；持续回合从下一次行动开始计算。
				source.status_effects["damage_boost"] = (active_duration if active_duration > 0 else 2) + 1
				source.status_effects["damage_boost_percent"] = clampi(skill.get_effect_value() if skill.get_effect_value() > 0 else 20, 1, 100)
			elif skill.get_effect_value() > 0:
				target.status_effects["guard"] = active_duration if active_duration > 0 else 1
	_sync_team_health()


func _team_apply_turn_start_status(unit: BattleCombatant) -> bool:
	if unit == null or not unit.alive:
		return true
	if int(unit.status_effects.get("field_breath", 0)) > 0:
		unit.stats.mp = mini(unit.stats.max_mp, unit.stats.mp + 12)
		unit.status_effects["field_breath"] = int(unit.status_effects["field_breath"]) - 1
	if int(unit.status_effects.get("field_guard", 0)) > 0:
		unit.status_effects["field_guard"] = int(unit.status_effects["field_guard"]) - 1
	var venom := int(unit.status_effects.get("venom", 0)) > 0
	if venom or int(unit.status_effects.get("poison", 0)) > 0:
		var poison := VENOM_STATUS if venom else POISON_STATUS
		var base_damage := maxi(4, roundi(unit.stats.max_hp * poison.effect_value))
		var poison_damage := maxi(1, roundi(base_damage * _poison_damage_multiplier(unit)))
		unit.stats.hp = max(0, unit.stats.hp - poison_damage)
		for key in ["poison", "venom"]:
			if int(unit.status_effects.get(key, 0)) > 0:
				unit.status_effects[key] -= 1
		_log("[color=#72d2a6]%s %s发作，受到%d点伤害[/color]" % [unit.display_name, "烈毒" if venom else "中毒", poison_damage])
		var poison_actor := _team_actor(unit.unit_id)
		if poison_actor != null:
			await poison_actor.play_hit(poison_damage, false)
		if unit.stats.is_dead():
			unit.alive = false
			if poison_actor != null:
				var poisoned_def: EnemyDef = null
				if unit.team == BattleCombatant.Team.ENEMY:
					poisoned_def = _load_enemy(String(unit.definition_id))
				if not _is_nonlethal_story_boss(poisoned_def):
					await poison_actor.play_defeat()
			_sync_team_health()
			return true
	if int(unit.status_effects.get("bleed", 0)) > 0:
		var bleed_damage: int = maxi(3, int(round(float(unit.stats.max_hp) * 0.04)))
		unit.stats.hp = max(0, unit.stats.hp - bleed_damage)
		unit.status_effects["bleed"] = int(unit.status_effects["bleed"]) - 1
		_log("[color=#e36c6c]%s 伤口流血，受到%d点伤害[/color]" % [unit.display_name, bleed_damage])
		var bleed_actor := _team_actor(unit.unit_id)
		if bleed_actor != null:
			await bleed_actor.play_hit(bleed_damage, false)
		if unit.stats.is_dead():
			unit.alive = false
			if bleed_actor != null:
				await bleed_actor.play_defeat()
			_sync_team_health()
			return true
	if int(unit.status_effects.get("weaken", 0)) > 0:
		unit.status_effects["weaken"] = int(unit.status_effects["weaken"]) - 1
	if int(unit.status_effects.get("armor_break", 0)) > 0:
		unit.status_effects["armor_break"] = int(unit.status_effects["armor_break"]) - 1
		if int(unit.status_effects["armor_break"]) <= 0:
			unit.status_effects.erase("armor_break_percent")
			if unit.enemy_definition != null and unit.enemy_definition.breakable_armor > 0:
				_log("%s 再度合拢锁甲。" % unit.display_name)
	if int(unit.status_effects.get("vulnerable", 0)) > 0:
		unit.status_effects["vulnerable"] = int(unit.status_effects["vulnerable"]) - 1
		if int(unit.status_effects["vulnerable"]) <= 0:
			unit.status_effects.erase("vulnerable_percent")
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
	_team_apply_action_end_status(_team_active_unit)
	formation_view.clear_active_unit()
	action_panel.visible = false
	await get_tree().create_timer(0.35).timeout
	_team_take_next_turn()


func _team_apply_action_end_status(unit: BattleCombatant) -> void:
	# One source of truth for runtime and headless real-action QA.
	if unit == null:
		return
	if int(unit.status_effects.get("poison_ward", 0)) > 0:
		unit.status_effects["poison_ward"] -= 1
	if int(unit.status_effects.get("burst", 0)) > 0:
		unit.status_effects["burst"] = int(unit.status_effects["burst"]) - 1
	if int(unit.status_effects.get("clear_sight", 0)) > 0:
		unit.status_effects["clear_sight"] -= 1
		if unit.status_effects["clear_sight"] == 0:
			_log("%s 的明目药效已尽。" % unit.display_name)
	if int(unit.status_effects.get("field_edge", 0)) > 0:
		unit.status_effects["field_edge"] = int(unit.status_effects["field_edge"]) - 1
	if int(unit.status_effects.get("field_focus", 0)) > 0:
		unit.status_effects["field_focus"] = int(unit.status_effects["field_focus"]) - 1
	if int(unit.status_effects.get("damage_boost", 0)) > 0:
		unit.status_effects["damage_boost"] = int(unit.status_effects["damage_boost"]) - 1
		if int(unit.status_effects["damage_boost"]) <= 0:
			unit.status_effects.erase("damage_boost_percent")
	if int(unit.status_effects.get("internal_lock", 0)) > 0:
		unit.status_effects["internal_lock"] = int(unit.status_effects["internal_lock"]) - 1


func _team_finish_player_action(force_end_turn: bool = false) -> void:
	if _team_active_unit == null:
		return
	# Victory has priority over any remaining action points. Otherwise a lethal
	# first action could leave the command panel open until the player clicked
	# one more skill.
	if _team_all_dead(_team_enemies):
		_team_finish(true)
		return
	_team_active_unit.action_points = 0 if force_end_turn else max(0, _team_active_unit.action_points - 1)
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


func _team_find_ally(unit_id: StringName) -> BattleCombatant:
	for unit in _team_allies:
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
			if not unit.alive:
				_cancel_boss_windup(unit)
			formation_view.update_unit_health(unit.unit_id, unit.stats.hp, unit.stats.max_hp, not unit.alive)
			formation_view.update_unit_mana(unit.unit_id, unit.stats.mp, unit.stats.max_mp, not unit.alive)
			formation_view.update_unit_status(unit.unit_id, unit.status_summary())
			formation_view.update_unit_effects(unit.unit_id, unit.status_effects)


func _team_actor(unit_id: StringName) -> BattleActor:
	return formation_view.get_actor(unit_id) if formation_view != null else null


func _team_speed(unit: BattleCombatant) -> int:
	return unit.stats.speed + Inventory.get_speed_bonus_for(StringName(unit.stats.character_id)) if unit.team == BattleCombatant.Team.ALLY else unit.stats.speed


func _team_effective_attack(stats: CharacterStats, skill: Skill = null) -> int:
	var character_id := StringName(stats.character_id)
	var final_attack_bonus := Inventory.get_atk_bonus_for(character_id)
	if skill != null and skill.damage_type == Skill.DamageType.INTERNAL:
		return BattleFormula.calc_internal_attack(stats.inner_power, Inventory.get_attribute_bonus_for(character_id, &"get_inner_power_bonus"), final_attack_bonus)
	return BattleFormula.calc_external_attack(stats.strength, Inventory.get_attribute_bonus_for(character_id, &"get_strength_bonus"), final_attack_bonus)


func _team_effective_defense(stats: CharacterStats) -> int:
	if stats == null:
		return 0
	var value := stats.defense + Inventory.get_def_bonus_for(StringName(stats.character_id))
	if &"qinghe_jade_guard" in stats.skills:
		value += 6
	return value


func _team_attack_value(unit: BattleCombatant, skill: Skill = null) -> int:
	if unit == null or unit.stats == null:
		return 0
	# EnemyDef already owns the authored combat attack value (and applies the
	# party-size multiplier in to_runtime_stats). Enemy runtime stats do not use
	# the player's seven-attribute growth model, so recalculating from their
	# default strength/inner_power silently collapsed every formation enemy to
	# roughly 16 attack regardless of the value authored in the .tres file.
	if unit.team == BattleCombatant.Team.ENEMY:
		return unit.stats.attack
	return _team_effective_attack(unit.stats, skill)


func _calc_team_player_skill_damage(skill: Skill, source: BattleCombatant, target: BattleCombatant) -> int:
	if source == null or source.stats == null or target == null or target.stats == null:
		return 1
	var gear_bonus := Inventory.get_equipped_skill_bonus_for(StringName(source.stats.character_id), skill.school, skill.get_bonus_weapon_style())
	var attack_scaling := _skill_attack_scaling(skill, source.stats, int(gear_bonus.get("scaling", 0)))
	var internal_art_bonus := GameState.get_equipped_internal_art_bonus(source.stats, skill)
	var target_defense := _team_defense_after_armor_break(target)
	var total_pierce := clampi(skill.defense_pierce_percent + int(internal_art_bonus.get("defense_pierce", 0)), 0, 80)
	if total_pierce > 0:
		target_defense = maxi(0, int(round(float(target_defense) * float(100 - total_pierce) / 100.0)))
	var modifiers := _team_damage_modifiers(source, target)
	if target.definition_id == &"ch8_su_wusheng_final" and int(target.status_effects.get("vulnerable", 0)) > 0:
		if int(gear_bonus.get("scaling", 0)) > 0 and int(internal_art_bonus.get("scaling", 0)) > 0:
			modifiers.add_outgoing_bonus("趁隙合招", 0.35)
	var execute_threshold := float(internal_art_bonus.get("execute_threshold", 0.0))
	var execute_bonus := float(internal_art_bonus.get("execute_damage_bonus", 0.0))
	if execute_threshold > 0.0 and execute_bonus > 0.0 and float(target.stats.hp) / maxf(1.0, float(target.stats.max_hp)) < execute_threshold:
		modifiers.add_outgoing_bonus("心法追击", execute_bonus)
	return _calc_damage_for_source(
		_team_attack_value(source, skill), skill.fixed_damage, attack_scaling,
		target_defense, source.stats, true,
		float(gear_bonus.get("crit_mult", 0.0)) + float(internal_art_bonus.get("crit_multiplier", 0.0)), int(source.status_effects.get("burst", 0)) > 0,
		int(target.status_effects.get("weaken", 0)) > 0,
		int(source.status_effects.get("weaken", 0)) > 0, _team_base_hit_chance(skill, source, target),
		float(internal_art_bonus.get("crit_chance", 0.0)) + skill.skill_crit_chance_bonus + (0.15 if int(source.status_effects.get("field_focus", 0)) > 0 else 0.0), 1.0, "",
		source.display_name, target.display_name, skill.display_name,
		modifiers
	)


func _poison_damage_multiplier(target: BattleCombatant) -> float:
	var multiplier := 1.0 - _charm_resistance(target, &"poison_resist")
	if int(target.status_effects.get("poison_ward", 0)) > 0:
		multiplier *= 0.4
	return multiplier


func _calc_team_enemy_skill_damage(skill: Skill, source: BattleCombatant, target: BattleCombatant) -> int:
	if source == null or source.stats == null or target == null or target.stats == null:
		return 1
	var fixed_damage := skill.fixed_damage if skill != null else 2
	var attack_scaling := skill.get_attack_scaling() if skill != null else 100
	var poison_hit := source.enemy_definition != null and source.enemy_definition.poison_weapons
	return _calc_damage_for_source(
		_team_attack_value(source, skill), fixed_damage, attack_scaling,
		_team_defense_after_armor_break(target), source.stats, false, 0.0, false,
		int(target.status_effects.get("weaken", 0)) > 0,
		int(source.status_effects.get("weaken", 0)) > 0, skill.base_hit_chance if skill != null else 0.85,
		0.0, _poison_damage_multiplier(target) if poison_hit else 1.0, "淬毒兵器" if poison_hit else "", source.display_name, target.display_name,
		skill.display_name if skill != null else "普通攻击",
		_team_damage_modifiers(source, target)
	)


func _team_base_hit_chance(skill: Skill, source: BattleCombatant, target: BattleCombatant) -> float:
	if int(source.status_effects.get("clear_sight", 0)) > 0:
		return 1.0
	var charm := Inventory.get_equipped_for(StringName(source.stats.character_id), Equipment.Slot.ACCESSORY)
	if charm != null and charm.special_effect_type == &"sure_hit" and randf() < charm.special_effect_chance:
		_log("[color=#a8d9dc]%s 的%s听出落脚处，此击必中。[/color]" % [source.display_name, charm.display_name])
		return 1.0
	var evasion := target.enemy_definition.evasion_penalty if target.enemy_definition != null else 0.0
	return skill.base_hit_chance - evasion


func _team_defense_after_armor_break(target: BattleCombatant) -> int:
	var defense := _team_effective_defense(target.stats) + _field_medicine_defense(target)
	if target.enemy_definition != null and int(target.status_effects.get("armor_break", 0)) <= 0:
		defense += target.enemy_definition.breakable_armor
	var armor_break_percent := int(target.status_effects.get("armor_break_percent", 0))
	return maxi(0, roundi(float(defense) * float(100 - armor_break_percent) / 100.0)) if armor_break_percent > 0 else defense


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
	var usable := _enemy_usable_skills(stats)
	if usable.is_empty():
		return &"basic_attack"
	if def.enemy_id == &"boss_zhao_wuji":
		var living_count := _team_living_allies().size()
		if living_count >= 2 and &"zhao_black_wind_sweep" in usable and randf() < 0.58:
			return &"zhao_black_wind_sweep"
		if &"zhao_broken_gate_strike" in usable and randf() < 0.62:
			return &"zhao_broken_gate_strike"
		if &"toxic_needle" in usable and randf() < 0.36:
			return &"toxic_needle"
	var signature_skills: Array[StringName] = []
	for skill_id: StringName in usable:
		if skill_id not in [&"basic_attack", &"examiner_staff_press"]:
			signature_skills.append(skill_id)
	if not signature_skills.is_empty() and randf() < clampf(def.aggression, 0.0, 1.0):
		return signature_skills[randi() % signature_skills.size()]
	if &"basic_attack" in usable:
		return &"basic_attack"
	return usable[randi() % usable.size()]


func _enemy_usable_skills(stats: CharacterStats) -> Array[StringName]:
	var usable: Array[StringName] = []
	for skill_id: StringName in stats.skills:
		var skill := _load_skill(skill_id)
		if skill != null and stats.mp >= skill.mp_cost:
			usable.append(skill_id)
	return usable


func _team_finish(victory: bool) -> void:
	_state = State.ENDED
	action_panel.visible = false
	if _is_sparring_battle():
		if victory:
			await _play_player_victory(_team_actor(&"player"))
		EventBus.battle_ended.emit(victory, false)
		SceneRouter.settle_sparring(victory)
		return
	if victory:
		if _office_victory_action in OFFICE_PATROL_VICTORIES:
			var wounds: Dictionary = GameState.get_flag("ch7_office_injuries", {}).duplicate()
			for ally in _team_allies:
				var injury := int(ally.status_effects.get("internal_injury", 0))
				if injury > 0:
					wounds[ally.stats.character_id] = injury
				else:
					wounds.erase(ally.stats.character_id)
			GameState.flags["ch7_office_injuries"] = wounds
		elif _office_victory_action == OFFICE_FINAL_VICTORY:
			GameState.flags.erase("ch7_office_injuries")
		var defeated_actors: Array[BattleActor] = []
		for enemy in _team_enemies:
			var actor := _team_actor(enemy.unit_id)
			if actor != null:
				defeated_actors.append(actor)
		await _team_play_simultaneous_defeats(defeated_actors)
		if _is_nonlethal_story_boss(_enemy_def):
			await get_tree().create_timer(0.65).timeout
		await _play_player_victory(_team_actor(&"player"))
		var total_gold: int = 0
		var total_exp: int = 0
		var elite_loot: Array[Dictionary] = []
		var item_drops: Array[Dictionary] = []
		for enemy_index in _team_enemies.size():
			var enemy: BattleCombatant = _team_enemies[enemy_index]
			var def := _load_enemy(String(enemy.definition_id))
			# A formation should pay more than a lone enemy, but not multiply the
			# economy two or three times. The lead unit grants full rewards; each
			# additional body grants 55% and cannot repeat a guaranteed story drop.
			var support_reward_scale := 1.0 if enemy_index == 0 else 0.55
			var loot := _settle_drops(def, support_reward_scale, enemy_index == 0)
			total_gold += int(loot.get("gold", 0))
			total_exp += int(loot.get("exp", 0))
			item_drops.append_array(loot.item_drops)
			if not loot.elite_drop.is_empty():
				elite_loot.append(loot.elite_drop)
			_record_enemy_defeat_flag(def.enemy_id)
			EventBus.enemy_defeated.emit(def.enemy_id)
			if _is_chapter_boss(def):
				var boss_flag_key := StringName("chapter_boss_defeated_%s" % String(def.enemy_id))
				GameState.set_flag(boss_flag_key, true)
		var participating_party := GameState.party.filter(func(member: CharacterStats) -> bool:
			return _team_allies.any(func(unit: BattleCombatant) -> bool: return unit.stats == member)
		)
		var party_exp_results := _grant_battle_exp(participating_party, total_exp)
		GameState.add_training_points(total_exp)
		GameState.party_changed.emit()
		for enemy in _team_enemies:
			_apply_nonlethal_boss_outcome(_load_enemy(String(enemy.definition_id)))
		EventBus.battle_ended.emit(true, false)
		_record_openworld_route_progress(true, false)
		SceneRouter.go_victory(total_gold, total_exp, party_exp_results)
		# change_scene_to_file defers the victory panel's _ready until the frame ends.
		SceneRouter.get_result_payload()["item_drops"] = item_drops
		if not elite_loot.is_empty():
			SceneRouter.get_result_payload()["elite_loot"] = elite_loot
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
	_player_action_points = 1
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
		var active_stats: CharacterStats = _team_active_unit.stats if _team_mode and _team_active_unit != null else _player
		btn_skill.disabled = not _has_available_active_skill(active_stats)
		btn_item.disabled = not _has_usable_battle_item()
		if _is_sparring_battle():
			btn_flee.disabled = true
	for b in [btn_attack, btn_skill, btn_equip, btn_defend, btn_flee, btn_item]:
		_refresh_command_button_visual(b)


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
	var extra_scaling: int = 0
	var complement_active: bool = false
	var crit_mult_bonus: float = 0.0

	if skill.school != "":
		# 装备技能加成
		var gear_bonus := Inventory.get_equipped_skill_bonus(skill.school, skill.get_bonus_weapon_style())
		extra_scaling += int(gear_bonus.get("scaling", 0))
		crit_mult_bonus += gear_bonus["crit_mult"]

		# 旧互补词条现在属于“装备心法”语义；只学会、不装备不触发。
		if skill.complemented_by != "" and _player.equipped_internal_art == StringName(skill.complemented_by):
			complement_active = true
			extra_scaling += skill.get_complement_scaling_bonus()

	var internal_art_bonus := GameState.get_equipped_internal_art_bonus(_player, skill)
	extra_scaling += int(internal_art_bonus.get("scaling", 0))
	var internal_art_crit_chance := float(internal_art_bonus.get("crit_chance", 0.0)) + skill.skill_crit_chance_bonus
	crit_mult_bonus += float(internal_art_bonus.get("crit_multiplier", 0.0))

	var mastery_bonus := GameState.get_skill_mastery(skill.skill_id) * 2
	var attack_scaling: int = skill.get_attack_scaling() + extra_scaling + mastery_bonus
	if mastery_bonus > 0:
		_log("  [color=#9fd3d0][熟练] %s 攻击系数 +%d%%[/color]" % [skill.display_name, mastery_bonus])

	# 华山互补：暴击倍率加成
	if complement_active and skill.school == "huashan":
		crit_mult_bonus += 0.3

	# 凌月已改为棍法门派；旧版寒针中毒互补不再由门派名硬编码。
	_complement_poison_boost = false

	# 茗雾旧数据兼容；新版追击效果由心法协同数据统一提供。
	var mingwu_bonus_applied := false
	var execute_threshold := float(internal_art_bonus.get("execute_threshold", 0.0))
	var execute_bonus := float(internal_art_bonus.get("execute_damage_bonus", 0.0))
	if execute_threshold > 0.0 and execute_bonus > 0.0:
		var enemy_hp_ratio: float = float(_enemy.hp) / max(1, _enemy.max_hp)
		mingwu_bonus_applied = enemy_hp_ratio < execute_threshold
	elif complement_active and skill.school == "mingwu":
		var enemy_hp_ratio: float = float(_enemy.hp) / max(1, _enemy.max_hp)
		if enemy_hp_ratio < 0.5:
			mingwu_bonus_applied = true

	# 武当互补：反射标记（在 _post_action 中处理）
	_complement_reflect_active = complement_active and skill.school == "wudang"

	# 互补效果日志
	if complement_active and skill.complement_bonus_desc != "":
		_log("  [color=#c8a04a][互补] %s[/color]" % skill.complement_bonus_desc)
	if mingwu_bonus_applied:
		_log("  [color=#c8a04a][心法追击] 敌人气血低于%d%%，伤害+%d%%[/color]" % [int(round(execute_threshold * 100.0)) if execute_threshold > 0.0 else 50, int(round(execute_bonus * 100.0)) if execute_bonus > 0.0 else 20])

	var use_legendary_cinematic := _uses_legendary_cinematic(skill)
	if use_legendary_cinematic:
		await legendary_cinematic.play_intro(skill)
		# The title/mask is only the prelude. The actor action must start on the
		# fully visible battlefield, not underneath the lingering dark overlay.
		await legendary_cinematic.reveal_battlefield()

	# 治疗使用独立 effect_value，不进入攻击伤害公式。
	if skill.kind == Skill.Kind.HEAL:
		_configure_actor_action_timing(player_actor, skill)
		_play_skill_sfx(_skill_cast_sfx(skill))
		await player_actor.play_cast()
		await battle_vfx_layer.play_for_skill(skill.animation_id, player_actor, enemy_actor)
		var before_hp := _player.hp
		var effective_inner := _player.inner_power + Inventory.get_inner_power_bonus()
		_player.heal(maxi(1, skill.get_active_effect_value(_skill_mastery_for_stats(skill, _player)) + effective_inner * 4))
		_log("→ 你施展 [b]%s[/b]，恢复 [color=#72d2a6]%d[/color] 气血" % [skill.display_name, _player.hp - before_hp])
		_refresh_hud()
		_current_skill_index = skill_idx
		if use_legendary_cinematic:
			await legendary_cinematic.finish()
		await _post_action()
		return

	# BUFF 型技能：不造成伤害，施加爆发/防御等自身效果
	if skill.kind == Skill.Kind.BUFF:
		_configure_actor_action_timing(player_actor, skill)
		_play_skill_sfx(_skill_cast_sfx(skill))
		await player_actor.play_cast()
		await battle_vfx_layer.play_for_skill(skill.animation_id, player_actor, enemy_actor)
		_apply_player_buff(skill)
		_refresh_hud()
		_current_skill_index = skill_idx
		if use_legendary_cinematic:
			await legendary_cinematic.finish()
		await _post_action()
		return

	var atk: int = _player_effective_attack(skill)
	var target_defense := _enemy.defense
	var total_pierce := clampi(skill.defense_pierce_percent + int(internal_art_bonus.get("defense_pierce", 0)), 0, 80)
	if total_pierce > 0:
		target_defense = maxi(0, int(round(float(target_defense) * float(100 - total_pierce) / 100.0)))
	var raw: int = _calc_damage_ext(
		atk, skill.fixed_damage, attack_scaling, target_defense, true, crit_mult_bonus,
		skill.base_hit_chance, internal_art_crit_chance, skill.display_name,
		(1.0 + execute_bonus) if mingwu_bonus_applied and execute_bonus > 0.0 else (1.2 if mingwu_bonus_applied else 1.0), "心法追击" if mingwu_bonus_applied else ""
	)
	var was_critical: bool = _last_damage_was_critical
	var attack_missed := _last_attack_missed
	_configure_actor_action_timing(player_actor, skill)
	player_actor.set_action_frames(
		_action_frames_for(skill.animation_id, player_actor.default_attack_frames, true),
		_player_action_pose(skill)
	)
	_arm_skill_strike_audio(player_actor, skill)
	if _skill_uses_approach(skill):
		await _play_skill_approach(player_actor, enemy_actor, skill)
	else:
		if skill.delivery == Skill.Delivery.STATIONARY_AOE:
			await player_actor.play_stationary_attack(enemy_actor, true)
		else:
			await player_actor.play_stationary_attack(enemy_actor, skill.skill_id != &"basic_attack")
	var use_fullscreen_impact := use_legendary_cinematic and skill.target == Skill.Target.ENEMY_ALL and legendary_cinematic.has_fullscreen_effect(skill.skill_id) and not BattleVfxPlayer.has_dragon_wave(skill.animation_id)
	if use_fullscreen_impact:
		await legendary_cinematic.play_fullscreen_effect(skill.skill_id, _skill_impact_sfx(skill))
	else:
		_play_skill_sfx(_skill_impact_sfx(skill))
		await battle_vfx_layer.play_for_skill(_resolved_vfx_id(skill, _player), enemy_actor, player_actor)
	var dmg: int = _enemy.take_damage(raw)
	if attack_missed:
		await enemy_actor.play_dodge(player_actor)
	elif dmg > 0:
		await enemy_actor.play_hit(dmg, was_critical, _has_distinct_hit_sfx(_enemy_def.hit_sfx_path), player_actor)
	if _skill_uses_approach(skill):
		await player_actor.play_attack_recover()

	if attack_missed:
		_log("→ 你施展 [b]%s[/b]，被 %s 闪避" % [skill.display_name, _enemy.display_name])
	elif skill.skill_id == &"basic_attack":
		_log("→ 你出招，对 %s 造成 [color=#ff6e6e]%d[/color] 伤害" % [_enemy.display_name, dmg])
	else:
		_log("→ 你施展 [b]%s[/b]，对 %s 造成 [color=#ffb14a]%d[/color] 伤害" % [
			skill.display_name, _enemy.display_name, dmg
		])

	if dmg > 0:
		_try_apply_player_debuff(skill.skill_id)
		_apply_legacy_internal_art_self_effect(skill, internal_art_bonus)

	# 自 buff 型攻击技（造成伤害 + 自身爆发）
	match String(skill.skill_id):
		"mingwu_saofeng", "mingwu_wuyin_sanshi":
			_player_burst_turns = max(_player_burst_turns, 1)
			_log("  [color=#ffb14a][爆发] 暴击率 +50%%，持续 1 回合[/color]")

	_refresh_hud()
	_current_skill_index = skill_idx
	if use_legendary_cinematic:
		await legendary_cinematic.finish()
	await _post_action()


func _player_action_defend() -> void:
	if _state != State.PLAYER_TURN: return
	if _team_mode:
		await _team_player_action_defend()
		return
	_set_buttons_enabled(false)
	_state = State.EXECUTE
	_player_defending = true
	await player_actor.play_defend()
	_log("→ 你摆出防御姿态，本回合受到伤害减半")
	await _post_action(true)


func _team_player_action_defend() -> void:
	if _team_active_unit == null:
		return
	_set_buttons_enabled(false)
	_state = State.EXECUTE
	_team_active_unit.status_effects["guard"] = 1
	var actor := _team_actor(_team_active_unit.unit_id)
	if actor != null:
		await actor.play_defend()
		_log("→ %s 进入防御架势" % _team_active_unit.display_name)
	await _team_finish_player_action(true)


func _player_action_flee() -> void:
	if _state != State.PLAYER_TURN: return
	if _team_mode:
		_set_buttons_enabled(false)
		await _finish_retreat()
		return
	_set_buttons_enabled(false)
	if randf() < 0.5:
		_log("→ 你成功逃离战场")
		_end_battle(false, true)
	else:
		_log("→ 逃跑失败！")
		_state = State.EXECUTE
		await _post_action()


func _request_player_flee() -> void:
	if _state != State.PLAYER_TURN or _flee_confirm_dialog == null:
		return
	var warning := "[center]确定要撤离当前战斗吗？\n\n[color=#d6c4a4]若撤离失败，本次行动将直接结束。[/color][/center]"
	if _team_mode:
		warning = "[center]确定让队伍撤离当前战斗吗？[/center]"
	_flee_confirm_dialog.show_confirm("确认撤离", warning, "确认撤离", "继续战斗")


# --- 流程 ---

func _post_action(force_end_turn: bool = false) -> void:
	action_panel.visible = false
	if _enemy.is_dead():
		_end_battle(true, false)
		return
	_player_action_points = 0 if force_end_turn else max(0, _player_action_points - 1)
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
	var skill: Skill = _load_skill(skill_id)
	if skill != null:
		_enemy.mp = maxi(0, _enemy.mp - skill.mp_cost)
	var atk: int = _enemy.attack
	var fixed_damage := skill.fixed_damage if skill != null else 2
	var attack_scaling := skill.get_attack_scaling() if skill != null else 100
	var dmg: int = _calc_damage_ext(
		atk, fixed_damage, attack_scaling, _player.defense + Inventory.get_def_bonus(), false, 0.0,
		skill.base_hit_chance if skill != null else 0.85, 0.0,
		skill.display_name if skill != null else "普通攻击"
	)
	var was_critical: bool = _last_damage_was_critical
	var attack_missed := _last_attack_missed
	_configure_actor_action_timing(enemy_actor, skill)
	enemy_actor.set_action_frames(EnemySignatureFrames.resolve(_enemy_def.enemy_id, skill, enemy_actor.default_attack_frames))
	_arm_skill_strike_audio(enemy_actor, skill)
	if _skill_uses_approach(skill):
		await _play_skill_approach(enemy_actor, player_actor, skill)
	else:
		await enemy_actor.play_stationary_attack(player_actor, skill != null and skill.skill_id != &"basic_attack")
	if skill != null:
		_play_skill_sfx(_skill_impact_sfx(skill))
		await battle_vfx_layer.play_for_skill(_resolved_vfx_id(skill, _enemy, _enemy_def), player_actor, enemy_actor)
	else:
		_play_skill_sfx(AudioManager.DEFAULT_HIT_SFX)

	if not attack_missed and _player_defending:
		dmg = maxi(1, int(round(float(dmg) * 0.5)))

	if not attack_missed and _player_redirect_percent > 0:
		var redirected := maxi(1, int(round(float(dmg) * float(_player_redirect_percent) / 100.0)))
		dmg = maxi(1, dmg - redirected)
		_enemy.hp = max(0, _enemy.hp - redirected)
		_log("  [color=#72d2c9][回澜] 你化去攻势并返还 %d 点伤害[/color]" % redirected)
		_player_redirect_percent = 0

	# 武当互补：玄武心经护体反射 15%
	if not attack_missed and _complement_reflect_active:
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
	if attack_missed:
		await player_actor.play_dodge(enemy_actor)
	elif dmg > 0:
		await player_actor.play_hit(dmg, was_critical, false, enemy_actor)
	if _skill_uses_approach(skill):
		await enemy_actor.play_attack_recover()

	if attack_missed:
		_log("← %s 的攻势被你闪避" % _enemy.display_name)
	elif skill != null and skill.skill_id != &"basic_attack":
		_log("← %s 使出 [b]%s[/b]，对你造成 [color=#ff6e6e]%d[/color] 伤害" % [
			_enemy.display_name, skill.display_name, dmg
		])
	else:
		_log("← %s 攻击，对你造成 [color=#ff6e6e]%d[/color] 伤害" % [_enemy.display_name, dmg])

	if not attack_missed:
		_try_apply_enemy_debuff(skill_id)
	_refresh_hud()
	if _enemy.is_dead():
		_end_battle(true, false)
		return
	if _player.is_dead():
		_end_battle(false, false)


func _enemy_choose_skill() -> StringName:
	return _enemy_choose_skill_for(_enemy_def, _enemy)


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


func _play_player_victory(actor: BattleActor) -> void:
	AudioManager.play_music_sting(BattleActor.VICTORY_MUSIC)
	if actor != null:
		await actor.play_player_victory()


func _end_battle(victory: bool, fled: bool) -> void:
	_state = State.ENDED
	action_panel.visible = false
	if fled:
		# A successful withdrawal is not a defeat animation.  Keep the party on
		# its feet and return to the field after a brief readable pause.
		_record_openworld_route_progress(false, true)
		EventBus.battle_ended.emit(false, true)
		await get_tree().create_timer(0.35).timeout
		var payload: Dictionary = SceneRouter.get_battle_payload()
		var return_scene: StringName = payload.get("return_scene", &"")
		if String(return_scene) != "":
			SceneRouter.return_from_battle_payload(payload)
		else:
			SceneRouter.go_main_menu()
		return

	if victory:
		await enemy_actor.play_defeat()
		await _play_player_victory(player_actor)
	else:
		await player_actor.play_defeat()
		await enemy_actor.play_victory()
	await get_tree().create_timer(0.45).timeout
	if _is_sparring_battle():
		EventBus.battle_ended.emit(victory, false)
		SceneRouter.settle_sparring(victory)
		return
	if victory:
		var loot := _settle_drops(_enemy_def)
		_record_enemy_defeat_flag(_enemy_def.enemy_id)
		EventBus.enemy_defeated.emit(_enemy_def.enemy_id)
		EventBus.battle_ended.emit(true, false)
		var exp_results := _grant_battle_exp([_player], loot.exp)
		GameState.add_training_points(loot.exp)
		if _is_chapter_boss(_enemy_def):
			var boss_flag_key := "chapter_boss_defeated_%s" % String(_enemy_def.enemy_id)
			GameState.set_flag(StringName(boss_flag_key), true)
		_apply_nonlethal_boss_outcome(_enemy_def)
		_record_openworld_route_progress(true, false)
		SceneRouter.go_victory(loot.gold, loot.exp, exp_results)
		SceneRouter.get_result_payload()["item_drops"] = loot.item_drops
		if not loot.elite_drop.is_empty():
			SceneRouter.get_result_payload()["elite_loot"] = [loot.elite_drop]
	else:
		EventBus.battle_ended.emit(false, false)
		SceneRouter.go_defeat()


func _grant_battle_exp(members: Array, amount: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for raw_member: Variant in members:
		var member := raw_member as CharacterStats
		if member == null:
			continue
		var before := member.level
		member.gain_exp(amount)
		results.append({
			"character_id": member.character_id,
			"display_name": member.display_name,
			"exp_gained": amount,
			"level_before": before,
			"level_after": member.level,
			"levels_gained": maxi(0, member.level - before),
		})
	return results


func _finish_retreat() -> void:
	_state = State.ENDED
	action_panel.visible = false
	formation_view.clear_active_unit()
	_record_openworld_route_progress(false, true)
	EventBus.battle_ended.emit(false, true)
	await get_tree().create_timer(0.35).timeout
	var payload: Dictionary = SceneRouter.get_battle_payload()
	var return_scene: StringName = payload.get("return_scene", &"")
	if not String(return_scene).is_empty():
		SceneRouter.return_from_battle_payload(payload)
	else:
		SceneRouter.go_main_menu()


func _record_openworld_route_progress(victory: bool, fled: bool) -> void:
	if not victory and not fled:
		return
	var payload: Dictionary = SceneRouter.get_battle_payload()
	if StringName(payload.get("return_scene", &"")) != &"openworld_yanmen_pass":
		return
	var progress := mini(2, int(GameState.get_flag(&"openworld_yanmen_route_progress", 0)) + 1)
	GameState.set_flag(&"openworld_yanmen_route_progress", progress)
	if progress >= 2:
		GameState.set_flag(&"openworld_yanmen_cave_unlocked", true)


func _settle_drops(def: EnemyDef, reward_scale: float = 1.0, grant_guaranteed_items: bool = true) -> Dictionary:
	var safe_scale := clampf(reward_scale, 0.0, 1.0)
	var rolled_gold := randi_range(def.drop_gold_min, def.drop_gold_max)
	var gold := roundi(float(rolled_gold) * safe_scale)
	var exp_reward := roundi(float(def.drop_exp) * safe_scale)
	GameState.add_gold(gold)

	var item_drops: Array[Dictionary] = []
	if grant_guaranteed_items:
		for item_id in def.drop_items:
			_grant_battle_drop(item_id, 1, item_drops)
	var elite_drop := {}
	var elite_item := WILDERNESS_ELITE.equipment_for_roll(def.enemy_id, randf()) if WILDERNESS_ELITE.is_elite(def.enemy_id) else &""
	if elite_item != &"":
		var gear := Inventory.load_item_by_id(elite_item) as Equipment
		if gear != null:
			var collected := _grant_battle_drop(elite_item, 1, item_drops) == 1
			elite_drop = {"item_id": elite_item, "collected": collected}

	for entry in def.drop_random:
		var iid: StringName = StringName(entry.get("item_id", ""))
		var chance: float = float(entry.get("chance", 0.0))
		var count: int = int(entry.get("count", 1))
		if String(iid) != "" and randf() < chance * safe_scale:
			_grant_battle_drop(iid, count, item_drops)

	# M1 验收：打印背包 + 战利品摘要到控制台，方便确认数据驱动闭环
	print("[M1 Smoke] enemy=%s gold=+%d exp=+%d slots=%d equipped=%d" % [
		def.enemy_id,
		gold,
		exp_reward,
		Inventory.slots.size(),
		Inventory.equipped.size(),
	])
	for s in Inventory.slots:
		var it: Item = s.get("item")
		if it != null:
			print("    - %s × %d" % [it.display_name, int(s.get("count", 0))])

	return {
		"gold": gold,
		"exp": exp_reward,
		"elite_drop": elite_drop,
		"item_drops": item_drops,
	}


func _grant_battle_drop(item_id: StringName, count: int, item_drops: Array[Dictionary]) -> int:
	var item := Inventory.load_item_by_id(item_id)
	if item == null or count <= 0:
		return 0
	var before := Inventory.count_of(item_id)
	var added := count if Inventory.add_item(item_id, count) else clampi(Inventory.count_of(item_id) - before, 0, count)
	item_drops.append({"item_id": item_id, "count": added, "uncollected": count - added})
	if added > 0:
		_log("[color=#6fc8ff]获得物品：%s × %d[/color]" % [item.display_name, added])
	if added < count:
		_log("[color=#f4c486]背包已满，未能拾取：%s × %d[/color]" % [item.display_name, count - added])
	return added


func _is_sparring_battle() -> bool:
	return StringName(SceneRouter.get_battle_payload().get("battle_mode", &"")) == &"sparring"


# --- Helpers ---

func _player_effective_attack(skill: Skill = null) -> int:
	var final_attack_bonus := Inventory.get_atk_bonus()
	if skill != null and skill.damage_type == Skill.DamageType.INTERNAL:
		return BattleFormula.calc_internal_attack(_player.inner_power, Inventory.get_inner_power_bonus(), final_attack_bonus)
	return BattleFormula.calc_external_attack(_player.strength, Inventory.get_strength_bonus(), final_attack_bonus)


func _player_effective_speed() -> int:
	var legacy_spd: int = _player.speed + Inventory.get_speed_bonus()
	var core_spd: int = _player.agility * 2 + Inventory.get_agility_bonus() * 2
	return max(legacy_spd, core_spd)


func _apply_legacy_internal_art_self_effect(skill: Skill, bonus: Dictionary) -> void:
	if skill == null or _player == null:
		return
	var old_hp := _player.hp
	var old_mp := _player.mp
	var hp_restore := int(bonus.get("self_hp_restore", 0))
	var mp_restore := int(bonus.get("self_mp_restore", 0))
	if hp_restore > 0:
		_player.heal(hp_restore)
	if mp_restore > 0:
		_player.mp = mini(_player.max_mp, _player.mp + mp_restore)
	if _player.hp > old_hp or _player.mp > old_mp:
		_log("  [color=#72d2a6][心法回息] 生命 +%d，内力 +%d[/color]" % [_player.hp - old_hp, _player.mp - old_mp])


func _calc_damage(base_atk: int, fixed_damage: int, attack_scaling: int, target_def: int, is_player: bool, skill_label: String = "") -> int:
	return _calc_damage_ext(base_atk, fixed_damage, attack_scaling, target_def, is_player, 0.0, 1.0, 0.0, skill_label)


## 扩展伤害计算，支持暴击倍率加成（用于互补/装备加成系统）。
func _calc_damage_ext(base_atk: int, fixed_damage: int, attack_scaling: int, target_def: int, is_player: bool, crit_mult_bonus: float, base_hit_chance: float = 1.0, extra_crit_chance: float = 0.0, skill_label: String = "", post_multiplier: float = 1.0, post_modifier_label: String = "") -> int:
	var source_stats: CharacterStats = _player if is_player else _enemy
	var burst_active := _player_burst_turns > 0 if is_player else _enemy_burst_turns > 0
	var target_weak := _enemy_weak_turns > 0 if is_player else _player_weak_turns > 0
	var source_weak := _player_weak_turns > 0 if is_player else _enemy_weak_turns > 0
	var modifiers := DamageModifierStack.new()
	var final_post_multiplier := post_multiplier
	var final_post_label := post_modifier_label
	# 影杀/心法追击是攻击方增伤，和其他增伤同区加算。post区只保留给真正
	# 不属于攻击方、易伤或防御机制的剧情最终修正。
	if post_modifier_label in ["影杀", "心法追击"] and post_multiplier > 1.0:
		modifiers.add_outgoing_bonus(post_modifier_label, post_multiplier - 1.0)
		final_post_multiplier = 1.0
		final_post_label = ""
	return _calc_damage_for_source(
		base_atk, fixed_damage, attack_scaling, target_def, source_stats, is_player,
		crit_mult_bonus, burst_active, target_weak, source_weak, base_hit_chance, extra_crit_chance,
		final_post_multiplier, final_post_label,
		source_stats.display_name if source_stats != null else "",
		(_enemy.display_name if is_player and _enemy != null else _player.display_name if _player != null else ""),
		skill_label, modifiers
	)


func _calc_damage_for_source(base_atk: int, fixed_damage: int, attack_scaling: int, target_def: int, source_stats: CharacterStats, is_player: bool, crit_mult_bonus: float = 0.0, burst_active: bool = false, target_weak: bool = false, source_weak: bool = false, base_hit_chance: float = 1.0, extra_crit_chance: float = 0.0, post_multiplier: float = 1.0, post_modifier_label: String = "", source_label: String = "", target_label: String = "", skill_label: String = "", modifier_stack: DamageModifierStack = null) -> int:
	var equipment_crit_chance := 0.0
	var equipment_hit_chance := 0.0
	if is_player and source_stats != null:
		equipment_crit_chance = Inventory.get_crit_chance_bonus_for(StringName(source_stats.character_id))
		equipment_hit_chance = Inventory.get_hit_chance_bonus_for(StringName(source_stats.character_id))
		var weapon := Inventory.get_equipped_for(StringName(source_stats.character_id), Equipment.Slot.WEAPON)
		if weapon != null and weapon.forge_affixes.has("crit_damage"):
			crit_mult_bonus += 0.20
	var result := BattleFormula.calc_damage(
		base_atk, fixed_damage, attack_scaling, target_def, is_player, crit_mult_bonus,
		equipment_crit_chance + extra_crit_chance, burst_active,
		target_weak, source_weak,
		source_stats.hp if source_stats != null else 1,
		source_stats.max_hp if source_stats != null else 1,
		base_hit_chance, equipment_hit_chance, post_multiplier, post_modifier_label, modifier_stack
	)
	last_damage_breakdown = result.get("breakdown") as DamageBreakdown
	if last_damage_breakdown != null:
		last_damage_breakdown.annotate(source_label, target_label, skill_label)
		EventBus.damage_calculated.emit(last_damage_breakdown)
	_last_attack_missed = not bool(result.get("hit", true))
	_last_damage_was_critical = bool(result.get("was_crit", false))
	if _last_attack_missed:
		_log("  [color=#aeb8bc]攻击被闪开！[/color]")
		return 0
	if _last_damage_was_critical:
		var crit_mult := last_damage_breakdown.crit_multiplier if last_damage_breakdown != null else minf(BattleFormula.CRIT_MULT + crit_mult_bonus, BattleFormula.CRIT_MULT_MAX)
		_log("  [color=#ffb14a][b]暴击！(×%.1f)[/b][/color]" % crit_mult)
		if last_damage_breakdown != null and last_damage_breakdown.crit_multiplier_capped:
			_log("  [color=#e0b76a][暴伤上限] 原倍率 ×%.2f，按 ×%.2f 结算。[/color]" % [last_damage_breakdown.requested_crit_multiplier, last_damage_breakdown.crit_multiplier])
	return int(result.get("dealt", 1))


func _team_damage_modifiers(source: BattleCombatant, target: BattleCombatant) -> DamageModifierStack:
	var modifiers := DamageModifierStack.new()
	if source != null:
		var boost_percent := int(source.status_effects.get("damage_boost_percent", 0))
		if int(source.status_effects.get("damage_boost", 0)) > 0 and boost_percent > 0:
			modifiers.add_outgoing_bonus("增伤", float(boost_percent) / 100.0)
		if int(source.status_effects.get("field_edge", 0)) > 0:
			modifiers.add_outgoing_bonus("砺锋丸", 0.15)
	if target != null:
		var vulnerable_percent := int(target.status_effects.get("vulnerable_percent", 0))
		if int(target.status_effects.get("vulnerable", 0)) > 0 and vulnerable_percent > 0:
			modifiers.add_incoming_vulnerability("易伤", float(vulnerable_percent) / 100.0)
	return modifiers


func _skill_attack_scaling(skill: Skill, stats: CharacterStats, equipment_scaling: int = 0) -> int:
	if skill == null:
		return 100
	var total := skill.get_attack_scaling() + equipment_scaling
	if stats != null and skill.complemented_by != "" and stats.equipped_internal_art == StringName(skill.complemented_by):
		total += skill.get_complement_scaling_bonus()
	if stats != null:
		total += int(GameState.get_equipped_internal_art_bonus(stats, skill).get("scaling", 0))
	if stats != null and stats.character_id == "protagonist":
		total += GameState.get_skill_mastery(skill.skill_id) * 2
	return total


func _skill_mastery_for_stats(skill: Skill, stats: CharacterStats) -> int:
	if skill != null and stats != null and stats.character_id == "protagonist":
		return GameState.get_skill_mastery(skill.skill_id)
	return 0


func _try_apply_player_debuff(skill_id: StringName) -> void:
	## 玩家技能附加状态效果（中毒/虚弱/爆发）
	match String(skill_id):
		# ── 虚弱类 ──
		"gufeng_fuhu":
			if randf() < 0.25:
				_enemy_weak_turns = max(_enemy_weak_turns, 2)
				_log("  [color=#cc8844]敌人虚弱！攻防降低，持续 2 回合。[/color]")
		"huashan_poyun":
			if randf() < 0.30:
				_enemy_weak_turns = max(_enemy_weak_turns, 2)
				_log("  [color=#cc8844]破云穿空！敌人虚弱，攻防降低 2 回合。[/color]")
		"canghai_zhenyue_palms":
			_enemy_weak_turns = max(_enemy_weak_turns, 2)
			_log("  [color=#72d2c9]沧浪叠势！敌人虚弱，攻防降低 2 回合。[/color]")

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

	# 新武学统一读取资源状态字段，避免更换门派定位后仍残留旧 ID 硬编码。
	var skill_path := "res://data/skills/%s.tres" % String(skill_id)
	var skill := load(skill_path) as Skill if ResourceLoader.exists(skill_path) else null
	if skill != null and skill.inflicted_status != &"" and skill.status_duration > 0:
		if skill.status_chance <= 0.0 or randf() <= skill.status_chance:
			match String(skill.inflicted_status):
				"poison":
					_enemy_poison_turns = max(_enemy_poison_turns, skill.status_duration)
				"weaken":
					_enemy_weak_turns = max(_enemy_weak_turns, skill.status_duration)
			_log("  [color=#72d2c9]%s附加%s，持续 %d 回合。[/color]" % [skill.display_name, String(skill.inflicted_status), skill.status_duration])

	# 重置互补临时状态
	_complement_poison_boost = false


func _on_status_cured(cure_type: StringName) -> void:
	## 战斗中使用了状态解除物品
	if _team_mode and _team_active_unit != null:
		match cure_type:
			&"poison":
				_team_clear_ailments(_team_active_unit, ["poison", "venom"], "解毒药")
			&"weak":
				_team_clear_ailments(_team_active_unit, ["weaken"], "药物")
			&"all":
				_team_clear_ailments(_team_active_unit, ["poison", "venom", "weaken", "bleed", "vulnerable", "armor_break", "freeze", "stun", "internal_injury", "internal_lock"], "清心露")
		_sync_team_health()
		_refresh_hud()
		return
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
	var active_duration := skill.get_active_duration(_skill_mastery_for_stats(skill, _player))
	match sid:
		"defend":
			_player_defending = true
			_log("→ 你摆出防御姿态，本回合受到伤害减半")
			return
		"huashan_zixia_shengong", "huashan_zixia_ninggang", "lingyue_tayue_lingbo":
			var duration := active_duration if active_duration > 0 else 3
			_player_burst_turns = max(_player_burst_turns, duration)
			_log("→ 你施展 [b]%s[/b]！暴击率 +50%%，持续 %d 回合。[color=#ffb14a][爆发][/color]" % [skill.display_name, duration])
		"gufeng_jingang_buhuai", "wudang_xuanwu_ge":
			_player_weak_turns = 0
			_player_defending = true
			_log("→ 你施展 [b]%s[/b]！虚弱清除 + 本回合防御。[color=#88aaff][守御][/color]" % skill.display_name)
		"mingwu_mingwu_bu":
			_player_burst_turns = max(_player_burst_turns, 1)
			_log("→ 你施展 [b]%s[/b]！本回合暴击率 +50%%。[color=#ffb14a][爆发][/color]" % skill.display_name)
		"huilan_redirecting_art":
			_player_redirect_percent = skill.get_active_effect_value(_skill_mastery_for_stats(skill, _player))
			_log("→ 你施展 [b]%s[/b]，下一次受击化去并返还 %d%% 伤害。[color=#72d2c9][回澜][/color]" % [skill.display_name, _player_redirect_percent])
		"mingwu_saofeng", "mingwu_wuyin_sanshi":
			_player_burst_turns = max(_player_burst_turns, 1)
			_log("→ 你施展 [b]%s[/b]！暴击率 +50%%，持续 1 回合。[color=#ffb14a][爆发][/color]" % skill.display_name)
		_:
			_log("→ 你施展 [b]%s[/b]" % skill.display_name)


func _refresh_skill_button() -> void:
	if _player_skills.size() > 1 and _current_skill_index >= 0 and _current_skill_index < _player_skills.size():
		var sk: Skill = _player_skills[_current_skill_index]
		var atk: int = _player_effective_attack(sk)
		var gear_bonus := Inventory.get_equipped_skill_bonus(sk.school, sk.get_bonus_weapon_style())
		var preview := BattleFormula.estimate_damage_range(
			atk, sk.fixed_damage, _skill_attack_scaling(sk, _player, int(gear_bonus.get("scaling", 0)))
		)
		var dmg_low: int = preview.x
		var dmg_high: int = preview.y
		btn_skill.text = "%s ⚔%d-%d（内力-%d）" % [sk.display_name, dmg_low, dmg_high, sk.mp_cost]
	else:
		btn_skill.text = "(无可用技能)"


func _has_available_active_skill(stats: CharacterStats = null) -> bool:
	if stats == null:
		stats = _player
	for skill in _skills_for_stats(stats):
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
	# 心法、治疗和纯增益依靠运气行功，不应被名称里的“剑、刀”等字样
	# 错绑到当前兵器。防御是系统通用动作，亦无武器要求。
	if skill != null and (skill.is_internal_art or skill.kind == Skill.Kind.HEAL or (skill.kind == Skill.Kind.BUFF and skill.skill_id != &"defend")):
		return &""
	if skill.required_weapon_type != &"":
		return Equipment.normalize_weapon_type(skill.required_weapon_type)
	var bonus_style := skill.get_bonus_weapon_style()
	if bonus_style == &"palm":
		return &"palm"
	var id := String(skill.skill_id)
	if id.begins_with("gufeng_") and id != "gufeng_jingang_buhuai" and id != "gufeng_jingang_li":
		return &"blade"
	if id.begins_with("huashan_") or id == "linxi_basic_sword_one":
		return &"sword"
	if id.begins_with("wudang_"):
		return &"palm"
	if id.begins_with("lingyue_"):
		return &"staff"
	return &""


func _weapon_type_for_equipment(equipment: Equipment) -> StringName:
	if equipment == null:
		return &""
	if equipment.weapon_type != &"":
		return Equipment.normalize_weapon_type(equipment.weapon_type)
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
	if skill == null or skill.is_passive or (skill.is_internal_art and not skill.has_active_effect()) or stats == null or stats.mp < skill.mp_cost:
		return false
	if _team_mode and _team_active_unit != null and _team_active_unit.stats == stats and int(_team_active_unit.status_effects.get("internal_lock", 0)) > 0 and skill.skill_id not in [&"basic_attack", &"defend"]:
		return false
	return _matches_current_weapon(skill, stats)


func _matches_current_weapon(skill: Skill, stats: CharacterStats) -> bool:
	var required := _required_weapon_for_skill(skill)
	if required == &"":
		return true
	var weapon := Inventory.get_equipped_for(StringName(stats.character_id), Equipment.Slot.WEAPON)
	if weapon == null:
		# Weapon specialty describes what a character can learn, not an invisible
		# weapon they may use in battle.  Sword/blade/staff/palm/hidden techniques
		# all require a matching item in the shared weapon slot.
		return false
	return _weapon_type_for_equipment(weapon) == required


func _skills_for_stats(stats: CharacterStats) -> Array[Skill]:
	var result: Array[Skill] = []
	if stats == null:
		return result
	for skill_id: StringName in stats.skills:
		var skill := _load_skill(skill_id)
		if skill != null:
			result.append(skill)
	return result


func _create_skill_popup() -> void:
	_skill_popup = PopupPanel.new()
	_skill_popup.name = "SkillSelector"
	_skill_popup.exclusive = true
	var panel_style := _generated_texture_style(BATTLE_SKILL_PANEL_PATH, 74.0, 74.0, 54.0, 54.0)
	if panel_style != null:
		_skill_popup.add_theme_stylebox_override("panel", panel_style)
	else:
		_skill_popup.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.018, 0.035, 0.050, 0.90), Color(0.34, 0.70, 0.72, 0.96), 8, 1))
	_system_ui_canvas_layer.add_child(_skill_popup)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 46.0
	content.offset_top = 36.0
	content.offset_right = -46.0
	content.offset_bottom = -34.0
	_skill_popup.add_child(content)
	var title := Label.new()
	title.text = "选择招式"
	title.custom_minimum_size = Vector2(0.0, 42.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.94, 0.80, 0.43, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.03, 1.0))
	title.add_theme_constant_override("outline_size", 3)
	content.add_child(title)
	var separator := HSeparator.new()
	content.add_child(separator)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(704, 420)
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
	var stats: CharacterStats = _team_active_unit.stats if _team_mode and _team_active_unit != null else _player
	var available_skills := _skills_for_stats(stats)
	var shown_count: int = 0
	for skill_index in available_skills.size():
		var skill: Skill = available_skills[skill_index]
		if not _matches_current_weapon(skill, stats):
			continue
		if skill.is_passive or (skill.is_internal_art and not skill.has_active_effect()):
			continue
		var option: Button = Button.new()
		option.custom_minimum_size = Vector2(704, 108)
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.text = ""
		option.flat = false
		UI_THEME.style_button(option, 18, UI_THEME.TEXT)
		_apply_generated_skill_row_style(option)
		var can_use: bool = _can_use_skill(skill, stats)
		option.disabled = not can_use
		if not can_use:
			option.modulate = Color(0.50, 0.54, 0.58, 0.82)
			option.mouse_default_cursor_shape = Control.CURSOR_ARROW
		option.tooltip_text = skill.description
		option.pressed.connect(_on_skill_selected.bind(skill_index))
		var item_content: VBoxContainer = VBoxContainer.new()
		item_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		item_content.offset_left = 58.0
		item_content.offset_top = 10.0
		item_content.offset_right = -58.0
		item_content.offset_bottom = -10.0
		item_content.add_theme_constant_override("separation", 4)
		option.add_child(item_content)
		var headline: HBoxContainer = HBoxContainer.new()
		headline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item_content.add_child(headline)
		var name_label: Label = Label.new()
		name_label.text = skill.display_name
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", UI_THEME.GOLD_LIGHT)
		name_label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.03, 0.96))
		name_label.add_theme_constant_override("outline_size", 3)
		if not can_use:
			name_label.modulate = Color(0.56, 0.60, 0.64, 1.0)
		headline.add_child(name_label)
		var cost_label: Label = Label.new()
		cost_label.text = "内力 %d" % skill.mp_cost
		cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cost_label.add_theme_font_size_override("font_size", 17)
		cost_label.add_theme_color_override("font_color", Color(0.68, 0.98, 0.92, 1.0))
		cost_label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.03, 0.96))
		cost_label.add_theme_constant_override("outline_size", 2)
		if not can_use:
			cost_label.modulate = Color(0.62, 0.66, 0.70, 1.0)
		cost_label.custom_minimum_size = Vector2(72.0, 0.0)
		headline.add_child(cost_label)
		var description_label: Label = Label.new()
		description_label.text = _compact_skill_description(skill.description)
		description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		description_label.clip_text = false
		description_label.custom_minimum_size = Vector2(0.0, 40.0)
		description_label.add_theme_font_size_override("font_size", 16)
		description_label.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0, 1.0))
		description_label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.03, 0.92))
		description_label.add_theme_constant_override("outline_size", 2)
		if not can_use:
			description_label.modulate = Color(0.58, 0.62, 0.66, 1.0)
		item_content.add_child(description_label)
		_skill_list.add_child(option)
		if can_use:
			option.mouse_entered.connect(_refresh_skill_option_visual.bind(option))
			option.mouse_exited.connect(_refresh_skill_option_visual.bind(option))
			option.button_down.connect(_refresh_skill_option_visual.bind(option))
			option.button_up.connect(_refresh_skill_option_visual.bind(option))
			_refresh_skill_option_visual(option)
		shown_count += 1
	if shown_count == 0:
		return
	_skill_popup.popup_centered(Vector2i(820, 600))


func _compact_skill_description(source: String, max_chars: int = 0) -> String:
	var compact: String = source.replace("\r", " ").replace("\n", " ").strip_edges()
	while compact.contains("  "):
		compact = compact.replace("  ", " ")
	if max_chars <= 0 or compact.length() <= max_chars:
		return compact
	return compact.substr(0, maxi(0, max_chars - 1)) + "…"


func _refresh_skill_option_visual(button: Button) -> void:
	if button == null or not is_instance_valid(button) or button.disabled:
		return
	if button.button_pressed:
		button.modulate = Color(0.82, 1.0, 0.94, 1.0)
	elif button.is_hovered():
		button.modulate = Color(0.72, 1.0, 1.0, 1.0)
	else:
		button.modulate = Color.WHITE


func _on_skill_selected(skill_index: int) -> void:
	if _skill_popup != null:
		_skill_popup.hide()
	_player_action_skill_use(skill_index)


func _open_battle_inventory() -> void:
	if _state != State.PLAYER_TURN:
		return
	if _battle_inventory_panel == null:
		_battle_inventory_panel = INVENTORY_PANEL_SCENE.instantiate() as Control
		_battle_inventory_panel.set_script(preload("res://scripts/battle/field_medicine_inventory.gd"))
		_battle_inventory_panel.name = "BattleInventoryPanel"
		_system_ui_canvas_layer.add_child(_battle_inventory_panel)
		_battle_inventory_panel.closed.connect(_on_battle_inventory_closed)
		_battle_inventory_panel.action_committed.connect(_on_battle_inventory_action)
	_battle_inventory_panel.call("set_battle_mode", true)
	_set_buttons_enabled(false)
	_battle_inventory_panel.call("open")


func _on_battle_inventory_closed() -> void:
	if _state == State.PLAYER_TURN:
		# 战斗中主动关闭背包也消耗本角色本次操作，不能反复开关规避回合。
		_on_battle_inventory_action(&"close")


func _field_medicine_defense(unit: BattleCombatant) -> int:
	return 8 if int(unit.status_effects.get("field_guard", 0)) > 0 else 0


func apply_field_medicine(id: String) -> bool:
	if not _team_mode or _state != State.PLAYER_TURN or _team_active_unit == null or not _team_active_unit.alive:
		return false
	var effects := _team_active_unit.status_effects
	match id:
		"clear_sight_powder":
			# Using the item ends this turn immediately; the next three full turns remain.
			effects["clear_sight"] = 4
			_log("[color=#a8d9dc]%s 服下明目散，接下来三个自身回合，每击必中。[/color]" % _team_active_unit.display_name)
		"field_edge_pill":
			# The inventory action itself consumes one counter.
			effects["field_edge"] = 3
		"field_focus_pill":
			effects["field_focus"] = 3
		"field_breath_pill":
			effects["field_breath"] = 2
		"field_guard_powder":
			effects["field_guard"] = 2
		_:
			return false
	return true


func _on_battle_inventory_action(action_type: StringName) -> void:
	if _state != State.PLAYER_TURN:
		return
	_state = State.EXECUTE
	if _battle_inventory_panel != null and _battle_inventory_panel.visible:
		_battle_inventory_panel.call("close")
	_set_buttons_enabled(false)
	var action_label := "使用道具" if action_type == &"use_item" else ("更换装备" if action_type == &"equip" else "关闭背包")
	_log("-> 背包操作：%s" % action_label)
	_refresh_hud()
	if _team_mode:
		await _team_finish_player_action(true)
	else:
		await _post_action(true)


func _roll_damage(base_attack: int) -> int:
	## 80% - 120% 浮动（保留兼容旧代码）
	return int(base_attack * randf_range(0.8, 1.2))


func _is_chapter_boss(def: EnemyDef) -> bool:
	return def != null and def.is_chapter_boss


func _record_enemy_defeat_flag(id: StringName) -> void:
	# These enemy definitions are shared with ambient spawns. Only a victory
	# from the authored confrontation unlocks the corresponding story doors.
	if id in [&"masked_killer_minion", &"masked_killer_elite"]:
		var payload := SceneRouter.get_battle_payload()
		if payload.get("return_scene", &"") != &"ch2_s3_forest_ambush" or payload.get("enemy_id", &"") != id:
			return
	var expected := ""
	match id:
		&"linxi_wild_beast": expected = "dialog:ch1_forest_trail_secured"
		&"zhuwei_bandit": expected = "dialog:ch1_ruin_yard_secured"
	if not expected.is_empty() and SceneRouter.get_battle_payload().get("victory_action", "") != expected:
		return
	GameState.set_flag(StringName("defeated_%s" % String(id)), true)


func _is_nonlethal_story_boss(def: EnemyDef) -> bool:
	return def != null and def.enemy_id == &"boss_zhao_wuji"


func _apply_nonlethal_boss_outcome(def: EnemyDef) -> void:
	if not _is_nonlethal_story_boss(def):
		return
	# The battle only establishes a narrow victory. The field cutscene applies
	# Zhao's escape and the protagonist's severe injury after his counter-palm;
	# setting those flags here made the evidence appear before the animation.
	GameState.set_flag(&"zhao_wuji_escape_cutscene_pending", true)


func _log(line: String) -> void:
	var localized_line: String = line
	localized_line = localized_line.replace("takes a guarded stance", "进入防御架势")
	localized_line = localized_line.replace("->", "→")
	battle_log.append_text(localized_line + "\n")
	battle_log.scroll_following = true
	battle_log.scroll_to_line(max(0, battle_log.get_line_count() - 1))
