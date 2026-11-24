extends SceneTree
## Exact return-coordinate regression. No field, input, gameplay or save loads.
var failures: Array[String]=[]
var checks: int=0
var rows: Array[Dictionary]=[]
func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for child: Node in root.get_children():_early(child)
	_run.call_deferred()
func _early(node: Node) -> void:
	if node.name==&"PlatformBridge":node.call("set_checkpoint_saves_suspended",true)
func need(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);printerr("SECT_WORLD_RETURN_FAIL ",label)
func _run() -> void:
	var reg: Script=load("res://build/three_towns_world_20261029j_system01/town_registry.gd")
	var router: Node=root.get_node("SceneRouter")
	need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"CHECKPOINTS_SUSPENDED")
	need(reg.can_instantiate(),"REGISTRY_COMPILES")
	need(reg.source_valid(),"NATIVE_SOURCES_EXACT_NOT_WEAKENED")
	var layout: WalkableMapLayout=load("res://data/maps/world_map_jianghu_layout_v15.tres")
	need(layout.schema_version==15 and Vector2(layout.design_size)==reg.WORLD_SIZE,"CURRENT_WORLD_COORDINATE_SPACE")
	for id: StringName in reg.IDS:
		var row: Dictionary=reg.town(id)
		var foot: Variant=row.get("world_foot")
		need(foot is Vector2,"ALL_REGISTERED_IDS_HAVE_WORLD_FOOT:"+String(id))
		if not foot is Vector2:continue
		need(foot.is_finite() and foot.x>=0 and foot.y>=0 and foot.x<reg.WORLD_SIZE.x and foot.y<reg.WORLD_SIZE.y,"VALID_WORLD_FOOT:"+String(id))
		for world: StringName in reg.WORLDS:
			var actual: Variant=router.call("get_world_map_position_for_scene",id,world)
			need(actual is Vector2 and (actual*reg.WORLD_SIZE).distance_to(foot)<.01,"REAL_ROUTER_RETURN:"+String(id)+":"+String(world))
		if not reg.SECT_IDS.has(id):continue
		var portal_id: StringName=router.WORLD_MAP_REGION_PORTALS[id]
		var matched: bool=false
		for portal: Dictionary in layout.portals:
			if String(portal.get("id"))!=String(portal_id):continue
			matched=true
			need(String(portal.target_scene)==String(id) and (portal.pos*reg.WORLD_SIZE).distance_to(foot)<.01,"ORIGINAL_WORLD_DOOR_UNCHANGED:"+String(id))
			rows.append({"id":String(id),"portal_id":String(portal_id),"expected_normalized":portal.pos,"actual_normalized":router.call("get_world_map_position_for_scene",id),"world_foot":foot})
		need(matched,"ORIGINAL_PORTAL_EXISTS:"+String(id))
	need(current_scene==null and get_nodes_in_group("player").is_empty(),"NO_GAME_FIELD_OR_ACTOR_INSTANCES")
	var path: String="res://build/sect_world_return_20261030i_root01/result_%d.json"%OS.get_process_id()
	var file:=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"errors":failures,"sect_returns":rows,"all_registry_ids":reg.IDS.size(),"scope":"REAL_ROUTER_COORDINATE_METHODS_ONLY_NOT_PHYSICAL_EXIT_TRAVEL","input_events":0,"field_instances":0,"save_loads":0,"save_writes":0},"\t")+"\n");file.close()
	print("SECT_WORLD_RETURN_RESULT ",checks," / ",failures.size()," ",path)
	quit(0 if failures.is_empty() else 1)
