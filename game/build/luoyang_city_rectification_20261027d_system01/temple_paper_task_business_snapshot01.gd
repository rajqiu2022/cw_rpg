extends RefCounted
## Original Temple paper-task branch only; no C owner or other-city runtime branches.
const Presentation=preload("res://build/luoyang_city_rectification_20261027d_system01/presentation_definition.gd")
const SPEC_PATH := "res://data/luoyang_city_tasks_20261016/overlay.json"
const SPEC_SHA := "9e654f67be48a8da93232e0f2b66e109cdd769577fb53545f72f81885e90a3bb"
const TASK_BIND_PATH := "res://build/luoyang_layout_quest_20261018t_task_integration_source01/task_runtime_binding.json"
const TASK_BIND_SHA := "28c74795ce107f9e6a5f845394dad7e7ffe0969a45502d8c46aa128ce8a4406e"
const PREFIX := "luoyang_city_tasks_20261016/"
const TASK_IDS := ["ch4_s3_luoyang_market","ch4_s2_canal_docks","ch4_s4_ancient_temple"]
const IDS := ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s3_luoyang_market","ch4_s2_canal_docks","ch4_s4_ancient_temple"]
const ACTIVE := 1
const COMPLETED := 2
const CANAL := "q_ch4_side_06_canal_grudge"
const PAPER := "q_ch4_side_02_luoyang_paper"
const HANJIA := "q_ch4_side_07_hanjia_blade"
static func _v(value: Array) -> Vector2:
	return Vector2(float(value[0]),float(value[1]))

static func _truth(flags: Dictionary,key: String) -> bool:
	return bool(flags.get(key,flags.get(StringName(key),false)))

static func _status(states: Dictionary,id: String) -> int:
	return int(states.get(id,states.get(StringName(id),0)))

static func _dialog(id: String) -> String: return PREFIX+id

static func _spec() -> Dictionary:
	if FileAccess.get_sha256(SPEC_PATH)!=SPEC_SHA: return {}
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(SPEC_PATH))
	if not data is Dictionary or data.get("version")!=1 or data.get("id")!="luoyang_city_tasks_20261016": return {}
	for path: String in data.get("source_pins",{}):
		if not path.begins_with("res://") or ".." in path or FileAccess.get_sha256(path)!=data.source_pins[path]: return {}
	return data

static func _task_binding() -> Dictionary:
	if FileAccess.get_sha256(TASK_BIND_PATH)!=TASK_BIND_SHA: return {}
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(TASK_BIND_PATH))
	return data if data is Dictionary and data.get("status")=="SOURCE_READY_NOT_DEPLOYED" and data.get("same_id_quest_canonical_resolution_required")==true and not data.get("source_sha256",{}).is_empty() else {}

static func _task_sources_ready() -> bool:
	var binding:=_task_binding()
	if binding.is_empty(): return false
	for path: String in binding.source_sha256:
		if not path.begins_with("res://") or ".." in path or FileAccess.get_sha256(path)!=binding.source_sha256[path]: return false
	return true

static func task_successor_ready() -> bool: return _task_sources_ready()

static func stages(flags: Dictionary,states: Dictionary) -> Dictionary:
	var canal := "not_started"
	if _status(states,CANAL)==COMPLETED: canal="completed"
	elif _status(states,CANAL)==ACTIVE:
		canal="accepted"
		if _truth(flags,"canal_grudge_started") and _truth(flags,"canal_grudge_route_heard"):
			canal="witness"
			if _truth(flags,"canal_grudge_warehouse_located"):
				canal="located"
				if _truth(flags,"canal_grudge_evidence_found"): canal="evidence"
	elif _status(states,CANAL)!=0: canal="blocked"
	var paper := "not_started"
	if _status(states,PAPER)==COMPLETED: paper="completed"
	elif _status(states,PAPER)==ACTIVE:
		paper="accepted"
		if _truth(flags,"luoyang_paper_started") and _truth(flags,"luoyang_paper_artisan_hint"):
			paper="hint"
			if _truth(flags,"luoyang_paper_materials_found"): paper="materials"
	elif _status(states,PAPER)!=0: paper="blocked"
	return {"canal":canal,"paper":paper}

static func _fail(message: String) -> Dictionary:
	return {"ok":false,"matched":true,"error":message}

static func project(scene: SceneScript,flags: Dictionary,quest_states: Dictionary,input_interactions: Array) -> Dictionary:
	if scene==null: return _fail("TASK_SOURCE_NULL")
	var result: Dictionary={"ok":true,"matched":false,"error":"","npcs":scene.npcs.duplicate(true),"visual_objects":scene.map_layout.visual_objects.duplicate(true) if scene.map_layout!=null else scene.scene_objects.duplicate(true),"interactions":input_interactions.duplicate(true),"receipt":{}}
	var id: String=String(scene.scene_id)
	var spec: Dictionary=_spec()
	if spec.is_empty(): return _fail("TASK_SPEC_OR_SOURCE_SHA_CHANGED")
	if id!=spec.temple.scene_id: return _fail("PURE_TEMPLE_ONLY")
	var phase: Dictionary=stages(flags,quest_states)
	var interactions: Array=result.interactions
	if scene.resource_path!=spec.temple.resource_path or scene.background_path!=spec.temple.background_path or scene.actor_positions_are_feet: return _fail("TASK_TEMPLE_SOURCE_CHANGED")
	var found := -1
	for i in range(interactions.size()):
		if interactions[i].get("action")==spec.temple.old_action:
			if found>=0: return _fail("TASK_TEMPLE_PAPER_DUPLICATE")
			found=i
	if found<0: return _fail("TASK_TEMPLE_PAPER_INTERACTION_MISSING")
	var entry: Dictionary=interactions[found]
	if entry.get("pos")!=_v(spec.temple.position_uv) or entry.get("require_flag")!=spec.temple.old_require_flag or entry.get("hide_flag")!=spec.temple.old_hide_flag: return _fail("TASK_TEMPLE_PAPER_ANCHOR_CHANGED")
	if phase.paper=="hint" and _truth(flags,"luoyang_paper_started"):
		entry["action"]="dialog:"+_dialog("paper_materials")
		entry["require_flag"]="luoyang_paper_artisan_hint"; entry["hide_flag"]="luoyang_paper_materials_found"; entry["require_quest_active"]=PAPER
		entry["label"]="废纸坊檐下 · 寻找干藤皮与旧木模"
		entry["interaction_visual_kind"]="ledger"
	else: interactions.remove_at(found)

	result.matched=true
	result.receipt={"overlay_id":spec.id,"spec_sha256":SPEC_SHA,"source_scene_id":id,"stage":phase,"source_resource_unmodified":true,"navigation_modified":false,"ordinary_cargo_is_not_quest_evidence":true,"candidate_only":true,"runtime_Physics_acceptance_pending":true}
	var presentation: Dictionary=Presentation.readiness()
	if presentation.get("ok")!=true: return presentation
	var visual: Dictionary=Presentation.compose_exact(scene.scene_id,result.npcs,presentation.author)
	if visual.get("ok")!=true: return visual
	result.npcs=visual.npcs
	return result
