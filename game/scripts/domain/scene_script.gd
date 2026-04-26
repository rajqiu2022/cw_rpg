class_name SceneScript
extends Resource

## 探索场景脚本。一个场景 = 一张静态背景 + N 个互动热点。
## FieldController 加载本资源，渲染背景与热点按钮。

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
