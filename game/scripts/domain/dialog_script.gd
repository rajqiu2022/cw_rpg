class_name DialogScript
extends Resource

## 一组对话脚本（.tres）。包含若干 DialogNode，按 node_id 索引。
## DialogPlayer.play(script) 从 entry_node_id 开始播放。

@export var dialog_id: StringName = ""
@export var entry_node_id: StringName = &"start"
@export var nodes: Array[DialogNode] = []


func find_node_by_id(node_id: StringName) -> DialogNode:
	for n in nodes:
		if n.node_id == node_id:
			return n
	return null


func get_entry_node() -> DialogNode:
	return find_node_by_id(entry_node_id)
