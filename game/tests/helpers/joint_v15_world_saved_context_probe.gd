extends RefCounted
## Actual inherited SaveManager + ordinary Field births for genuinely FREE old
## world coordinates and indoor saved contexts. Every input has its own owned
## directory/readback SHA; pure prepare/previous 48 portals cannot substitute.
const ISOLATED := "res://tests/helpers/v15_isolated_save_manager.gd"
const SIZE := Vector2(12288,8192)
const OLD := {12:"res://data/maps/world_map_jianghu_legacy_v12_scene.tres",13:"res://data/scenes/world_map_jianghu_v13_staging.tres",14:"res://data/scenes/world_map_jianghu_v14.tres"}
const INDOORS: Array[String]=["openworld_bianzhou_city","openworld_wudang_gate","linxi_village_scrollmap"]
var phase: RefCounted
var tree: SceneTree
var slots: Node
var directory: String
var template: Dictionary={}
var raw: RefCounted
var records: Array[Dictionary]=[]
var checks: int=0
var failures: int=0

func _check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failures+=1
	phase.call("_check",ok,"world free/indoor save context: "+label)
	return ok

func _point(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size()==2: return Vector2(float(value[0]),float(value[1]))
	return Vector2(INF,INF)

func _persist_case(name: String,data: Dictionary) -> Dictionary:
	var owned: String=directory+"/"+name
	var absolute: String=ProjectSettings.globalize_path(owned).simplify_path()
	var prefix: String=ProjectSettings.globalize_path(directory).simplify_path()+"/"
	if not absolute.begins_with(prefix) or DirAccess.dir_exists_absolute(absolute) or not bool(slots.call("configure_directory",owned)): return {}
	var path: String=String(slots.call("slot_path",0))
	if not path.begins_with(owned+"/") or not path.begins_with("user://world_map_v15_qa/") or FileAccess.file_exists(path): return {}
	var file: FileAccess=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return {}
	var encoded: String=JSON.stringify(data,"\t")
	file.store_string(encoded)
	file.flush()
	var error: Error=file.get_error()
	file.close()
	if error!=OK or JSON.parse_string(FileAccess.get_file_as_string(path))!=JSON.parse_string(encoded): return {}
	return {"primary_path":path,"sha256":FileAccess.get_sha256(path),"actual_input":data.duplicate(true)}

func _load(data: Dictionary,name: String,expected_id: StringName,expected_root: Vector2,kind: String) -> Dictionary:
	var persisted: Dictionary=_persist_case(name,data)
	if not _check(not persisted.is_empty(),"unique test-owned case content flush/readback verified"): return {}
	if not _check(bool(phase.call("_write_json",name+"_input.json",persisted)),"input bytes/SHA recorded before actual preview/load"): return {}
	var current_world: StringName=phase.get("scene_id")
	_check(slots.call("get_save_field_id",0,current_world)==expected_id,"real preview selects exact expected scene identity")
	if not _check(bool(slots.call("load_from_slot",0,current_world)),"actual SaveManager applies precisely this historic context"): return {}
	_check(FileAccess.get_sha256(String(persisted.primary_path))==persisted.sha256,"case immutable bytes not replaced by another sample during load")
	var router: Node=tree.root.get_node("SceneRouter")
	var nav: Dictionary=router.call("get_navigation_state")
	var actual_root: Vector2=_point(nav.get("current_field_spawn"))
	_check(String(nav.get("current_field",""))==String(expected_id) and int(nav.get("world_map_version",-1))==15 and actual_root==expected_root,"actual stored coordinate/scene agrees with independent expectation")
	router.call("resume_current_field")
	if not bool(await phase.call("_wait_field",expected_id)) or not bool(await phase.call("_normal_intro")): return {}
	var field: Node=phase.get("field")
	var player: Node2D=field.get("_player") as Node2D
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	var size: Vector2=field.get("_world_size")
	var legal: bool=false
	if expected_id==current_world: legal=bool(raw.call("clear",player.position)) and bool(phase.call("_physical_clear",player.position))
	elif bool(phase.call("_configure_ordinary",definition)): legal=bool(phase.call("_ordinary_clear",player.position))
	_check(player.position.distance_to(expected_root*size)<.02 and legal,"real normal Field exact birth with independent source feet plus actual Physics")
	var first_native: Dictionary=router.call("get_navigation_state")
	if not _check(bool(slots.call("save_to_slot",1)),"actual upgraded native state saved only in owned second slot"): return {}
	var native_path: String=String(slots.call("slot_path",1))
	var saved: Variant=JSON.parse_string(FileAccess.get_file_as_string(native_path))
	_check(saved is Dictionary and saved.get("version")==14 and (saved.get("navigation",{}) as Dictionary).get("world_map_version")==15,"save schema14 is distinct from world coordinate15")
	_check(bool(slots.call("load_from_slot",1,current_world)) and router.call("get_navigation_state")==first_native,"real persisted version15 reread is complete navigation identity, no second repair/remap")
	return {"kind":kind,"source_version":(data.navigation as Dictionary).get("world_map_version",-1),"input":persisted,"expected_root":[expected_root.x,expected_root.y],"actual_birth_px":[player.position.x,player.position.y],"actual_birth_physical_clear":legal,"loaded_navigation":nav,"native_navigation":first_native,"native_slot_path":native_path,"native_slot_sha256":FileAccess.get_sha256(native_path)}

func _free_cases(version: int,old: SceneScript) -> void:
	if not bool(phase.call("_configure_ordinary",old)): return
	var accepted: int=0
	var distinct: Array[Vector2]=[]
	for y in range(1,16):
		for x in range(1,16):
			var p:=Vector2(float(x)/16,float(y)/16)
			if not bool(phase.call("_ordinary_static_clear",p*Vector2(old.map_layout.design_size))): continue
			var expectation: Dictionary=phase.call("_independent_historic_mapping",old,p)
			if expectation.get("kind")!="independent_local_free_mapping": continue
			var expected: Vector2=expectation.get("expected",Vector2(INF,INF))
			if not expected.is_finite() or not bool(raw.call("clear",expected*SIZE)): continue
			var nearest: float=INF
			var world: SceneScript=phase.get("world") as SceneScript
			for portal: Dictionary in world.map_layout.portals: nearest=minf(nearest,((expected-_point(portal.pos))*SIZE).length())
			if nearest<=64: continue
			var repeated: bool=false
			for previous: Vector2 in distinct: repeated=repeated or previous.distance_to(expected*SIZE)<20
			if repeated: continue
			var data: Dictionary=template.duplicate(true)
			data.current_field=String(old.scene_id)
			data.navigation={"current_field":String(old.scene_id),"current_field_spawn":[p.x,p.y],"world_map_version":version,"portal_return_spawns":{}}
			var record: Dictionary=await _load(data,"free_v%d_%d"%[version,accepted],phase.get("scene_id"),expected,"FREE_GEOGRAPHY_NOT_PORTAL_SNAP")
			if not record.is_empty():
				record["source_resource_sha256"]=FileAccess.get_sha256(OLD[version])
				record["old_root"]= [p.x,p.y]
				record["independent_mapping"]=expectation
				record["nearest_portal_distance_px"]=nearest
				records.append(record)
				distinct.append(expected*SIZE)
				accepted+=1
			# Rebind the independent old layout after actual Field load changed it.
			if not bool(phase.call("_configure_ordinary",old)): break
			if accepted==3: break
		if accepted==3: break
	_check(accepted==3,"three actual distinct nonportal historical FREE saves per source version")

func _indoor_cases(version: int,old: SceneScript) -> void:
	for id: String in INDOORS:
		var definition: SceneScript=load("res://data/scenes/"+id+".tres") as SceneScript
		if not _check(definition!=null and definition.map_layout!=null and bool(phase.call("_configure_ordinary",definition)),"actual original indoor/local scene resource"): continue
		var inner: Vector2=definition.player_spawn
		if not _check(bool(phase.call("_ordinary_static_clear",inner*Vector2(definition.map_layout.design_size))),"indoor fixture uses actual source default legal root, not a fake white point"): continue
		var anchor: Vector2=Vector2(INF,INF)
		for portal: Dictionary in old.map_layout.portals:
			if String(portal.get("target_scene",""))==id: anchor=_point(portal.pos); break
		if not _check(anchor.is_finite(),"original corresponding world door exists for indoor saved context"): continue
		var expected: Dictionary=phase.call("_independent_historic_mapping",old,anchor)
		var target_world: String=String(phase.get("scene_id"))
		var data: Dictionary=template.duplicate(true)
		data.current_field=id
		data.navigation={"current_field":id,"current_field_spawn":[inner.x,inner.y],"world_map_version":version,"portal_return_spawns":{id+"->"+String(old.scene_id):[anchor.x,anchor.y],String(old.scene_id)+"->"+id:[inner.x,inner.y]}}
		var record: Dictionary=await _load(data,"indoor_v%d_%s"%[version,id],StringName(id),inner,"INDOOR_COORDINATE_UNCHANGED_WORLD_SIDE_REMAPPED")
		if record.is_empty(): continue
		var nav: Dictionary=record.loaded_navigation
		var returns: Dictionary=nav.get("portal_return_spawns",{})
		_check(_point(returns.get(id+"->"+target_world))==expected.get("expected") and _point(returns.get(target_world+"->"+id))==inner,"actual indoor save preserves exact inner coordinate and repairs only corresponding world-side memory/key")
		record["independent_world_expected"]=expected
		records.append(record)

func _domain_snapshot() -> Dictionary:
	var state: Node=tree.root.get_node("GameState")
	var manager: Node=tree.root.get_node("SaveManager")
	var player: Dictionary=manager.call("_serialize_stats",state.get("player"))
	var party: Array[Dictionary]=[]
	for member: Resource in state.get("party"): party.append(manager.call("_serialize_stats",member))
	var result: Dictionary={"player":player,"party":party,"flags":(state.get("flags") as Dictionary).duplicate(true),"gold":state.get("gold"),"chapter":state.get("current_chapter"),"reputation":state.get("reputation"),"training":state.get("training_points_total"),"active_slot":manager.get("active_slot"),"normal_files":phase.call("_actual_saves"),"navigation":tree.root.get_node("SceneRouter").call("get_navigation_state")}
	for singleton: String in ["Inventory","QuestManager","BountyManager","InvestigationState"]: result[singleton]=tree.root.get_node(singleton).call("to_dict")
	return result

func _unknown_cases() -> void:
	for version: Variant in [-1,16,99,15.5,"15",true]:
		var data: Dictionary=template.duplicate(true)
		var id: String=String(phase.get("scene_id"))
		data.current_field=id
		data.gold=int(data.get("gold",0))+313
		data.flags={"qa_unknown_version_must_not_apply":true}
		data.navigation={"current_field":id,"current_field_spawn":[.5,.5],"world_map_version":version,"portal_return_spawns":{}}
		var before: Dictionary=_domain_snapshot()
		var name: String="unsupported_v_"+str(records.size())
		var input: Dictionary=_persist_case(name,data)
		if not _check(not input.is_empty() and bool(phase.call("_write_json",name+"_input.json",input)),"unsupported real input bytes are isolated/persisted before load"): continue
		var loaded: bool=slots.call("load_from_slot",0,phase.get("scene_id"))
		var after: Dictionary=_domain_snapshot()
		_check(not loaded and before==after,"unknown world version rejects actual SaveManager load before all domain/slot/navigation mutations")
		records.append({"kind":"UNKNOWN_VERSION_REJECTED_ZERO_MUTATION","input":input,"source_version":version,"loaded":loaded,"before":before,"after":after,"zero_mutation":before==after})

func run(owner: RefCounted) -> Dictionary:
	phase=owner
	tree=phase.get("owner_tree") as SceneTree
	raw=phase.get("oracle") as RefCounted
	directory="user://world_map_v15_qa/free_indoor_%d"%Time.get_ticks_usec()
	var script: Script=load(ISOLATED) as Script
	if not _check(script!=null and script.can_instantiate(),"real inherited SaveManager in registered autoload context"): return await _finish()
	slots=script.new() as Node
	if not _check(slots!=null and bool(slots.call("configure_directory",directory)),"new owned manager and unique template directory"): return await _finish()
	tree.root.add_child(slots)
	if not _check(bool(slots.call("save_to_slot",0)),"serialize current actual state to immutable isolated template"): return await _finish()
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(String(slots.call("slot_path",0))))
	if not _check(parsed is Dictionary,"actual template JSON"): return await _finish()
	template=parsed
	for version: int in [12,13,14]:
		var old: SceneScript=load(OLD[version]) as SceneScript
		if not _check(old!=null and old.map_layout!=null,"real immutable historical world resource"): continue
		await _free_cases(version,old)
		await _indoor_cases(version,old)
	await _unknown_cases()
	_check(records.size()==24,"actual9 free-world +9 indoor historic load/Field/native15 identity and6 unknown-zero-mutation cases")
	return await _finish()

func _finish() -> Dictionary:
	var reference: WeakRef=weakref(slots) if is_instance_valid(slots) else null
	if is_instance_valid(slots):
		if slots.get_parent()!=null: slots.get_parent().remove_child(slots)
		slots.queue_free()
	slots=null
	for settle in 8: await tree.process_frame
	_check(reference==null or reference.get_ref()==null,"owned isolated manager/case references naturally released")
	var result: Dictionary={"scope":"ACTUAL24_FREE_INDOOR_AND_UNKNOWN_SAVE_LOAD_NORMAL_FIELD_NOT_MENU","checks":checks,"failures":failures,"complete":failures==0 and records.size()==24,"records":records.duplicate(true),"isolated_root":directory,"executing_script_path":get_script().resource_path,"executing_script_sha256":FileAccess.get_sha256(get_script().resource_path)}
	_check(bool(phase.call("_write_json","actual_free_indoor_saved_contexts.json",result)),"full free/indoor actual case index checked persistence")
	result.checks=checks
	result.failures=failures
	result.complete=failures==0 and records.size()==24
	template.clear()
	raw=null
	phase=null
	tree=null
	return result
