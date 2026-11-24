extends RefCounted
## Exact Temple gameplay refresh. No floor/environment/visual/static-body setup.
const READY: bool=false
const SELF: String="res://build/luoyang_city_rectification_20261027d_system01/temple_dynamic_refresh_NOTREADY.gd"
const TEMPLE_ID: StringName=&"ch4_s4_ancient_temple"
const T_PATH: String="res://scripts/city/luoyang_temple_assembly_20261016.gd"
const TASK_PATH: String="res://scripts/city/luoyang_temple_task_adapter_20261016.gd"
const C_PATH: String="res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const MONKS: Array[String]=["temple_cave_keeper_20261018t","temple_bell_keeper_20261018t"]

static func source_paths_for(id: StringName) -> Dictionary:
	return {SELF:true} if id==TEMPLE_ID else {}

static func _owner(field: Node,allow_setup: bool) -> Dictionary:
	if not READY or not is_instance_valid(field) or not field.is_inside_tree() or field.get_tree().current_scene!=field or field.get("_scene_rebuilding")!=allow_setup or field.get("_field_loading_failed")==true: return {}
	var scene: SceneScript=field.get("_current_scene") as SceneScript
	var temple: RefCounted=field.get("_temple_session") as RefCounted
	var lease: RefCounted=field.get("_finish25i") as RefCounted
	if scene==null or scene.scene_id!=TEMPLE_ID or scene.map_layout==null or temple==null or lease==null or temple.get_script()!=load(T_PATH) or not lease._owned(allow_setup,true): return {}
	var state: Dictionary=lease.get("_state");var original: Dictionary=temple.state()
	if state.is_empty() or state.get("finalized")!=true or state.get("owner_kind")!="TEMPLE_OWN_FIELD_ORIGINAL" or state.get("token")==0 or state.get("token")!=temple.get_instance_id() or not state.get("scene") is WeakRef or state.scene.get_ref()!=scene or not state.get("layout") is WeakRef or state.layout.get_ref()!=scene.map_layout or not state.get("field") is WeakRef or state.field.get_ref()!=field or not state.get("temple_ref") is WeakRef or state.temple_ref.get_ref()!=temple: return {}
	if original.get("finalized")!=true or original.get("released")!=false or original.get("error")!="" or original.get("scene_instance")!=scene.get_instance_id() or original.get("source_first")!=original.get("source_final") or original.get("source_first")!=state.get("first"): return {}
	for path: String in [SELF,T_PATH,TASK_PATH,C_PATH]:
		if not state.first.get(path) is String or FileAccess.get_sha256(path)!=state.first[path]: return {}
	var city: Variant=load(C_PATH)
	if temple.get("_scene")!=scene or not city._equal_value(temple.get("_scene_storage"),city._transition_storage(scene)) or not city._equal_value(temple.get("_layout_storage"),city._transition_storage(scene.map_layout)): return {}
	return state

static func _static(field: Node) -> Dictionary:
	var objects: Array=[];var bodies: Array=[];var exits: Array=[];var roots: Array=[]
	for sprite: Sprite2D in field.get("_scene_object_nodes"):
		if not is_instance_valid(sprite): return {}
		if String(sprite.name).begins_with("TriggerVisual_"): continue
		objects.append([sprite.get_instance_id(),sprite.texture.get_instance_id() if sprite.texture!=null else 0,sprite.material,sprite.position,sprite.scale])
	for body: StaticBody2D in field.get("_collision_bodies"):
		if not is_instance_valid(body): return {}
		bodies.append(body.get_instance_id())
	for zone: Node in field.get("_exit_nodes"):
		if not is_instance_valid(zone): return {}
		exits.append(zone.get_instance_id())
	for child: Node in field.get("world_container").get_children(): roots.append(child.get_instance_id())
	return {"objects":objects,"bodies":bodies,"exits":exits,"roots":roots,"world":field.get("world_container"),"world_transform":field.get("world_container").transform,"background":field.get("_world_background"),"camera":field.get("_world_camera"),"player":field.get("_player"),"mask":field.get("_walkable_mask_image"),"temple":field.get("_temple_session"),"lease":field.get("_finish25i"),"geometry":var_to_bytes(field.get("_functional_room_geometry")),"size":field.get("_world_size")}

static func _actor(actor: NPCNode) -> Dictionary:
	var body: StaticBody2D=actor.get("_body_collider") as StaticBody2D
	var shape: CollisionShape2D=body.get_child(0) as CollisionShape2D if is_instance_valid(body) and body.get_child_count()==1 else null
	return {"instance":actor.get_instance_id(),"body":body,"shape":shape,"body_rect":(shape.shape as RectangleShape2D).size if shape!=null and shape.shape is RectangleShape2D else Vector2.INF,"body_transform":body.transform if body!=null else Transform2D.IDENTITY,"shape_transform":shape.transform if shape!=null else Transform2D.IDENTITY,"position":actor.position,"scale":actor.sprite_scale,"sprite":actor.sprite,"texture":actor.sprite.texture if is_instance_valid(actor.sprite) else null,"sprite_path":actor.sprite_path,"portrait":actor.portrait_path,"name":actor.npc_name,"action":actor.interaction_action,"variants":actor.dialog_variants.duplicate(true),"movement":actor.movement_mode,"calibrate":actor._calibrate_adult_body,"ground":actor._ground_anchored}

static func refresh(field: Node) -> Dictionary:
	var state: Dictionary=_owner(field,true)
	if state.is_empty(): return {"ok":false,"error":"TEMPLE_DYNAMIC_REAL_FINAL_OWNER_OR_SOURCE"}
	var scene: SceneScript=field.get("_current_scene") as SceneScript
	var temple: RefCounted=field.get("_temple_session") as RefCounted
	var lease: RefCounted=field.get("_finish25i") as RefCounted
	var revision: int=int(field.get("_city3_motion_revision"));var token: int=LoadingManager._external_token
	var before: Dictionary=_static(field)
	var owner: Callable=func() -> bool: return is_instance_valid(field) and field.is_inside_tree() and field.get_tree().current_scene==field and field.get("_current_scene")==scene and field.get("_temple_session")==temple and int(field.get("_city3_motion_revision"))==revision and LoadingManager._external_token==token and field.get("_scene_rebuilding")==true
	# Preserve the original complete source/storage FINAL, not a reduced hash gate.
	if before.is_empty() or not await temple.finalize(scene,owner) or not owner.call() or not lease.revalidate_boundary(): return {"ok":false,"error":"TEMPLE_DYNAMIC_ORIGINAL_FINAL"}
	var flags: Dictionary=GameState.flags.duplicate(true);var quests: Dictionary=QuestManager.states.duplicate(true)
	var raw_objects: Array=temple.get_script().project_objects(temple.get("data"),field.get("_world_size"))
	var projected: Dictionary=load(TASK_PATH).project(scene,flags,quests,scene.map_layout.interactions,raw_objects)
	if projected.get("ok")!=true or projected.get("matched")!=true or var_to_bytes(projected.get("visual_objects"))!=var_to_bytes(raw_objects) or projected.get("npcs",[]).size()!=2: return {"ok":false,"error":"TEMPLE_DYNAMIC_ORIGINAL_TASK_PROJECTION"}
	var interaction_rows: Dictionary=lease.project_interactions(projected.interactions)
	if interaction_rows.get("ok")!=true: return {"ok":false,"error":"TEMPLE_DYNAMIC_EFFECTIVE_INTERACTIONS"}
	var actors: Dictionary={};var protected: Dictionary={};var dialogs: Dictionary={}
	for actor: NPCNode in field.get("_npc_nodes"):
		if not is_instance_valid(actor): return {"ok":false,"error":"TEMPLE_DYNAMIC_ACTOR_RELEASED"}
		if actor.npc_id in MONKS:
			if actors.has(actor.npc_id) or actor.get_parent()!=field.get("_actor_layer"): return {"ok":false,"error":"TEMPLE_DYNAMIC_MONK_IDENTITY"}
			actors[actor.npc_id]=actor;protected[actor.npc_id]=_actor(actor)
	for row: Dictionary in projected.npcs:
		var id: String=String(row.get("npc_id",""))
		if not id in MONKS or not actors.has(id) or dialogs.has(id) or row.get("interaction_action")!="" or row.get("dialog_variants")!=[]: return {"ok":false,"error":"TEMPLE_DYNAMIC_DECLARED_MONK_DIALOG"}
		dialogs[id]=String(row.dialog_id)
	if actors.size()!=2 or dialogs.size()!=2: return {"ok":false,"error":"TEMPLE_DYNAMIC_TWO_ORIGINAL_MONKS"}
	# Keep the real actors, original bodies/texture/scale/feet and every portal.
	# Only their source-projected quest dialogue and dynamic investigation areas change.
	for id: String in MONKS: actors[id].dialog_id=dialogs[id]
	var old_areas: Array=field.get("_trigger_areas").duplicate()
	for area: Area2D in old_areas:
		if not is_instance_valid(area): return {"ok":false,"error":"TEMPLE_DYNAMIC_AREA_RELEASED"}
		field.call("_set_interaction_highlight",area,false)
		var highlight: Variant=area.get_meta("highlight_node",null)
		if highlight is Sprite2D and is_instance_valid(highlight) and String(highlight.name).begins_with("TriggerVisual_") and field.get("_scene_object_nodes").has(highlight):
			field.get("_scene_object_nodes").erase(highlight);highlight.get_parent().remove_child(highlight);highlight.free()
		area.get_parent().remove_child(area);area.free()
	field.get("_trigger_areas").clear()
	field.call("_spawn_trigger_zones",interaction_rows.rows)
	var receipt: Dictionary=projected.receipt.duplicate(true)
	receipt.merge({"matched":true,"render_applied":true,"original_scene_identity":scene.get_instance_id(),"dynamic_only":true},true)
	field.set("_city_tasks_receipt",receipt)
	for id: String in MONKS:
		if _actor(actors[id])!=protected[id] or actors[id].dialog_id!=dialogs[id]: return {"ok":false,"error":"TEMPLE_DYNAMIC_PROTECTED_ACTOR_CHANGED"}
	if before!=_static(field) or not owner.call() or not lease.revalidate_boundary() or _owner(field,true).is_empty(): return {"ok":false,"error":"TEMPLE_DYNAMIC_STATIC_OR_OWNER_CHANGED"}
	return {"ok":true,"dynamic_only":true,"static_objects_preserved":true,"monk_instances_and_bodies_preserved":true,"phase":receipt.phase,"pending_again":flags!=GameState.flags or quests!=QuestManager.states}
