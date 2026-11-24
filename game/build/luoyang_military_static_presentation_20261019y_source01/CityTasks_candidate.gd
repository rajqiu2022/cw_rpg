extends RefCounted
## Fifth-layer task projection only. Caller keeps its proven _current_scene.
## Does not prepare/resolve C, write a Resource, mutate flags or award anything.
const C = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const T = preload("res://scripts/city/luoyang_layout_quest_20261018t.gd")
const MILITARY_Y = preload("res://scripts/city/luoyang_military_static_presentation_20261019y.gd")
const SPEC_PATH := "res://data/luoyang_city_tasks_20261016/overlay.json"
const SPEC_SHA := "9e654f67be48a8da93232e0f2b66e109cdd769577fb53545f72f81885e90a3bb"
const TASK_BIND_PATH := "res://build/luoyang_layout_quest_20261018t_task_integration_source01/task_runtime_binding.json"
const TASK_BIND_SHA := "28c74795ce107f9e6a5f845394dad7e7ffe0969a45502d8c46aa128ce8a4406e"
const PREFIX := "luoyang_city_tasks_20261016/"
const IDS := ["ch4_s3_luoyang_market","ch4_s2_canal_docks","ch4_s4_ancient_temple","ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen"]
const PRESENTATION_ONLY_IDS := ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen"]
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

static func source_paths() -> Dictionary:
	var spec:=_spec()
	if spec.is_empty(): return {}
	var paths: Dictionary={SPEC_PATH:true,"res://scripts/city/luoyang_city_tasks_20261016.gd":true,TASK_BIND_PATH:true}
	for path: String in spec.source_pins: paths[path]=true
	var binding:=_task_binding()
	if binding.is_empty(): return {}
	for path: String in binding.source_sha256: paths[path]=true
	paths.merge(MILITARY_Y.source_paths())
	return paths

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

static func owns_dialog(id: String) -> bool: return id.begins_with(PREFIX) or T.owns_dialog(id)

static func authorize_dialog(id: String,flags: Dictionary,states: Dictionary) -> bool:
	if T.owns_dialog(id): return _task_sources_ready() and T.authorize_dialog(id,flags,states)
	if not owns_dialog(id): return true
	if _spec().is_empty(): return false
	var name:=id.trim_prefix(PREFIX)
	var phase:=stages(flags,states)
	match name:
		"canal_offer": return _status(states,CANAL)==0
		"canal_progress": return _status(states,CANAL)==ACTIVE and not _truth(flags,"canal_feud_resolved")
		"canal_witness": return phase.canal=="accepted" and _truth(flags,"canal_grudge_started")
		"canal_warehouse_clue": return phase.canal=="witness" and _truth(flags,"canal_grudge_started")
		"canal_evidence": return phase.canal=="located" and _truth(flags,"canal_grudge_route_heard")
		"canal_report": return phase.canal=="evidence" and _truth(flags,"canal_grudge_started") and not _truth(flags,"canal_feud_resolved")
		"canal_after": return phase.canal=="completed" and _truth(flags,"canal_feud_resolved")
		"paper_offer": return _status(states,PAPER)==0
		"paper_progress": return _status(states,PAPER)==ACTIVE and not _truth(flags,"luoyang_paper_helped")
		"paper_hint": return phase.paper=="accepted" and _truth(flags,"luoyang_paper_started")
		"paper_hint_repeat": return phase.paper=="hint" and _truth(flags,"luoyang_paper_started")
		"paper_materials": return phase.paper=="hint" and _truth(flags,"luoyang_paper_started")
		"paper_ready","paper_report": return phase.paper=="materials" and not _truth(flags,"luoyang_paper_helped")
		"paper_after","artisan_after": return phase.paper=="completed" and _truth(flags,"luoyang_paper_helped")
		"artisan_daily": return _status(states,PAPER)==0
		"hanjia_offer": return _status(states,HANJIA)==0
		"hanjia_progress": return _status(states,HANJIA)==ACTIVE and _truth(flags,"hanjia_blade_search_started") and not _truth(flags,"hanjia_blade_recovered")
		"hanjia_after": return _status(states,HANJIA)==COMPLETED and _truth(flags,"hanjia_blade_recovered")
	return false # Unknown IDs in our namespace fail closed.

static func _index(items: Array,key: String,value: String) -> int:
	var found := -1
	for i in range(items.size()):
		if items[i] is Dictionary and items[i].get(key)==value:
			if found>=0: return -1
			found=i
	return found

static func _npc_matches(npc: Dictionary,expected: Dictionary) -> bool:
	for key: String in ["npc_id","npc_name","dialog_id","interaction_action","hide_flag"]:
		if String(npc.get(key,""))!=String(expected.get(key,"")): return false
	return npc.get("pos")==_v(expected.pos_uv)

static func _set_dialog(npc: Dictionary,id: String) -> void:
	npc.erase("hide_flag")
	npc["interaction_action"]=""
	npc["dialog_id"]=_dialog(id)
	npc["dialog_variants"]=[]

static func _native_clear(id: StringName,point: Vector2) -> bool:
	# Never call prepare or silently fall back to BASE on a missing scoped record.
	var key:=String(id)
	if not C._records.has(key) or not C._masks.has(key) or C._using_patch.get(key,false)!=true or not C.safe_body(id,point): return false
	var mask: Image=C._masks[key]
	# Explicit 17 mask samples accompany the complete C 35x25 / polygon check.
	for i in range(17):
		var p:=point if i==0 else point+Vector2(cos(TAU*float(i-1)/16.0)*17.0,sin(TAU*float(i-1)/16.0)*12.0)
		var pixel:=Vector2i(roundi(p.x),roundi(p.y))
		if pixel.x<0 or pixel.y<0 or pixel.x>=mask.get_width() or pixel.y>=mask.get_height(): return false
		var color:=mask.get_pixelv(pixel)
		if color.a<.5 or color.r<.5: return false
	return true

static func _fail(message: String) -> Dictionary:
	return {"ok":false,"matched":true,"error":message}

static func _military_presentation(result: Dictionary,id: StringName) -> Dictionary:
	var military: Dictionary=MILITARY_Y.project(id,result.npcs)
	if military.get("ok")!=true: return _fail("TASK_MILITARY_PRESENTATION:"+String(military.get("error","UNKNOWN")))
	var output: Dictionary=result.duplicate(true)
	output.npcs=military.npcs
	return output

static func project(scene: SceneScript,flags: Dictionary,quest_states: Dictionary,input_interactions: Array) -> Dictionary:
	if scene==null: return _fail("TASK_SOURCE_NULL")
	var result: Dictionary={"ok":true,"matched":false,"error":"","npcs":scene.npcs.duplicate(true),"visual_objects":scene.map_layout.visual_objects.duplicate(true) if scene.map_layout!=null else scene.scene_objects.duplicate(true),"interactions":input_interactions.duplicate(true),"receipt":{}}
	var id:=String(scene.scene_id)
	if id not in IDS: return result
	# These two newly admitted domains are presentation-only. They never enter
	# an old Market/Docks/Temple task branch or read/mutate a quest/flag value.
	if id in PRESENTATION_ONLY_IDS: return _military_presentation(result,scene.scene_id)
	var spec:=_spec()
	if spec.is_empty(): return _fail("TASK_SPEC_OR_SOURCE_SHA_CHANGED")
	var phase:=stages(flags,quest_states)
	var npcs: Array=result.npcs
	var objects: Array=result.visual_objects
	var interactions: Array=result.interactions
	if id!=spec.temple.scene_id:
		var expected_manifest: String=spec.base_revision.market_manifest if id==spec.market.scene_id else spec.base_revision.docks_manifest
		if scene.get_meta("city_revision_runtime_binding_sha","")!=spec.base_revision.binding_sha256 or scene.get_meta("city_frontage_revision_manifest_sha","")!=expected_manifest: return _fail("TASK_BASE_REVISION_IDENTITY_CHANGED")
		var record: Dictionary=C._records.get(id,{})
		if record.get("city_revision_binding_sha")!=spec.base_revision.binding_sha256 or record.get("city_revision_manifest_sha")!=expected_manifest: return _fail("TASK_BASE_NAV_RECORD_NOT_BOUND")
	if id==spec.market.scene_id:
		if npcs.size()!=int(spec.market.original_npc_count): return _fail("TASK_MARKET_NPC_COUNT_CHANGED")
		var index:=_index(npcs,"npc_id",spec.market.scholar.npc_id)
		if index<0 or not _npc_matches(npcs[index],spec.market.scholar): return _fail("TASK_SCHOLAR_SOURCE_CHANGED")
		var dialog: String="paper_offer"
		if phase.paper=="completed": dialog="paper_after"
		elif phase.paper=="materials": dialog="paper_report"
		elif phase.paper!="not_started": dialog="paper_progress"
		_set_dialog(npcs[index],dialog)
		var artisan: Dictionary=spec.market.artisan
		if _index(npcs,"npc_id",artisan.npc_id)>=0: return _fail("TASK_ARTISAN_DUPLICATE_ID")
		if not _native_clear(scene.scene_id,_v(artisan.foot_px)): return _fail("TASK_ARTISAN_UNSAFE_FOOT_1320_1290")
		if not _native_clear(scene.scene_id,_v(artisan.approach_px)): return _fail("TASK_ARTISAN_UNSAFE_APPROACH_1240_1290")
		var artisan_dialog: String="artisan_daily"
		if phase.paper=="completed": artisan_dialog="artisan_after"
		elif phase.paper=="materials": artisan_dialog="paper_ready"
		elif phase.paper=="hint": artisan_dialog="paper_hint_repeat"
		elif phase.paper=="accepted": artisan_dialog="paper_hint"
		npcs.append({"npc_id":artisan.npc_id,"npc_name":artisan.npc_name,"pos":_v(artisan.foot_px)/C.SIZE,"scale":float(artisan.scale),"sprite_path":artisan.sprite_path,"portrait_path":artisan.portrait_path,"dialog_id":_dialog(artisan_dialog)})
	elif id==spec.docks.scene_id:
		if npcs.size()!=int(spec.docks.original_npc_count): return _fail("TASK_DOCKS_NPC_COUNT_CHANGED")
		for expected: Dictionary in [spec.docks.chief,spec.docks.soldier]:
			var index:=_index(npcs,"npc_id",expected.npc_id)
			if index<0 or not _npc_matches(npcs[index],expected): return _fail("TASK_DOCKS_NPC_IDENTITY_CHANGED")
		var chief_index:=_index(npcs,"npc_id",spec.docks.chief.npc_id)
		var chief_dialog: String="canal_offer"
		if phase.canal=="completed": chief_dialog="canal_after"
		elif phase.canal=="evidence": chief_dialog="canal_report"
		elif phase.canal!="not_started": chief_dialog="canal_progress"
		_set_dialog(npcs[chief_index],chief_dialog)
		var soldier_index:=_index(npcs,"npc_id",spec.docks.soldier.npc_id)
		var soldier_dialog: String="hanjia_offer"
		if _status(quest_states,HANJIA)==COMPLETED: soldier_dialog="hanjia_after"
		elif _status(quest_states,HANJIA)==ACTIVE: soldier_dialog="hanjia_progress"
		if phase.canal=="accepted": soldier_dialog="canal_witness"
		_set_dialog(npcs[soldier_index],soldier_dialog)
		var evidence: Dictionary=spec.docks.evidence
		var interaction_index:=_index(interactions,"id",evidence.interaction_id)
		if interaction_index<0: return _fail("TASK_MUD_INTERACTION_MISSING")
		var entry: Dictionary=interactions[interaction_index]
		if entry.get("action")!=evidence.old_action or entry.get("require_flag")!=evidence.old_require_flag or entry.get("hide_flag")!=evidence.old_hide_flag or entry.get("visual_object_id")!=evidence.object_id or entry.get("pos")!=_v(evidence.stand_px)/C.SIZE or not _native_clear(scene.scene_id,_v(evidence.stand_px)): return _fail("TASK_MUD_SOURCE_OR_CLEARANCE_CHANGED")
		var object_index:=_index(objects,"id",evidence.object_id)
		if object_index<0 or objects[object_index].get("blocking")!=false or not objects[object_index].get("solid_polygons_px",[]).is_empty() or C._vec(objects[object_index].get("collision_size_px"))!=Vector2.ZERO: return _fail("TASK_MUD_MUST_REMAIN_NONBLOCKING")
		var visible: bool=phase.canal in ["witness","located"] and _truth(flags,"canal_grudge_started")
		if visible:
			entry["action"]="dialog:"+_dialog("canal_warehouse_clue" if phase.canal=="witness" else "canal_evidence")
			entry["require_flag"]="canal_grudge_route_heard"; entry["hide_flag"]="canal_grudge_evidence_found"; entry["require_quest_active"]=CANAL
			entry["label"]="废仓墙脚 · 查验拖痕" if phase.canal=="witness" else "废仓石缝 · 收取残契与泥样"
			objects[object_index]["require_flag"]="canal_grudge_route_heard"; objects[object_index]["hide_flag"]="canal_grudge_evidence_found"; objects[object_index]["require_quest_active"]=CANAL
		else:
			interactions.remove_at(interaction_index); objects.remove_at(object_index)
		var cargo_index:=_index(objects,"id",spec.docks.cargo_decor.object_id)
		if cargo_index<0 or C._vec(objects[cargo_index].get("world_foot_px"))!=_v(spec.docks.cargo_decor.world_foot_px): return _fail("TASK_ORDINARY_CARGO_IDENTITY_CHANGED")
		for key: String in ["interaction_action","interaction_label","require_flag","hide_flag","require_quest_active","require_quest_completed"]:
			if objects[cargo_index].has(key): return _fail("TASK_ORDINARY_CARGO_MUST_HAVE_NO_TASK_GATE_OR_ACTION")
		for item: Dictionary in interactions:
			if item.get("id")=="canal_feud_chest" or item.get("visual_object_id")=="canal_feud_chest": return _fail("TASK_CARGO_MUST_NOT_BE_INTERACTIVE")
	else:
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
	if id==spec.market.scene_id:
		if not _task_sources_ready(): return _fail("TASK_SUCCESSOR_SOURCE_OR_QUEST_RESOLVER_CHANGED")
		var successor: Dictionary=T.project_market(result,flags,quest_states)
		if successor.get("ok")!=true or successor.get("matched")!=true: return _fail("TASK_MARKET_SUCCESSOR_REFUSED:"+String(successor.get("error","UNKNOWN")))
		successor.receipt["prior_city_task_receipt"]=result.receipt.duplicate(true)
		successor.receipt["same_id_quest_defs_resolve_from_canonical_paths"]=true
		return _military_presentation(successor,scene.scene_id)
	return _military_presentation(result,scene.scene_id)
