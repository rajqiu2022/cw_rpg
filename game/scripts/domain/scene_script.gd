class_name SceneScript
extends Resource

## 探索场景脚本。一个场景 = 一张静态背景 + N 个互动热点。
## FieldController 加载本资源，渲染背景与热点按钮。

## is_walkable = true: 启用可行走模式（玩家自由移动 + NPC交互）
## is_walkable = false: 经典模式（背景图 + 热点按钮）

@export var scene_id: StringName = ""
@export var display_name: String = ""
@export var background_path: String = ""
@export var bgm_path: String = ""

## 进入场景时自动播放的对话（旁白），可空
@export var on_enter_dialog: DialogScript = null

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

## 玩家进入时的初始位置（归一化坐标，0~1 范围，(0.5, 0.8)=中下）
@export var player_spawn: Vector2 = Vector2(0.5, 0.8)

## Tiled / 模块化场景元素。每项格式：
## {
##   "id": "build_linxi_inn_storefront",
##   "texture": "res://art/modules/building/build_linxi_inn_storefront.png",
##   "pos": Vector2(0.30, 0.48),          # 归一化坐标，以 Tiled 对象中心 / tile 中心导入
##   "scale": Vector2(1.0, 1.0),
##   "z_index": 12,
##   "centered": true,
##   "require_flag": "",
##   "hide_flag": ""
## }
@export var scene_objects: Array[Dictionary] = []

## 程序化动态氛围物件。用于整图背景上的小动画叠加，不参与碰撞。
## {
##   "id": "inn_banner",
##   "type": "banner" | "smoke" | "glow",
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
##   "dialog_id": "ch1_s2_inn_keeper",
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
