extends "res://tests/helpers/luoyang_enclosure_v11_city_only_phase.gd"
## Only the authored Market->Gate edge has no direct reverse door.
## All other original stage/input/Physics/music/reward/negative/cleanup methods
## remain inherited. A zero-motion leg is evidence of overlap, not movement.
const MARKET_RETURN_PARENT_SHA := "47006fbee07d3d4c88c223816ca3876bdfde2bf3b1583ff5b6ca674c2944045a"
const MARKET_RETURN_KIND := "INDIRECT_GATE_YAMEN_MARKET_INPUT"
const MARKET_RETURN_SOURCE_PINS := {
	"res://data/maps/luoyang_v3_legacy/ch4_s0_luoyang_gate_scene.tres":"b967c347e745e6f05d51a8f596fde4744571f5d459279467c706e66d9be24bd1",
	"res://data/maps/luoyang_v3_legacy/ch4_s0_luoyang_gate_layout.tres":"1d5cca7d70b14032f116964533cc33b9a1b7937beb85c829a4148dfa5c79cc82",
	"res://data/maps/luoyang_v3_legacy/ch4_s1_luoyang_yamen_scene.tres":"7bed5d322d583c9c7bf4e392f3f4c75ffb0577db24bb9e6237a4ae3aa0808b01",
	"res://data/maps/luoyang_v3_legacy/ch4_s1_luoyang_yamen_layout.tres":"658d7038a28f63aa84c701f604bd04405dcff3a8df6bacc7c533557e2e73ab63",
	"res://data/maps/luoyang_v3_legacy/ch4_s3_luoyang_market_scene.tres":"5cd76d0c0a0c54358f50b341186c5ea078a7d20657c97dc15ef15027755661ab",
	"res://data/maps/luoyang_v3_legacy/ch4_s3_luoyang_market_layout.tres":"d99c58dc2ad2e8b1bfbcbc1ac69e7a9aa08e2ac7cfffc773d4b5708f6825b60c",
}
var _market_return_edge_active: bool=false
const ROOT_AND_FEET_RAW = preload("res://tests/helpers/luoyang_enclosure_v11_target_root_and_feet_raw_20261011.gd")

func _bind_field(id: String) -> bool:
	_release_field_oracles()
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	if not _check(definition!=null and definition.scene_id==StringName(id) and definition.map_layout!=null and ENCLOSURE.is_v3(definition),"current actual city3 definition and exact enclosure/base metadata"): return false
	if not _check(field.get_script().resource_path=="res://scripts/field/field_walkable_controller.gd" and ENCLOSURE.semantic_fidelity(definition),"production Field and unchanged original gameplay storage"): return false
	raw=ENCLOSURE_RAW.new()
	if not _check(raw.call("configure_city",definition,candidate),"independent BASE/patch PNG/full17/source-solid city reader"): return false
	manifest=(raw.get("source_record") as Dictionary).duplicate(true)
	author_records[id]=manifest.duplicate(true)
	probe=preload("res://tests/helpers/luoyang_roof_source_display_actual_probe_20261011_retry3.gd").new()
	return _check(probe.call("configure",tree,field,manifest,_check,_capture),"complete current875/17 actualPhysics/Y/alpha probe")

func _input_existing_exit_to(source: String) -> Dictionary:
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	var is_world: bool=String(definition.scene_id) in ["world_map_jianghu_v15","world_map_jianghu"]
	var actual_raw: RefCounted=FORMAL_WORLD_RAW.new() if is_world else ENCLOSURE_RAW.new() if IDS.has(String(definition.scene_id)) else ROOT_AND_FEET_RAW.new()
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
	await _finish_dialogs()
	if not _check(not bool(tree.root.get_node("DialogPlayer").call("is_playing")),"previous dialogue normally finished before bounty fixture reset"): return
	var legacy: SceneScript=ENCLOSURE.legacy_scene(StringName(IDS[0]))
	var boards: Array[Dictionary]=[]
	if legacy!=null and legacy.map_layout!=null:
		for entry: Dictionary in legacy.map_layout.interactions:
			if entry.get("id")=="luoyang_repeatable_bounty_board": boards.append(entry.duplicate(true))
	if not _check(boards.size()==1 and FileAccess.get_sha256("res://data/maps/luoyang_v3_legacy/ch4_s0_luoyang_gate_layout.tres")==MARKET_RETURN_SOURCE_PINS["res://data/maps/luoyang_v3_legacy/ch4_s0_luoyang_gate_layout.tres"],"one exact original repeatable board source"): return
	var board: Dictionary=boards[0]
	if not _check(typeof(board.get("require_flag"))==TYPE_STRING and board.require_flag=="luoyang_case_found_clue" and board.get("action")=="bounty_board:luoyang" and board.get("activation")=="interact" and board.get("clickable")==true,"original board author flag/action/activation, no invented accepted bounty"): return
	_public_fixture(board)
	var id: String=IDS[0]
	if not await _open(id): return
	var slot: Dictionary=_slot(manifest.gameplay_slots.interactions,"luoyang_repeatable_bounty_board")
	var approach: Dictionary=await probe.call("move_to",_point(slot.get("stand_px")))
	if not _check(bool(approach.get("ok",false)),"real bounty entity approachable"): return
	var areas: Array[Area2D]=[]
	for area: Area2D in field.get("_trigger_areas"):
		if is_instance_valid(area) and (area.get_meta("trigger_data",{}) as Dictionary).get("id")==board.id: areas.append(area)
	if not _check(areas.size()==1,"original live repeatable board Area present before click"): return
	var live_data: Dictionary=areas[0].get_meta("trigger_data",{})
	var live_ok: bool=areas[0].is_inside_tree() and areas[0].overlaps_body(field.get("_player")) and areas[0].collision_layer==4 and areas[0].collision_mask==2 and areas[0].input_pickable
	for key: String in ["id","action","require_flag","activation","clickable"]:
		live_ok=live_ok and typeof(live_data.get(key))==typeof(board.get(key)) and var_to_bytes(live_data.get(key))==var_to_bytes(board.get(key))
	if not _check(live_ok and (tree.root.get_node("GameState").get("flags") as Dictionary).get(board.require_flag)==true,"actual source-bound enabled board Area/action and real body overlap before normal pointer"): return
	records["bounty_board_binding"]={"source_entry":board.duplicate(true),"source_path":"res://data/maps/luoyang_v3_legacy/ch4_s0_luoyang_gate_layout.tres","source_sha256":MARKET_RETURN_SOURCE_PINS["res://data/maps/luoyang_v3_legacy/ch4_s0_luoyang_gate_layout.tres"],"live_trigger_data":live_data.duplicate(true),"live_Area_instance_id":areas[0].get_instance_id(),"original_approach":approach}
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
		var target_raw: RefCounted=ROOT_AND_FEET_RAW.new()
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
		_market_return_edge_active=id=="ch4_s3_luoyang_market" and sid=="to_city_gate" and target=="ch4_s0_luoyang_gate" and mode in ["space","mouse"]
		back=await _return_from_target(id)
		_market_return_edge_active=false
		_check(bool(back.get("returned",false)),"actual target public exit/input returns city, no Router shortcut")
		if bool(back.get("returned",false)):
			await _finish_dialogs()
			if String(back.get("kind",""))=="DIRECT_ORIGINAL_REVERSE_INPUT":
				_check((field.get("_player") as Node2D).position.distance_to(before_foot)<.03,"paired direct city return preserves exact ordinary pre-departure feet")
			elif id=="ch4_s3_luoyang_market" and sid=="to_city_gate" and target=="ch4_s0_luoyang_gate" and mode in ["space","mouse"]:
				_check(back.get("kind")=="INDIRECT_GATE_YAMEN_MARKET_INPUT" and back.get("not_a_direct_paired_return")==true and (back.get("steps",[]) as Array).size()==2 and back.get("final_market_feet_exact")==true,"original Gate to Yamen to Market two-step input return, not direct paired memory or Router shortcut")
			else:
				_check(String(back.get("kind",""))=="INDIRECT_WORLD_GATE_YAMEN_DOCKS_INPUT","indirect original topology is explicitly distinguished from nonexistent direct paired-docks input")
			_bind_field(id)
	var record: Dictionary={"source_scene_id":id,"source_id":sid,"mode":mode,"dry_run":false,"target":target,"entered":entered,"source_foot_px":[before_foot.x,before_foot.y],"approach":approach,"return":back,"separate_paired_memory_api":paired_memory_api,"bgm_before":before_bgm,"bgm_selection":bgm_selection,"bgm_started":bgm_started,"bgm_observation":bgm_observed}
	records.portals.append(record)
	_check(_write("portal_"+id+"_"+sid+"_"+mode+".json",record),"normal portal evidence persists")


func _market_return_sources() -> Dictionary:
	var result: Dictionary={}
	for path: String in MARKET_RETURN_SOURCE_PINS:
		var file: FileAccess=FileAccess.open(path,FileAccess.READ)
		var sha: String=FileAccess.get_sha256(path)
		if not _check(file!=null and sha==MARKET_RETURN_SOURCE_PINS[path],"fixed original Market/Gate/Yamen source and layout bytes: "+path): return {}
		result[path]={"sha256":sha,"bytes":file.get_length(),"exists":true}
	return result

func _market_live_endpoint(expected_scene: String) -> Dictionary:
	# Synchronous endpoint observation, not a per-tick body/Physics receipt.
	var result: Dictionary={"complete":false,"expected_scene_id":expected_scene,"scope":"ACTUAL_ENDPOINT_ORIGINAL_RAW_FULL17_PLUS_PLAYER_SHAPE_PHYSICS"}
	if not is_instance_valid(field): return result
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	var player: Node2D=field.get("_player") as Node2D
	if not is_instance_valid(player) or definition==null or String(definition.scene_id)!=expected_scene or not ENCLOSURE.is_v3(definition): return result
	var endpoint_raw: RefCounted=ENCLOSURE_RAW.new()
	var configured: bool=bool(endpoint_raw.call("configure_city",definition,candidate))
	var foot: Vector2=player.position
	var evidence: Dictionary=endpoint_raw.call("foot_evidence",foot) if configured else {"clear":false,"kind":"raw_not_configured"}
	var physics_clear: bool=configured and _actual_body_clear(field,foot)
	var verified: bool=configured and bool(endpoint_raw.call("verify_sources"))
	result.merge({"scene_id":String(definition.scene_id),"scene_resource_path":definition.resource_path,
		"layout_resource_path":definition.map_layout.resource_path,"Field_instance_id":field.get_instance_id(),
		"player_instance_id":player.get_instance_id(),"foot_px":[foot.x,foot.y],
		"foot_native_bytes":var_to_bytes(foot).hex_encode(),"world_size":field.get("_world_size"),
		"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames(),
		"raw_full17_evidence":evidence,"raw_full17_clear":evidence.get("clear")==true,
		"actual_Physics_clear":physics_clear,"source_bytes_verified":verified,
		"base_manifest_path":ENCLOSURE.base_manifest_path(definition.scene_id),
		"base_manifest_sha256":ENCLOSURE.base_manifest_sha(definition.scene_id),
		"patch_manifest_path":ENCLOSURE.manifest_path(definition.scene_id),
		"patch_manifest_sha256":ENCLOSURE.manifest_sha(definition.scene_id)},true)
	endpoint_raw.call("release")
	result.complete=configured and verified and evidence.get("clear")==true and physics_clear
	return result

func _market_departure_zone(expected_scene: String,portal_id: String,destination: String) -> Dictionary:
	var result: Dictionary={"complete":false}
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	if definition==null or String(definition.scene_id)!=expected_scene: return result
	var matches: int=0
	for index in definition.map_layout.portals.size():
		var row: Dictionary=definition.map_layout.portals[index]
		if String(row.get("id",""))!=portal_id: continue
		matches+=1
		var exits: Array=field.get("_exit_nodes")
		if index>=exits.size(): continue
		var zone: Node2D=exits[index] as Node2D
		if not is_instance_valid(zone): continue
		var target: Vector2=row.get("pos",Vector2(INF,INF))*Vector2(field.get("_world_size"))
		var ready: bool=String(row.get("target_scene",""))==destination and String(zone.get("target_scene_id"))==destination and typeof(zone.get("is_locked"))==TYPE_BOOL and not zone.get("is_locked") and zone.position==target and zone.get("target_spawn_pos")==row.get("target_pos")
		result={"complete":ready,"source_scene_id":expected_scene,"destination_scene_id":destination,
			"original_portal_id":portal_id,"original_portal_row":row.duplicate(true),
			"actual_zone_index":index,"actual_zone_instance_id":zone.get_instance_id(),
			"actual_zone_node_path":str(zone.get_path()),"actual_zone_name":String(zone.name),
			"actual_zone_target":String(zone.get("target_scene_id")),"actual_zone_position":zone.position,
			"actual_zone_spawn":zone.get("target_spawn_pos"),"actual_zone_locked":zone.get("is_locked")}
	result.complete=result.get("complete")==true and matches==1
	return result

func _market_original_drive_complete(driven: Dictionary) -> bool:
	if driven.get("ok")!=true or not driven.get("segments") is Array or driven.segments.is_empty(): return false
	for segment: Variant in driven.segments:
		if not segment is Dictionary or segment.get("ok")!=true or segment.get("reached")!=true or segment.get("all_recorded_feet_clear")!=true: return false
		if typeof(segment.get("physics_samples"))!=TYPE_INT or segment.physics_samples<0 or not segment.get("first_bad") is Array or not segment.first_bad.is_empty(): return false
		var start: Vector2=_point(segment.get("start"))
		var target: Vector2=_point(segment.get("target"))
		var end: Vector2=_point(segment.get("actual_end"))
		if not start.is_finite() or not target.is_finite() or not end.is_finite(): return false
		if segment.physics_samples==0 and not (start==target and target==end): return false
	return true

func _return_from_target(source: String) -> Dictionary:
	if not _market_return_edge_active:
		return await super._return_from_target(source)
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	var result: Dictionary={"returned":false,"kind":MARKET_RETURN_KIND,"not_a_direct_paired_return":true,
		"scope":"EXACT_MARKET_TO_CITY_GATE_ORIGINAL_TWO_STEP_INPUT","steps":[],
		"source_scene_id":source,"departure_scene_id":String(definition.scene_id) if definition!=null else "",
		"public_router_shortcut_used":false,"separate_API_credited_as_input":false}
	if not _check(source=="ch4_s3_luoyang_market" and definition!=null and String(definition.scene_id)=="ch4_s0_luoyang_gate","only original Market to_city_gate arrival uses two-step reverse topology"): return result
	if not _check(FileAccess.get_sha256("res://tests/helpers/luoyang_enclosure_v11_city_only_phase.gd")==MARKET_RETURN_PARENT_SHA,"unchanged original complete city-only phase"): return result
	var source_before: Dictionary=_market_return_sources()
	result["original_source_before"]=source_before
	if source_before.size()!=MARKET_RETURN_SOURCE_PINS.size(): return result
	var departures: Array[String]=["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen"]
	var destinations: Array[String]=["ch4_s1_luoyang_yamen","ch4_s3_luoyang_market"]
	var portal_ids: Array[String]=["enter_luoyang","to_south_market"]
	for index in 2:
		var before: Dictionary=_market_live_endpoint(departures[index])
		var original_zone: Dictionary=_market_departure_zone(departures[index],portal_ids[index],destinations[index])
		if not _check(before.complete and original_zone.complete,"exact original reverse zone and legal departure feet for Market return step "+str(index)):
			result.steps.append({"departure":before,"original_zone_binding":original_zone,"returned":false})
			return result
		# Calls the original city-only method, including original planner,
		# full17/Physics callback, follow, enabled-area overlap and Space.
		var step: Dictionary=await super._input_existing_exit_to(destinations[index])
		var arrival: Dictionary=_market_live_endpoint(destinations[index])
		step["departure"]=before
		step["arrival"]=arrival
		step["original_zone_binding"]=original_zone
		step["source_verification"]=source_before.duplicate(true)
		step["input_classification"]="ORIGINAL_NORMAL_SPACE_REVERSE_INPUT"
		step["drive_complete_original_contract"]=_market_original_drive_complete(step.get("drive",{}))
		result.steps.append(step)
		var valid: bool=step.get("returned")==true and step.get("target_scene")==departures[index] and arrival.complete and step.drive_complete_original_contract
		if not _check(valid,"original normal Space reverse step reached exact destination with raw17/Physics and valid zero/nonzero drive"):
			return result
		await _finish_dialogs()
	var source_after: Dictionary=_market_return_sources()
	result["original_source_after"]=source_after
	var final: Dictionary=_market_live_endpoint("ch4_s3_luoyang_market")
	result["final_arrival"]=final
	result["final_market_feet_exact"]=final.get("complete")==true and _point(final.get("foot_px"))==Vector2(1536,770)
	result.returned=result.steps.size()==2 and result.final_market_feet_exact and source_after==source_before
	_check(result.returned,"two original Gate/Yamen Space inputs return legal authored Market feet1536,770 with unchanged source bytes")
	return result

