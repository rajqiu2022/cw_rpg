extends "res://tests/helpers/joint_v15_wasapi_operational_city_phase_20261007.gd"
## New city-only scope; inherited dialogue/battle/UI/normal input/Physics thresholds
## stay intact. Formal world14 and existing outskirts are NOT candidate subjects.
const ENCLOSURE = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const ENCLOSURE_RAW = preload("res://tests/helpers/luoyang_enclosure_v11_city_only_raw.gd")
const FORMAL_WORLD_RAW = preload("res://tests/helpers/v15_field_raw_oracle.gd")
const TARGET_RAW = preload("res://tests/helpers/luoyang_enclosure_v11_city_only_target_raw.gd")
const CITY_ONLY_SELECTED_TRACK_BGM = preload("res://tests/helpers/luoyang_wasapi_catalog3_continuity_20261011.gd")
const CITY_ONLY_SELECTED_TRACK_BGM_SHA: String = "62acbff384fecf1de7309907745c2e736bdaefd6f3b3d34b7e8dcb86fe9e9f6a"
const CITY_ONLY_SCOPE := "LUOYANG_ENCLOSURE_V11_CITY_ONLY_FRESH_ACTUAL"
var author_records: Dictionary={}

func _bind_field(id: String) -> bool:
	_release_field_oracles()
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	if not _check(definition!=null and definition.scene_id==StringName(id) and definition.map_layout!=null and ENCLOSURE.is_v3(definition),"current actual city3 definition and exact enclosure/base metadata"): return false
	if not _check(field.get_script().resource_path=="res://scripts/field/field_walkable_controller.gd" and ENCLOSURE.semantic_fidelity(definition),"production Field and unchanged original gameplay storage"): return false
	raw=ENCLOSURE_RAW.new()
	if not _check(raw.call("configure_city",definition,candidate),"independent BASE/patch PNG/full17/source-solid city reader"): return false
	manifest=(raw.get("source_record") as Dictionary).duplicate(true)
	author_records[id]=manifest.duplicate(true)
	probe=preload("res://tests/helpers/luoyang_roof_source_display_actual_probe_20261011_retry2.gd").new()
	return _check(probe.call("configure",tree,field,manifest,_check,_capture),"complete current875/17 actualPhysics/Y/alpha probe")

func run_city_stage(owner: SceneTree,before_cutover: bool,stage: String,directory: String) -> Dictionary:
	tree=owner; candidate=before_cutover; output=directory
	before_files=_normal_files(); before_slot=tree.root.get_node("SaveManager").get("active_slot")
	driver=INPUT.new(); driver.call("configure",tree)
	_check(stage in ["geometry","gameplay"],"explicit geometry/gameplay stage")
	_check(candidate==("--luoyang-enclosure-v11-candidate" in OS.get_cmdline_user_args()) and candidate==("--luoyang-v3-candidate" in OS.get_cmdline_user_args()),"candidate requires BOTH explicit city flags; formal forbids them")
	_check(FileAccess.get_sha256(V9C_CITY_ORIGIN_PATH).to_lower()==V9C_CITY_ORIGIN_SHA,"original authored lifecycle source unchanged")
	for id: String in IDS:
		var reader: RefCounted=ENCLOSURE_RAW.new()
		var record: Dictionary=reader.call("independent_record",StringName(id))
		reader.call("release")
		if not _check(not record.is_empty(),"current independently pinned author record "+id): continue
		author_records[id]=record
		var legacy: SceneScript=ENCLOSURE.legacy_scene(StringName(id))
		if not _check(legacy!=null and record.get("gameplay_slots") is Dictionary,"actual immutable gameplay identities "+id): continue
		for kind: String in COUNTS:
			var originals: Array=legacy.npcs if kind=="npcs" else legacy.map_layout.get(kind)
			var slots: Array=record.gameplay_slots.get(kind,[])
			var seen: Dictionary={}
			for entry: Dictionary in originals:
				var sid: String=String(entry.get("npc_id" if kind=="npcs" else "id",""))
				expected[kind].append(id+"/"+sid)
				_check(not sid.is_empty() and not seen.has(sid) and not _slot(slots,sid).is_empty(),"original slot preserved "+id+"/"+sid)
				seen[sid]=true
			_check(slots.size()==originals.size(),"exact semantic set "+id+"/"+kind)
	for kind: String in COUNTS: _check(expected[kind].size()==int(COUNTS[kind]),"all four original "+kind+" identities")
	if failures==0:
		_public_fixture({})
		tree.root.get_node("SceneRouter").call("reset_for_new_game")
		# Only current city3 ledger initialization, never historical coordinates.
		var router: Node=tree.root.get_node("SceneRouter")
		router.call("restore_navigation_state",router.call("get_navigation_state"),&"", &"world_map_jianghu")
		before_nav=(router.call("get_navigation_state") as Dictionary).duplicate(true)
		_check(before_nav.get("world_map_version")==14 and String(router.call("get_active_world_map_scene"))=="world_map_jianghu","existing formal world14 remains active")
		_connect_events()
		if stage=="gameplay":
			var sprite_alpha: RefCounted=SPRITE_ALPHA.new()
			_check(_write("current_sprite_atlas_region_flips.json",await sprite_alpha.call("run",tree,_check,output)),"original actual current-frame/region/flip probe")
			sprite_alpha=null
		for id: String in IDS:
			if stage=="geometry":
				_public_fixture({})
				if not await _open(id): continue
				await probe.call("run_routes"); await probe.call("run_objects")
				var data: Dictionary=(probe.get("data") as Dictionary).duplicate(true)
				_check(data.routes.size()==manifest.routes.size() and data.objects.size()==manifest.objects.size(),"no geometry subset: all routes and all NEW retained/appended objects "+id)
				var found: Dictionary={}
				for object: Dictionary in data.objects:
					_check(not found.has(String(object.id)),"unique actually tested object "+id+"/"+str(object.id))
					found[String(object.id)]=true
					if object.get("alpha",{}).get("method")=="continuous_full_drawrect_axis_separation": records.water_domains.append(object.alpha)
				for object: Dictionary in manifest.objects: _check(found.has(String(object.id)),"actual object identity covered "+id+"/"+str(object.id))
				records.regions.append({"id":id,"manifest_path":ENCLOSURE.manifest_path(StringName(id)),"manifest_sha256":ENCLOSURE.manifest_sha(StringName(id)),"physical_and_current_alpha":data})
			else:
				var legacy: SceneScript=ENCLOSURE.legacy_scene(StringName(id))
				for entry: Dictionary in legacy.npcs:
					for mode: String in ["space","mouse"]: await _normal_action_case(id,"npcs",entry,mode)
				for entry: Dictionary in legacy.map_layout.interactions:
					for mode: String in ["space","mouse"]: await _normal_action_case(id,"interactions",entry,mode)
				for entry: Dictionary in legacy.map_layout.portals:
					for mode: String in ["space","mouse"]: await _normal_portal_case(id,entry,mode)
		if stage=="gameplay":
			await _normal_bounty_rewards()
			var negatives: RefCounted=INTERACTION_NEGATIVES.new()
			records.interaction_negatives=await negatives.call("run",self)
			negatives=null
			_check(records.npcs.size()==30 and records.interactions.size()==22 and records.portals.size()==24 and records.bounties.size()==2 and records.interaction_negatives.get("complete")==true,"all52 original NPC/action inputs,24 portals,2 rewards and all interaction negatives")
	return await _finish_city_stage(stage)

func _finish_city_stage(stage: String) -> Dictionary:
	await natural_field_grace("city_only_before_actual_cleanup")
	records["own_natural_grace"]=natural_grace_records.duplicate(true)
	var bus: Node=tree.root.get_node("EventBus")
	for entry: Dictionary in event_connections:
		if bus.is_connected(entry.signal,entry.callable): bus.disconnect(entry.signal,entry.callable)
	event_connections.clear()
	if raw!=null: _check(raw.call("verify_sources"),"last current PNG source verification")
	_release_field_oracles()
	var reference: WeakRef=weakref(field) if is_instance_valid(field) else null
	if is_instance_valid(tree.current_scene): tree.current_scene.queue_free(); tree.current_scene=null
	field=null
	for tick in 8: await tree.process_frame
	_check(reference==null or reference.get_ref()==null,"owned Field released normally")
	_check(_normal_files()==before_files and tree.root.get_node("SaveManager").get("active_slot")==before_slot,"all player paths and slot unchanged")
	if not before_nav.is_empty():
		var router: Node=tree.root.get_node("SceneRouter")
		router.call("reset_for_new_game")
		router.call("restore_navigation_state",router.call("get_navigation_state"),&"", &"world_map_jianghu")
		_check(router.call("get_navigation_state")==before_nav,"public current-format process baseline restored exactly")
	if stage=="geometry":
		_check(records.regions.size()==4,"all four geometry regions")
		var route_count: int=0
		for row: Dictionary in records.regions: route_count+=(row.physical_and_current_alpha.routes as Array).size()
		_check(route_count==20,"all20 unchanged authored route inputs")
	else: _finalize_water_proofs()
	var report: Dictionary={"schema":1,"scope":CITY_ONLY_SCOPE,"phase":stage,"candidate_before_cutover":candidate,"historical_compatibility_tested":false,"world_subject_version":14,"world_full_tested":false,"complete":failures==0 and runtime_started,"checks":checks,"failures":failures,"records":records.duplicate(true),"current_author_bindings":{},"water_decoration_absence_proofs":water_summaries.duplicate(true),"player_saves_unchanged":_normal_files()==before_files,"visual_verdict":"NOT_REVIEWED","formal_approved":false}
	for id: String in author_records: report.current_author_bindings[id]={"path":ENCLOSURE.manifest_path(StringName(id)),"sha256":ENCLOSURE.manifest_sha(StringName(id)),"base_path":ENCLOSURE.base_manifest_path(StringName(id)),"base_sha256":ENCLOSURE.base_manifest_sha(StringName(id))}
	_check(_write("stage_result.json",report),"actual city-only stage persisted")
	if driver!=null: driver.call("release"); driver=null
	manifest.clear(); tree=null
	report.checks=checks; report.failures=failures; report.complete=report.complete and failures==0
	return report

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
	var target: String=String(entry.get("target_scene",""))
	if String(entry.get("action",""))=="world_map": target="world_map_jianghu"
	var bgm_selection: Dictionary=CITY_ONLY_SELECTED_TRACK_BGM.expected_transfer(id,target)
	var bgm_observer: RefCounted=CITY_ONLY_SELECTED_TRACK_BGM.new()
	_check(FileAccess.get_sha256("res://tests/helpers/luoyang_wasapi_catalog3_continuity_20261011.gd")==CITY_ONLY_SELECTED_TRACK_BGM_SHA,"current exact effective-selected track observer source is frozen")
	var bgm_started: Dictionary=bgm_observer.call("begin_transfer",tree,id+"/"+sid+"/"+mode,bgm_selection,120.0)
	if mode=="space": await driver.call("key",KEY_SPACE)
	else:
		var container: Node2D=field.get("world_container") as Node2D
		await driver.call("pointer",container.get_global_transform_with_canvas()*point)
	var entered: bool=await _wait_field(target)
	var bgm_observed: Dictionary=bgm_observer.call("finish_transfer")
	bgm_observer.call("release")
	bgm_observer=null
	_check(entered,"normal city portal really arrives exact original target: "+id+"/"+sid)
	var back: Dictionary={"not_run":true}
	var paired_memory_api: Dictionary={"not_run":true}
	if entered:
		await _finish_dialogs()
		var kind: String=String(bgm_selection.get("kind",""))
		_check(kind in ["SAME_SELECTED_TRACK","DIFFERENT_SELECTED_TRACK"] and bool(bgm_started.get("ok",false)) and bool(bgm_observed.get("ok",false)),"normal portal effective-selected BGM begin/finish source-bound contract")
		if kind=="SAME_SELECTED_TRACK":
			_check(bgm_observed.get("continuity_tested")==true and bgm_observed.get("continuity_credit")==true,"same effective-selected BGM keeps exact stream/player/path, zero change events and measured looped playhead continuity")
		elif kind=="DIFFERENT_SELECTED_TRACK":
			_check(bgm_observed.get("continuity_tested")==false and bgm_observed.get("continuity_credit")==false,"different effective-selected track is one normal target change, never same-song continuity credit")
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
	var record: Dictionary={"source_scene_id":id,"source_id":sid,"mode":mode,"dry_run":false,"target":target,"entered":entered,"source_foot_px":[before_foot.x,before_foot.y],"approach":approach,"return":back,"separate_paired_memory_api":paired_memory_api,"bgm_before":before_bgm,"bgm_selection":bgm_selection,"bgm_started":bgm_started,"bgm_observation":bgm_observed}
	records.portals.append(record)
	_check(_write("portal_"+id+"_"+sid+"_"+mode+".json",record),"normal portal evidence persists")

func _input_existing_exit_to(source: String) -> Dictionary:
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	var is_world: bool=String(definition.scene_id) in ["world_map_jianghu_v15","world_map_jianghu"]
	var actual_raw: RefCounted=FORMAL_WORLD_RAW.new() if is_world else ENCLOSURE_RAW.new() if IDS.has(String(definition.scene_id)) else TARGET_RAW.new()
	var ok: bool=bool(actual_raw.call("configure_city",definition,candidate)) if IDS.has(String(definition.scene_id)) else bool(actual_raw.call("configure",definition.map_layout)) if is_world else bool(actual_raw.call("configure_current",definition,field))
	var result: Dictionary={"returned":false,"target_scene":String(definition.scene_id)}
	if not _check(ok,"target's original raw native/legacy navigation configured independently"): actual_raw.call("release"); return result
	var size: Vector2=field.get("_world_size")
	var clear: Callable=func(p: Vector2)->bool: return bool(actual_raw.call("clear",p)) and _actual_body_clear(field,p)
	var segment: Callable=func(a: Vector2,b: Vector2)->Dictionary:
		var count: int=maxi(1,ceili(a.distance_to(b)/4))
		for index in range(count+1):
			if not bool(clear.call(a.lerp(b,float(index)/count))): return {"clear":false,"index":index}
		return {"clear":true,"centers":count+1}
	var zone: Node
	# Ordinary ancient-temple doors are genuinely generated from original
	# SceneScript.hotspots. Inspect the live ExitZone rather than assuming every
	# original reverse door was authored in map_layout.portals.
	for actual_zone: Node in field.get("_exit_nodes"):
		if String(actual_zone.get("target_scene_id"))==source and not bool(actual_zone.get("is_locked")):
			zone=actual_zone
			break
	if not _check(zone!=null,"real target has original reverse route"): actual_raw.call("release"); return result
	var target: Vector2=zone.position
	result["original_reverse_zone"]={"node_path":str(zone.get_path()),"name":String(zone.name),"target_scene_id":String(zone.get("target_scene_id")),"target_spawn_pos":zone.get("target_spawn_pos"),"original_scene_sha256":FileAccess.get_sha256(definition.resource_path) if not definition.resource_path.is_empty() else "IN_MEMORY_CANDIDATE"}
	var path: PackedVector2Array=driver.call("plan",(field.get("_player") as Node2D).position,target,size,clear,segment)
	var driven: Dictionary=await driver.call("follow",field,path,clear,segment)
	_check(bool(driven.get("ok",false)) and bool(zone.get("_in_range")),"normal target input reaches enabled reverse area with complete feet/physics")
	if bool(driven.get("ok",false)):
		await driver.call("key",KEY_SPACE)
		result.returned=await _wait_field(source)
	result["drive"]=driven
	actual_raw.call("release")
	return result

func _normal_bounty_rewards() -> void:
	_public_fixture({"require_flag":"clue_luoyang_case"})
	var id: String=IDS[0]
	if not await _open(id): return
	var slot: Dictionary=_slot(manifest.gameplay_slots.interactions,"luoyang_repeatable_bounty_board")
	var approach: Dictionary=await probe.call("move_to",_point(slot.get("stand_px")))
	if not _check(bool(approach.get("ok",false)),"real bounty entity approachable"): return
	await probe.call("click_entity",probe.call("prop",String(slot.get("object_id",""))))
	for tick in 10: await tree.process_frame
	var page: Node=tree.current_scene
	if not _check(page!=null and page.get_node_or_null("BountyEntries")!=null,"ordinary entity opens actual two-case board"): return
	var entries: Array[Dictionary]=tree.root.get_node("BountyManager").call("get_board_entries",&"luoyang")
	_check(entries.size()==2,"both existing Luoyang bounty identities retained")
	for entry: Dictionary in entries:
		var button: Button=page.get_node_or_null("BountyEntries/BountyEntry_"+String(entry.bounty_id)+"/Content/AcceptButton") as Button
		_check(button!=null and not button.disabled,"ordinary available bounty accept control")
		if button!=null: await driver.call("pointer",button.get_global_rect().get_center())
	await driver.call("pointer",(page.get_node("CloseButton") as Control).get_global_rect().get_center())
	_check(await _wait_field(id),"normal bounty board closes to exact city")
	for entry: Dictionary in entries:
		var manager: Node=tree.root.get_node("BountyManager")
		var states: Dictionary=(manager.call("to_dict") as Dictionary).states
		var state: Dictionary=states.get(String(entry.bounty_id),{})
		var definition: BountyDef=manager.call("get_definition",StringName(entry.bounty_id)) as BountyDef
		_check(String(state.get("status",""))=="active" and definition!=null,"normal actual UI accepted bounty, no injected active state")
		if definition==null or int(state.get("location_index",-1))<0: continue
		var location: Dictionary=definition.locations[int(state.location_index)]
		var target_id: String=String(location.scene_id)
		_check(not IDS.has(target_id),"existing bounty neighbor art/identity retained, not rebuilt as city")
		var accepted: bool=tree.root.get_node("SceneRouter").call("go_field_smart",StringName(target_id))
		if not _check(accepted and await _wait_field(target_id),"normal public travel enters original neighboring bounty scene"): continue
		await _finish_dialogs()
		var current: SceneScript=field.get("_current_scene") as SceneScript
		var target_raw: RefCounted=TARGET_RAW.new()
		if not _check(bool(target_raw.call("configure_current",current,field)),"original neighbor raw navigation still valid"): target_raw.call("release"); continue
		var bounty_npc: Node=_npc("bounty_"+String(entry.bounty_id))
		_check(bounty_npc!=null,"actual accepted bounty spawns normal target NPC")
		if bounty_npc==null: target_raw.call("release"); continue
		var clear: Callable=func(p: Vector2)->bool: return bool(target_raw.call("clear",p)) and _actual_body_clear(field,p)
		var segment: Callable=func(a: Vector2,b: Vector2)->Dictionary:
			var count: int=maxi(1,ceili(a.distance_to(b)/4))
			for index in range(count+1):
				if not bool(clear.call(a.lerp(b,float(index)/count))): return {"clear":false}
			return {"clear":true}
		var station: Vector2=Vector2(INF,INF)
		for radius in [48,56,64,72]:
			for angle in 16:
				var point: Vector2=bounty_npc.position+Vector2.from_angle(TAU*angle/16)*radius
				if bool(clear.call(point)): station=point; break
			if station.is_finite(): break
		var path: PackedVector2Array=driver.call("plan",(field.get("_player") as Node2D).position,station,field.get("_world_size"),clear,segment)
		var driven: Dictionary=await driver.call("follow",field,path,clear,segment)
		if not _check(bool(driven.get("ok",false)),"actual normal input approaches original bounty NPC"): target_raw.call("release"); continue
		var pre: Dictionary=_state()
		var original_foot: Vector2=(field.get("_player") as Node2D).position
		var original_size: Vector2=field.get("_world_size")
		await driver.call("key",KEY_SPACE)
		var battle: RefCounted=BATTLE.new()
		battle.call("configure",tree,driver,_check)
		var actual: Dictionary=await battle.call("victory",target_id,original_foot,1,original_size)
		battle.call("release")
		var after: Dictionary=_state()
		var final_state: Dictionary=((manager.call("to_dict") as Dictionary).states as Dictionary).get(String(entry.bounty_id),{})
		_check(bool(actual.get("won",false)) and String(final_state.get("status",""))=="captured" and int(final_state.get("completion_count",0))==1,"real bounty victory completes original case exactly once")
		_check(int(after.reputation)==int(pre.reputation)+definition.reward_reputation and int(after.training)==int(pre.training)+definition.reward_training,"normal capture gives exact authored reputation/training, no fake result")
		records.bounties.append({"id":entry.bounty_id,"location":location,"normal_drive":driven,"battle":actual,"before":pre,"after":after,"final_state":final_state})
		target_raw.call("release")

