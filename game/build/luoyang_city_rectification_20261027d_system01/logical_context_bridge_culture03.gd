extends RefCounted
## New REGION_27D conversation owner. Legacy Field guards are never overridden.
## Existing Coordinator is used only as a pure authored Dialog graph builder.
const SELF="res://build/luoyang_city_rectification_20261027d_system01/logical_context_bridge_culture03.gd"
const FIELD="res://build/luoyang_regions_20261027d_source01/region_field.gd"
const SESSION="res://build/luoyang_regions_20261027d_source01/region_session.gd"
const Compiler=preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const Projector=preload("res://build/luoyang_city_rectification_20261027d_system01/logical_terminal_projector04_culture_definition.gd")
const Culture=preload("res://build/luoyang_regions_20261027d_source01/culture_business_snapshot01.gd")
const Definition=preload("res://build/luoyang_city_rectification_20261027d_system01/culture_definition.gd")
const Ambient=preload("res://build/luoyang_city_finish_20261025i_source01/runtime_READY01/ambient18_runtime_READY.gd")
const Present=preload("res://build/luoyang_city_full_rollout_20261022ap_npc01/presentation_execution.gd")
const People=preload("res://build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people_execution.gd")
const Conversation=preload("res://build/luoyang_city_revision_20261024b_dialog01/npc_conversation_CANDIDATE.gd")
var _field: WeakRef
var _owner: RefCounted
var _contexts: Dictionary={}
var _sources: Dictionary={}
var _token: int=0
var _serial: int=0
var _conversation: Dictionary={}
var _builder: RefCounted
var _ambient_rows: Dictionary={}
var _visits: Dictionary={}
var _letter: Sprite2D
var _tween: Tween
var _last: Dictionary={}
var _feedback_id: StringName=&""

static func project(logical_id: StringName,source: SceneScript,raw: Dictionary,flags: Dictionary,states: Dictionary) -> Dictionary:
	return Projector.project(logical_id,source,raw,flags,states)
func project_all(flags: Dictionary,states: Dictionary,inputs: Dictionary) -> Dictionary:
	var actors: Dictionary={};var slots: Dictionary={};var interactions: Dictionary={};var visuals: Dictionary={}
	for logical: String in inputs:
		var context: Dictionary=inputs[logical]
		var raw: Dictionary=context.get("terminal",context)
		var source: SceneScript=context.get("source_scene") as SceneScript
		if source==null: source=source_scene(StringName(logical))
		if source==null: return fail("REGION_PHASE_SOURCE_SCENE")
		var phase: Dictionary=Projector.project(StringName(logical),source,raw,flags,states)
		if phase.get("ok")!=true: return phase
		for row: Dictionary in phase.npcs:
			var key: String=logical+"/"+String(row.data.npc_id)
			slots[key]=phase.actor_slots[key].duplicate(true)
			if slots[key].active:
				actors[key]={"dialog_id":String(row.data.get("dialog_id","")),"interaction_action":String(row.data.get("interaction_action","")),"dialog_variants":row.data.get("dialog_variants",[]).duplicate(true)}
		for row: Dictionary in phase.interactions:
			var properties: Dictionary={"active":row.get("default_active",true)}
			for key: String in ["action","require_flag","hide_flag","require_quest_active","require_quest_completed"]: properties[key]=row.data.get(key,"")
			interactions[logical+"/"+row.id]=properties
		for key: String in phase.dynamic_visual_state: visuals[logical+"/"+key]=phase.dynamic_visual_state[key]
	return {"ok":true,"npcs":actors,"actor_slots":slots,"interactions":interactions,"dynamic_visual_state":visuals}
static func fail(reason: String,matched: bool=true) -> Dictionary: return {"ok":false,"matched":matched,"error":reason}
static func dependency_paths() -> Array[String]:
	# The Source sealer assigns immutable values; this never current-fills SHA.
	return [SELF,"res://build/luoyang_city_rectification_20261027d_system01/logical_terminal_projector04_culture_definition.gd",FIELD,SESSION,"res://build/luoyang_regions_20261027d_source01/region_compiler.gd","res://build/luoyang_regions_20261027d_source01/culture_business_snapshot01.gd","res://build/luoyang_city_finish_20261025i_source01/runtime_READY01/ambient18_runtime_READY.gd","res://build/luoyang_city_full_rollout_20261022ap_npc01/presentation_execution.gd","res://build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people_execution.gd","res://build/luoyang_city_revision_20261024b_dialog01/npc_conversation_CANDIDATE.gd"] + Definition.dependency_paths()
func attach(field: Node,session: RefCounted,logical_contexts: Dictionary) -> bool:
	if _field!=null or not is_instance_valid(field) or session==null or field.get_script().resource_path!=FIELD or session.get_script()!=load(SESSION) or not session.matches(field,field.get("_current_scene")): return false
	var receipt: Dictionary=session.receipt()
	if receipt.get("owner_kind")!="REGION_27D" or receipt.get("token")!=session.get_instance_id() or int(receipt.get("token",0))==0 or logical_contexts.is_empty(): return false
	if not receipt.get("source_first") is Dictionary or receipt.source_first.is_empty() or receipt.source_first.get(SELF)!=FileAccess.get_sha256(SELF): return false
	for logical: String in logical_contexts:
		var context: Dictionary=logical_contexts[logical]
		if not context.get("source_scene") is SceneScript or context.source_scene.scene_id!=StringName(logical) or not context.get("terminal") is Dictionary or context.terminal.get("logical_id")!=logical: return false
	_field=weakref(field);_owner=session;_contexts=logical_contexts.duplicate(true);_sources=receipt.source_first.duplicate(true);_token=session.get_instance_id()
	_ambient_rows=Ambient._read_data()
	return not _ambient_rows.is_empty() and Ambient._register_core_rects()
func source_scene(logical_id: StringName) -> SceneScript:
	return _contexts.get(String(logical_id),{}).get("source_scene") as SceneScript
func _live(setup: bool=false) -> bool:
	var field: Node=_field.get_ref() as Node if _field!=null else null
	if not is_instance_valid(field) or not field.is_inside_tree() or field.get_tree().current_scene!=field or field.get_script().resource_path!=FIELD or _owner==null or _owner.get_instance_id()!=_token or field.call("region_session_handle")!=_owner or not _owner.matches(field,field.get("_current_scene")): return false
	var receipt: Dictionary=_owner.receipt()
	if receipt.get("token")!=_token or receipt.get("source_first")!=_sources or receipt.get("owner_kind")!="REGION_27D": return false
	if setup: return receipt.get("phase") in ["FIRST","LIVE"] and field.get("_field_loading_failed")!=true
	return receipt.get("phase")=="LIVE" and receipt.get("finalized")==true and receipt.get("source_final")==_sources and field.get("_field_loading_complete")==true and field.get("_field_loading_failed")!=true and field.get("_scene_rebuilding")!=true and not LoadingManager._transition_active and not LoadingManager._external_active
func _actor(id: String,logical: String) -> NPCNode:
	var field: Node=_field.get_ref() as Node;var found: NPCNode
	for npc: NPCNode in field.get("_npc_nodes"):
		if not is_instance_valid(npc) or npc.npc_id!=id or String(npc.get_meta("region27d_logical_id",""))!=logical: continue
		if found!=null: return null
		found=npc
	return found
func _native(actor: NPCNode) -> bool:
	var field: Node=_field.get_ref() as Node
	if not is_instance_valid(actor) or not actor.is_inside_tree() or not actor.is_visible_in_tree() or actor.get_parent()!=field.get("_actor_layer"): return false
	var body: StaticBody2D=actor.get("_body_collider") as StaticBody2D
	if body==null or not body.is_inside_tree() or body.collision_layer!=1 or body.get_child_count()!=1: return false
	var shape: CollisionShape2D=body.get_child(0) as CollisionShape2D
	return shape!=null and not shape.disabled and shape.shape is RectangleShape2D and actor.sprite!=null and actor.sprite.texture!=null
func configure_actor_before_ready(actor: NPCNode,source_row: Dictionary) -> Dictionary:
	if not _live(true) or actor==null or actor.is_inside_tree() or actor.get_parent()!=null or not source_row.get("data") is Dictionary: return fail("REGION_PRE_ADD_OWNER")
	var data: Dictionary=source_row.data;var logical: String=String(source_row.get("logical_id",""))
	if source_scene(StringName(logical))==null or actor.npc_id!=String(data.get("npc_id","")): return fail("REGION_PRE_ADD_LOGICAL_ID")
	actor.set_meta("region27d_logical_id",logical)
	actor.set_meta("region27d_primary",data.get("region27d_primary",{}).duplicate(true))
	for key: String in ["npc_name","dialog_id","interaction_action","sprite_path","portrait_path","walk_sprite_path","movement_mode"]:
		if data.has(key) and actor.get(key)!=data[key]: return fail("REGION_PRE_ADD_SOURCE_FIELD:"+key)
	if actor.sprite_scale!=float(data.get("scale",.08)) or actor.dialog_variants!=data.get("dialog_variants",[]): return fail("REGION_PRE_ADD_SCALE_OR_VARIANTS")
	if data.get("region27d_calibrate_adult",false): actor._calibrate_adult_body=true
	if data.get("harbour_life_ground_anchored",false) or data.get("district_life_ground_anchored",false): actor._calibrate_adult_body=true;actor.sprite_scale=1.0
	if data.get("culture_x_pickup_recipient",false): actor.set_meta("region27d_actual_recipient",true)
	return {"ok":true,"source_logical_id":logical}
func update_actor_primary(actor: NPCNode,data: Dictionary) -> bool:
	if not _live() or not _native(actor) or actor.npc_id!=data.get("npc_id") or _actor(actor.npc_id,String(actor.get_meta("region27d_logical_id","")))!=actor or not data.get("region27d_primary") is Dictionary: return false
	actor.set_meta("region27d_primary",data.region27d_primary.duplicate(true))
	return true
func _guard() -> Dictionary:
	if _conversation.is_empty() or not _live(): return fail("REGION_CONVERSATION_OWNER")
	var field: Node=_field.get_ref() as Node;var actor: NPCNode=_conversation.actor.get_ref() as NPCNode;var player: Node2D=field.get("_player") as Node2D
	if not _native(actor) or player==null or not player.is_inside_tree() or _actor(actor.npc_id,_conversation.logical_id)!=actor or player.get_instance_id()!=_conversation.player_id or field.get_instance_id()!=_conversation.field_id or field.get("_current_scene").get_instance_id()!=_conversation.scene_id or String(actor.get_meta("region27d_logical_id",""))!=_conversation.logical_id: return fail("REGION_CONVERSATION_INSTANCE")
	if player.global_position.distance_to(actor.global_position)>118.0 or not Compiler.safe_body(field.get("_region"),player.position,Vector2(17,12)): return fail("REGION_CONVERSATION_DISTANCE_OR_FOOT")
	return {"ok":true,"field":field,"actor":actor,"player":player,"logical_id":_conversation.logical_id}
func _known(logical: String,id: String,ready: Dictionary) -> bool:
	if _ambient_rows.has(id) and String(_ambient_rows[id].text.scene_id)==logical: return true
	if People.daily_handles(StringName(logical),id) or Present.daily_handles(StringName(logical),id): return true
	for q: Dictionary in ready.quests.values():
		for who: Dictionary in q.actors:
			if who.scene_id==logical and who.npc_id==id: return true
	return logical==Culture.DOCKS and id==Culture.BUYER
func _prepared(graph: DialogScript,actor: NPCNode,logical: String,pure_daily: bool,preserve: bool) -> DialogScript:
	var key: String=logical+"|"+actor.npc_id;var count: int=int(_visits.get(key,0))
	var hero: String=GameState.player.display_name if GameState.player!=null else "冷孤云"
	var portrait: String=GameState.player.portrait_path if GameState.player!=null else Conversation.HERO_PORTRAIT
	var result: Dictionary=Conversation.prepare(graph,logical,actor.npc_id,actor.npc_name,hero,portrait,count,pure_daily,preserve)
	if result.get("ok")!=true: return null
	_visits[key]=count+1
	return result.script as DialogScript
func prepare_primary(actor: NPCNode,script: DialogScript) -> DialogScript:
	if not _live() or not _native(actor): return null
	var playable: DialogScript=script
	if not DialogPlayer.can_play_script(playable):
		playable=DialogPlayer._early_visit_dialog(playable)
		if playable==null or not DialogPlayer.can_play_script(playable): return null
	return _prepared(playable,actor,String(actor.get_meta("region27d_logical_id","")),false,false)
func open(actor: Node,kind: String,payload: String) -> Dictionary:
	if not actor is NPCNode or not _live(): return fail("REGION_OPEN_OWNER")
	var npc: NPCNode=actor as NPCNode;var logical: String=String(npc.get_meta("region27d_logical_id",""))
	if source_scene(StringName(logical))==null or _actor(npc.npc_id,logical)!=npc or not _native(npc): return fail("REGION_OPEN_LOGICAL_ACTOR")
	if kind=="dialog" and payload!=npc.dialog_id or kind=="action" and payload!=npc.interaction_action: return fail("REGION_OPEN_ACTUAL_PAYLOAD")
	var ready: Dictionary=Definition.readiness()
	if ready.get("ok")!=true: return ready
	if not _known(logical,npc.npc_id,ready): return {"ok":true,"matched":false,"allow_original_dispatch":true,"source_logical_id":logical}
	if DialogPlayer.is_playing() or not _conversation.is_empty(): return fail("REGION_OPEN_BUSY")
	var field: Node=_field.get_ref() as Node;var player: Node2D=field.get("_player") as Node2D
	if player==null or player.global_position.distance_to(npc.global_position)>118.0 or not _owner.revalidate_boundary(field,field.get("_current_scene"),field.get("_region")): return fail("REGION_OPEN_BOUNDARY")
	_serial+=1
	_conversation={"serial":_serial,"actor":weakref(npc),"logical_id":logical,"player_id":player.get_instance_id(),"field_id":field.get_instance_id(),"scene_id":field.get("_current_scene").get_instance_id(),"selected":{},"handoff_ready":false}
	if not _owner.pin("logical_conversation"): _conversation.clear();return fail("REGION_CONVERSATION_PIN")
	var graph: DialogScript
	if People.daily_handles(StringName(logical),npc.npc_id) or Present.daily_handles(StringName(logical),npc.npc_id):
		var daily: Dictionary=People.build_daily_menu(StringName(logical),npc.npc_id,npc.npc_name) if People.daily_handles(StringName(logical),npc.npc_id) else Present.build_daily_menu(StringName(logical),npc.npc_id,npc.npc_name)
		if daily.get("ok")!=true: abort("daily_source");return daily
		graph=_prepared(daily.script,npc,logical,true,false)
	elif _ambient_rows.has(npc.npc_id):
		var text: Dictionary=_ambient_rows[npc.npc_id].text
		graph=DialogScript.new();graph.dialog_id=StringName("region27d_daily_%d"%_serial);graph.entry_node_id=&"hero"
		var builder: RefCounted=Culture.new()
		var hero_name: String=GameState.player.display_name if GameState.player!=null else "冷孤云"
		var hero: DialogNode=builder._node(graph,String(text.get("hero_opening_line","劳驾，近来街坊有什么新鲜事？")),hero_name,"hero")
		hero.portrait_path=GameState.player.portrait_path if GameState.player!=null else Conversation.HERO_PORTRAIT
		var first: DialogNode=builder._node(graph,text.lines[0],npc.npc_name,"first");first.portrait_path=npc.portrait_path
		var last: DialogNode=builder._node(graph,text.lines[1],npc.npc_name,"last");last.portrait_path=npc.portrait_path
		hero.on_end="next:"+String(first.node_id);first.on_end="next:"+String(last.node_id);graph.entry_node_id=hero.node_id
	else:
		_builder=Culture.new() # No attach(), _owned(), open() or finish() calls.
		_builder.set("_session",{"actions":{},"states":{},"common":ready.text.common})
		graph=DialogScript.new();graph.dialog_id=StringName("region27d_culture_%d_%d"%[field.get_instance_id(),_serial])
		var menu: DialogNode=_builder._node(graph,ready.text.common.greeting,npc.npc_name,"menu")
		var topics: DialogNode=_builder._node(graph,ready.text.common.culture_topics,npc.npc_name,"topics")
		var primary: Dictionary=npc.get_meta("region27d_primary",{})
		if not String(primary.get("dialog_id","")).is_empty() or not String(primary.get("interaction_action","")).is_empty():
			menu.choices.append({"text":ready.text.primary_option_labels.get(npc.npc_id,ready.text.common.original_primary),"next":_builder._terminal(graph,"我们接着原来的话题说。",npc.npc_name,{"type":"primary"})})
		menu.choices.append({"text":ready.text.common.culture_topics,"next":String(topics.node_id)});menu.choices.append({"text":ready.text.common.leave,"next":"end"})
		for q: Dictionary in ready.quests.values():
			var relevant: bool=false
			for who: Dictionary in q.actors:
				if who.scene_id==logical and who.npc_id==npc.npc_id: relevant=true
			if q.id==Culture.LETTER and logical==Culture.DOCKS and npc.npc_id==Culture.BUYER: relevant=true
			if relevant: topics.choices.append({"text":ready.text_by_id[q.id].topic_label,"next":_builder._topic(graph,q,ready.text_by_id[q.id],logical,npc,String(topics.node_id))})
		topics.choices.append({"text":ready.text.common.back,"next":String(menu.node_id)});graph.entry_node_id=menu.node_id
		graph=_prepared(graph,npc,logical,false,true)
	if graph==null: abort("dialog_preparation");return fail("REGION_DIALOG_PREPARATION")
	_conversation["script"]=graph
	return {"ok":true,"matched":true,"npc":npc,"script":graph,"source_logical_id":logical}
func observe_node() -> void:
	if _conversation.is_empty(): return
	if _guard().get("ok")!=true or DialogPlayer._current_script!=_conversation.script: abort("stale_dialog_owner");return
	if _builder==null: return
	var build: Dictionary=_builder.get("_session");var node: DialogNode=DialogPlayer._current_node
	if node==null or not build.actions.has(String(node.node_id)): return
	var action: Dictionary=build.actions[String(node.node_id)]
	if action.node!=node: abort("selected_node_identity");return
	_conversation.selected=action.event.duplicate(true)
	if _conversation.selected.type=="pickup" and not _conversation.get("handoff_running",false) and not _conversation.handoff_ready: _handoff(_conversation.serial)
func _pickup_people() -> Dictionary:
	var guard: Dictionary=_guard()
	if guard.get("ok")!=true or guard.logical_id!=Culture.DOCKS or guard.actor.npc_id!=Culture.BOOKING: return fail("REGION_PICKUP_ORIGINAL_CLERK")
	var buyer: NPCNode=_actor(Culture.BUYER,Culture.DOCKS);var clerk: NPCNode=guard.actor
	if not _native(buyer) or not buyer.get_meta("region27d_actual_recipient",false) or buyer.global_position.distance_to(clerk.global_position)>140 or guard.player.global_position.distance_to(buyer.global_position)>118: return fail("REGION_PICKUP_PERSONAL_PEOPLE")
	for person: NPCNode in [buyer,clerk]:
		if not Compiler.safe_body(guard.field.get("_region"),person.position,Vector2(17,15)): return fail("REGION_PICKUP_GROUND")
		var body: StaticBody2D=person.get("_body_collider") as StaticBody2D;var shape: CollisionShape2D=body.get_child(0) as CollisionShape2D
		var query:=PhysicsShapeQueryParameters2D.new();query.shape=shape.shape;query.transform=shape.global_transform;query.collision_mask=1;query.exclude=[body.get_rid(),guard.player.get_rid()]
		if not guard.field.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty(): return fail("REGION_PICKUP_ACTUAL_PHYSICS")
	return {"ok":true,"field":guard.field,"buyer":buyer,"clerk":clerk}
func _handoff(serial: int) -> void:
	var people: Dictionary=_pickup_people()
	if people.get("ok")!=true: _conversation["rejected"]=people.get("error","pickup");return
	var ready: Dictionary=Definition.readiness();var texture: Texture2D=load(ready.contract.pickup.letter_texture) as Texture2D
	if texture==null: _conversation["rejected"]="letter_texture";return
	_conversation["handoff_running"]=true
	_letter=Sprite2D.new();_letter.texture=texture;_letter.scale=Vector2.ONE*(34.0/texture.get_width());_letter.position=Vector2(-24,-72);_letter.z_index=20;people.clerk.add_child(_letter)
	var letter: Sprite2D=_letter
	_tween=people.field.create_tween();_tween.tween_property(letter,"global_position",people.buyer.global_position+Vector2(20,-72),.45)
	_tween.finished.connect(func() -> void:
		if _conversation.is_empty() or _conversation.serial!=serial or DialogPlayer._current_script!=_conversation.script:
			if is_instance_valid(letter): letter.queue_free()
			return
		var current: Dictionary=_pickup_people()
		if current.get("ok")!=true or not is_instance_valid(letter) or letter!=_letter: _conversation["rejected"]="handoff_owner_lost";return
		letter.reparent(current.buyer,true);current.buyer.set_meta("region27d_letter_holder",letter.get_instance_id());_conversation.handoff_ready=true;_conversation.handoff_running=false
	,CONNECT_ONE_SHOT)
func finish(id: StringName) -> Dictionary:
	if id==_feedback_id:
		_feedback_id=&"";abort("feedback_end");return {"ok":true,"matched":true,"committed":false}
	if _conversation.is_empty() or _conversation.script.dialog_id!=id: return {"ok":true,"matched":false}
	if DialogPlayer.is_playing() or DialogPlayer._current_script!=null: return fail("REGION_NOT_NORMAL_DIALOG_END")
	var guard: Dictionary=_guard()
	if guard.get("ok")!=true: abort("finish_owner");return guard
	if not String(_conversation.get("rejected","")).is_empty(): abort("rejected");return fail("REGION_CONVERSATION_REJECTED")
	var chosen: Dictionary=_conversation.selected.duplicate(true)
	if chosen.is_empty(): abort("normal_no_effect");return {"ok":true,"matched":true,"committed":false}
	if chosen.type=="primary":
		var primary: Dictionary=guard.actor.get_meta("region27d_primary",{}).duplicate(true);abort("primary_dispatch")
		return {"ok":true,"matched":true,"primary":primary,"npc_id":guard.actor.npc_id,"source_logical_id":guard.logical_id}
	var current: Dictionary=Culture.read_state(String(chosen.qid),GameState.flags,QuestManager.states);var built: Dictionary=_builder.get("_session")
	if current.get("ok")!=true or current.state!=built.states.get(chosen.qid): abort("stale_progress");return fail("REGION_PROGRESS_CHANGED")
	var ready: Dictionary=Definition.readiness()
	if ready.get("ok")!=true or not _owner.revalidate_boundary(guard.field,guard.field.get("_current_scene"),guard.field.get("_region")): abort("finish_boundary");return fail("REGION_FINISH_SOURCE_BOUNDARY")
	var q: Dictionary=ready.quests[chosen.qid]
	var authority: Dictionary={}
	if chosen.type in ["accept","decline"]: authority=Culture.ISSUERS[chosen.qid]
	elif chosen.type=="solve": authority=Culture.SOLVERS[chosen.qid]
	elif chosen.type=="report": authority=q.reporter
	if not authority.is_empty() and (authority.scene_id!=guard.logical_id or authority.npc_id!=guard.actor.npc_id): abort("wrong_role");return fail("REGION_ORIGINAL_QUEST_ROLE")
	var event: Dictionary={"type":String(chosen.type)}
	if chosen.type=="discover":
		if chosen.scene_id!=guard.logical_id or chosen.npc_id!=guard.actor.npc_id: abort("wrong_witness");return fail("REGION_ORIGINAL_WITNESS")
		event={"type":"discover","clue_id":String(chosen.clue_id),"scene_id":String(chosen.scene_id),"npc_id":String(chosen.npc_id)}
	elif chosen.type=="solve": event={"type":"solve","choice_id":String(chosen.choice_id)}
	elif chosen.type=="report": event={"type":"report","scene_id":guard.logical_id,"npc_id":guard.actor.npc_id}
	elif chosen.type=="pickup":
		var people: Dictionary=_pickup_people()
		if people.get("ok")!=true or not _conversation.handoff_ready or not is_instance_valid(_letter) or _letter.get_parent()!=people.buyer or people.buyer.get_meta("region27d_letter_holder",0)!=_letter.get_instance_id(): abort("personal_handoff_missing");return fail("REGION_PERSONAL_HANDOFF_REQUIRED")
		event={"type":"pickup","scene_id":Culture.DOCKS,"npc_id":Culture.BOOKING,"recipient_npc_id":Culture.BUYER,"personal_pickup_confirmed":true}
	var reduced: Dictionary=Culture.W.transition(String(chosen.qid),current.state,event)
	if reduced.get("ok")!=true: abort("reducer_refused");return reduced
	var accepted: bool=reduced.get("accepted",false)
	if accepted:
		if chosen.type=="accept" and not QuestManager.accept(StringName(chosen.qid)): abort("quest_accept");return fail("REGION_ORIGINAL_QUEST_ACCEPT")
		if chosen.type=="report" and not QuestManager.complete(StringName(chosen.qid)): abort("quest_complete");return fail("REGION_ORIGINAL_QUEST_COMPLETE")
		GameState.flags[Culture.state_key(String(chosen.qid))]=JSON.stringify(reduced.state);GameState.set_flag(Culture.CHANGED_FLAG,true)
	_last={"source_logical_id":guard.logical_id,"npc_id":guard.actor.npc_id,"token":str(_token),"event":chosen.type,"accepted":accepted,"numeric_reward":0,"normal_dialog_end":true}
	var feedback: DialogScript=_feedback(ready.text_by_id[chosen.qid],chosen,accepted,guard.actor)
	abort("committed",chosen.type=="pickup" and accepted)
	return {"ok":true,"matched":true,"committed":accepted,"refresh_dynamic":accepted,"feedback":feedback}
func _feedback(text: Dictionary,selected: Dictionary,accepted: bool,actor: NPCNode) -> DialogScript:
	var line: String="记录已核对。"
	match selected.type:
		"accept": line=text.phase_lines.active
		"decline": line=text.decline_reply
		"discover": line=String(text.clue_log_labels[selected.clue_id])
		"solve": line=String(text.phase_lines.solved) if accepted else String(text.wrong_feedback[selected.choice_id])
		"report": line=String(text.report_reply)
	var script:=DialogScript.new();script.dialog_id=StringName("region27d_feedback_%d_%d"%[_token,_serial])
	var builder: RefCounted=Culture.new();var previous: DialogNode
	var sequence: Array=text.pickup_sequence if selected.type=="pickup" and accepted else [{"text":line,"speaker":actor.npc_name}]
	for item: Dictionary in sequence:
		var node: DialogNode=builder._node(script,String(item.text),String(item.speaker),"feedback")
		if previous==null: script.entry_node_id=node.node_id
		else: previous.on_end="next:"+String(node.node_id)
		previous=node
	_feedback_id=script.dialog_id
	return script
func interaction(area: Area2D,action: String) -> Dictionary:
	if not _live() or not is_instance_valid(area) or not area.is_inside_tree(): return fail("REGION_INTERACTION_OWNER")
	var field: Node=_field.get_ref() as Node;var player: Node2D=field.get("_player") as Node2D
	var logical: String=String(area.get_meta("region27d_logical_id",""));var data: Dictionary=area.get_meta("trigger_data",{})
	if source_scene(StringName(logical))==null or String(data.get("action",""))!=action or not area in field.get("_trigger_areas") or area.get_parent()!=field.get("_interaction_layer") or player==null or not Compiler.safe_body(field.get("_region"),player.position,Vector2(17,12)): return fail("REGION_INTERACTION_LOGICAL_PAYLOAD")
	var declared: Array=field.get("_region").interactions.filter(func(row: Dictionary) -> bool: return row.logical_id==logical and row.key==data.get("id",""))
	if declared.size()!=1 or area.position!=declared[0].foot or player.global_position.distance_to(area.global_position)>maxf(118.0,declared[0].get("size_px",Vector2.ZERO).length()*.5): return fail("REGION_INTERACTION_DECLARED_FOOT_OR_DISTANCE")
	return {"ok":true,"matched":false,"source_logical_id":logical,"action":action}
func abort(reason: String,keep_letter: bool=false) -> void:
	if is_instance_valid(_tween): _tween.kill()
	_tween=null
	if not keep_letter and is_instance_valid(_letter):
		var parent: Node=_letter.get_parent()
		if parent!=null and parent.get_meta("region27d_letter_holder",0)==_letter.get_instance_id(): parent.remove_meta("region27d_letter_holder")
		_letter.queue_free()
	if not keep_letter: _letter=null
	if not _conversation.is_empty() and _owner!=null: _owner.unpin("logical_conversation")
	_conversation.clear();_builder=null
	_last["ended_reason"]=reason
func debug_state() -> Dictionary:
	return {"owner_kind":"REGION_27D_LOGICAL_CONVERSATION","token":str(_token),"active":not _conversation.is_empty(),"last":_last.duplicate(true)}
