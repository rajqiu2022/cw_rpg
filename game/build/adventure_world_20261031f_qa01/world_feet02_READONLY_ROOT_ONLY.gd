extends SceneTree
## Root-only bounded source-contract sample; no Field, travel or save API.
const C_PATH: String="res://scripts/world/world_map_v15_contract.gd"
const C=preload("res://scripts/world/world_map_v15_contract.gd")
const SIZE:=Vector2(12288,8192)
var suspended:=false
func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children():_early(node)
	_run.call_deferred()
func _early(node: Node) -> void:
	if node.name==&"PlatformBridge":node.call("set_checkpoint_saves_suspended",true);suspended=bool(node.call("is_checkpoint_saves_suspended"))
func _body_clear(scene: SceneScript,p: Vector2) -> Dictionary:
	if not C.safe_foot(scene,p/SIZE):return {"clear":false,"reason":"ORIGINAL_SAFE_FOOT_REJECT"}
	## Source-only centered34x24 proxy; live transformed actor shape checked later.
	for x: int in range(-17,18):
		for y: int in range(-12,13):
			if not C._pixel_clear(p+Vector2(x,y)):return {"clear":false,"reason":"FULL_PROXY_NAV_PIXEL"}
	var corners:=PackedVector2Array([p+Vector2(-17,-12),p+Vector2(17,-12),p+Vector2(17,12),p+Vector2(-17,12)])
	var box:=Rect2(p-Vector2(17,12),Vector2(34,24))
	for rect: Rect2 in C._blockers:
		if box.intersects(rect,true):return {"clear":false,"reason":"FULL_PROXY_BLOCKER"}
	for polygon: PackedVector2Array in C._solid_polygons:
		if not Geometry2D.intersect_polygons(corners,polygon).is_empty():return {"clear":false,"reason":"FULL_PROXY_SOLID_POLYGON"}
	return {"clear":true,"reason":"SOURCE_SAFE_AND_FULL_PROXY_CLEAR"}
func _run() -> void:
	await process_frame
	var directory: String="res://build/adventure_world_20261031f_qa01/world_feet_actual/"+str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(directory)
	var scene: SceneScript=load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	var centers: Dictionary={"adventure31f_forest":Vector2(6900,4700),"adventure31f_mine":Vector2(5200,6000),"adventure31f_riverside":Vector2(5600,3300)}
	var records: Array=[];var all_center_clear:=true
	for id: String in centers:
		var p: Vector2=centers[id];var direct: Dictionary=_body_clear(scene,p);all_center_clear=all_center_clear and bool(direct.clear)
		var alternatives: Array=[]
		if not direct.clear:
			for delta: Vector2 in [Vector2(64,0),Vector2(-64,0),Vector2(0,64),Vector2(0,-64),Vector2(128,0),Vector2(-128,0),Vector2(0,128),Vector2(0,-128)]:
				var outcome: Dictionary=_body_clear(scene,p+delta);alternatives.append({"foot":p+delta,"result":outcome})
		var nearest_old: Array=[]
		for row: Dictionary in scene.map_layout.portals:
			if row.get("pos") is Vector2 and p.distance_to(row.pos*SIZE)<700:nearest_old.append({"id":row.get("id"),"foot":row.pos*SIZE,"distance":p.distance_to(row.pos*SIZE)})
		records.append({"id":id,"proposed_foot":p,"center":direct,"bounded_alternatives_not_runtime_nearest":alternatives,"old_portals_within700px":nearest_old})
	var output:=FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"passed":suspended and all_center_clear,"checkpoint_suspended":suspended,"records":records,"source_contract":C_PATH,"scene_path":scene.resource_path,"layout_path":scene.map_layout.resource_path,"source_contract_sha256":FileAccess.get_sha256(C_PATH),"source_only_not_physics_or_streaming":true,"scene_instances":0,"input_events":0,"real_save_API_calls":0},"\t"));output.close()
	quit(0 if suspended and all_center_clear else 1)
