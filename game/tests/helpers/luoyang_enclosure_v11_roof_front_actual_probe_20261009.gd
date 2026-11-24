extends "res://tests/helpers/joint_v15_wall_v5_fine_alpha_probe.gd"
## Only six fixed roofs get an explicit continuous-front contract. Other objects
## retain super's strong front+behind algorithm; no coarse miss ever proves absence.
const ROOF_PROOF = preload("res://tests/helpers/luoyang_enclosure_v11_roof_front_proof_20261009.gd")
const ROOF_PROOF_PATH := "res://tests/helpers/luoyang_enclosure_v11_roof_front_proof_20261009.gd"
const ROOF_PROOF_SHA := "8a82284236fe033f770fc4ff803106abd04c23c64728d713d157c0e11a66b891"
var roof_proof: RefCounted=ROOF_PROOF.new()
var roof_ready:=false

func configure(tree: SceneTree,actual_field: Control,original: Dictionary,checker: Callable,screenshot: Callable) -> bool:
	if not super.configure(tree,actual_field,original,checker,screenshot): return false
	roof_ready=FileAccess.get_sha256(ROOF_PROOF_PATH)==ROOF_PROOF_SHA and roof_proof.call("prepare")==true
	return roof_ready

func _current_identity() -> Dictionary:
	var player: Node2D=field.get("_player") as Node2D
	var sprite: Sprite2D=player.get("sprite") as Sprite2D if player!=null else null
	if player==null or sprite==null or sprite.texture==null or player.get_script()==null or player.get_script().resource_path!=ROOF_PROOF.PLAYER or FileAccess.get_sha256(ROOF_PROOF.PLAYER)!=ROOF_PROOF.PLAYER_SHA: return {}
	var family: Variant=player.get("_weapon_style"); var moving: Variant=player.get("_is_moving"); var direction: Variant=player.get("_direction")
	if typeof(family)!=TYPE_STRING_NAME or typeof(moving)!=TYPE_BOOL or typeof(direction)!=TYPE_STRING or String(family) not in ["sword","dao","staff","palm","hidden"] or direction not in ["up","down","left","right"]: return {}
	var state: String="walk" if moving else "idle"
	var frames: int=8 if moving else 4
	var path: String=ROOF_PROOF.ROOT+String(family)+"/lengguyun_"+String(family)+"_"+state+"_"+direction+"_25d_"+str(frames)+"f.png"
	var key: String=String(family)+":"+direction+":"+state
	if typeof(player.get("_applied_visual_key"))!=TYPE_STRING or player.get("_applied_visual_key")!=key or sprite.texture.resource_path!=path or sprite.hframes!=frames or sprite.vframes!=1 or sprite.frame<0 or sprite.frame>=frames: return {}
	return {"family":String(family),"state":state,"direction":direction,"current_texture":path,"current_texture_sha256":FileAccess.get_sha256(path),"frame":sprite.frame,"hframes":frames,"applied_visual_key":key,"ground_anchored":player.get("_ground_anchored"),"source_exact":true}

func _front_proof(object: Dictionary) -> Dictionary:
	if not roof_ready or String(manifest.get("canonical_scene_id",""))!="ch4_s1_luoyang_yamen" or _current_identity().is_empty(): return {}
	var player: Node2D=field.get("_player") as Node2D
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	var container: Node2D=field.get("world_container") as Node2D
	if definition==null or not definition.actor_positions_are_feet or player.get("_ground_anchored")!=true: return {}
	return roof_proof.call("prove_actual",String(object.id),prop(String(object.id)),player.get("sprite") as Sprite2D,float(player.call("get_depth_sort_y")),container.to_global(point(object.world_foot_px)).y,definition.player_visual_scale,true)

func _alpha_trial(object: Dictionary) -> Dictionary:
	if String(object.id) not in ROOF_PROOF.IDS: return await super._alpha_trial(object)
	var origin_exact: bool=FileAccess.get_sha256(FINE_ALPHA_ORIGIN_PATH).to_lower()==FINE_ALPHA_ORIGIN_SHA
	_check(origin_exact,"six-roof preserves exact original physical source")
	var initial_proof: Dictionary=_front_proof(object)
	var proved: bool=origin_exact and not initial_proof.is_empty() and initial_proof.get("proved")==true
	_check(proved,"fixed six-roof ALL240 continuous front domain strict proof; absence of proof is FAIL: "+String(object.id))
	if not proved: return {"complete":false,"records":[],"front_proof":_scalar_evidence(initial_proof),"missing_relation_is_fail":true,"scope":"SIX_ROOF_PROOF_NOT_PROVEN_NO_FALLBACK"}
	var player: Node2D=field.get("_player") as Node2D
	var sprite: Sprite2D=player.get("sprite") as Sprite2D
	var container: Node2D=field.get("world_container") as Node2D
	var target_prop: Sprite2D=prop(String(object.id))
	var bounds: Rect2=alpha.bounds_in(target_prop,container)
	var stations: Dictionary={}; var considered:=0
	var discovery: Array[Dictionary]=[]
	# Exact original coarse and, when needed, 1px X refinement/Y inventory.
	# Behind ALWAYS needs genuine current-frame strong intersection. Front needs
	# actual legal full875/17 + Physics/segment; proof independently covers alpha.
	for fine: bool in [false,true]:
		if stations.size()==2: break
		for direction: Vector2 in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
			var orientation: Dictionary=await move_to(player.position+direction*2)
			await driver.completed_actor_stage()
			var identity: Dictionary=_current_identity()
			_check(not identity.is_empty(),"actual natural input weapon/state/direction/texture identity: "+String(object.id))
			var stage: Dictionary={"fine":fine,"direction":_scalar_evidence(direction),"orientation":orientation,"identity":identity,"considered":0,"accepted":[],"absence_from_search_claimed":false}
			discovery.append(stage)
			if not bool(orientation.get("ok",false)) or identity.is_empty(): continue
			var xs: Array[float]=[]
			if fine:
				for x: int in range(floori(bounds.position.x)-20,ceili(bounds.end.x)+21): xs.append(float(x))
			else: xs=[bounds.position.x-20,bounds.position.x+20,bounds.get_center().x,bounds.end.x-20,bounds.end.x+20]
			var ys: Array[float]=[]
			for d: float in [-256.,-128.,-64.,-32.,-16.,-8.,-2.,2.,8.,16.,32.,64.]: ys.append(float(object.depth_foot_y)+d)
			for y: int in range(maxi(16,floori(bounds.position.y)),mini(2032,ceili(bounds.end.y)+116),16): ys.append(float(y))
			stage["xs"]=xs.duplicate(); stage["ys"]=ys.duplicate()
			for y: float in ys:
				for x: float in xs:
					considered+=1; stage["considered"]=int(stage.considered)+1
					var p:=Vector2(x,y)
					if not clear(p) or not bool(segment(p-direction*2,p).get("clear",false)): continue
					var actor_foot: float=float(player.call("get_depth_sort_y"))+container.to_global(p).y-player.global_position.y
					var prop_foot: float=container.to_global(point(object.world_foot_px)).y
					if absf(actor_foot-prop_foot)<=.01: continue
					var relation: String="front" if actor_foot>prop_foot else "behind"
					if stations.has(relation): continue
					var hits: Dictionary=alpha.strong_intersection(sprite,target_prop,container.to_global(p)-player.global_position)
					if relation=="behind" and int(hits.get("hits",0))<=0: continue
					stations[relation]={"point":p,"direction":direction,"current_search_frame":hits}
					(stage.accepted as Array).append({"relation":relation,"point":_scalar_evidence(p),"current_search_frame":hits})
					if stations.size()==2: break
				if stations.size()==2: break
			if stations.size()==2: break
	var trials: Array[Dictionary]=[]
	for relation: String in ["behind","front"]:
		_check(stations.has(relation),"six-roof legal actual-facing station (behind strong, front continuous negative): "+String(object.id)+" "+relation)
		if not stations.has(relation): continue
		var station: Dictionary=stations[relation]; var target: Vector2=station.point; var direction: Vector2=station.direction
		var approach: Dictionary=await move_to(target-direction*2)
		var leg: Dictionary=await driver.drive(field,target,clear) if bool(approach.get("ok",false)) else {"ok":false}
		await driver.completed_actor_stage()
		var hits: Dictionary=alpha.strong_intersection(sprite,target_prop)
		var actor_front: bool=alpha.actual_in_front(player,target_prop)
		var feet_relation: bool=float(player.call("get_depth_sort_y"))>container.to_global(point(object.world_foot_px)).y
		var debug: Dictionary=field.call("get_v14_modular_overlap_debug")
		var assertion_snapshot: Dictionary=_alpha_observation(target_prop)
		var identity: Dictionary=_current_identity()
		var actual_proof: Dictionary=_front_proof(object)
		_check(bool(approach.get("ok",false)) and bool(leg.get("ok",false)),"normal input and actual-facing final leg reach alpha witness: "+String(object.id)+" "+relation)
		_check(raw_clear(player.position) and physical_clear(player.position) and (int(hits.get("hits",0))>0 if relation=="behind" else int(hits.get("hits",-1))==0),"real current-frame strong behind/strict zero front with full17/34x24 and Physics2D: "+String(object.id)+" "+relation)
		_check(not identity.is_empty() and not actual_proof.is_empty() and actual_proof.get("proved")==true,"first assertion exact current identity and independently revalidated ALL240 front proof")
		_check(feet_relation==(relation=="front") and actor_front==feet_relation,"completed normal node stage actual feet/order incl same-band siblings: "+String(object.id)+" "+relation)
		var hit_count: int=int((debug.get("prop_hits",{}) as Dictionary).get(String(object.id),0))
		_check(hit_count>0 if relation=="behind" else hit_count==0,"only genuinely covered behind pixels ghost; continuous front never fades: "+String(object.id)+" "+relation)
		_check(exact_union(debug),"independent current-frame LINEAR union byteexact, not whole-person fade: "+String(object.id)+" "+relation)
		var trial: Dictionary={"relation":relation,"actual_point":_scalar_evidence(player.position),"actual_alpha":hits,"raw":raw_evidence(player.position),"physical_clear":physical_clear(player.position),"actor_front":actor_front,"actor_band":player.z_index,"prop_band":target_prop.z_index,"actor_index":player.get_index(),"prop_index":target_prop.get_index(),"approach":approach,"final_leg":leg,"ghost_target_pixels":hit_count,"union_pixels":debug.get("pixels",0),"first_assertion_snapshot":assertion_snapshot,"actual_identity":identity,"continuous_front_proof":_scalar_evidence(actual_proof)}
		await driver.completed_actor_stage()
		trial["second_natural_stage_snapshot"]=_alpha_observation(target_prop)
		trial["second_natural_stage_alpha"]=alpha.strong_intersection(sprite,target_prop)
		trial["second_natural_stage_raw"]=raw_evidence(player.position)
		trial["second_natural_stage_physical_clear"]=physical_clear(player.position)
		trial["second_stage_is_diagnostic_not_assertion_replacement"]=true
		trials.append(trial)
		await capture.call(String(object.id)+"_"+relation)
	return {"scope":"SIX_FIXED_ROOFS_CONTINUOUS_FRONT_NEGATIVE_PLUS_CURRENT_STRONG_BEHIND","complete":trials.size()==2,"records":trials,"front_proof":_scalar_evidence(initial_proof),"discovery":discovery,"considered":considered,"missing_relation_is_fail":trials.size()!=2,"search_miss_is_never_absence_proof":true}

func run_six_roofs() -> void:
	var player: Node2D = field.get("_player") as Node2D
	var actor: Sprite2D = player.get("sprite") as Sprite2D
	var shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	_check(shape != null and not shape.disabled and shape.shape is RectangleShape2D and shape.shape.size == BODY and shape.position == Vector2.ZERO, "ordinary actor keeps real enabled centered 34x24 Rectangle, never travel circle")
	_check(absf(actor.scale.y - .945 * .91) < .000001 and absf(float(player.call("get_depth_sort_y")) - player.global_position.y) < .01, "normal adult .91 visual scale and grounded foot; no tiny-world identity")
	var source: Image = alpha.image_for(actor)
	var current: Rect2i = alpha.frame(actor, source)
	var top := current.size.y
	var bottom := -1
	for y in current.size.y:
		for x in current.size.x:
			if source.get_pixelv(current.position + Vector2i(x, y)).a > .12:
				top = mini(top, y)
				bottom = maxi(bottom, y)
	# 113.5134 is DOWN reference, not a blanket current-facing height.
	var facing := ""
	for direction: String in IDLE_REFERENCES:
		var path: String = "res://art/characters/weapon_variants/lengguyun/v7_idle_stable/sword/lengguyun_sword_idle_%s_25d_4f.png" % direction
		if actor.texture.resource_path == path: facing = direction
	_check(not facing.is_empty() and String(player.get("_direction")) == facing, "actual idle texture/facing identity matches one precise independently measured adult source")
	if not facing.is_empty():
		var expected: Dictionary = IDLE_REFERENCES[facing]
		_check(FileAccess.get_sha256(actor.texture.resource_path).to_lower() == String(expected.sha256), "actual facing original PNG exact SHA, not mutable self-reference")
		_check(bottom >= top and bottom - top + 1 == int(expected.height), "current idle-frame alpha height equals its exact facing reference (DOWN132/UP131/LR130), never widened tolerance")
		_check(absf((bottom - top + 1) * actor.scale.y - float(expected.height) * .945 * .91) < .0001, "actual current-frame effective alpha height uses actual Sprite scale and precise facing reference")
		_check(absf(float(manifest.ordinary_actor_effective_height_px) - 132 * .945 * .91) < .000001, "manifest adult height is explicitly DOWN132 reference, not all facing equality")
		data["adult_current_frame_height"] = {"facing": facing, "frame": actor.frame, "path": actor.texture.resource_path, "sha256": FileAccess.get_sha256(actor.texture.resource_path), "source_alpha_height_px": bottom - top + 1, "source_reference_height_px": expected.height, "actual_scale": actor.scale.y, "effective_height_px": (bottom - top + 1) * actor.scale.y, "down_reference_px": manifest.ordinary_actor_effective_height_px}
	_runtime_collision_inventory()
	for object: Dictionary in manifest.objects:
		if String(object.id) not in ROOF_PROOF.IDS: continue
		var id: String = String(object.id)
		var sprite: Sprite2D = prop(id)
		_check(sprite != null and sprite.texture.resource_path == String(object.texture), "independent runtime PNG binding: " + id)
		if sprite == null: continue
		_check((sprite.get_rect().size * sprite.scale.abs()).distance_to(point(object.render_size_px)) < .01 and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "actual rendered dimensions/filter: " + id)
		_check(_physical_binding(id), "actual StaticBody geometry exactly matches original world solids: " + id)
		var collision: Dictionary = await _collision_trial(id) if blocking_ids.has(id) else {"blocking": false, "actual_static_body_absent": _physical_binding(id), "scope": "nonblocking; no fictional solid stop"}
		var alpha_record: Dictionary
		if object.get("role","")=="ground_overlay":
			var global_alpha_depth: int = alpha.effective_z(sprite)
			_check(not blocking_ids.has(id) and sprite.z_index==-2 and object.get("ghost_occlusion")==false,"ground-only mud overlay is neither solid nor occluding foreground: "+id)
			alpha_record={"scope":"GROUND_OVERLAY_NEGATIVE_NOT_STRONG_FOREGROUND_CREDIT","effective_z":global_alpha_depth,"ghost_occlusion":false}
		elif object.get("role","")=="water_decoration":
			alpha_record=await _water_decoration_domain_trial(object)
		else: alpha_record=await _alpha_trial(object)
		var record: Dictionary = {"id": id, "blocking": blocking_ids.has(id), "collision": collision, "alpha": alpha_record}
		data.objects.append(record)
	_check(data.objects.size() == 6, "limited six-roof focus complete; full manifest/collision inventory retained, not full-city coverage")
	for npc: Node in (field.get("_actor_layer") as Node).get_children():
		if not npc is NPCNode: continue
		var rows: Array = []
		for tick in 8:
			await driver.completed_actor_stage()
			var foot: float = npc.get_depth_sort_y()
			_check(npc.z_index == clampi(floori(foot / 8), 0, 255), "normally spawned original NPC ordinary foot band: " + String(npc.npc_id))
			rows.append({"foot": foot, "band": npc.z_index, "frame": npc.sprite.frame})
		data.npcs.append({"id": npc.npc_id, "rows": rows})
	_check(data.npcs.size() == (field.get("_npc_nodes") as Array).size(), "all normally spawned current gate-visible NPCs observed; other gated identities tested in normal action phase")

func release() -> void:
	if roof_proof!=null: roof_proof.call("release"); roof_proof=null
	super.release()
