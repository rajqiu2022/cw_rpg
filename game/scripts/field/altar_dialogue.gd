extends DialogScript

const CURSOR := "ch8_altar_dialogue_cursor"
const BEATS := [&"assembly", &"declare", &"challenge", &"draw", &"shield"]

func get_entry_node() -> DialogNode:
	var cursor := StringName(str(GameState.flags.get(CURSOR, "")))
	if BEATS.has(cursor):
		return find_node_by_id(cursor)
	return super.get_entry_node()
