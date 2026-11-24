extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## READY hall-return-only successor: A -> final02 -> native/metadata03. Prior75656 FAIL retained.
## Preserve 3AFA/113456 production fail; only early same-target Field failure observation added.
## Expected complete maps come from exact A result + generated registry; never current collector.
## No runtime-derived hash admission, private teleport, or production safe_foot.
const REPRESENTATIVES_READY := true
const PLAN_PATH := "res://tests/fixtures/luoyang_t_yamen_hall_return_retry1_20261019u.json"
const PLAN_SHA := "c3b0c0273d86e8db3b0387f84dc37846d307e8953d97f815b1564c2a819a9007"
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
	if not check(atom=="yamen","Fixed representative scope") or not track(PLAN_PATH,PLAN_SHA): return false
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
	# Producer authority is frozen by exact bytes above; decode expected maps only.
	var a: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(plan.authority.A_result))
	var registry: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(plan.authority.registry))
	var city_id: String=String(plan.atoms.yamen.city_id)
	var room_id: String=String(plan.atoms.yamen.room_id)
	if not check(a.get("passed")==true and a.get("geometry_not_recomputed")==true,"Actual A complete publication, no fresh geometry credit"): return false
	var expected: Dictionary=a.runtime_closures[city_id].duplicate(true)
	for addition: Dictionary in [a.runtime_authorities[city_id],a.rows[city_id]]:
		for path: String in addition:
			if expected.has(path) and not check(C._equal_value(expected[path],addition[path]),"No conflicting expected authority "+path): return false
			expected[path]=addition[path]
	var declared: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(plan.successor.deployment_path))
	if not check(C._equal_value(declared.targets,plan.successor.targets),"Exact independent eight-target deployment authority"): return false
	for delta: Dictionary in plan.successor.targets:
		var path: String=String(delta.target)
		if expected.has(path):
			if not check(expected[path]==delta.old_sha256 or expected[path]==delta.new_sha256,"Only explicit source old/new "+path): return false
			expected[path]=delta.new_sha256
	for path: String in plan.successor.added_legacy_source_sha256:
		var sha: String=String(plan.successor.added_legacy_source_sha256[path])
		if not check(not expected.has(path) and a.source_first.get(path)==sha and a.source_final.get(path)==sha,"Only new actual-read alias already observed in A "+path): return false
		expected[path]=sha
	var hall_delta: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(plan.hall_successor.deployment_path))
	if not check(C._equal_value(hall_delta.targets,plan.hall_successor.targets),"Exact second eight-target native/metadata authority"): return false
	var native_repair: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(plan.hall_successor.native_report_path))
	if not check(native_repair.get("passed")==true and native_repair.get("checks")==20 and native_repair.output.get("geometry_recomputed")==false and native_repair.output.get("scene_bytes_unchanged")==true,"Actual native-only two-field repair proof, not new geometry"): return false
	for delta: Dictionary in plan.hall_successor.targets:
		var path: String=String(delta.target)
		if expected.has(path):
			if not check(C._equal_value(expected[path],delta.old_sha256),"Second successor exact prior value "+path): return false
			expected[path]=delta.new_sha256
	# Bootstrap authority is appended only after both strict historical migrations.
	for path: String in [String(plan.authority.index),String(plan.authority.manifest)]:
		if not check(not expected.has(path),"No self-referential bootstrap leaf "+path): return false
	expected[String(plan.authority.index)]=String(plan.authority.index_sha)
	expected[String(plan.authority.manifest)]=String(plan.authority.manifest_sha)
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(plan.authority.manifest))
	var old_manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(plan.successor.prior_city_manifest_path))
	for key: String in ["artifacts","geometry_proof_basis","parent_publication","publication_source_first","publication_source_final","mask_sha","layout_proof"]:
		if not check(C._equal_value(manifest.get(key),old_manifest.get(key)),"All original proof/artifact field unchanged "+key): return false
	var declared_full: Dictionary=manifest.legacy_source_sha256.duplicate(true)
	for part: Dictionary in [manifest.runtime_authority_sha256,manifest.artifacts,{String(plan.authority.index):String(plan.authority.index_sha),String(plan.authority.manifest):String(plan.authority.manifest_sha)}]: declared_full.merge(part)
	if not check(C._equal_value(declared_full,expected),"Complete A map plus only explicit successor, never current collector backfill"): return false
	plan.identities[city_id].source_sha256=expected
	var row: Dictionary=registry.rooms[room_id]
	if not check(row.scene_path==plan.identities[room_id].scene_path and row.layout_path==plan.identities[room_id].layout_path,"Frozen generated room identity"): return false
	var original_registry: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(plan.successor.prior_registry_path))
	var expected_room: Dictionary=original_registry.rooms[room_id].source_sha256.duplicate(true)
	var changed_path: String=String(plan.successor.changed_room_source_path)
	if not check(expected_room.get(changed_path)==plan.successor.changed_room_source_old,"Original room exact prior District pin"): return false
	expected_room[changed_path]=plan.successor.changed_room_source_new
	for delta: Dictionary in plan.hall_successor.targets:
		if delta.get("binary",false)==true:
			var path: String=String(delta.target)
			if not check(C._equal_value(expected_room.get(path),delta.old_sha256),"Hall source exact original native value "+path): return false
			expected_room[path]=delta.new_sha256
	if not check(C._equal_value(row.source_sha256,expected_room),"Room complete source map changes only District and exact hall native pair"): return false
	plan.identities[room_id].source_sha256=expected_room
	selected=plan.atoms[atom]
	return check(not selected.is_empty(),"Final authored Yamen and official hall identities")

func _draw() -> void:
	if target.is_empty() or not first_draw.is_empty() or not is_instance_valid(current_scene): return
	var s: SceneScript=current_scene.get("_current_scene") as SceneScript
	var p: CharacterBody2D=current_scene.get("_player") as CharacterBody2D
	if s==null or String(s.scene_id)!=target or p==null or not p.can_process() or p.get("can_move")!=true: return
	var state: Dictionary=current_scene.call("get_field_loading_state")
	var screen: Node=root.get_node("LoadingManager").get("_screen")
	var panel: Control=screen.get("root") as Control if is_instance_valid(screen) else null
	if not state.get("complete",false) or state.get("failed",false) or (panel!=null and panel.is_visible_in_tree()): return
	# Cheap scalars only on first draw; full receipt and all disk hashes remain post-freeze.
	if target==String(plan.atoms.yamen.city_id) and (C._resident_ready.get("scene")!=s or C._resident_ready.get("sources_finalized")!=true): return
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
				return check(false,"Matching actual Field failed before first operable draw",{"target":id,"Field_id":current_scene.get_instance_id(),"field_loading":field_state,"public":public})
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
			if not check(receipt.scene.get_ref()==scene and receipt.layout.get_ref()==scene.map_layout,"Actual finalized room session owns same native Scene/layout"): return false
			var actual_row: Dictionary=M.catalogue().get("rooms",{}).get(id,{})
			actual=actual_row.get("source_sha256",{})
		"TEMPLE":
			receipt=field.call("get_temple_assembly_state")
			if not check(receipt.get("scope")=="TEMPLE_OWN_FIELD_NOT_C_CITY_RECEIPT" and receipt.get("finalized",false) and not receipt.get("worker_active",true) and receipt.get("source_first")==receipt.get("source_final"),"Temple owns its complete first/final; no borrowed C proof"): return false
			actual=receipt.source_first
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

func _room_trip() -> bool:
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

func _exercise() -> bool:
	_arm(selected.city_id)
	if not check(root.get_node("SceneRouter").call("go_field_smart",StringName(selected.city_id),_v(selected.setup_uv),"",-1,C.VERSION),"Legal public near setup; explicitly not intercity travel") or not await _arrive(selected.city_id): return false
	if not await _capture(atom+"_layout_ordinary_camera"): return false
	return await _room_trip()

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
	output="res://build/luoyang_t_yamen_hall_return_retry1_20261019u/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(output)
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
	finish(output,began,complete,"T_YAMEN_OFFICIAL_HALL_CANDIDATE_ACTUAL_FIELD_90S")
