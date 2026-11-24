extends RefCounted
## Pure logical source projection for REGION_27D. Never prepares a legacy owner.
const TASK=preload("res://scripts/city/luoyang_city_tasks_20261016.gd")
const LAYOUT_TASK=preload("res://scripts/city/luoyang_layout_quest_20261018t.gd")
const PRESENTATION=preload("res://build/luoyang_city_rectification_20261027d_system01/presentation_definition.gd")
const CULTURE=preload("res://build/luoyang_city_rectification_20261027d_system01/culture_definition.gd")
const DG=preload("res://scripts/city/luoyang_district_life_crowd_20261016f.gd")
const HC=preload("res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd")
const CATALOG: NPCCatalog=preload("res://data/npcs/npc_catalog.tres")
const AMBIENT=preload("res://build/luoyang_city_finish_20261025i_source01/runtime_READY01/ambient18_runtime_READY.gd")
const CONVERSATION=preload("res://build/luoyang_city_revision_20261024b_dialog01/npc_conversation_CANDIDATE.gd")
const MONK_DISPLAY=preload("res://build/luoyang_city_finish_20261025i_source01/Estate_wall_source_repair01/closure_READY01/wing_door_depth_children_READY.gd")
const SIZE=Vector2(3072,2048)
const MARKET_SPACE_BINDING="res://build/luoyang_city_space_20261024b_source01/runtime_READY02/market_space_binding_READY.json"
const MARKET_T_AUTHOR="res://build/luoyang_layout_quest_20261018t_layout_source01/author_retry2.json"
const DG_AUTHOR="res://data/maps/luoyang_district_life_20261016f/author.json"
const MARKET_AUTHOR="res://build/luoyang_city_blocks_20261024e_system01/author_market_block07_paper_foot_NOTREADY.json"
const YAMEN_ROW=preload("res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/yamen_consumer_preparation01/clerk_row_projection_PREPARATION_ONLY.gd")
static func fail(why: String) -> Dictionary: return {"ok":false,"error":why}
static func v(raw: Variant) -> Vector2:
	return raw if raw is Vector2 else Vector2(float(raw[0]),float(raw[1])) if raw is Array and raw.size()==2 else Vector2(INF,INF)
static func json_source(path: String,sources: Dictionary) -> Dictionary:
	if not sources.get(path) is String or FileAccess.get_sha256(path)!=sources[path]: return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
static func index(rows: Array,id: String,key: String="npc_id") -> int:
	var result: int=-1
	for i: int in rows.size():
		if String(rows[i].get(key,""))==id:
			if result>=0: return -2
			result=i
	return result
static func _task(source: SceneScript,raw: Dictionary,flags: Dictionary,states: Dictionary,presentation: Dictionary) -> Dictionary:
	var id: String=String(source.scene_id);var spec: Dictionary=TASK._spec()
	if spec.is_empty() or not TASK.task_successor_ready(): return fail("LOGICAL_TASK_SOURCE")
	var npcs: Array=source.npcs.duplicate(true);var interactions: Array=source.map_layout.interactions.duplicate(true)
	var objects: Array=source.map_layout.visual_objects.duplicate(true);var probes: Array=[]
	var phase: Dictionary=TASK.stages(flags,states)
	if id=="ch4_s4_ancient_temple":
		var temple: Variant=load("res://build/luoyang_city_rectification_20261027d_system01/temple_source_business_snapshot01.gd")
		var adapter: Variant=load("res://build/luoyang_city_rectification_20261027d_system01/temple_task_business_snapshot01.gd")
		var render: Array=temple.project_objects(temple.author(temple.binding()),v(raw.local_size_px))
		return adapter.project(source,flags,states,interactions,render)
	if id=="ch4_s3_luoyang_market":
		if npcs.size()!=int(spec.market.original_npc_count): return fail("LOGICAL_MARKET_ORIGINAL_NPCS")
		var scholar: int=index(npcs,String(spec.market.scholar.npc_id))
		if scholar<0 or not TASK._npc_matches(npcs[scholar],spec.market.scholar): return fail("LOGICAL_SCHOLAR_SOURCE")
		var paper_dialog: String="paper_after" if phase.paper=="completed" else "paper_report" if phase.paper=="materials" else "paper_offer" if phase.paper=="not_started" else "paper_progress"
		TASK._set_dialog(npcs[scholar],paper_dialog)
		var artisan: Dictionary=spec.market.artisan
		if index(npcs,String(artisan.npc_id))!=-1: return fail("LOGICAL_ARTISAN_DUPLICATE")
		var artisan_dialog: String="artisan_after" if phase.paper=="completed" else "paper_ready" if phase.paper=="materials" else "paper_hint_repeat" if phase.paper=="hint" else "paper_hint" if phase.paper=="accepted" else "artisan_daily"
		npcs.append({"npc_id":artisan.npc_id,"npc_name":artisan.npc_name,"pos":v(artisan.foot_px)/SIZE,"scale":float(artisan.scale),"sprite_path":artisan.sprite_path,"portrait_path":artisan.portrait_path,"dialog_id":TASK._dialog(artisan_dialog)})
		probes.append_array([v(artisan.foot_px),v(artisan.approach_px)])
	elif id=="ch4_s2_canal_docks":
		if npcs.size()!=int(spec.docks.original_npc_count): return fail("LOGICAL_DOCKS_ORIGINAL_NPCS")
		for expected: Dictionary in [spec.docks.chief,spec.docks.soldier]:
			var person_index: int=index(npcs,String(expected.npc_id))
			if person_index<0 or not TASK._npc_matches(npcs[person_index],expected): return fail("LOGICAL_DOCKS_TASK_IDENTITY")
		TASK._set_dialog(npcs[index(npcs,String(spec.docks.chief.npc_id))],"canal_after" if phase.canal=="completed" else "canal_report" if phase.canal=="evidence" else "canal_offer" if phase.canal=="not_started" else "canal_progress")
		var soldier_dialog: String="hanjia_after" if TASK._status(states,TASK.HANJIA)==2 else "hanjia_progress" if TASK._status(states,TASK.HANJIA)==1 else "hanjia_offer"
		TASK._set_dialog(npcs[index(npcs,String(spec.docks.soldier.npc_id))],"canal_witness" if phase.canal=="accepted" else soldier_dialog)
		var evidence: Dictionary=spec.docks.evidence;var at: int=index(interactions,String(evidence.interaction_id),"id")
		if at<0: return fail("LOGICAL_MUD_SOURCE_MISSING")
		var row: Dictionary=interactions[at]
		if row.get("action")!=evidence.old_action or row.get("require_flag")!=evidence.old_require_flag or row.get("hide_flag")!=evidence.old_hide_flag or row.get("visual_object_id")!=evidence.object_id or row.get("pos")!=v(evidence.stand_px)/SIZE: return fail("LOGICAL_MUD_ORIGINAL_SOURCE")
		var mud_index: int=index(objects,String(evidence.object_id),"id")
		if mud_index<0 or objects[mud_index].get("blocking")!=false or not objects[mud_index].get("solid_polygons_px",[]).is_empty() or v(objects[mud_index].get("collision_size_px",Vector2.ZERO))!=Vector2.ZERO: return fail("LOGICAL_MUD_NONBLOCKING_SOURCE")
		var cargo_index: int=index(objects,String(spec.docks.cargo_decor.object_id),"id")
		if cargo_index<0 or v(objects[cargo_index].get("world_foot_px"))!=v(spec.docks.cargo_decor.world_foot_px): return fail("LOGICAL_CARGO_SOURCE")
		for key: String in ["interaction_action","interaction_label","require_flag","hide_flag","require_quest_active","require_quest_completed"]:
			if objects[cargo_index].has(key): return fail("LOGICAL_CARGO_TASK_GATE")
		for item: Dictionary in interactions:
			if item.get("id")=="canal_feud_chest" or item.get("visual_object_id")=="canal_feud_chest": return fail("LOGICAL_CARGO_TASK_INTERACTION")
		if phase.canal in ["witness","located"] and TASK._truth(flags,"canal_grudge_started"):
			row.action="dialog:"+TASK._dialog("canal_warehouse_clue" if phase.canal=="witness" else "canal_evidence")
			row.require_flag="canal_grudge_route_heard";row.hide_flag="canal_grudge_evidence_found";row.require_quest_active=TASK.CANAL
		else: interactions.remove_at(at)
		probes.append(v(evidence.stand_px))
	var base: Dictionary={"ok":true,"matched":id in TASK.TASK_IDS,"npcs":npcs,"interactions":interactions,"visual_objects":objects,"receipt":{"source_scene_id":id,"stage":phase,"region27d_pure_source_not_legacy_owner":true}}
	if id=="ch4_s3_luoyang_market": base=LAYOUT_TASK.project_market(base,flags,states)
	if base.get("ok")!=true: return base
	if id=="ch4_s3_luoyang_market":
		var space_binding: Dictionary=json_source(MARKET_SPACE_BINDING,raw.sources)
		var space_source: Dictionary=json_source(String(space_binding.get("author_path","")),raw.sources)
		if space_source.is_empty() or raw.sources.get(space_binding.get("author_path",""))!=space_binding.get("author_sha256"): return fail("LOGICAL_MARKET_TASK_SPACE_SOURCE")
		# These eight native NPC migrations are ALREADY materialized in the fixed
		# market_detours06 source Scene. Validate the complete output layer once;
		# applying them again would reject or double-move the true source rows.
		for declared: Dictionary in space_source.scene_npc_migrations:
			var native_index: int=index(source.npcs,String(declared.id))
			if native_index<0 or source.npcs[native_index].get("pos")!=v(declared.new_foot_px)/SIZE: return fail("LOGICAL_MARKET_NATIVE_SPACE_LAYER:"+String(declared.id))
		# Field1137 applies this AFTER Task creates the same-identity artisan,
		# before crowd/DE191. It is distinct from the Scene's eight native rows.
		var task_move: Dictionary=space_source.same_identity_task_migration
		var task_id: String=String(spec.market.artisan.npc_id)
		var task_index: int=index(base.npcs,task_id)
		if task_move.get("id")!="luoyang_paper_artisan" or task_id!="luoyang_paper_artisan_20261016" or task_index<0 or base.npcs[task_index].get("pos")!=v(task_move.old_foot_px)/SIZE: return fail("LOGICAL_MARKET_TASK_SPACE_ORIGINAL_FOOT")
		base.npcs[task_index].pos=v(task_move.new_foot_px)/SIZE
		probes.append_array([v(task_move.new_foot_px),v(task_move.new_approach_px)])
	var presented: Dictionary=PRESENTATION.compose_exact(source.scene_id,base.npcs,presentation.author)
	if presented.get("ok")!=true: return presented
	base.npcs=presented.npcs;base["required_fullbody_probes"]=probes
	return base
static func _harbour(source: SceneScript,presentation_data: Dictionary) -> Dictionary:
	var rows: Array=HC.project(source.scene_id)
	if source.scene_id==&"ch4_s2_canal_docks":
		var office: Variant=load("res://scripts/city/luoyang_docks_office_roles_20261016h.gd")
		var roles: Dictionary=office.project_npcs(source,rows)
		if roles.get("ok")!=true: return roles
		rows=roles.npcs
		var presentation: Variant=load("res://scripts/city/luoyang_docks_roles_20261019ad.gd")
		var ready: Dictionary=presentation.readiness()
		if ready.get("ok")!=true: return ready
		var pure: Dictionary=presentation.compose_exact(rows,rows,ready.spec)
		if pure.get("ok")!=true: return pure
		rows=pure.npcs
	return PRESENTATION.compose_exact(source.scene_id,rows,presentation_data.author)
static func _moves(rows: Array,moves: Array,size: Vector2,skip_paper: bool=false) -> Dictionary:
	var out: Array=rows.duplicate(true)
	for move: Dictionary in moves:
		var id: String=String(move.get("npc_id",move.get("id","")))
		if skip_paper and id=="luoyang_paper_artisan_20261016": continue
		if not move.has("npc_id") and id not in ["luoyang_armorer","luoyang_paper_artisan_20261016"]: id="district_life_"+id
		var at: int=index(out,id)
		if at<0: return fail("LOGICAL_MIGRATION_ID:"+id)
		var before: Vector2=v(move.get("old_source_origin_px",move.get("old_foot_px")))
		var after: Vector2=v(move.get("new_source_origin_px",move.get("foot_px")))
		if out[at].get("pos")!=before/size: return fail("LOGICAL_MIGRATION_ORIGINAL_FOOT:"+id)
		out[at].pos=after/size
	return {"ok":true,"npcs":out}
static func _catalog(id: StringName,row: Dictionary) -> Dictionary:
	var out: Dictionary=row.duplicate(true);var profile: NPCProfile=CATALOG.find(StringName(out.npc_id),id)
	var guessed: bool=String(out.get("portrait_path","")).is_empty()
	if profile!=null:
		if out.get("harbour_life_ground_anchored",false) or out.get("district_life_ground_anchored",false): return {}
		if profile.display_name!="": out.npc_name=profile.display_name
		if profile.default_dialog_id!=&"" and not TASK.owns_dialog(String(out.get("dialog_id",""))): out.dialog_id=String(profile.default_dialog_id)
		for pair: Array in [["sprite_path",profile.sprite_path],["portrait_path",profile.portrait_path],["walk_sprite_path",profile.walk_sprite_path]]:
			if pair[1]!="": out[pair[0]]=pair[1]
		if not profile.portrait_path.is_empty(): guessed=false
		if profile.sprite_scale>0: out.scale=profile.sprite_scale
		if not out.has("movement_mode"): out.movement_mode=profile.movement_mode
	if guessed and String(id) in CULTURE.IDS: out.portrait_path=CONVERSATION.fallback_portrait(String(out.get("sprite_path","")))
	if id==&"ch4_s3_luoyang_market" and out.npc_id=="spar_luoyang_examiner": out.portrait_path="res://art/portraits/luoyang_city_finish_20261022ap/examiner_mature_v1.png"
	if id==&"ch4_s3_luoyang_market" and out.npc_id=="luoyang_paper_scholar":
		out.sprite_path="res://art/characters/npc_luoyang_paper_scholar_idle_down_25d_1f_20261024.png";out.portrait_path="res://art/characters/portraits/luoyang_scholar_20261024c/paper_scholar_v1.png";out["region27d_calibrate_adult"]=true
	return out
static func _display(source: SceneScript,row: Dictionary,visual: Dictionary) -> Dictionary:
	var out: Dictionary=row.duplicate(true)
	out.scale=float(out.get("scale",.08))*source.npc_visual_scale
	if out.get("harbour_life_ground_anchored",false) or out.get("district_life_ground_anchored",false): out.scale=1.0;out["region27d_calibrate_adult"]=true
	for change: Dictionary in visual.actor_overrides:
		if change.npc_id!=out.npc_id or String(source.scene_id)!=change.before.scene_id: continue
		for key: String in ["npc_name","sprite_path","walk_sprite_path","portrait_path","movement_mode"]:
			if out.get(key,"")!=change.before.get(key,""): return {}
		if not String(out.get("dialog_id","")).is_empty() or not String(out.get("interaction_action","")).is_empty() or not out.get("dialog_variants",[]).is_empty(): return {}
		if change.walker:
			if out.scale!=1.0 or out.get("region27d_calibrate_adult")!=true or float(out.get("walk_frame_seconds",.12))!=.12: return {}
			out.sprite_path=change.after.sprite_path;out.walk_sprite_path=change.after.walk_sprite_path;out.conversation_base_facing="front"
		out.portrait_path=change.after.portrait_path
	if source.scene_id==&"ch4_s4_ancient_temple" and out.npc_id in MONK_DISPLAY.MONK_IDS:
		if out.sprite_path!=MONK_DISPLAY.MONK_OLD or out.portrait_path!=MONK_DISPLAY.MONK_OLD or out.scale!=LAYOUT_TASK.MONK_SCALE or out.get("region27d_calibrate_adult",false): return {}
		# Formal elder pair is pending. Preserve both old paths, not a mismatched head.
		if out.npc_id==MONK_DISPLAY.MONK_IDS[1]: out.portrait_path=MONK_DISPLAY.MONK_MEDIA.bell_portrait.path
	return out
static func _market_crowd(original: Array,sources: Dictionary) -> Dictionary:
	# DT.prepare's actual source order: D98 -> T crowd moves -> Space -> DG.project.
	# AP moves only the prop rows, not crowd; DE191 consumes the Space output.
	var binding: Dictionary=json_source(MARKET_SPACE_BINDING,sources)
	var task: Dictionary=json_source(MARKET_T_AUTHOR,sources)
	if binding.is_empty() or task.is_empty(): return fail("LOGICAL_MARKET_CROWD_PARENT_SOURCES")
	var path: String=String(binding.get("author_path",""))
	if sources.get(path)!=binding.get("author_sha256"): return fail("LOGICAL_MARKET_SPACE_AUTHOR_PIN")
	var space: Dictionary=json_source(path,sources)
	if space.is_empty(): return fail("LOGICAL_MARKET_SPACE_AUTHOR")
	var prior: Array=original.duplicate(true)
	for move: Dictionary in task.get("districts",{}).get("ch4_s3_luoyang_market",{}).get("crowd_moves",[]):
		var at: int=index(prior,String(move.id),"id")
		if at<0 or v(prior[at].foot_px)!=v(move.old_foot_px) or float(prior[at].distance_px)!=float(move.distance_px): return fail("LOGICAL_MARKET_T_CROWD_ORIGINAL_FOOT:"+String(move.id))
		prior[at].foot_px=move.new_foot_px.duplicate(true)
	if var_to_bytes(prior)!=var_to_bytes(space.get("district_current_frozen",{}).get("crowd",[])): return fail("LOGICAL_MARKET_SPACE_COMPLETE_PARENT_CROWD")
	var after: Array=space.get("runtime_district",{}).get("crowd",[]).duplicate(true)
	if after.size()!=prior.size(): return fail("LOGICAL_MARKET_SPACE_CROWD_COUNT")
	for i: int in prior.size():
		var old_fields: Dictionary=prior[i].duplicate(true);var new_fields: Dictionary=after[i].duplicate(true)
		old_fields.erase("foot_px");new_fields.erase("foot_px")
		if var_to_bytes(old_fields)!=var_to_bytes(new_fields) or not v(after[i].get("foot_px")).is_finite(): return fail("LOGICAL_MARKET_SPACE_CROWD_IDENTITY")
	return {"ok":true,"crowd":after}
static func _field_truth(flags: Dictionary,key: String) -> bool:
	# Exact original Field._flag_truthy semantics, including non-scalar truth.
	var value: Variant=flags.get(key,null)
	if value==null: return false
	if typeof(value)==TYPE_BOOL: return value
	if typeof(value)==TYPE_INT: return value!=0
	if typeof(value)==TYPE_STRING: return value!=""
	return true
static func _available(row: Dictionary,flags: Dictionary,states: Dictionary) -> bool:
	var required: String=String(row.get("require_flag",""));var hidden: String=String(row.get("hide_flag",""))
	if not required.is_empty() and not _field_truth(flags,required): return false
	if not hidden.is_empty() and _field_truth(flags,hidden): return false
	var active: String=String(row.get("require_quest_active",""));var completed: String=String(row.get("require_quest_completed",""))
	if not active.is_empty() and TASK._status(states,active)!=1: return false
	if not completed.is_empty() and TASK._status(states,completed)!=2: return false
	return true
static func project(logical_id: StringName,source_scene: SceneScript,raw_terminal: Dictionary,flags: Dictionary,states: Dictionary) -> Dictionary:
	if source_scene==null or source_scene.scene_id!=logical_id or source_scene.map_layout==null or raw_terminal.get("logical_id")!=String(logical_id) or not raw_terminal.get("sources") is Dictionary: return fail("LOGICAL_SOURCE_CONTEXT")
	var presentation: Dictionary=PRESENTATION.readiness()
	if presentation.get("ok")!=true: return presentation
	var base: Dictionary=_task(source_scene,raw_terminal,flags,states,presentation)
	if base.get("ok")!=true: return base
	var npcs: Array=base.npcs;var interactions: Array=base.interactions
	# Declare every authored task Area once. Quest phases toggle availability;
	# they must not silently remove a future task's geometry from the compiler.
	var active_interactions: Dictionary={}
	for interaction: Dictionary in interactions: active_interactions[String(interaction.get("id",""))]=true
	for original: Dictionary in source_scene.map_layout.interactions:
		var original_id: String=String(original.get("id",""))
		if index(interactions,original_id,"id")==-1:
			interactions.append(original.duplicate(true));active_interactions[original_id]=false
	if logical_id==&"ch4_s4_ancient_temple":
		# Exact two future investigation Areas from the original Task constants.
		# Do not simulate accepting a quest merely to discover their positions.
		for contract: Dictionary in [{"id":"temple_longmen_investigate_20261018t","foot":LAYOUT_TASK.LONGMEN_INVESTIGATE_FOOT,"dialog":"longmen_investigate","quest":LAYOUT_TASK.LONGMEN,"require":LAYOUT_TASK.LONGMEN_STARTED,"hide":LAYOUT_TASK.LONGMEN_EVIDENCE,"label":"查验石壁水槽与暗缝"},{"id":"temple_baima_investigate_20261018t","foot":LAYOUT_TASK.BAIMA_INVESTIGATE_FOOT,"dialog":"baima_investigate","quest":LAYOUT_TASK.BAIMA,"require":LAYOUT_TASK.BAIMA_STARTED,"hide":LAYOUT_TASK.BAIMA_EVIDENCE,"label":"查验钟楼东墙砖缝"}]:
			if index(interactions,contract.id,"id")==-1:
				interactions.append({"id":contract.id,"pos":contract.foot/LAYOUT_TASK.SIZE,"size":Vector2(.11,.12),"activation":"interact","label":contract.label,"action":"dialog:"+LAYOUT_TASK._dialog(contract.dialog),"require_quest_active":contract.quest,"require_flag":contract.require,"hide_flag":contract.hide})
				active_interactions[contract.id]=false
	if logical_id in [&"ch4_s0_luoyang_gate",&"ch4_s2_canal_docks"]:
		var crowd: Dictionary=_harbour(source_scene,presentation)
		if crowd.get("ok")!=true: return crowd
		npcs.append_array(crowd.npcs)
	if logical_id in [&"ch4_s0_luoyang_gate",&"ch4_s1_luoyang_yamen",&"ch4_s2_canal_docks",&"ch4_s3_luoyang_market"]:
		var author: Dictionary=json_source(DG_AUTHOR,raw_terminal.sources)
		if author.is_empty(): return fail("LOGICAL_DISTRICT_AUTHOR")
		var crowd_spec: Array=author.districts[String(logical_id)].crowd
		if logical_id==&"ch4_s3_luoyang_market":
			var space_crowd: Dictionary=_market_crowd(crowd_spec,raw_terminal.sources)
			if space_crowd.get("ok")!=true: return space_crowd
			crowd_spec=space_crowd.crowd
		var district: Dictionary=PRESENTATION.compose_exact(logical_id,DG.project(crowd_spec),presentation.author)
		if district.get("ok")!=true: return district
		if logical_id==&"ch4_s1_luoyang_yamen": district=YAMEN_ROW.compose_preparation_only(logical_id,district.npcs)
		if district.get("ok")!=true: return district
		npcs.append_array(district.npcs)
	var market: Dictionary={}
	if logical_id==&"ch4_s3_luoyang_market":
		market=json_source(MARKET_AUTHOR,raw_terminal.sources)
		if market.is_empty(): return fail("LOGICAL_MARKET_AUTHOR")
		var market_moved: Dictionary=_moves(npcs,market.npc_migrations,SIZE,true)
		if market_moved.get("ok")!=true: return market_moved
		npcs=market_moved.npcs
		for move: Dictionary in market.interaction_migrations:
			var at: int=index(interactions,String(move.id),"id")
			if at<0 or interactions[at].get("pos")!=v(move.old_foot_px)/SIZE: return fail("LOGICAL_MARKET_INTERACTION")
			interactions[at].pos=v(move.foot_px)/SIZE
	npcs.append_array(BountyManager.get_scene_npcs(logical_id))
	var letter: Dictionary=CULTURE.read_state(CULTURE.LETTER,flags,states)
	if letter.get("ok")!=true: return letter
	var culture_ready: Dictionary=CULTURE.readiness()
	if culture_ready.get("ok")!=true: return culture_ready
	if logical_id==&"ch4_s3_luoyang_market" and index(npcs,CULTURE.BUYER)<0: return fail("LOGICAL_CULTURE_BUYER")
	if logical_id==&"ch4_s2_canal_docks":
		var pickup: Dictionary=culture_ready.contract.pickup
		npcs.append({"npc_id":CULTURE.BUYER,"npc_name":"采买妇人","pos":v(pickup.recipient_foot_px)/SIZE,"sprite_path":pickup.sprite_path,"portrait_path":pickup.portrait_path,"scale":1.0,"movement_mode":"idle","dialog_id":"","interaction_action":"","district_life_ground_anchored":true,"culture_x_pickup_recipient":true})
	if logical_id==&"ch4_s3_luoyang_market":
		var paper: Array=[]
		for move: Dictionary in market.npc_migrations:
			if move.id=="luoyang_paper_artisan_20261016": paper.append(move)
		var final_paper: Dictionary=_moves(npcs,paper,SIZE)
		if final_paper.get("ok")!=true: return final_paper
		npcs=final_paper.npcs
	var payload: Dictionary=raw_terminal.get("finish_payload",{})
	if payload.get("scene_id")!=String(logical_id): return fail("LOGICAL_FINISH_PAYLOAD_REQUIRED")
	var moved: Dictionary=_moves(npcs,payload.npc_migrations,v(payload.world_size_px))
	if moved.get("ok")!=true: return moved
	npcs=moved.npcs;npcs.append_array(payload.new_NPCs.duplicate(true))
	for patch: Dictionary in payload.interaction_patches:
		var at: int=index(interactions,String(patch.id),"id")
		if at<0 or var_to_bytes(interactions[at])!=var_to_bytes(patch.before): return fail("LOGICAL_FINISH_INTERACTION")
		interactions[at]=patch.after.duplicate(true)
	var visual: Dictionary=AMBIENT._visual_data();var ambient: Dictionary=AMBIENT._read_data()
	if visual.is_empty() or ambient.is_empty(): return fail("LOGICAL_AMBIENT_VISUAL_SOURCE")
	var seen: Dictionary={};var rows: Array=[];var actor_slots: Dictionary={}
	for row: Dictionary in npcs:
		var id: String=String(row.get("npc_id",""))
		if id.is_empty() or seen.has(id): return fail("LOGICAL_DUPLICATE_NPC:"+id)
		seen[id]=true
		var final_row: Dictionary=_catalog(logical_id,row)
		if final_row.is_empty(): return fail("LOGICAL_CATALOG_COLLISION:"+id)
		final_row=_display(source_scene,final_row,visual)
		if final_row.is_empty(): return fail("LOGICAL_VISUAL_IDENTITY:"+id)
		final_row["region27d_primary"]={"dialog_id":String(final_row.get("dialog_id","")),"interaction_action":String(final_row.get("interaction_action","")),"dialog_variants":final_row.get("dialog_variants",[]).duplicate(true)}
		var menu: bool=PRESENTATION.daily_handles_exact(logical_id,id,presentation)
		for quest: Dictionary in culture_ready.quests.values():
			for who: Dictionary in quest.actors:
				if who.scene_id==String(logical_id) and who.npc_id==id: menu=true
		if id==CULTURE.BUYER and logical_id==StringName(CULTURE.DOCKS): menu=true
		if menu: final_row.interaction_action="culture_x_menu"
		elif ambient.has(id) and ambient[id].text.scene_id==String(logical_id): final_row.interaction_action="region27d_daily"
		var slot: String=String(logical_id)+"/"+id
		var wrapped: Dictionary={"slot_key":slot,"foot_px":v(final_row.pos)*v(raw_terminal.local_size_px),"half_body":Vector2(17,15),"ground_anchored":source_scene.actor_positions_are_feet or final_row.get("harbour_life_ground_anchored",false) or final_row.get("district_life_ground_anchored",false),"data":final_row}
		wrapped["default_active"]=_available(final_row,flags,states)
		if id==CULTURE.BUYER:
			wrapped["phase_exclusive_group"]="culture_return_buyer"
			wrapped["default_active"]=wrapped.default_active and ((letter.state.status=="solved") if logical_id==StringName(CULTURE.DOCKS) else (letter.state.status!="solved"))
		actor_slots[slot]={"active":wrapped.get("default_active",true),"data":final_row.duplicate(true)}
		rows.append(wrapped)
	var interaction_rows: Array=[]
	for row: Dictionary in interactions:
		interaction_rows.append({"id":String(row.get("id","")),"default_active":active_interactions.get(String(row.get("id","")),true),"foot_px":v(row.get("pos"))*v(raw_terminal.local_size_px),"size_px":v(row.get("size",Vector2(.05,.04)))*v(raw_terminal.local_size_px),"data":row.duplicate(true)})
	var result: Dictionary=raw_terminal.duplicate(true)
	result.npcs=rows;result.interactions=interaction_rows;result["actor_slots"]=actor_slots;result["ok"]=true;result["receipt"]=base.get("receipt",{});result["required_fullbody_probes"]=base.get("required_fullbody_probes",[])
	result["dynamic_visual_state"]={"warehouse_mud_trace":base.get("receipt",{}).get("stage",{}).get("canal") in ["witness","located"] and TASK._truth(flags,"canal_grudge_started")} if logical_id==&"ch4_s2_canal_docks" else {}
	return result
