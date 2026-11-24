extends "res://tests/test_luoyang_loading_baseline_ready_20261018r.gd"
## READY ordinary world96/Space Gate32; fixed hall03 successor and sole formal-index bool.
## Preserve obsolete7215 draft; full source expected derives A -> final02 -> hall03, not current collector.
## Reuses the original first-operable-post-draw instrument; POST checks separate.
const T_GATE_READY := true
const T_GATE_CONTRACT := "res://tests/fixtures/luoyang_t_ordinary_world_gate_final_20261019u.json"
const T_GATE_CONTRACT_SHA := "b6aea50592ba2046f07846d666dfd3a7a8309764cf0b7047ae02faf08fdfc114"
const T_GATE_WHOLE_MS := 120000
const T_RAW := preload("res://tests/helpers/luoyang_eleven_rooms_raw_polygon_oracle_v2_20261016g.gd")
var t_gate: Dictionary={}
var t_gate_geometry_bound: bool=false
var t_gate_mask: Image

func precheck() -> bool:
	if not check(T_GATE_READY,"NOTREADY: final C/bundle/manifest/Temple source succession not frozen"): return false
	if not check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0,"Ordinary 1080P Field GUI/native clock; no whole-camera capture"): return false
	if not track(T_GATE_CONTRACT,T_GATE_CONTRACT_SHA): return false
	t_gate=JSON.parse_string(FileAccess.get_file_as_string(T_GATE_CONTRACT))
	var actual_args: PackedStringArray=OS.get_cmdline_user_args()
	if not check(actual_args.size()==t_gate.allowed_args.size(),"Exact final Gate candidate/ordinary argument count"): return false
	for i: int in actual_args.size():
		if not check(actual_args[i]==t_gate.allowed_args[i],"Exact final argument, no unrelated suite flag"): return false
	for path: String in t_gate.core_source_sha256:
		if not track(path,t_gate.core_source_sha256[path]): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false

	var admission: Dictionary=t_gate.authority
	var api: Variant=load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
	var index: Variant=load(admission.index_path)
	if not check(actual_args.is_empty() and index.formal_enabled()==true and LEASE.LIVE_WORLD_FORMAL_ENABLED,"Ordinary no flags; actual bundle and existing live lease formal enabled"): return false
	var before: String=FileAccess.get_file_as_string(admission.false_index_path)
	var after: String=FileAccess.get_file_as_string(admission.index_path)
	if not check(before.count("const FORMAL_ENABLED=false")==1 and before.replace("const FORMAL_ENABLED=false","const FORMAL_ENABLED=true")==after,"Full index bytes differ only one approved bool, never whitespace normalization"): return false
	var entries: Dictionary=index.entries()
	if not check(entries.size()==4,"Original four explicit index entries"): return false
	for id: String in ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]:
		if not check(entries.has(id) and api.requested(StringName(id)),"Ordinary formal requested path "+id): return false
	var a: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(admission.A_result))
	if not check(a.get("passed")==true and a.get("geometry_not_recomputed")==true,"Original actual A source authority reused, not fresh geometry"): return false
	var expected: Dictionary=a.runtime_closures[GATE_ID].duplicate(true)
	for part: Dictionary in [a.runtime_authorities[GATE_ID],a.rows[GATE_ID]]:
		for path: String in part:
			if expected.has(path) and not check(C._equal_value(expected[path],part[path]),"One exact authority value "+path): return false
			expected[path]=part[path]
	var deployment: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(admission.deployment_path))
	if not check(C._equal_value(deployment.targets,admission.targets),"Fixed eight-target migration, not current collector expectation"): return false
	for row: Dictionary in admission.targets:
		var path: String=String(row.target)
		if expected.has(path):
			if not check(expected[path]==row.old_sha256,"Exact old value before explicit successor "+path): return false
			expected[path]=row.new_sha256
	for path: String in admission.added_legacy_source_sha256:
		var sha: String=String(admission.added_legacy_source_sha256[path])
		if not check(not expected.has(path) and a.source_first.get(path)==sha and a.source_final.get(path)==sha,"Only actual-read alias already observed by A "+path): return false
		expected[path]=sha
	var hall_deployment: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(admission.hall_successor.deployment_path))
	if not check(C._equal_value(hall_deployment.targets,admission.hall_successor.targets),"Exact hall03 native/metadata successor tuples"): return false
	for row: Dictionary in admission.hall_successor.targets:
		var path: String=String(row.target)
		if expected.has(path):
			if not check(C._equal_value(expected[path],row.old_sha256),"Exact previous value before hall03 successor "+path): return false
			expected[path]=row.new_sha256
	if not check(not expected.has(String(admission.index_path)) and not expected.has(String(admission.manifest_path)),"Bootstrap index/own manifest remain outside historical source union"): return false
	expected[String(admission.index_path)]=String(admission.index_sha)
	expected[String(admission.manifest_path)]=String(admission.manifest_sha)
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(admission.manifest_path))
	var declared: Dictionary=manifest.legacy_source_sha256.duplicate(true)
	for part: Dictionary in [manifest.runtime_authority_sha256,manifest.artifacts,{String(admission.index_path):String(admission.index_sha),String(admission.manifest_path):String(admission.manifest_sha)}]: declared.merge(part)
	if not check(C._equal_value(expected,declared),"Complete fixed expected Gate set, no old625/count-only/current-autoaccept"): return false
	t_gate.complete_source_sha256=expected
	package=R.binding();author=R.author(package)
	return check(not package.is_empty() and not author.is_empty() and t_gate.whole_ms==T_GATE_WHOLE_MS and t_gate.arrival_ms==60000,"Frozen current dependency and120/60 budget, not old s manifest admission")

func _post_gate(warm: bool) -> bool:
	if not check(not warm and first_draw.trusted_scene_same and first_draw.trusted_id==GATE_ID and first_draw.trusted_sources_finalized and first_draw.trusted_token>0,"First draw itself is current same-owner finalized, no warm or post-hoc backfill"): return false
	var started: int=Time.get_ticks_usec()
	var proof: Dictionary=C.resident_receipt(scene)
	if not check(proof.get("sources_finalized",false) and proof.get("proof_kind")==t_gate.proof_kind and proof.token==first_draw.trusted_token and C._equal_value(proof.get("sources",{}),t_gate.complete_source_sha256),"Full independently frozen t Gate authority, not old625/658/current-autoaccept"): return false
	var collector: Dictionary=C._transition_sources(proof.source_scene,false)
	if not check(collector.size()==proof.sources.size(),"Whole current collector exact set"): return false
	for path: String in collector:
		if not check(proof.sources.has(path),"Exact actual collector leaf "+path) or not track(path,proof.sources[path]): return false
	baseline_sources=proof.sources.duplicate(true)
	records.append({"kind":"T_GATE_POSTVERIFY_NOT_LOADING_TIME","first_draw":first_draw.duplicate(true),"postverify_usec":Time.get_ticks_usec()-started,"complete_source_map":baseline_sources,"proof_kind":proof.proof_kind})
	return true

func _segment(a: Vector2,b: Vector2) -> Dictionary:
	if not t_gate_geometry_bound: return super._segment(a,b)
	var result: Dictionary=oracle.segment(a,b,deadline)
	if not result.get("clear",false): return result
	var n: int=maxi(1,ceili(a.distance_to(b)/4.0))
	for i: int in range(n+1):
		if not _t_gate_mask_clear(a.lerp(b,float(i)/n)): return {"clear":false,"sample":i,"mask_reject":true}
	return result

func _t_gate_mask_clear(foot: Vector2) -> bool:
	if t_gate_mask==null: return false
	var base: Vector2i=Vector2i(foot.round())
	for y: int in range(-12,13):
		for x: int in range(-17,18):
			var p: Vector2i=base+Vector2i(x,y)
			if p.x<0 or p.y<0 or p.x>=t_gate_mask.get_width() or p.y>=t_gate_mask.get_height() or t_gate_mask.get_pixelv(p)!=Color.WHITE: return false
	return true

func _clear(foot: Vector2) -> bool:
	return super._clear(foot) and (not t_gate_geometry_bound or _t_gate_mask_clear(foot))

func _exercise() -> bool:
	var router: Node=root.get_node("SceneRouter")
	# This near-world setup is NOT default-world first parse performance credit.
	var definition: SceneScript=ResourceLoader.load("res://data/scenes/world_map_jianghu.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var entries: Array=[]
	for item: Dictionary in definition.map_layout.portals:
		if item.get("target_scene")==GATE_ID: entries.append(item)
	if not check(entries.size()==1,"Original unique actual world Gate portal"): return false
	var entry: Vector2=entries[0].pos*Vector2(12288,8192)
	_arm_draw(WORLD_ID,"T_LEGAL_WORLD_NEAR_SETUP_NOT_DEFAULT_WORLD_PERFORMANCE")
	if not check(router.call("go_field_smart",StringName(WORLD_ID),(entry+Vector2(0,96))/Vector2(12288,8192),"",15),"Public legal world setup") or not await _wait_once(WORLD_ID) or not _world_bind(): return false
	if not await _walk(PackedVector2Array([field.get("_player").position,entry])) or not _zone(GATE_ID) or not await _space_to(GATE_ID,"T_REAL_WORLD96_SPACE_GATE"): return false
	district="gate";scene_id=GATE_ID
	var g: Dictionary=t_gate.gate_geometry
	oracle=T_RAW.new();t_gate_mask=Image.load_from_file(g.mask_path)
	if not check(scene.resource_path==t_gate.scene_path and scene.map_layout.resource_path==t_gate.layout_path and scene.actor_positions_are_feet and field.get("_player").position==Vector2(1536,1860) and oracle.configure(g.floor_regions_px,g.solids,Vector2(3072,2048),Vector2(3072,2048),g.foot_forbidden_regions_px) and t_gate_mask!=null,"Actual intended Gate, original return/native-independent geometry"): return false
	var shape: CollisionShape2D=field.get("_player").get_node("CollisionShape2D") as CollisionShape2D
	if not check(shape.position==Vector2.ZERO and shape.shape is RectangleShape2D and shape.shape.size==Vector2(34,24),"Original native Player34x24 and zero child offset"): return false
	t_gate_geometry_bound=true
	if not check(_clear(Vector2(1536,1860)),"Actual initial native Player34x24/full87517") or not await _walk(PackedVector2Array([Vector2(1536,1860),Vector2(1568,1860)])): return false
	return await _capture("t_real_world_Space_Gate_ordinary32px")

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+T_GATE_WHOLE_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_t_ordinary_gate_entry_20261019u/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool=false
	if precheck():
		driver=INPUT.new();driver.configure(self);RenderingServer.frame_post_draw.connect(_r_draw)
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		complete=await _exercise()
	draw_target=""
	if RenderingServer.frame_post_draw.is_connected(_r_draw): RenderingServer.frame_post_draw.disconnect(_r_draw)
	if driver!=null: driver.release();driver=null
	# End at Gate: actual own tree exit, NOT a world/District released alias.
	var weak: WeakRef=null
	if is_instance_valid(current_scene):
		var own: Node=current_scene;weak=weakref(own);current_scene=null;own.queue_free();field=null;scene=null;own=null
	root.get_node("SceneRouter").call("reset_for_new_game")
	await process_frame;await process_frame
	if not check(weak==null or weak.get_ref()==null,"Own actual Gate Field tree exited"): complete=false
	oracle=null;t_gate_mask=null;frame_images.clear()
	records.append({"kind":"T_GATE_ONLY_SCOPE","whole_ms":T_GATE_WHOLE_MS,"arrival_ms":60000,"captures":captures,"native_queries":native_queries,"no_world_return_warm_othercity_or_room_suite":true})
	finish(folder,began,complete,"T_ORDINARY_TRUE_INDEX_WORLD_SPACE_GATE_ONLY_120S")
