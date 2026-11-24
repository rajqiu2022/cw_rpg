extends RefCounted
## NEW source-only candidate. Production adapters/scenes are read-only.
## The producer must rebind exact source hashes before any runtime adoption.

const SIZE := Vector2(1536.0, 1024.0)
const NOT_STARTED := 0
const ACTIVE := 1
const COMPLETED := 2
const FAILED := 3
const PREFIX := "luoyang_layout_quest_20261018t/"

const LONGMEN := "q_ch4_side_04_longmen_mystery"
const BAIMA := "q_ch4_side_05_baima_bell"
const PEONY := "q_ch4_side_03_peony_poetry"

const LONGMEN_STARTED := "longmen_mystery_started_20261018t"
const LONGMEN_EVIDENCE := "longmen_mystery_investigated_20261018t"
const BAIMA_STARTED := "baima_bell_started_20261018t"
const BAIMA_EVIDENCE := "baima_bell_investigated_20261018t"
const PEONY_STARTED := "peony_poetry_started_20261018t"
const PEONY_ANSWERED := "peony_poetry_answered_20261018t"

# Deliberately fail closed until the producer supplies the approved, source-
# Source-pinned 160x160 single-frame idle-down monk image.  The same correct-
# identity full-body image is an explicit temporary portrait; this is not
# final portrait-art credit and must never fall back to a generic long-haired
# character.  Scale is 140 / actual A>0 height 148.
const MONK_SPRITE := "res://art/characters/luoyang_layout_quest_20261018t/npc_temple_gate_monk_idle_down_1f_v1.png"
const MONK_PORTRAIT := MONK_SPRITE
const MONK_ASSET_SHA := "6268061eab18d2bf8c1ea0c13873f0d718feb82a119f00a67edf7c52bcb077ad"
const MONK_ASSET_BYTES := 16832
const MONK_SCALE := 0.9459459459459459

const LONGMEN_MONK_FOOT := Vector2(936.0, 900.0)
const LONGMEN_INVESTIGATE_FOOT := Vector2(380.0, 600.0)
const BAIMA_MONK_FOOT := Vector2(600.0, 900.0)
const BAIMA_INVESTIGATE_FOOT := Vector2(1320.0, 670.0)
const MARKET_EXIT_FOOT := Vector2(240.0, 850.0)
const DOCKS_EXIT_FOOT := Vector2(1296.0, 850.0)
const LEGACY_TARGET_POS := Vector2(0.12, 0.75)

static func _status(states: Dictionary, qid: String) -> int:
	return int(states.get(qid, states.get(StringName(qid), NOT_STARTED)))

static func _truth(flags: Dictionary, key: String) -> bool:
	return bool(flags.get(key, flags.get(StringName(key), false)))

static func _dialog(name: String) -> String:
	return PREFIX + name

static func _monk_asset_ready() -> bool:
	return (
		FileAccess.file_exists(MONK_SPRITE)
		and FileAccess.get_sha256(MONK_SPRITE) == MONK_ASSET_SHA
		and FileAccess.get_file_as_bytes(MONK_SPRITE).size() == MONK_ASSET_BYTES
	)

static func _quest_phase(qid: String, started: String, evidence: String, flags: Dictionary, states: Dictionary) -> String:
	var status := _status(states, qid)
	if status == COMPLETED:
		return "completed"
	if status == FAILED:
		return "failed"
	if status == NOT_STARTED:
		return "not_started"
	if status != ACTIVE:
		return "invalid"
	if _truth(flags, evidence):
		return "evidence"
	if _truth(flags, started):
		return "started"
	return "accepted_without_stage"

static func phases(flags: Dictionary, states: Dictionary) -> Dictionary:
	return {
		"longmen": _quest_phase(LONGMEN, LONGMEN_STARTED, LONGMEN_EVIDENCE, flags, states),
		"baima": _quest_phase(BAIMA, BAIMA_STARTED, BAIMA_EVIDENCE, flags, states),
		"peony": _quest_phase(PEONY, PEONY_STARTED, PEONY_ANSWERED, flags, states),
	}

static func _npc_dialog(kind: String, phase: String) -> String:
	if phase == "not_started":
		return _dialog(kind + "_offer")
	if phase == "evidence":
		return _dialog(kind + "_report")
	if phase == "completed":
		return _dialog(kind + "_after")
	return _dialog(kind + "_progress")

static func _unique_index(rows: Array, key: String, value: String) -> int:
	var found := -1
	for index in rows.size():
		if rows[index] is Dictionary and String(rows[index].get(key, "")) == value:
			if found >= 0:
				return -2
			found = index
	return found

static func _project_monk(rows: Array, id: String, name: String, foot: Vector2, dialog_id: String) -> bool:
	var index := _unique_index(rows, "npc_id", id)
	if index < 0:
		return false
	var row: Dictionary = rows[index]
	if (
		String(row.get("npc_name", "")) != name
		or row.get("pos") != foot / SIZE
		or float(row.get("scale", 0.0)) != MONK_SCALE
		or String(row.get("sprite_path", "")) != MONK_SPRITE
		or String(row.get("portrait_path", "")) != MONK_PORTRAIT
		or String(row.get("movement_mode", "idle")) != "idle"
		or String(row.get("conversation_base_facing", "front")) != "front"
	):
		return false
	row.erase("hide_flag")
	row.erase("require_flag")
	row["interaction_action"] = ""
	row["dialog_variants"] = []
	row["dialog_id"] = dialog_id
	rows[index] = row
	return true

static func _move_temple_portals(portals: Array) -> bool:
	if portals.size() != 2:
		return false
	var expected := {
		"legacy_portal_6": {"target": "ch4_s3_luoyang_market", "foot": MARKET_EXIT_FOOT},
		"legacy_portal_7": {"target": "ch4_s2_canal_docks", "foot": DOCKS_EXIT_FOOT},
	}
	for portal: Dictionary in portals:
		var id := String(portal.get("id", ""))
		if not expected.has(id):
			return false
		if String(portal.get("target_scene", "")) != String(expected[id].target):
			return false
		if portal.get("target_pos") != LEGACY_TARGET_POS:
			return false
		# Keep the existing ordinary ExitZone path. Field already binds the
		# paired return to `pos` when source_spawn_pos is absent; adding that key
		# would select the unrelated outskirts_exit_zone implementation.
		if portal.has("source_spawn_pos") or portal.has("source_foot_pos"):
			return false
		var source_pos: Vector2 = expected[id].foot / SIZE
		portal["pos"] = source_pos
	var first_foot: Vector2 = Vector2(portals[0].pos) * SIZE
	var second_foot: Vector2 = Vector2(portals[1].pos) * SIZE
	return first_foot.distance_to(second_foot) >= 1000.0

static func project_temple(base: Dictionary, source_portals: Array, flags: Dictionary, states: Dictionary) -> Dictionary:
	## `base` is the already source-validated result from the existing Temple adapter.
	## The current adapter does not return portals, so its source-validated
	## `scene.map_layout.portals` closure is supplied explicitly and kept separate.
	if base.get("ok") != true or base.get("matched") != true:
		return {"ok": false, "error": "TASK_BASE_TEMPLE_REFUSED"}
	var npcs: Array = base.get("npcs", []).duplicate(true)
	var interactions: Array = base.get("interactions", []).duplicate(true)
	var portals: Array = source_portals.duplicate(true)
	if npcs.size() != 2:
		return {"ok": false, "error": "TASK_BASE_TEMPLE_NPC_COUNT_CHANGED"}
	if MONK_PORTRAIT.is_empty() or MONK_SCALE <= 0.0 or not _monk_asset_ready():
		return {"ok": false, "error": "TASK_MONK_ASSET_SOURCE_CHANGED"}
	if _unique_index(interactions, "id", "legacy_hotspot_4") != -1 or _unique_index(interactions, "id", "legacy_hotspot_5") != -1:
		return {"ok": false, "error": "TASK_LEGACY_SPEAKER_HOTSPOT_STILL_PRESENT"}
	var stage := phases(flags, states)
	if not _project_monk(npcs, "temple_cave_keeper_20261018t", "守窟僧", LONGMEN_MONK_FOOT, _npc_dialog("longmen", stage.longmen)):
		return {"ok": false, "error": "TASK_LONGMEN_MONK_SOURCE_CHANGED"}
	if not _project_monk(npcs, "temple_bell_keeper_20261018t", "守钟僧", BAIMA_MONK_FOOT, _npc_dialog("baima", stage.baima)):
		return {"ok": false, "error": "TASK_BAIMA_MONK_SOURCE_CHANGED"}
	if stage.longmen == "started":
		interactions.append({
			"id": "temple_longmen_investigate_20261018t",
			"pos": LONGMEN_INVESTIGATE_FOOT / SIZE,
			"size": Vector2(0.11, 0.12),
			"activation": "interact",
			"label": "查验石壁水槽与暗缝",
			"action": "dialog:" + _dialog("longmen_investigate"),
			"require_quest_active": LONGMEN,
			"require_flag": LONGMEN_STARTED,
			"hide_flag": LONGMEN_EVIDENCE,
		})
	if stage.baima == "started":
		interactions.append({
			"id": "temple_baima_investigate_20261018t",
			"pos": BAIMA_INVESTIGATE_FOOT / SIZE,
			"size": Vector2(0.11, 0.12),
			"activation": "interact",
			"label": "查验钟楼东墙砖缝",
			"action": "dialog:" + _dialog("baima_investigate"),
			"require_quest_active": BAIMA,
			"require_flag": BAIMA_STARTED,
			"hide_flag": BAIMA_EVIDENCE,
		})
	if not _move_temple_portals(portals):
		return {"ok": false, "error": "TASK_TEMPLE_PORTAL_ID_TARGET_OR_SEPARATION_CHANGED"}
	return {
		"ok": true,
		"matched": true,
		"npcs": npcs,
		"interactions": interactions,
		"portals": portals,
		"visual_objects": base.get("visual_objects", []).duplicate(true),
		"receipt": {
			"candidate_only": true,
			"phase": stage,
			"two_visible_monk_entities": true,
			"npc_interaction_uses_entity_foot": true,
			"monk_asset_sha256": MONK_ASSET_SHA,
			"monk_asset_bytes": MONK_ASSET_BYTES,
			"monk_hframes": 1,
			"monk_scale": MONK_SCALE,
			"monk_ordinary_interaction_enabled": true,
			"legacy_speaker_hotspots_removed": ["legacy_hotspot_4", "legacy_hotspot_5"],
			"portal_source_and_implicit_return_feet_px": [MARKET_EXIT_FOOT, DOCKS_EXIT_FOOT],
			"portal_target_pos_preserved": LEGACY_TARGET_POS,
			"ordinary_exit_zone_preserved": true,
			"actual_city_arrival_remains_current_revision_authority": true,
		}
	}

static func project_market(base: Dictionary, flags: Dictionary, states: Dictionary) -> Dictionary:
	## `base` is the already source-validated current Market task projection.
	if base.get("ok") != true or base.get("matched") != true:
		return {"ok": false, "error": "TASK_BASE_MARKET_REFUSED"}
	var npcs: Array = base.get("npcs", []).duplicate(true)
	var index := _unique_index(npcs, "npc_id", "luoyang_poetry_host")
	if index < 0:
		return {"ok": false, "error": "TASK_PEONY_HOST_MISSING_OR_DUPLICATE"}
	var stage := phases(flags, states)
	npcs[index].erase("hide_flag")
	# Peony's evidence step is the host's explicit riddle response, not a
	# background hotspot.  Keep the same visible host and route ACTIVE+started
	# to the separate answer dialogue; only evidence returns to claim.
	if stage.peony == "started":
		npcs[index]["dialog_id"] = _dialog("peony_investigate")
	else:
		npcs[index]["dialog_id"] = _npc_dialog("peony", stage.peony)
	return {
		"ok": true,
		"matched": true,
		"npcs": npcs,
		"interactions": base.get("interactions", []).duplicate(true),
		"visual_objects": base.get("visual_objects", []).duplicate(true),
		"receipt": {
			"candidate_only": true,
			"peony_phase": stage.peony,
			"host_entity_preserved": true,
			"same_dialog_accept_and_complete_removed": true,
		}
	}

static func owns_dialog(id: String) -> bool:
	return id.begins_with(PREFIX)

static func authorize_dialog(id: String, flags: Dictionary, states: Dictionary) -> bool:
	if not owns_dialog(id):
		return true
	var name := id.trim_prefix(PREFIX)
	var stage := phases(flags, states)
	match name:
		"longmen_offer": return stage.longmen == "not_started"
		"longmen_progress": return stage.longmen in ["started", "accepted_without_stage"]
		"longmen_investigate": return stage.longmen == "started"
		"longmen_report": return stage.longmen == "evidence"
		"longmen_after": return stage.longmen == "completed"
		"baima_offer": return stage.baima == "not_started"
		"baima_progress": return stage.baima in ["started", "accepted_without_stage"]
		"baima_investigate": return stage.baima == "started"
		"baima_report": return stage.baima == "evidence"
		"baima_after": return stage.baima == "completed"
		"peony_offer": return stage.peony == "not_started"
		"peony_progress": return stage.peony in ["started", "accepted_without_stage"]
		"peony_investigate": return stage.peony == "started"
		"peony_report": return stage.peony == "evidence"
		"peony_after": return stage.peony == "completed"
	return false
