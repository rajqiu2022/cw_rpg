extends RefCounted
## Build-only pure proposal. No production caller, readiness, installation,
## source_paths, node mutation, geometry admission, or runtime approval.
const SCENE := &"ch4_s1_luoyang_yamen"
const NPC_ID := "district_life_yamen_clerk"
const PROPOSAL_PATH := "res://build/luoyang_city_full_rollout_20261022ap_system01/yamen_waiting_cluster_epoch01_retry1/author_delta_READY.json"
const PROPOSAL_SHA := "5295d53977f3773bd2861d384aad2f64a5b14b0c56461e3a67bdbd15d6d6505b"
const PARENT_AUTHOR_SHA := "d98c65879681b58feea64158a4d0bde33d2ef9fc6b8a25d7d2f33dc961a9c59c"
const OLD_FOOT := Vector2(1260, 1500)
const NEW_FOOT := Vector2(1130, 1360)
const WORLD := Vector2(3072, 2048)
const MERCHANT_IDLE := "res://art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f_v3_runtime.png"

static func same_typed(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b): return false
	if a is Dictionary:
		if a.size() != b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not same_typed(a[key], b[key]): return false
		return true
	if a is Array:
		if a.size() != b.size(): return false
		for index: int in a.size():
			if not same_typed(a[index], b[index]): return false
		return true
	return a == b

static func expected_parent_row() -> Dictionary:
	# Complete current CROWD.project row, not a partial identity allow-list.
	# AP_NPC's seven visual patches do not include this clerk.
	return {"npc_id": NPC_ID, "npc_name": "书办", "pos": OLD_FOOT / WORLD,
		"sprite_path": MERCHANT_IDLE, "walk_sprite_path": "", "scale": 1.0,
		"movement_mode": "idle", "patrol_axis": Vector2.RIGHT,
		"patrol_distance": 0.0, "patrol_speed": 22.0,
		"invert_patrol_facing": true, "idle_frame_seconds": 0.18,
		"walk_frame_seconds": 0.12, "dialog_id": "", "interaction_action": "",
		"district_life_ground_anchored": true}

static func compose_preparation_only(scene_id: StringName, rows: Array) -> Dictionary:
	# The real future entry point must first bind the fixed proposal, actual
	# native proof, Root art admission, scene owner and complete source receipt.
	# This pure method deliberately cannot attest any of those runtime gates.
	var out: Array = rows.duplicate(true)
	if scene_id != SCENE:
		return {"ok": true, "matched": false, "npcs": out, "runtime_admitted": false}
	if rows.size() != 6: return {"ok": false, "error": "YAMEN_SIX_PARENT_ROWS_REQUIRED"}
	var seen: Dictionary = {}; var changed_index: int = -1
	for index: int in rows.size():
		var value: Variant = rows[index]
		if not value is Dictionary or not value.get("npc_id") is String:
			return {"ok": false, "error": "YAMEN_PARENT_ROW_DOMAIN"}
		var id: String = value.npc_id
		if seen.has(id): return {"ok": false, "error": "YAMEN_DUPLICATE_PARENT_ID"}
		seen[id] = true
		if id == NPC_ID:
			if not same_typed(value, expected_parent_row()):
				return {"ok": false, "error": "YAMEN_COMPLETE_CLERK_PARENT_CHANGED"}
			changed_index = index
	if changed_index < 0: return {"ok": false, "error": "YAMEN_CLERK_ABSENT"}
	out[changed_index]["pos"] = NEW_FOOT / WORLD
	var restored: Array = out.duplicate(true)
	restored[changed_index]["pos"] = rows[changed_index]["pos"]
	if not same_typed(restored, rows):
		return {"ok": false, "error": "YAMEN_COMPLETE_ROW_ARRAY_INVERSE_FAILED"}
	return {"ok": true, "matched": true, "npcs": out,
		"changed_ids": [NPC_ID], "changed_keys": ["pos"],
		"whole_parent_array_typed_inverse": true, "runtime_admitted": false,
		"status": "BUILD_ONLY_PURE_PREPARATION_NOT_RUNTIME_NATIVE_OR_ART_ADMISSION"}
