class_name DialogScript
extends Resource

## 一组对话脚本（.tres）。包含若干 DialogNode，按 node_id 索引。
## DialogPlayer.play(script) 从 entry_node_id 开始播放。

@export var dialog_id: StringName = ""
@export var entry_node_id: StringName = &"start"
@export var nodes: Array[DialogNode] = []
## Story access is independent from geographical access. These checks also
## apply to direct NPC interactions and play_at, not only scene introductions.
@export var required_story_flag: StringName = &""
@export var required_completed_quest: StringName = &""
@export var fallback_dialog_id: StringName = &""
@export var blocked_story_flag: StringName = &""
## One-time caches must remain available when the backpack cannot hold them.
@export var required_free_inventory_slots: int = 0


func find_node_by_id(node_id: StringName) -> DialogNode:
	for n in nodes:
		if n.node_id == node_id:
			return n
	return null


func get_entry_node() -> DialogNode:
	return find_node_by_id(entry_node_id)
