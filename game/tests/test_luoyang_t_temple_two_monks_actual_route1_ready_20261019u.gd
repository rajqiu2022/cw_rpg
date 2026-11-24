extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## READY Temple-only actual Field/NPC/ordinary-exit observations, no city bundle authority.
## Frozen independent source expansion from Temple parent/successor/task binding, not C receipt.
## No runtime-derived hash admission, private teleport, or production safe_foot.
const REPRESENTATIVES_READY := true
const PLAN_PATH := "res://tests/fixtures/luoyang_t_temple_two_monks_actual_route1_20261019u.json"
const PLAN_SHA := "f2b7aa51b64bdac6d02485c7101b680ebe138f5d88b51471419d545b599c7ebb"
const WHOLE_MS := 90000
const ARRIVAL_MS := 60000
const RETURN_MS := 2000
const INPUT := preload("res://tests/helpers/v15_input_driver.gd")
const RAW := preload("res://tests/helpers/luoyang_eleven_rooms_raw_polygon_oracle_v2_20261016g.gd")
const C := preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const M := preload("res://scripts/city/luoyang_assembled_interiors_20261016g.gd")
const CITY_TASK := preload("res://scripts/city/luoyang_city_tasks_20261016.gd")
var atom: String = ""
var plan: Dictionary = {}
var selected: Dictionary = {}
var field: Node
var scene: SceneScript
var driver: RefCounted
var independent: RefCounted
var mask: Image
var output: String
var captures: Array[Dictionary] = []
var native_queries: int = 0
var target: String = ""
var triggered_usec: int = 0
var first_draw: Dictionary = {}

func _v(value: Variant) -> Vector2:
	return value if value is Vector2 else Vector2(value[0],value[1])

func precheck() -> bool:
	if not check(REPRESENTATIVES_READY,"NOTREADY: final complete source maps/authority/native routes not frozen"): return false
	if not check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0,"Actual GUI and native clock"): return false
	# Exactly one fixed atom; any eventual candidate flag must be explicitly
	# listed by the final contract, never accepted by prefix or current file hash.
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--t-atom="):
			if not check(atom.is_empty(),"Exactly one t atom"): return false
			atom=arg.trim_prefix("--t-atom=")
	if not check(atom=="temple","Fixed representative scope") or not track(PLAN_PATH,PLAN_SHA): return false
	plan=JSON.parse_string(FileAccess.get_file_as_string(PLAN_PATH))
	if not check(plan.get("ready")==true and plan.get("whole_ms")==WHOLE_MS and plan.get("arrival_ms")==ARRIVAL_MS and plan.get("return_ms")==RETURN_MS,"Frozen budgets and actual-source contract"): return false
	var actual_args: Array[String]=[]
	for arg: String in OS.get_cmdline_user_args(): actual_args.append(arg)
	var expected_args: Array=plan.allowed_args.duplicate();expected_args.append("--t-atom="+atom)
	actual_args.sort();expected_args.sort()
	if not check(actual_args.size()==expected_args.size(),"Exact final flag count"): return false
	for i: int in actual_args.size():
		if not check(actual_args[i]==expected_args[i],"Exact final flag value, no other candidate suite"): return false
	for path: String in plan.source_sha256:
		if not track(path,plan.source_sha256[path]): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	selected=plan.atoms[atom]
	return check(not selected.is_empty(),"Final authored representative routes and identities")

func _draw() -> void:
	if target.is_empty() or not first_draw.is_empty() or not is_instance_valid(current_scene): return
	var s: SceneScript=current_scene.get("_current_scene") as SceneScript
	var p: CharacterBody2D=current_scene.get("_player") as CharacterBody2D
	if s==null or String(s.scene_id)!=target or p==null or not p.can_process() or p.get("can_move")!=true: return
	var state: Dictionary=current_scene.call("get_field_loading_state")
	var screen: Node=root.get_node("LoadingManager").get("_screen")
	var panel: Control=screen.get("root") as Control if is_instance_valid(screen) else null
	if not state.get("complete",false) or state.get("failed",false) or (panel!=null and panel.is_visible_in_tree()): return
	# First operable post-draw timestamp is frozen BEFORE receipt/deep copy/SHA.
	var now: int=Time.get_ticks_usec()
	first_draw={"target":target,"trigger_usec":triggered_usec,"first_draw_usec":now,"elapsed_usec":now-triggered_usec,"frame":Engine.get_process_frames(),"Field_id":current_scene.get_instance_id(),"Scene_id":s.get_instance_id(),"Player_id":p.get_instance_id(),"foot":p.position,"Loading_hidden":true,"can_move":true}

func _arm(id: String) -> void:
	target=id;triggered_usec=Time.get_ticks_usec();first_draw={}

func _arrive(id: String,limit_ms: int=ARRIVAL_MS) -> bool:
	var until: int=mini(deadline,int(triggered_usec/1000)+limit_ms)
	while Time.get_ticks_msec()<until:
		var public: Dictionary=root.get_node("SceneRouter").call("get_public_city_preparation_state")
		if public.get("scene_id")==id and public.get("phase")=="FAILED": return check(false,"Matching public request failed",public)
		if is_instance_valid(current_scene) and current_scene.has_method("get_field_loading_state"):
			var field_state: Dictionary=current_scene.call("get_field_loading_state")
			if field_state.get("scene_id")==id and field_state.get("failed")==true:
				return check(false,"Matching actual Temple Field failed before first draw",field_state)
		if not first_draw.is_empty():
			field=current_scene;scene=field.get("_current_scene") as SceneScript;target=""
			records.append({"kind":"FIRST_OPERABLE_DRAW_BEFORE_POSTVERIFY","measurement":first_draw.duplicate(true)})
			return _post_owner(id) and _bind_independent(id)
		await process_frame
	target=""
	return check(false,"Original arrival/return deadline includes hidden+operable first draw",{"target":id,"first_draw":first_draw,"public":root.get_node("SceneRouter").call("get_public_city_preparation_state"),"lease":root.get_node("SceneRouter").call("get_resident_city_state")})

func _post_owner(id: String) -> bool:
	var spec: Dictionary=plan.identities[id]
	if not check(scene.resource_path==spec.scene_path and scene.map_layout.resource_path==spec.layout_path and scene.actor_positions_are_feet,"Actual intended successor Scene/layout/feet, not old revision same ID"): return false
	var actual: Dictionary={};var receipt: Dictionary={}
	match String(spec.owner_kind):
		"CITY":
			receipt=C.resident_receipt(scene)
			if not check(receipt.get("sources_finalized",false) and receipt.get("proof_kind")==spec.proof_kind,"Actual city same-token complete source owner"): return false
			actual=receipt.sources
			var collector: Dictionary=C._transition_sources(receipt.source_scene,false)
			if not check(collector.size()==actual.size(),"Whole city collector, not fixed known subset"): return false
			for path: String in collector:
				if not check(actual.has(path),"Actual collector leaf exists "+path): return false
		"ROOM":
			# Read actual Field-established session. Do NOT finalize it from QA.
			var live_api: Variant=M # Candidate static session API; not old g's different field.
			receipt=live_api._sessions.get(scene.get_instance_id(),{})
			if not check(receipt.get("finalized",false) and M.is_room(scene),"Actual room setup finalized independently of QA"): return false
			actual=spec.source_sha256
		"TEMPLE":
			receipt=field.call("get_temple_assembly_state")
			if not check(receipt.get("scope")=="TEMPLE_OWN_FIELD_NOT_C_CITY_RECEIPT" and receipt.get("scene_instance")==scene.get_instance_id() and receipt.get("finalized",false) and not receipt.get("worker_active",true) and C._equal_value(receipt.get("source_first"),receipt.get("source_final")),"Temple owns its complete first/final; no borrowed C proof"): return false
			actual=receipt.source_first
			var temple_api: Variant=load("res://scripts/city/luoyang_temple_assembly_20261016.gd")
			var paths: Dictionary=temple_api.source_paths()
			if not check(paths.size()==actual.size(),"Whole Temple own source collector, not known subset"): return false
			for path: String in paths:
				if not check(actual.has(path),"Temple own actual source leaf "+path): return false
		_: return check(false,"Unknown source owner kind")
	if not check(C._equal_value(actual,spec.source_sha256),"Exact independently frozen complete per-Scene source map"): return false
	for path: String in actual:
		if not track(path,actual[path]): return false
	records.append({"kind":"POSTVERIFY_SOURCE_OWNER","id":id,"sources":actual.duplicate(true),"postverify_after_first_draw":true})
	return true

func _bind_independent(id: String) -> bool:
	var g: Dictionary=plan.geometry[id]
	independent=RAW.new();mask=null
	if not check(_v(field.get("_world_size"))==_v(g.world_size_px) and independent.configure(g.floor_regions_px,g.solids,_v(g.source_size_px),_v(g.world_size_px),g.foot_forbidden_regions_px),"Independent full raw geometry, no production safe_foot"): return false
	if not String(g.mask_path).is_empty():
		mask=Image.load_from_file(g.mask_path)
		if not check(mask!=null and mask.get_size()==Vector2i(_v(g.world_size_px)),"Actual source-bound full city mask"): return false
	return _clear(field.get("_player").position)

func _mask_clear(foot: Vector2) -> bool:
	if mask==null: return true
	var origin: Vector2i=Vector2i(foot.round())
	for y: int in range(-12,13):
		for x: int in range(-17,18):
			var p: Vector2i=origin+Vector2i(x,y)
			if p.x<0 or p.y<0 or p.x>=mask.get_width() or p.y>=mask.get_height() or mask.get_pixelv(p)!=Color.WHITE: return false
	return true

func _clear(foot: Vector2) -> bool:
	if Time.get_ticks_msec()>=deadline or not is_instance_valid(field) or field!=current_scene or independent==null or not independent.clear(foot) or not _mask_clear(foot): return false
	var player: CharacterBody2D=field.get("_player") as CharacterBody2D
	var shape: CollisionShape2D=player.get_node("CollisionShape2D") as CollisionShape2D
	if not check(shape.position==Vector2.ZERO and shape.shape is RectangleShape2D and shape.shape.size==Vector2(34,24),"Original native Player34x24 / child0"): return false
	var world: Node2D=field.get("world_container") as Node2D
	var query:=PhysicsShapeQueryParameters2D.new();query.shape=shape.shape;query.transform=shape.global_transform
	query.transform.origin+=world.to_global(foot)-player.global_position;query.exclude=[player.get_rid()];query.collision_mask=1;query.collide_with_areas=false
	native_queries+=1
	return player.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()

func _segment(a: Vector2,b: Vector2) -> Dictionary:
	var n: int=maxi(1,ceili(a.distance_to(b)/4.0))
	for i: int in range(n+1):
		var p: Vector2=a.lerp(b,float(i)/n)
		if not independent.clear(p) or not _mask_clear(p): return {"clear":false,"sample":i,"foot":p,"oracle":independent.last}
	return {"clear":true,"samples":n+1,"max_step_world_px":4,"full87517_and_continuous34x24":true}

func _walk(raw: Array,label: String) -> bool:
	var points:=PackedVector2Array()
	for p: Variant in raw: points.append(_v(p))
	var result: Dictionary=await driver.follow(field,points,_clear,_segment)
	records.append({"kind":"NORMAL_INPUT","label":label,"result":result})
	return check(result.get("ok")==true,"Normal INPUT, no actor teleport "+label,result)

func _space(id: String,limit_ms: int=ARRIVAL_MS) -> bool:
	_arm(id);await driver.key(KEY_SPACE)
	return await _arrive(id,limit_ms)

func _zone(target_id: String,native_foot: Vector2) -> bool:
	await driver.completed_actor_stage()
	var found: Array[Area2D]=[]
	for node: Node in field.get("_exit_nodes"):
		if node is Area2D and String(node.get("target_scene_id"))==target_id and node.position==native_foot: found.append(node)
	return check(found.size()==1 and found[0].overlaps_body(field.get("_player")) and found[0].get("_in_range")==true,"Actual exact-target native Area overlap before Space")

func _capture(label: String) -> bool:
	await RenderingServer.frame_post_draw
	var path: String=output.path_join(label+".png");var image: Image=root.get_texture().get_image()
	if not check(image!=null and image.save_png(path)==OK,"Actual ordinary camera image "+label): return false
	captures.append({"label":label,"path":path,"sha256":FileAccess.get_sha256(path)});return true

func _unused_room_trip_from_preserved_template() -> bool:
	if not await _walk(selected.street_to_door_world,"new street and actual door") or not await _zone(selected.room_id,_v(selected.native_door_world)): return false
	var exterior: WeakRef=weakref(field);var original_player: WeakRef=weakref(field.get("_player"));var original_scene: WeakRef=weakref(scene)
	var remembered: Vector2=(field.get("_player").position/_v(field.get("_world_size")))*_v(field.get("_world_size"))
	if not await _space(selected.room_id): return false
	# Exact representative fixture IDs/textures/bench orientation/name are final
	# contract rows, not a whole 59-prop or 12-room rescan.
	for row: Dictionary in selected.room_props:
		var matches: Array[Sprite2D]=[]
		for layer_name: String in ["_visual_layer","_actor_layer"]:
			var layer: Node=field.get(layer_name)
			var found: Sprite2D=layer.get_node_or_null("SceneObject_"+String(row.id)) as Sprite2D
			if found!=null: matches.append(found)
		if not check(matches.size()==1,"One native sort-layer component "+String(row.id)): return false
		var node: Sprite2D=matches[0]
		if not check(node.texture.resource_path==row.texture and node.rotation==float(row.rotation) and node.self_modulate.a==1.0,"Representative actual independent component "+String(row.id)): return false
	if not check(scene.display_name==selected.room_display_name,"Actual room label is the approved name") or not await _capture(atom+"_room"): return false
	if not await _walk(selected.room_to_exit_world,"representative room exit") or not await _zone(selected.city_id,_v(selected.native_room_exit_world)): return false
	if not await _space(selected.city_id,RETURN_MS): return false
	return check(int(first_draw.elapsed_usec)<RETURN_MS*1000 and field==exterior.get_ref() and field.get("_player")==original_player.get_ref() and scene==original_scene.get_ref() and field.get("_player").position==remembered and _clear(remembered),"Same live Field/Player/Scene exact remembered feet, hidden+operable <2000ms")

func _temple() -> bool:
	# Final two-entity, ordinary interaction observations; no QA direct-play gate.
	for row: Dictionary in selected.monks:
		var found: Array[Node2D]=[]
		for npc: Node2D in field.get("_npc_nodes"):
			if npc.get("npc_id")==row.id: found.append(npc)
		if not check(found.size()==1 and found[0].is_visible_in_tree() and found[0].position==_v(row.world_foot) and found[0].get("sprite_path")==row.sprite and found[0].get("portrait_path")==row.sprite and not found[0].get("_calibrate_adult_body"),"Actual persistent correct-identity monk, not ambient/calibrated duplicate"): return false
		for frame: int in 4:
			await driver.completed_actor_stage()
			var npc: Node2D=found[0]
			var sprite: Sprite2D=npc.get("sprite") as Sprite2D
			var image: Image=sprite.texture.get_image()
			if image.is_compressed() and image.decompress()!=OK: return check(false,"Actual monk texture cannot be decoded")
			var bounds: Rect2i=image.get_used_rect()
			var local_foot: Vector2=sprite.get_rect().position+Vector2(float(bounds.position.x+bounds.size.x*.5),float(bounds.end.y-1))
			var world: Node2D=field.get("world_container") as Node2D
			var alpha_foot: Vector2=world.to_local(sprite.to_global(local_foot))
			var body: StaticBody2D=npc.get("_body_collider") as StaticBody2D
			var shape: CollisionShape2D=body.get_child(0) as CollisionShape2D
			if not check(sprite.hframes==1 and sprite.texture.get_size()==Vector2(160,160) and bounds==Rect2i(52,6,58,148) and absf(alpha_foot.y-npc.position.y)<=12.0 and shape.shape is RectangleShape2D and shape.shape.size==_v(row.native_body_size) and shape.position==_v(row.native_body_offset) and body.position+shape.position==Vector2.ZERO,"Four natural frames actual one-frame monk/alpha foot <=12/native original body"): return false
			records.append({"kind":"MONK_SAME_FRAME","id":row.id,"frame":frame,"alpha_foot":alpha_foot,"npc_foot":npc.position,"native_size":shape.shape.size,"native_offset":shape.position,"sprite_scale":sprite.scale,"native_hframes":sprite.hframes})
		if not await _walk(row.approach_world,"monk "+String(row.id)): return false
		var before: Dictionary=_task_value();await driver.key(KEY_SPACE)
		var dp: Node=root.get_node("DialogPlayer")
		if not check(dp.call("is_playing") and dp.get("_pending_side_offer_id")==StringName(row.quest_id) and String(dp.get("_current_script").dialog_id)==row.offer_dialog,"Real NPC Space resolves actual authorized canonical offer"): return false
		# One representative accept; second monk rejects, no three-chain rerun.
		dp.call("choose",0 if row.accept else 1) # Actual NPC Space/authorized offer; choice enters real DP/QM, not QA play authorization.
		for step: int in 12:
			if not dp.call("is_playing"): break
			if not check(Time.get_ticks_msec()<deadline and dp.get("_pending_side_offer_id")==&"","Bounded normal dialog advance"): return false
			await driver.key(KEY_SPACE)
		if not check(not dp.call("is_playing") and C._equal_value(_task_value(),before) and root.get_node("QuestManager").call("get_status",StringName(row.quest_id))==(1 if row.accept else 0),"Actual accept/reject does not grant rewards or immediately complete"): return false
	# Final plan supplies native Area AABBs derived independently from authored
	# ordinary shapes. Both target/target_pos/type and non-overlap must hold.
	var boxes: Array[Rect2]=[]
	for portal: Dictionary in selected.exits:
		if not await _walk(portal.approach_world,"separated ordinary exit") or not await _zone(portal.target,_v(portal.native_world_foot)): return false
		var zone: Area2D=null
		for node: Area2D in field.get("_exit_nodes"):
			if String(node.get("target_scene_id"))==portal.target: zone=node
		if not check(zone!=null and zone.get_script().resource_path==portal.script and zone.get("target_spawn_pos")==_v(portal.target_pos),"Ordinary original-target exit, not outskirts source-spawn override"): return false
		var shape: CollisionShape2D=zone.get_node("CollisionShape2D") as CollisionShape2D
		if not check(not shape.disabled and shape.shape is RectangleShape2D and shape.shape.size==_v(portal.native_size),"Exact actual ordinary portal dimensions"): return false
		boxes.append(Rect2(zone.position-shape.shape.size*.5,shape.shape.size))
	if not check(boxes.size()==2 and not boxes[0].intersects(boxes[1],true),"Two actual ordinary portal shapes do not overlap"): return false
	return await _capture("temple_two_monks_and_separated_exits")

func _task_value() -> Dictionary:
	var gs: Node=root.get_node("GameState")
	return {"gold":gs.get("gold"),"exp":gs.get("player").exp,"training":gs.get("training_points_total"),"inventory":root.get_node("Inventory").call("to_dict").duplicate(true)}

func _exercise() -> bool:
	_arm(selected.city_id)
	if not check(root.get_node("SceneRouter").call("go_field_smart",StringName(selected.city_id),_v(selected.setup_uv),"",-1,C.VERSION),"Legal public near setup; explicitly not intercity travel") or not await _arrive(selected.city_id): return false
	return await _temple()

func _cleanup() -> bool:
	# Applicable to city/room/Temple itself; no assertion that a world or Temple
	# owns a District lease. Never rerun completed travel solely for cleanup.
	if driver!=null: driver.release();driver=null
	var weak: WeakRef=null
	if is_instance_valid(current_scene):
		var own: Node=current_scene;weak=weakref(own);current_scene=null;own.queue_free();field=null;scene=null;own=null
	root.get_node("SceneRouter").call("reset_for_new_game")
	await process_frame;await process_frame
	independent=null;mask=null
	return check(weak==null or weak.get_ref()==null,"Own actual Field tree exits; owner-kind-specific source cleanup recorded separately")

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+WHOLE_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	output="res://build/luoyang_t_temple_two_monks_actual_20261019u/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(output)
	var complete: bool=false
	if precheck():
		driver=INPUT.new();driver.configure(self);RenderingServer.frame_post_draw.connect(_draw)
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		root.get_node("GameState").set("current_chapter",4)
		complete=await _exercise()
	target=""
	if RenderingServer.frame_post_draw.is_connected(_draw): RenderingServer.frame_post_draw.disconnect(_draw)
	if not await _cleanup(): complete=false
	records.append({"kind":"FINITE_REPRESENTATIVE_SCOPE","atom":atom,"whole_ms":WHOLE_MS,"arrival_ms":ARRIVAL_MS,"return_ms":RETURN_MS,"captures":captures,"native_queries":native_queries,"no_full_city_12room_geometry_or_controlled_quest_chain_rerun":true})
	finish(output,began,complete,"T_TEMPLE_TWO_ACTUAL_MONKS_TWO_ORDINARY_AREAS_ACCEPT_REJECT_NO_REWARD_90S")
