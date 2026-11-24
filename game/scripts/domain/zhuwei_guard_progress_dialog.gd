extends DialogScript


func get_entry_node() -> DialogNode:
	if GameState.get_flag(&"defeated_boss_zhao_wuji"):
		return find_node_by_id(&"after_ruin")
	if GameState.get_flag(&"clue_west_ruin_supply_route"):
		return find_node_by_id(&"after_evidence")
	if GameState.get_flag(&"defeated_zhuwei_cave_wolf"):
		return find_node_by_id(&"after_wolf")
	return super.get_entry_node()
