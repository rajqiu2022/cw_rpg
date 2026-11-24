extends DialogScript


func find_node_by_id(node_id: StringName) -> DialogNode:
	if node_id == &"outcome":
		# The quest experience itself can raise insight. Consult the awarded skill
		# after settlement so the narration agrees with the reward receipt.
		var learned := &"canglong_three_turns" in GameState.player.skills
		return super.find_node_by_id(&"mastered" if learned else &"pending")
	return super.find_node_by_id(node_id)
