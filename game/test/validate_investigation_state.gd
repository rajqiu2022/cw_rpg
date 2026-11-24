extends SceneTree


func _initialize() -> void:
	var state: Node = get_root().get_node("InvestigationState")
	state.reset_for_new_game()

	_assert(state.acquire_evidence(&"ev_ch1_stone_warning", &"test"), "configured evidence can be acquired")
	_assert(not state.acquire_evidence(&"ev_ch1_stone_warning", &"test"), "evidence acquisition is idempotent")
	_assert(state.verify_evidence(&"ev_ch1_stone_warning", &"npc_xingfantian"), "evidence can be verified")
	_assert(state.is_evidence_verified(&"ev_ch1_stone_warning"), "verified state is queryable")

	_assert(state.hear_testimony(&"ts_ch1_bandit_claim"), "configured testimony can be heard")
	_assert(state.adjust_faction_trust(&"huashan", 120) == 100, "faction trust clamps at upper bound")
	_assert(state.adjust_companion_trust(&"yuewuheng", -140) == -100, "companion trust clamps at lower bound")
	_assert(state.add_bond_event(&"yuewuheng", &"ch1_first_mercy"), "bond event can be recorded")
	state.set_city_outcome(&"zhuwei", &"west_ruin_cleared", true)
	state.set_method_flag(&"spared_witness", true)

	var saved: Dictionary = state.to_dict()
	state.reset_for_new_game()
	_assert(not state.has_evidence(&"ev_ch1_stone_warning"), "reset clears investigation state")
	state.from_dict(saved)
	_assert(state.is_evidence_verified(&"ev_ch1_stone_warning"), "evidence survives round trip")
	_assert(state.has_testimony(&"ts_ch1_bandit_claim"), "testimony survives round trip")
	_assert(state.has_bond_event(&"yuewuheng", &"ch1_first_mercy"), "bond event survives round trip")
	_assert(bool(state.get_city_outcome(&"zhuwei", &"west_ruin_cleared", false)), "city outcome survives round trip")

	print("PASS: InvestigationState config, bounds and save round trip")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("FAIL: %s" % message)
	quit(1)
