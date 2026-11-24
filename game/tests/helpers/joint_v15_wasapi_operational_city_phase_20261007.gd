extends "res://tests/helpers/joint_v15_v9c_city_authored_transition_phase.gd"
## QA-only mechanical observer substitution. All original city portal gameplay,
## navigation, normal input, return predicates, thresholds and records retained.
## Immutable v8 parent and current v9c lifecycle chain remain unchanged.
const OPERATIONAL_BGM = preload("res://tests/helpers/joint_v15_wasapi_operational_bgm_continuity_20261007.gd")
const OPERATIONAL_BGM_SHA: String = "bf7d6c9265b19def36b6b1e4da326694b1c84e75a9eeeb23721128173e5322ca"

func run(owner: SceneTree,before_cutover: bool) -> Dictionary:
	if not FileAccess.get_sha256(SNAPSHOT_ORIGIN_PATH).to_lower()==SNAPSHOT_ORIGIN_SHA:
		return {"scope":"JOINT_CITY_ACTUAL_NORMAL_FIELD_GAMEPLAY_NOT_JOINT_FULL","checks":1,"failures":1,"source_complete":false,"ordinary_Field_executed":false,"normal_gameplay":false,"dry_run":false,"reason":"frozen city gameplay parent bytes changed"}
	tree=owner
	candidate=before_cutover
	before_files=_normal_files()
	before_slot=tree.root.get_node("SaveManager").get("active_slot")
	output="res://build/joint_world_luoyang_20261003_qa/city_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(output)==OK,"new city evidence directory")
	_check(candidate==("--luoyang-v3-candidate" in OS.get_cmdline_user_args()),"candidate city requires explicit candidate flag; canonical run forbids clone flag")
	driver=INPUT.new()
	driver.call("configure",tree)
	for id: String in IDS:
		var path: String=ART_ROOT+id+"/art_contract.json"
		var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		_check(parsed is Dictionary,"current complete city manifest exists: "+id)
		if not parsed is Dictionary: continue
		var current: Dictionary=parsed as Dictionary
		var legacy: SceneScript=CITY_SUBJECT.legacy_scene(StringName(id))
		_check(legacy!=null and current.get("gameplay_slots") is Dictionary,"actual immutable original semantic identities and current city slots: "+id)
		if legacy==null or not current.get("gameplay_slots") is Dictionary: continue
		for kind: String in COUNTS:
			var originals: Array=legacy.npcs if kind=="npcs" else legacy.map_layout.get(kind)
			var slots: Array=current.gameplay_slots.get(kind,[])
			var seen: Dictionary={}
			for entry: Dictionary in originals:
				var sid: String=String(entry.get("npc_id" if kind=="npcs" else "id",""))
				expected[kind].append(id+"/"+sid)
				_check(not sid.is_empty() and not seen.has(sid) and not _slot(slots,sid).is_empty(),"current gameplay slot preserves exact original identity: "+id+"/"+sid)
				seen[sid]=true
			_check(slots.size()==originals.size(),"no additional/missing semantic identities: "+id+" "+kind)
	for kind: String in COUNTS: _check((expected[kind] as Array).size()==int(COUNTS[kind]),"all four original city "+kind+" counted independently")
	if failures>0: return await _finish()
	var sprite_alpha: RefCounted=SPRITE_ALPHA.new()
	var current_texture_cases: Dictionary=await sprite_alpha.call("run",tree,_check,output)
	_check(_write("current_sprite_atlas_region_flips.json",current_texture_cases),"synthetic current-frame/region/flip hit+render evidence persisted, separate from gameplay")
	sprite_alpha=null
	_public_fixture({})
	tree.root.get_node("SceneRouter").call("reset_for_new_game")
	before_nav=tree.root.get_node("SceneRouter").call("get_navigation_state")
	if candidate:
		var upgraded: Dictionary=before_nav.duplicate(true)
		upgraded["world_map_version"]=15
		tree.root.get_node("SceneRouter").call("restore_navigation_state",upgraded,&"",&"world_map_jianghu_v15")
		_check(String(tree.root.get_node("SceneRouter").call("get_active_world_map_scene"))=="world_map_jianghu_v15","public explicit candidate navigation selects real v15 return map")
	_connect_events()
	for id: String in IDS:
		_public_fixture({})
		if not await _open(id): continue
		await probe.call("run_routes")
		await probe.call("run_objects")
		for object: Dictionary in (probe.get("data") as Dictionary).get("objects",[]):
			if (object.get("alpha",{}) as Dictionary).get("method")=="continuous_full_drawrect_axis_separation": records.water_domains.append(object.alpha)
		records.regions.append({"id":id,"manifest_sha256":FileAccess.get_sha256(ART_ROOT+id+"/art_contract.json"),"physical_and_current_alpha":(probe.get("data") as Dictionary).duplicate(true)})
		var legacy: SceneScript=CITY_SUBJECT.legacy_scene(StringName(id))
		for entry: Dictionary in legacy.npcs:
			for mode: String in ["space","mouse"]: await _normal_action_case(id,"npcs",entry,mode)
		for entry: Dictionary in legacy.map_layout.interactions:
			for mode: String in ["space","mouse"]: await _normal_action_case(id,"interactions",entry,mode)
		for entry: Dictionary in legacy.map_layout.portals:
			for mode: String in ["space","mouse"]: await _normal_portal_case(id,entry,mode)
	# Both existing cases use the real old adjacent fields and ordinary rewards.
	await _normal_bounty_rewards()
	var negatives: RefCounted=INTERACTION_NEGATIVES.new()
	records.interaction_negatives=await negatives.call("run",self)
	negatives=null
	if "--fresh-start-only" in OS.get_cmdline_user_args():
		records.migration={"scope":"HISTORICAL_COMPATIBILITY_NOT_EXECUTED","complete":false,"historical_compatibility_tested":false,"records":[]}
	else:
		var migration: RefCounted=MIGRATION_LOAD.new()
		records.migration=await migration.call("run",self)
		migration=null
	return await _finish()

func _normal_portal_case(id: String,entry: Dictionary,mode: String) -> void:
	_public_fixture(entry)
	if not await _open(id): return
	var sid: String=String(entry.id)
	var slot: Dictionary=_slot(manifest.gameplay_slots.portals,sid)
	var point: Vector2=_point(slot.get("foot_px"))
	var approach: Dictionary=await probe.call("move_to",point)
	if not _check(bool(approach.get("ok",false)),"normal continuous input reaches city doorway: "+id+"/"+sid): return
	var before_foot: Vector2=(field.get("_player") as Node2D).position
	var zone: Node
	for value: Node in field.get("_exit_nodes"):
		if String(value.name)=="Exit_"+sid or String(value.get_meta("portal_id",""))==sid: zone=value
	if zone==null:
		for index in (field.get("_current_scene") as SceneScript).map_layout.portals.size():
			if String((field.get("_current_scene") as SceneScript).map_layout.portals[index].id)==sid: zone=(field.get("_exit_nodes") as Array)[index]; break
	_check(zone!=null and bool(zone.get("_in_range")),"actual enabled doorway has real player Physics2D overlap")
	if zone==null: return
	var audio: Node=tree.root.get_node("AudioManager")
	var bgm: AudioStreamPlayer=audio.get("bgm_player") as AudioStreamPlayer
	var before_bgm: Dictionary={"path":String(audio.get("_current_bgm_path")),"id":bgm.get_instance_id() if bgm!=null else 0,"position":bgm.get_playback_position() if bgm!=null else 0}
	var bgm_observer: RefCounted=OPERATIONAL_BGM.new()
	_check(FileAccess.get_sha256("res://tests/helpers/joint_v15_wasapi_operational_bgm_continuity_20261007.gd")==OPERATIONAL_BGM_SHA,"current bounded loop-observer source is frozen")
	var bgm_started: Dictionary=bgm_observer.call("begin_observation",tree,id+"/"+sid+"/"+mode)
	if mode=="space": await driver.call("key",KEY_SPACE)
	else:
		var container: Node2D=field.get("world_container") as Node2D
		await driver.call("pointer",container.get_global_transform_with_canvas()*point)
	var target: String=String(entry.get("target_scene",""))
	if String(entry.get("action",""))=="world_map": target="world_map_jianghu_v15" if candidate else "world_map_jianghu"
	var entered: bool=await _wait_field(target)
	var bgm_observed: Dictionary=bgm_observer.call("finish_observation")
	bgm_observer.call("release")
	bgm_observer=null
	_check(entered,"normal city portal really arrives exact original target: "+id+"/"+sid)
	var back: Dictionary={"not_run":true}
	var paired_memory_api: Dictionary={"not_run":true}
	if entered:
		await _finish_dialogs()
		var definition: SceneScript=field.get("_current_scene") as SceneScript
		if definition.bgm_path==((CITY_SUBJECT.legacy_scene(StringName(id)) as SceneScript).bgm_path):
			_check(bool(bgm_started.get("ok",false)) and bool(bgm_observed.get("ok",false)),"same authored BGM keeps exact stream/player/path, zero change events and measured looped playhead continuity")
		if id=="ch4_s2_canal_docks" and target in ["world_map_jianghu_v15","world_map_jianghu"]:
			# Existing world UI has no direct world->docks door. The producer-approved
			# public paired-memory API is tested SEPARATELY, never input credit.
			tree.root.get_node("SceneRouter").call("return_from_world_map")
			var api_returned: bool=await _wait_field(id)
			var exact_memory: bool=api_returned and (field.get("_player") as Node2D).position.distance_to(before_foot)<.03
			_check(exact_memory,"separate PUBLIC_API_NOT_INPUT world return preserves precise docks memory")
			paired_memory_api={"scope":"PUBLIC_API_NOT_INPUT","returned":api_returned,"exact_source_feet":exact_memory}
			if not api_returned: return
			await _finish_dialogs()
			if not _bind_field(id): return
			var repeat_approach: Dictionary=await probe.call("move_to",before_foot)
			_check(bool(repeat_approach.get("ok",false)),"normal input re-reaches same docks ferry after separate API test")
			if not bool(repeat_approach.get("ok",false)): return
			await driver.call("key",KEY_SPACE)
			if not _check(await _wait_field(target),"normal ferry input re-enters world before original indirect return chain"): return
			await _finish_dialogs()
		back=await _return_from_target(id)
		_check(bool(back.get("returned",false)),"actual target public exit/input returns city, no Router shortcut")
		if bool(back.get("returned",false)):
			await _finish_dialogs()
			if String(back.get("kind",""))=="DIRECT_ORIGINAL_REVERSE_INPUT":
				_check((field.get("_player") as Node2D).position.distance_to(before_foot)<.03,"paired direct city return preserves exact ordinary pre-departure feet")
			else:
				_check(String(back.get("kind",""))=="INDIRECT_WORLD_GATE_YAMEN_DOCKS_INPUT","indirect original topology is explicitly distinguished from nonexistent direct paired-docks input")
			_bind_field(id)
	var record: Dictionary={"source_scene_id":id,"source_id":sid,"mode":mode,"dry_run":false,"target":target,"entered":entered,"source_foot_px":[before_foot.x,before_foot.y],"approach":approach,"return":back,"separate_paired_memory_api":paired_memory_api,"bgm_before":before_bgm,"bgm_started":bgm_started,"bgm_observation":bgm_observed}
	records.portals.append(record)
	_check(_write("portal_"+id+"_"+sid+"_"+mode+".json",record),"normal portal evidence persists")


