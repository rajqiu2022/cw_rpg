extends RefCounted
## NEW fixed wall_street candidate sibling; original predicates remain unchanged.
const SNAPSHOT_ORIGIN_PATH: String = "res://tests/helpers/joint_v15_city_migration_load_probe.gd"
const SNAPSHOT_ORIGIN_SHA: String = "87facd710283439b6ded45f64dba2119a86bc0bfec05e9d0ba061d1613bbca7b"
## NEW real isolated SaveManager loads and ordinary Field births. The expected
## mapping reads immutable old identities + current raw875/source geometry;
## never calls production migration/repair/clearance as its own oracle.
const RAW := preload("res://tests/helpers/joint_v15_wall_v5_ordinary_raw_oracle.gd")
const OLD_RAW := preload("res://tests/helpers/v15_field_raw_oracle.gd")
const CITY := preload("res://scripts/city/luoyang_layered_v3_contract.gd")
const IDS: Array[String]=["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]
const SIZE := Vector2(3072,2048)
const ISOLATED_PATH := "res://tests/helpers/v15_isolated_save_manager.gd"
var phase: RefCounted
var tree: SceneTree
var check_callback: Callable
var checks: int=0
var failures: int=0
var root_dir: String=""
var slots: Node
var raw: RefCounted
var records: Array[Dictionary]=[]
var before_files: Dictionary={}
var before_slot: Variant
var before_navigation: Dictionary={}

func _check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failures+=1
	check_callback.call(ok,"city isolated migration: "+label)
	return ok

func _point(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size()==2: return Vector2(float(value[0]),float(value[1]))
	return Vector2(INF,INF)

func _json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	return value as Dictionary if value is Dictionary else {}

func _slot(values: Array,id: String) -> Dictionary:
	for value: Dictionary in values:
		if String(value.get("source_id",""))==id: return value
	return {}

func _repair(point: Vector2) -> Variant:
	if not point.is_finite() or point.x<0 or point.y<0 or point.x>1 or point.y>1: return null
	if bool(raw.call("clear",point*SIZE)): return point
	for radius in range(4,197,4):
		for angle in 32:
			var candidate: Vector2=point*SIZE+Vector2.from_angle(TAU*angle/32.0)*radius
			if bool(raw.call("clear",candidate)): return candidate/SIZE
	return null

func _old_expectation(old: SceneScript,manifest: Dictionary,point: Vector2,incoming: String="") -> Dictionary:
	var anchors: Array[Dictionary]=[]
	for portal: Dictionary in old.map_layout.portals:
		var slot: Dictionary=_slot(manifest.gameplay_slots.portals,String(portal.id))
		if slot.is_empty(): return {}
		anchors.append({"id":String(portal.id),"old":portal.pos,"new":_point(slot.arrival_foot_px)/SIZE,"target":String(portal.get("target_scene",""))})
	if anchors.is_empty(): return {}
	var nearest: float=INF
	var closest: Dictionary={}
	for anchor: Dictionary in anchors:
		var distance: float=((point-anchor.old)*Vector2(old.map_layout.design_size)).length_squared()
		if distance<nearest: nearest=distance; closest=anchor
	if not incoming.is_empty():
		if incoming in ["world_map_jianghu","world_map_jianghu_staging","world_map_jianghu_v14","world_map_jianghu_v15"]:
			var at: Vector2=_point(manifest.entry_foot_px)/SIZE
			return {"expected":at,"reason":"authored_world_city_entry"} if bool(raw.call("clear",at*SIZE)) else {}
		for anchor: Dictionary in anchors:
			if anchor.target==incoming: closest=anchor; nearest=0; break
	var mapped: Vector2=closest.new
	var reason: String="same_district_portal_anchor"
	if nearest>200.0*200.0:
		var semantic: Array[Dictionary]=anchors.duplicate(true)
		for npc: Dictionary in old.npcs:
			var slot: Dictionary=_slot(manifest.gameplay_slots.npcs,String(npc.npc_id))
			if slot.is_empty(): return {}
			semantic.append({"old":npc.pos,"new":_point(slot.foot_px)/SIZE})
		for interaction: Dictionary in old.map_layout.interactions:
			var slot: Dictionary=_slot(manifest.gameplay_slots.interactions,String(interaction.id))
			if slot.is_empty(): return {}
			semantic.append({"old":interaction.pos,"new":_point(slot.stand_px)/SIZE})
		var delta: Vector2=Vector2.ZERO
		var total: float=0
		for anchor: Dictionary in semantic:
			var weight: float=1.0/maxf(.000001,point.distance_squared_to(anchor.old))
			delta+=(anchor.new-anchor.old)*weight
			total+=weight
		mapped=point+delta/total
		reason="same_district_semantic_interpolation"
	var repaired: Variant=_repair(mapped)
	if not repaired is Vector2 and reason=="same_district_semantic_interpolation":
		var best: Variant=null
		var best_distance: float=196.0*196.0
		for route: Dictionary in manifest.routes:
			var points: Array=route.get("points_px",[])
			for index in range(points.size()-1):
				var candidate: Vector2=Geometry2D.get_closest_point_to_segment(mapped*SIZE,_point(points[index]),_point(points[index+1]))
				var distance: float=(mapped*SIZE).distance_squared_to(candidate)
				if distance<best_distance and bool(raw.call("clear",candidate)): best=candidate/SIZE; best_distance=distance
		if best is Vector2: repaired=best; reason="same_district_local_authored_road_projection"
	if not repaired is Vector2:
		repaired=closest.new if bool(raw.call("clear",closest.new*SIZE)) else null
		reason="same_district_author_anchor_fallback"
	return {"expected":repaired,"reason":reason,"anchor_id":closest.id,"independent_unrepaired_mapping":[mapped.x,mapped.y]} if repaired is Vector2 else {}

func _state() -> Dictionary:
	var state: Dictionary=phase.call("_state")
	var save: Node=tree.root.get_node("SaveManager")
	var game: Node=tree.root.get_node("GameState")
	state["player"]=save.call("_serialize_stats",game.get("player"))
	var party: Array[Dictionary]=[]
	for member: Resource in game.get("party"): party.append(save.call("_serialize_stats",member))
	state["party"]=party
	state["active_slot"]=save.get("active_slot")
	state["field_payload"]=tree.root.get_node("SceneRouter").call("get_field_payload").duplicate(true)
	return state

func _persist_case(name: String,data: Dictionary) -> String:
	var directory: String=root_dir+"/"+name
	var absolute: String=ProjectSettings.globalize_path(directory).simplify_path()
	var allowed: String=ProjectSettings.globalize_path(root_dir).simplify_path()
	if not _check(absolute.begins_with(allowed+"/") and not DirAccess.dir_exists_absolute(absolute),"new case directory has exact owned prefix/no prior overwrite"): return ""
	if not _check(bool(slots.call("configure_directory",directory)),"real SaveManager paths select new owned case"): return ""
	var path: String=slots.call("slot_path",0)
	if not _check(path.begins_with(directory+"/") and not FileAccess.file_exists(path),"isolated case primary is new, not any normal player slot"): return ""
	var file: FileAccess=FileAccess.open(path,FileAccess.WRITE)
	if not _check(file!=null,"isolated case open succeeded"): return ""
	var encoded: String=JSON.stringify(data,"\t")
	file.store_string(encoded)
	file.flush()
	var error: Error=file.get_error()
	file.close()
	if not _check(error==OK and _json(path)==JSON.parse_string(encoded),"every case exact parsed readback before actual load"): return ""
	return FileAccess.get_sha256(path)

func _case(id: String,name: String,template: Dictionary,at: Vector2,version: Variant,expected: Dictionary,missing_version: bool=false,paired: Dictionary={}) -> void:
	var data: Dictionary=template.duplicate(true)
	data.current_field=id
	data.navigation={"current_field":id,"current_field_spawn":[at.x,at.y],"world_map_version":15,"portal_return_spawns":paired,"local_layout_versions":{}}
	if not missing_version: data.navigation.local_layout_versions[id]=version
	var input_sha: String=_persist_case(id+"_"+name,data)
	if input_sha.is_empty(): return
	var world_id: StringName=&"world_map_jianghu_v15" if bool(phase.get("candidate")) else &"world_map_jianghu"
	var path: String=slots.call("slot_path",0)
	var before: Dictionary=_state()
	var preview: StringName=slots.call("get_save_field_id",0,world_id)
	_check(_state()==before,"save preview has zero domain/navigation/payload mutation")
	var loaded: bool=slots.call("load_from_slot",0,world_id)
	if expected.is_empty():
		# Existing get_save_field_id is an identity-only preview, not a local
		# coordinate preparse validator. Only real load must reject the version.
		_check(not loaded and String(preview)==id and _state()==before,"unknown/unsupported local version refuses real load before all gameplay state and navigation mutation")
		records.append({"id":id,"case":name,"actual_input_sha256":input_sha,"isolated_path":path,"loaded":loaded,"zero_mutation":_state()==before})
		return
	if not _check(loaded and String(preview)==id,"real isolated preview/load resolves canonical city identity"): return
	_check(FileAccess.get_sha256(path)==input_sha,"load used precisely this independently persisted case")
	var router: Node=tree.root.get_node("SceneRouter")
	var nav: Dictionary=router.call("get_navigation_state")
	var actual: Vector2=_point(nav.get("current_field_spawn"))
	_check(nav.get("local_layout_versions",{}).get(id)==3 and actual==expected.expected and bool(raw.call("clear",actual*SIZE)),"actual local3 navigation equals independent complete875/17 semantic expectation")
	for key: String in expected.get("paired",{}):
		_check(_point(nav.get("portal_return_spawns",{}).get(key))==expected.paired[key],"actual paired return mapped independently in its own same district")
	router.call("resume_current_field")
	if not _check(bool(await phase.call("_wait_field",id)),"normal production Field really spawned from this loaded slot"): return
	await phase.call("_finish_dialogs")
	var field: Node=phase.get("field")
	var player: Node2D=field.get("_player") as Node2D
	var rebound: bool=phase.call("_bind_field",id)
	var physical_probe: RefCounted=phase.get("probe")
	_check(rebound and player!=null and player.position.distance_to(actual*SIZE)<.03 and bool(raw.call("clear",player.position)) and physical_probe!=null and bool(physical_probe.call("clear",player.position)),"actual ordinary actor birth is migrated foot with real Physics/full875, not preview-only pass")
	_check(bool(slots.call("save_to_slot",1)),"upgraded navigation persisted through real SaveManager in second isolated slot")
	var upgraded: Dictionary=_json(slots.call("slot_path",1))
	var upgraded_point: Vector2=_point(upgraded.get("navigation",{}).get("current_field_spawn"))
	_check(upgraded.get("version")==14 and upgraded.get("navigation",{}).get("local_layout_versions",{}).get(id)==3,"global save schema14 stays distinct from local layout3")
	_check(bool(slots.call("load_from_slot",1,world_id)) and _point(router.call("get_navigation_state").get("current_field_spawn"))==upgraded_point,"actual upgraded reread has no repeated local remap")
	records.append({"id":id,"case":name,"source_local_version":1 if missing_version else version,"input_path":path,"input_sha256":input_sha,"expected":expected,"actual_nav":nav,"actual_birth_px":[player.position.x,player.position.y],"upgraded_path":slots.call("slot_path",1),"upgraded_sha256":FileAccess.get_sha256(slots.call("slot_path",1))})

func run(owner: RefCounted) -> Dictionary:
	if not FileAccess.get_sha256(SNAPSHOT_ORIGIN_PATH).to_lower()==SNAPSHOT_ORIGIN_SHA:
		return {"scope":"ACTUAL_ISOLATED_LOCAL1_AND3_SAVE_LOAD_ORDINARY_FIELD_BIRTH_NOT_MENU_CONTINUE","checks":1,"failures":1,"complete":false,"records":[],"reason":"frozen migration parent bytes changed"}
	phase=owner
	tree=phase.get("tree") as SceneTree
	check_callback=Callable(phase,"_check")
	before_files=phase.call("_normal_files")
	before_slot=tree.root.get_node("SaveManager").get("active_slot")
	before_navigation=tree.root.get_node("SceneRouter").call("get_navigation_state").duplicate(true)
	root_dir="user://world_map_v15_qa/joint_city_migration_%d"%Time.get_ticks_usec()
	var script: Script=load(ISOLATED_PATH) as Script
	if not _check(script!=null and script.can_instantiate(),"real inherited SaveManager loads only in normal autoload context"): return _report()
	slots=script.new() as Node
	script=null
	tree.root.add_child(slots)
	if not _check(bool(slots.call("configure_directory",root_dir)) and bool(slots.call("save_to_slot",0)),"immutable isolated template produced by real SaveManager"): return await _finish()
	var template: Dictionary=_json(slots.call("slot_path",0))
	if not _check(not template.is_empty(),"template contains actual serialized gameplay state"): return await _finish()
	for id: String in IDS:
		if not bool(await phase.call("_open",id)): _check(false,"current ordinary city cannot open; no fabricated migration fixture"); continue
		var definition: SceneScript=(phase.get("field") as Node).get("_current_scene") as SceneScript
		var manifest: Dictionary=phase.get("manifest")
		raw=RAW.new()
		if not _check(bool(raw.call("configure_city",definition,bool(phase.get("candidate")))),"independent current raw875 source ready"): continue
		var old: SceneScript=CITY.legacy_scene(StringName(id))
		if not _check(old!=null and old.map_layout!=null,"hash-bound immutable original city available"): continue
		for portal: Dictionary in old.map_layout.portals:
			var at: Vector2=portal.pos
			var expected: Dictionary=_old_expectation(old,manifest,at)
			_check(not expected.is_empty(),"same-ID old portal has independent native arrival expectation")
			if expected.is_empty(): continue
			await _case(id,"old_explicit_"+String(portal.id),template,at,1,expected)
			await _case(id,"old_missing_"+String(portal.id),template,at,1,expected,true)
			await _case(id,"native_repeat_"+String(portal.id),template,expected.expected,3,{"expected":expected.expected})
			var incoming: String=String(portal.get("target_scene",""))
			var key: String=incoming+"->"+id
			var return_expected: Dictionary=_old_expectation(old,manifest,at,incoming)
			if not return_expected.is_empty():
				await _case(id,"paired_"+String(portal.id),template,at,1,{"expected":expected.expected,"paired":{key:return_expected.expected}},false,{key:[at.x,at.y]})
		var old_raw: RefCounted=OLD_RAW.new()
		var free_count: int=0
		var accepted_points: Array[Vector2]=[]
		if _check(bool(old_raw.call("configure",old.map_layout)),"original source raw navigation is independently readable"):
			for y in range(2,18):
				for x in range(2,18):
					if free_count>=3: break
					var at:=Vector2(x/20.0,y/20.0)
					if not bool(old_raw.call("clear",at*Vector2(old.map_layout.design_size))): continue
					var expected: Dictionary=_old_expectation(old,manifest,at)
					if expected.is_empty() or expected.reason not in ["same_district_semantic_interpolation","same_district_local_authored_road_projection"]: continue
					var no_portal_snap: bool=true
					for native: Dictionary in manifest.gameplay_slots.portals:
						if _point(native.arrival_foot_px).distance_to(expected.expected*SIZE)<2: no_portal_snap=false
					for previous: Vector2 in accepted_points:
						if previous.distance_to(expected.expected*SIZE)<20: no_portal_snap=false
					if not no_portal_snap: continue
					await _case(id,"free_%d"%free_count,template,at,1,expected)
					accepted_points.append(expected.expected*SIZE)
					free_count+=1
		_check(free_count==3,"three genuine independently mapped free points are not all doorway snaps")
		old_raw.call("release")
		old_raw=null
		for unsupported: Variant in [2,99,1.5,"3",true]:
			await _case(id,"unsupported_"+str(unsupported).replace(".","_"),template,_point(manifest.entry_foot_px)/SIZE,unsupported,{})
		raw.call("release")
		raw=null
	_check(records.size()==80,"all 24 missing/explicit old doors +12 native repeats +12 paired returns +12 distinct free points +20 unsupported cases actually recorded")
	return await _finish()

func _finish() -> Dictionary:
	if raw!=null: raw.call("release")
	raw=null
	var ref: WeakRef=weakref(slots) if is_instance_valid(slots) else null
	if is_instance_valid(slots): slots.get_parent().remove_child(slots); slots.queue_free()
	slots=null
	for stage in 8: await tree.process_frame
	_check(ref==null or ref.get_ref()==null,"owned real SaveManager naturally released; no orphan test node")
	_check(before_files==phase.call("_normal_files") and tree.root.get_node("SaveManager").get("active_slot")==before_slot,"all normal primary/bak/tmp bytes and active slot unchanged")
	var result: Dictionary=_report()
	_check(bool(phase.call("_write","actual_local_city_isolated_migration.json",result)),"all real case inputs/load/Field births/evidence checked readback")
	result.checks=checks
	result.failures=failures
	phase=null
	check_callback=Callable()
	return result

func _report() -> Dictionary:
	return {"scope":"ACTUAL_ISOLATED_LOCAL1_AND3_SAVE_LOAD_ORDINARY_FIELD_BIRTH_NOT_MENU_CONTINUE","checks":checks,"failures":failures,"complete":failures==0 and not records.is_empty(),"source_local_versions":[1,3],"isolated_run_root":root_dir,"records":records.duplicate(true),"normal_player_files_unchanged":before_files==phase.call("_normal_files"),"engine_pid":OS.get_process_id(),"source_sha256":FileAccess.get_sha256(get_script().resource_path)}
