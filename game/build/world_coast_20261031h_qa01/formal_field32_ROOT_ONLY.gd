extends "res://build/world_sects_cities_20261031c_qa01/probe_base_ROOT_ONLY.gd"
## Bounded new16 actual gameplay: original ferry choices, both World shores,
## new Bianzhou approach and one original Luoyang Gate. Public local setups only.
const SIZE:=Vector2(12288,8192)
const DISPATCH: String="res://build/world_coast_20261031h_system02/world_contract_dispatch03.gd"
const CONTRACT: String="res://build/world_coast_20261031h_system02/world_v16_contract03.gd"
const LOC: String="res://build/four_settlements_20261030e_system01/locations.gd"
var base_core: Dictionary={}
func _watch() -> void:
	await create_timer(180.0,true,false,true).timeout
	if not done:need(false,"HARD180S_BOUNDED_NEW_COAST");finish()
func boot(_domain: String) -> bool:
	directory="res://build/world_coast_20261031h_qa01/formal_field32_actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	router=root.get_node("SceneRouter")
	if not need(suspended,"EARLIEST_CHECKPOINT_SUSPEND"):return false
	var dispatch: Script=load(DISPATCH) as Script
	var contract: Script=load(CONTRACT) as Script
	if not need(int(dispatch.call("formal_version"))==16 and String(contract.get_script_constant_map().get("MANIFEST_SHA",""))=="022e24149ee224416c66f13b95adc0c7aab3282f3d2d673fd4a3b4e3024d386d","FORMAL16_APPROVED03_MANIFEST_NOT_OLD15"):return false
	return need(load("res://build/three_towns_world_20261029j_system01/town_registry.gd").source_valid(),"FORMAL_NATIVE_SOURCE_READY")
func core() -> Dictionary:
	var game: Node=root.get_node("GameState");var player: Resource=game.get("player") as Resource;var party: Array=[]
	for member: Resource in game.get("party"):party.append(member.get_instance_id())
	return {"player_instance":player.get_instance_id(),"hp":player.get("hp"),"mp":player.get("mp"),"gold":game.get("gold"),"party_instances":party}
func setup(id: StringName,uv: Variant,version: int=-1) -> bool:
	key(KEY_NONE);var old: int=current_scene.get_instance_id() if current_scene!=null else 0
	records.append({"public_local_setup_not_continuous_travel":id,"uv":uv,"world_version":16 if id==&"world_map_jianghu" else -1,"local_version":version})
	if not need(router.call("go_field_smart",id,uv,"",16 if id==&"world_map_jianghu" else -1,version)==true,"PUBLIC_SETUP:"+String(id)):return false
	return await ready_field(id,old)
func portal(id: String) -> Dictionary:
	for row: Dictionary in (field.get("_current_scene") as Resource).get("map_layout").get("portals"):
		if String(row.id)==id:return row
	return {}
func tap(code: Key) -> void:key(code);await tick();key(KEY_NONE);await tick()
func ferry(source: StringName,target: StringName) -> bool:
	var list: Array=field.get("_npc_nodes")
	if not need(not list.is_empty(),"ORIGINAL_BOATMAN_PRESENT:"+String(source)):return false
	var npc: Node2D=list[0] as Node2D
	var near: Vector2=world.to_local(npc.global_position)+Vector2(-65,20)
	var size: Vector2=load(LOC).town(source).size
	if not await setup(source,near/size,3001):return false
	await space()
	var dialog: Node=root.get_node("DialogPlayer");var node: Resource
	for index: int in range(14):
		for tick_index: int in range(3):await tick()
		node=dialog.get("_current_node") as Resource
		if node!=null and bool(node.call("has_choices")):break
		await space()
	if not need(node!=null and bool(node.call("has_choices")),"TRUE_BOAT_CHOICES_AFTER_HERO_OPENING:"+String(source)):return false
	records.append({"original_ferry_source":source,"original_ferry_target":target,"displayed_text":node.get("text"),"true_numeric_choice":1})
	var old: int=current_scene.get_instance_id();await tap(KEY_1)
	if not await ready_field(target,old):return false
	var row: Dictionary=load(LOC).town(target);var expected: Vector2=vec(row.returns[String(source)])
	return need(foot().distance_to(expected)<.01 and core()==base_core,"REAL_BOAT_TRAVEL_CORRECT_ORIGINAL_LANDING_AND_NO_FEE:"+String(target))
func shore_return(id: StringName,expected_world: Vector2,image_label: String) -> bool:
	var row: Dictionary=load(LOC).town(id);var exit_foot: Vector2=vec(row.returns.world_map_jianghu)
	if not await setup(id,exit_foot/row.size,3001):return false
	var door: ExitZone
	for candidate: ExitZone in field.get("_exit_nodes"):
		if candidate.target_scene_id=="world_map_jianghu":door=candidate;break
	if not need(door!=null and bool(door.call("_can_enter")) and door.overlaps_body(actor),"REAL_SHORE_RETURN_DOOR_OVERLAP:"+String(id)):return false
	if not await enter(&"world_map_jianghu"):return false
	if not need(foot().distance_to(expected_world)<.02,"ACTUAL_WORLD_SHORE16_EXACT_ORIGINAL_FOOT:"+String(id)):return false
	var scene: Resource=field.get("_current_scene") as Resource
	if not need(router.call("layered_world_contract",scene)==load(CONTRACT) and load(CONTRACT).safe_foot(scene,foot()/SIZE),"ACTUAL_FIELD_BOUND_TO_NEW16_AND_SHORE_SAFE"):return false
	await shot(image_label)
	return true
func _run() -> void:
	if not await boot("coast32"):finish();return
	base_core=core()
	if not await setup(&"openworld_bailu_ferry",null):finish();return
	if not await ferry(&"openworld_bailu_ferry",&"openworld_east_sea_port"):finish();return
	if not await shore_return(&"openworld_east_sea_port",Vector2(11700,3417.3652),"new_island_actual_normal_world"):finish();return
	var east: Dictionary=portal("east_sea_port")
	if not need(not east.is_empty(),"ORIGINAL_EAST_ISLAND_WORLD_PORTAL"):finish();return
	if not await enter(&"openworld_east_sea_port"):finish();return
	if not await ferry(&"openworld_east_sea_port",&"openworld_bailu_ferry"):finish();return
	if not await shore_return(&"openworld_bailu_ferry",Vector2(9300,4301.3623),"mainland_ferry_actual_normal_world"):finish();return
	if not await setup(&"world_map_jianghu",Vector2(7600,1800)/SIZE):finish();return
	if not await walk(Vector2(7632,1800),12):finish();return
	await shot("bianzhou_offset_approach_and_front_plaza")
	if not await setup(&"world_map_jianghu",Vector2(7600,1556.8779296875)/SIZE):finish();return
	var bian: Dictionary=portal("bianzhou");var bdoor: ExitZone
	for candidate: ExitZone in field.get("_exit_nodes"):
		if candidate.get_meta("portal_id","")=="bianzhou":bdoor=candidate;break
	if not need(not bian.is_empty() and bdoor!=null and bool(bdoor.call("can_enter")),"NEW_BIANZHOU_GATE_REAL_CAN_ENTER"):finish();return
	if not await setup(&"world_map_jianghu",Vector2(4000,2594.4912)/SIZE):finish();return
	var gate: ExitZone
	for candidate: ExitZone in field.get("_exit_nodes"):
		if candidate.target_scene_id=="ch4_s0_luoyang_gate":gate=candidate;break
	if not need(gate!=null and bool(gate.call("can_enter")),"FORMAL16_ORIGINAL_LUOYANG_DOOR_CAN_ENTER"):finish();return
	if not await enter(&"ch4_s0_luoyang_gate"):finish();return
	var arrival: Vector2=foot()
	if not await walk(arrival+Vector2(32,0),12):finish();return
	await shot("formal16_original_luoyang_gate_true_entry")
	need(core()==base_core,"ORIGINAL_PLAYER_PARTY_HP_MP_GOLD_PRESERVED")
	finish()
func finish() -> void:
	if done:return
	key(KEY_NONE);done=true
	var file:=FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"input_events":inputs,"scope":"formal16 two actual boat choices, both shore16 returns, offsetBianzhou localshortleg/can_enter and one originalLuoyang Gate; public local setups are not continuous world travel; no old city/battle matrix","real_save_API_calls":0,"actor_camera_writes":0,"production_writes":0},"\t"));file.close()
	quit(0 if errors.is_empty() else 1)
