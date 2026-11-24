extends RefCounted

enum Beat { NORMAL, WINDUP, RELEASE }

const PROFILES := {
	&"zhuwei_cave_wolf": {
		"opening": [&"basic_attack"], "pressed": [&"wolf_rending_bite", &"basic_attack"],
		"finisher": &"wolf_king_pounce", "cue": "伏低前身，死死盯住猎物",
	},
	&"boss_zhao_wuji": {
		"opening": [&"zhao_broken_gate_strike", &"basic_attack"], "pressed": [&"toxic_needle", &"heavy_swing"],
		"finisher": &"zhao_black_wind_sweep", "cue": "拧腰拖刀，刀锋贴地蓄势",
	},
	&"masked_killer_ambush": {
		"opening": [&"toxic_needle", &"basic_attack"], "pressed": [&"heavy_swing", &"toxic_needle"],
		"finisher": &"masked_crosscut", "cue": "压低刀锋，侧身寻隙",
	},
	&"wulin_examiner": {
		"opening": [&"basic_attack", &"examiner_staff_sweep"], "pressed": [&"examiner_staff_sweep"],
		"finisher": &"examiner_staff_press", "cue": "沉肩立棍，踏稳马步",
	},
	&"fake_liuyun_assassin": {
		"opening": [&"fake_liuyun_ambush_slash", &"basic_attack"], "pressed": [&"toxic_needle", &"fake_liuyun_ambush_slash"],
		"finisher": &"fake_liuyun_return_cut", "cue": "反手藏刃，绕向目标侧翼",
	},
	&"ch5_false_banner_captain": {
		"opening": [&"zhao_broken_gate_strike", &"basic_attack"], "pressed": [&"zhao_broken_gate_strike"],
		"finisher": &"ch5_false_banner_signal", "cue": "举旗压阵，准备下令夹击",
	},
	&"ch6_archive_reclaimer": {
		"opening": [&"mingwu_wuyin_sanshi", &"basic_attack"], "pressed": [&"mingwu_saofeng", &"mingwu_wuyin_sanshi"],
		"finisher": &"mingwu_yinying_duoming", "cue": "袖底透出一线青烟，守住要害可将烈毒减为寻常针毒",
	},
	&"ch7_mingwu_record_guard": {
		"opening": [&"mingwu_wuyin_sanshi", &"basic_attack"], "pressed": [&"toxic_needle", &"mingwu_wuyin_sanshi"],
		"finisher": &"mingwu_counterseal_needles", "cue": "张开双袖，针尖直取气海，此时护体可将内伤积累减半",
	},
	&"ch8_su_wusheng_final": {
		"opening": [&"mingwu_wuyin_sanshi", &"basic_attack"], "pressed": [&"mingwu_yinying_duoming", &"mingwu_wuyin_sanshi"],
		"finisher": &"ch8_su_teapot_meridian_rain", "cue": "托盏聚气，茶雨将至！此时防御可避茶毒，迫他露出破绽",
	},
	&"ch8_xueying_last_guard": {
		"opening": [&"mingwu_wuyin_sanshi", &"basic_attack"], "pressed": [&"toxic_needle", &"mingwu_wuyin_sanshi"],
		"finisher": &"ch8_xueying_shadow_fan", "cue": "收刃伏步，身侧隐现残影",
	},
}

var _turns: Dictionary = {}


func decide(enemy: BattleCombatant, available: Array[StringName], target: StringName) -> Dictionary:
	var profile: Dictionary = PROFILES[enemy.definition_id]
	if not _turns.has(enemy.unit_id):
		_turns[enemy.unit_id] = {"normal_turns": 0, "opening_index": 0, "pressed_index": 0, "target": &"", "charging": false, "pressed": false}
	var state: Dictionary = _turns[enemy.unit_id]
	var finisher: StringName = profile.finisher
	var phase_changed: bool = not state.pressed and enemy.stats.hp * 100 <= enemy.stats.max_hp * 55
	if phase_changed:
		state.pressed = true
	if state.charging:
		var locked_target: StringName = state.target
		cancel(enemy.unit_id)
		if finisher in available:
			return {"beat": Beat.RELEASE, "skill": finisher, "target": locked_target, "phase_changed": phase_changed}
		return {"beat": Beat.NORMAL, "skill": &"basic_attack", "phase_changed": phase_changed}
	if state.normal_turns >= (1 if state.pressed else 2) and finisher in available:
		state.charging = true
		state.target = target
		return {"beat": Beat.WINDUP, "skill": finisher, "target": target, "phase_changed": phase_changed}
	var rotation: Array = profile.pressed if state.pressed else profile.opening
	var index_key := "pressed_index" if state.pressed else "opening_index"
	var selected: StringName = rotation[int(state[index_key]) % rotation.size()]
	state[index_key] += 1
	state.normal_turns += 1
	return {"beat": Beat.NORMAL, "skill": selected if selected in available else &"basic_attack", "phase_changed": phase_changed}


func cancel(unit_id: StringName) -> bool:
	var state: Dictionary = _turns.get(unit_id, {})
	if not state.get("charging", false):
		return false
	state.charging = false
	state.target = &""
	state.normal_turns = 0
	return true
