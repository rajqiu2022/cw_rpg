class_name DialogNode
extends Resource

## 一段对话节点。一个对话 .tres 内含若干 DialogNode 串成链。
## DialogPlayer 一次播放一段，按 next 跳到下一段，nil 即结束。

@export var node_id: StringName = ""
@export var speaker: String = ""              ## "客栈老板" / "" 表示旁白
@export var portrait_path: String = ""        ## 立绘（可空）
@export var text: String = ""                 ## 台词内容

## 选项，空数组表示"按任意键继续"。每个元素：
## {"text": "我不感兴趣", "next": "node_b", "set_flag": ["x", true]}
@export var choices: Array[Dictionary] = []

## 节点结束后的动作（无选项时使用）。语法：
##   "next:node_b"          直接跳转
##   "battle:thug_lone"     启动战斗
##   "shop:qingfeng_inn"    打开商店
##   "scene:ch1_s2_main"    切换场景
##   "give_item:iron_sword:1"
##   "give_gold:50"
##   "set_flag:has_map:true"
##   "accept_quest:main_ch1_to_qingfeng"
##   "complete_quest:main_ch1_to_qingfeng"
##   "end"                  结束对话
@export var on_end: String = "end"


func has_choices() -> bool:
	return choices.size() > 0
