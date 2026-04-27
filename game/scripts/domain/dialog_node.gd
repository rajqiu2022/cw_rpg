class_name DialogNode
extends Resource

## 一段对话节点。一个 DialogScript 内含若干 DialogNode 串成图（不一定是链）。
## DialogPlayer 一次播放一段，按 on_end 解析跳转/动作。
##
## 设计要点（v0.2.0-m2 重构）：
##   - "附带效果"（给物品/给金/置 flag/接任务）独立成数组字段，可叠加。
##   - "结束动作"（on_end）只负责"跳到哪"，不再混入副作用。
##   - choices 选项的副作用同样用结构化字段表达，避免字符串 hack。
##
## 一个 node 的执行顺序：
##   1. 显示 speaker + text + 立绘
##   2. 若有 choices，等待玩家选 → 应用 choice 的 set_flags → 走 choice.next
##   3. 若无 choices，等玩家按继续 → 应用本节点 give_items / give_gold / set_flags / accept_quest
##                                 → 解析 on_end 跳转

@export var node_id: StringName = ""

## 显示
@export var speaker: String = ""              ## "客栈老板" / "" 表示旁白
@export var portrait_path: String = ""        ## 立绘路径，可空
@export var text: String = ""                 ## 台词内容（支持 BBCode）

## 选项。空数组 = "按任意键继续"。每个元素结构：
##   {
##     "text":     "我帮你",            # 选项文字
##     "next":     "node_helped",       # 选完跳到哪个 node_id；"" 或 "end" 即结束
##     "set_flag": {"helped": true},    # 可选，选完置 flag
##   }
@export var choices: Array[Dictionary] = []

## 本节点的"附带效果"，仅在没有 choices（按继续）时触发；
## 有 choices 时这些字段被忽略（副作用应放到 choice 自己里）。
@export var give_items: Array[Dictionary] = []     ## [{"id": "iron_sword", "count": 1}]
@export var give_gold: int = 0
@export var set_flags: Array[Dictionary] = []      ## [{"key": "has_map", "value": true}]
@export var accept_quest: StringName = &""
@export var complete_quest: StringName = &""

## 结束动作（仅"跳转"语义，不混副作用）。语法：
##   ""              / "end"   → 结束对话，回到调用方
##   "next:node_id"           → 跳到本 script 内的另一段
##   "battle:enemy_id"        → 启动战斗（结束对话）
##   "scene:scene_id"         → 切换探索场景（结束对话）
##   "shop:shop_id"           → 打开商店（结束对话）
##   "open_inventory"         → 打开背包 UI（M5）
@export var on_end: String = "end"


func has_choices() -> bool:
	return choices.size() > 0
