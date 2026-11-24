class_name SceneScript
extends Resource

## 探索场景脚本。一个场景 = 一张静态背景 + N 个互动热点。
## FieldController 加载本资源，渲染背景与热点按钮。

## is_walkable = true: 启用可行走模式（玩家自由移动 + NPC交互）
## is_walkable = false: 经典模式（背景图 + 热点按钮）

@export var scene_id: StringName = ""
@export var display_name: String = ""
@export var background_path: String = ""
## Optional platform-aware chunk set. When present, walkable gameplay streams
## this resource and keeps background_path only as UI preview / legacy fallback.
@export var streamed_background: StreamedBackgroundSet = null
@export var bgm_path: String = ""
## Optional looping environmental bed (rain, surf, wind). It is mixed under BGM
## and follows the same scene lifecycle, but keeps an independent fade/volume.
@export var ambience_path: String = ""
@export_range(-40.0, 6.0, 0.5) var ambience_volume_db: float = -14.0

## 进入场景时自动播放的对话（旁白），可空
@export var on_enter_dialog: DialogScript = null

## 可选主线门禁。世界地图允许提前游历城市时，未满足此旗标只跳过
## 自动主线开场，不阻止玩家进入场景、接触NPC或进行支线。
@export var on_enter_require_flag: StringName = &""

## 非空时，进场对话只播放一次。播放前会把该 flag 写为 true，避免往返场景反复播剧情。
@export var on_enter_once_flag: StringName = &""

## 互动热点列表。每项格式：
## {
##   "label": "客栈老板",       # 按钮显示文本
##   "action": "dialog:ch1_inn_keeper",  # 触发动作（语法同 DialogNode.on_end）
##   "icon": "",                          # 可选图标
##   "require_flag": "",                  # 可空，仅当 flag 为 true 时显示
##   "hide_flag": "",                     # 可空，flag 为 true 时隐藏（一次性）
## }
@export var hotspots: Array[Dictionary] = []

## --- 可行走模式扩展字段 (M7+) ---

## true = 玩家可在场景中自由移动（WASD/方向键）
## false = 经典模式：显示背景图 + 热点按钮
@export var is_walkable: bool = false

## Newly surveyed maps may author player/NPC positions at the visible feet.
## Opt-in preserves body-centred coordinates of existing maps and old layouts.
@export var actor_positions_are_feet: bool = false

## 城镇、村落与安全据点。安全聚落永远不触发随机战斗；剧情指定战斗仍可通过
## trigger_zones / NPC 对话显式发起。
@export var is_settlement: bool = false

## V2 自由行走地图空间数据。非空时优先使用，旧数组仅作为兼容回退。
@export var map_layout: WalkableMapLayout = null

## 玩家进入时的初始位置（归一化坐标，0~1 范围，(0.5, 0.8)=中下）
@export var player_spawn: Vector2 = Vector2(0.5, 0.8)

## Per-scene visual correction for compact interiors. Physics and interaction
## footprints remain unchanged, so this must never be used to compensate for a
## bad collision layout.
@export var player_visual_scale: float = 1.0

## Per-scene NPC visual multiplier. Wide overview maps use smaller actors than
## close field and indoor scenes, while preserving authored interaction points.
@export var npc_visual_scale: float = 1.0

## Camera magnification for large native-size maps. This scales the complete
## world (background, actors, props, collisions and interaction points) while
## leaving authored world coordinates unchanged.
@export_range(1.0, 2.0, 0.05) var camera_zoom: float = 1.0

## Tiled / 模块化场景元素。每项格式：
## {
##   "id": "build_linxi_inn_storefront",
##   "texture": "res://art/modules/building/build_linxi_inn_storefront.png",
##   "pos": Vector2(0.30, 0.48),          # 归一化坐标，以 Tiled 对象中心 / tile 中心导入
##   "scale": Vector2(1.0, 1.0),
##   "render_size_px": Vector2(160, 96), # optional; overrides scale using source pixels
##   "z_index": 12,
##   "centered": true,
##   "collision_size": Vector2(0.10, 0.06),   # 可选；独立物件脚底碰撞范围
##   "collision_offset": Vector2(0, 0.03),    # 可选；相对物件中心
##   "interaction_action": "dialog:open_box", # 可选；非空时可按交互键触发
##   "interaction_label": "打开木箱",
##   "interaction_size": Vector2(0.14, 0.12),
##   "interaction_offset": Vector2(0, 0.01),
##   "prompt_offset": Vector2(-0.055, -0.08),
##   "require_flag": "",
##   "hide_flag": ""
## }
@export var scene_objects: Array[Dictionary] = []

## Baked maps define dynamic foreground occluders on WalkableMapLayout rather
## than here. An occluder samples the scene background using cover_polygon and
## fades when the player's foot enters fade_region; it never changes collision.

## 程序化动态氛围物件。用于整图背景上的小动画叠加，不参与碰撞。
## {
##   "id": "inn_banner",
##   "type": "banner" | "texture_sway" | "flame" | "smoke" | "mist_drift" | "water_shimmer" | "snow_drift" | "rain_field" | "rain_splash" | "glow",
##   "pos": Vector2(0.25, 0.30),
##   "size": Vector2(0.05, 0.10),
##   "color": "#b73328",
##   "z_index": 25,
##   "speed": 1.0,
##   "require_flag": "",
##   "hide_flag": ""
## }
@export var animated_props: Array[Dictionary] = []

## 场景中的 NPC 列表。每项格式：
## {
##   "npc_id": "innkeeper",
##   "npc_name": "客栈老板",
##   "pos": Vector2(0.3, 0.4),            # 归一化坐标
##   "portrait_path": "res://art/characters/portrait_shenbanzhan_friendly.png",
##   "sprite_path": "res://art/characters/protagonist_neutral.png",
##   "conversation_sprite_paths": {"down": "res://...", "up": "res://...", "left": "res://...", "right": "res://..."},
##   "dialog_id": "ch1_s2_inn_keeper",
##   "interaction_action": "spar:market_blade:wandering_blademaster:流浪刀客:30:8",
##   "dialog_variants": [{"dialog_id": "ch2_followup", "require_flags": ["clue_a", "clue_b"]}],
##   "scale": 0.12,                       # sprite 缩放比例
##   "require_flag": "",                  # 可空，仅当 flag 为 true 时显示
##   "hide_flag": "",                     # 可空，flag 为 true 时隐藏
## }
@export var npcs: Array[Dictionary] = []

## 场景出口/传送门。每项格式：
## {
##   "label": "前往竹林",
##   "pos": Vector2(0.9, 0.5),            # 归一化中心位置
##   "size": Vector2(0.12, 0.4),          # 归一化大小
##   "target_scene": "ch1_s1_road",       # 目标场景 ID
##   "target_pos": Vector2(0.1, 0.5),     # 目标场景中的玩家初始位置
##   "require_flag": "",                  # 可空，需要 flag 才显示
##   "hide_flag": "",                     # 可空，flag 为 true 时隐藏
## }
@export var exits: Array[Dictionary] = []

## 静态障碍矩形。仅可行走模式使用，坐标和尺寸均为归一化 0~1。
## {
##   "id": "stall_block",
##   "pos": Vector2(0.35, 0.62),
##   "size": Vector2(0.20, 0.10),
##   "require_flag": "",
##   "hide_flag": ""
## }
@export var collision_rects: Array[Dictionary] = []

## 剧情触发区。玩家进入矩形后执行 action，语法同 SceneRouter.resolve_action()。
## {
##   "id": "forest_ambush",
##   "pos": Vector2(0.70, 0.55),
##   "size": Vector2(0.12, 0.18),
##   "action": "battle:masked_killer_leader",
##   "require_flag": "",
##   "hide_flag": "defeated_masked_killer_leader"
## }
@export var trigger_zones: Array[Dictionary] = []

## 可重复野外遭遇。仅在可行走场景中生效；由 FieldWalkableController
## 按实际移动距离结算，避免站桩或对话期间反复触发战斗。
@export var encounter_enemy_ids: Array[StringName] = []
## Optional weighted formations for random encounters. Each entry uses:
## {"enemy_ids": [&"bandit_scout", &"bandit_scout"], "weight": 2.0}
## When empty, encounter_enemy_ids keeps its legacy single-enemy behavior.
@export var encounter_groups: Array[Dictionary] = []
## High-risk regions may keep authored three-enemy formations even when the
## player travels alone.  Leave false in early regions so the normal solo cap
## still protects the onboarding curve.
@export var encounter_allow_full_group_for_solo: bool = false
@export var encounter_step_distance: float = 0.0
@export var encounter_chance: float = 0.0
@export var encounter_require_flag: StringName = &""
