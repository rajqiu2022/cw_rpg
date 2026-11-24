extends RefCounted
## Successor Temple task adapter candidate.  It keeps the old canonical scene as
## the paper-task oracle, but requires the actual successor child to contain the
## two monk entities, four non-speaker base interactions and separated portals.
const TEMPLE=preload("res://scripts/city/luoyang_temple_assembly_20261016.gd")
const TASK=preload("res://scripts/city/luoyang_layout_quest_20261018t.gd")

static func project(scene: SceneScript,flags: Dictionary,states: Dictionary,input: Array,render_objects: Array) -> Dictionary:
	if not TEMPLE.is_scene(scene): return {"ok":false,"error":"TEMPLE_TASK_CHILD_UNBOUND"}
	var original:=TEMPLE.original_scene()
	if original==null: return {"ok":false,"error":"TEMPLE_TASK_REAL_CANONICAL_MISSING"}
	var city: Variant=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
	var original_interactions:=TEMPLE.legacy_interactions(original)
	var authored: Dictionary=TEMPLE.author(TEMPLE.binding())
	var source_base: Array=TEMPLE.successor_interactions(original_interactions,authored)
	var source_portals: Array=TEMPLE.successor_portals(original)
	if original_interactions.size()!=6 or source_base.size()!=4 or source_portals.size()!=2: return {"ok":false,"error":"TEMPLE_TASK_SUCCESSOR_SOURCE_COUNT_CHANGED"}
	if not city._equal_value(input,source_base) or not city._equal_value(scene.map_layout.portals,source_portals): return {"ok":false,"error":"TEMPLE_TASK_INTERACTION_OR_PORTAL_SOURCE_CHANGED"}
	if not city._equal_value(scene.npcs,TEMPLE.successor_npcs()): return {"ok":false,"error":"TEMPLE_TASK_MONK_SOURCE_CHANGED"}
	var task: Variant=load("res://scripts/city/luoyang_city_tasks_20261016.gd")
	if not task.task_successor_ready(): return {"ok":false,"error":"TEMPLE_TASK_SUCCESSOR_DEFINITION_OR_DIALOG_SOURCE_CHANGED"}
	var old_projected: Dictionary=task.project(original,flags,states,original_interactions)
	if old_projected.get("ok")!=true or not old_projected.get("matched",false) or not old_projected.npcs.is_empty() or not old_projected.visual_objects.is_empty(): return {"ok":false,"error":"TEMPLE_TASK_ORIGINAL_ORACLE_REFUSED"}
	# The old task layer may still change/remove only the paper hotspot.  The two
	# legacy hidden-speaker rows are verified against the oracle, then explicitly
	# excluded from the successor child rather than silently retained.
	for item: Dictionary in original_interactions:
		if item.id=="legacy_hotspot_3": continue
		var found: int=0
		for row: Dictionary in old_projected.interactions:
			if row.get("id")==item.id:
				if not city._equal_value(row,item): return {"ok":false,"error":"TEMPLE_NON_PAPER_TASK_DELTA"}
				found+=1
		if found!=1: return {"ok":false,"error":"TEMPLE_NON_PAPER_TASK_MISSING"}
	var projected_base: Array=TEMPLE.successor_interactions(old_projected.interactions,authored)
	if projected_base.size()!=old_projected.interactions.size()-2: return {"ok":false,"error":"TEMPLE_TASK_RELOCATION_OR_SPEAKER_REMOVAL_REFUSED"}
	var base: Dictionary={"ok":true,"matched":true,"npcs":scene.npcs.duplicate(true),"visual_objects":render_objects.duplicate(true),"interactions":projected_base,"receipt":{"old_task_receipt":old_projected.receipt.duplicate(true)}}
	var projected: Dictionary=TASK.project_temple(base,source_portals,flags,states)
	if projected.get("ok")!=true or projected.get("matched")!=true: return {"ok":false,"error":"TEMPLE_LAYOUT_QUEST_SUCCESSOR_REFUSED:"+String(projected.get("error","UNKNOWN"))}
	if not city._equal_value(projected.portals,source_portals): return {"ok":false,"error":"TEMPLE_PROJECTED_PORTALS_CHANGED"}
	projected.receipt["source_scene_id"]=String(scene.scene_id)
	projected.receipt["new_child_path"]=scene.resource_path
	projected.receipt["canonical_oracle_path"]=original.resource_path
	projected.receipt["canonical_oracle_sha256"]=TEMPLE.ORIGINAL_SHA
	projected.receipt["old_task_receipt"]=old_projected.receipt.duplicate(true)
	projected.receipt["only_paper_phase_delta_in_old_task_layer"]=true
	projected.receipt["two_legacy_speaker_hotspots_absent_from_actual_layout"]=true
	projected.receipt["successor_portals_are_actual_scene_data"]=true
	projected.receipt["new_geometry_unmodified"]=true
	return projected
