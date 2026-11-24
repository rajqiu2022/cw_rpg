extends SceneTree
var town: Node2D
var graph:=AStar2D.new()
var ids: Dictionary={}
var levels: Dictionary={}
var checks: Array=[]
var traces: Array=[]
var input_ticks:=0
const CELL:=30
func check(ok: bool,label: String,detail: Variant=null) -> void:
	checks.append({"pass":ok,"label":label,"detail":detail})
	if not ok:print("FAIL ",label," ",detail)
func ticks(n: int) -> void:
	for i in range(n):await physics_frame
func key(code: Key,pressed: bool) -> void:
	var e:=InputEventKey.new();e.physical_keycode=code;e.keycode=code;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
func empty_at(p: Vector2,level: int) -> bool:
	var q:=PhysicsShapeQueryParameters2D.new();var shape:=RectangleShape2D.new();shape.size=Vector2(43,33);q.shape=shape;q.transform=Transform2D(0,p);q.collision_mask=8|town.terrain.layer(level)
	return town.get_world_2d().direct_space_state.intersect_shape(q,1).is_empty()
func make_graph() -> void:
	graph.clear();ids.clear();levels.clear()
	for y in range(5,int(town.layout.size[1])/CELL-3):
		for x in range(5,int(town.layout.size[0])/CELL-3):
			var p:=Vector2(x,y)*CELL;var level:=int(town.terrain.level_at(p))
			if not empty_at(p,level):continue
			var id:=graph.get_available_point_id();graph.add_point(id,p);ids[Vector3i(x,y,level)]=id;levels[id]=level
	for q: Vector3i in ids:
		for step: Vector3i in [Vector3i(1,0,0),Vector3i(0,1,0)]:
			if ids.has(q+step):graph.connect_points(ids[q],ids[q+step])
func near(p: Vector2,level: int) -> int:
	var best: int=-1;var distance:=INF;var c:=Vector2i(roundi(p.x/CELL),roundi(p.y/CELL))
	for x in range(c.x-4,c.x+5):
		for y in range(c.y-4,c.y+5):
			var q:=Vector3i(x,y,level)
			if not ids.has(q):continue
			var id:=int(ids[q]);var d: float=p.distance_squared_to(graph.get_point_position(id))
			if d<distance:distance=d;best=id
	return best
func move_exact(p: Vector2,tolerance: float=7.0) -> bool:
	var code: Key=KEY_NONE;var previous:=Vector2.INF;var stuck:=0
	for i in range(1000):
		var d: Vector2=p-town.actor.position
		if d.length()<tolerance:break
		if previous.distance_squared_to(town.actor.position)<.01:stuck+=1
		else:stuck=0
		if stuck>10:
			if code!=KEY_NONE:await key(code,false)
			print("BLOCKED ",town.actor.position," -> ",p)
			for ci in range(town.actor.get_slide_collision_count()):print("COLLIDER ",town.actor.get_slide_collision(ci).get_collider().get_path())
			return false
		previous=town.actor.position
		var next: Key=(KEY_D if d.x>0 else KEY_A) if absf(d.x)>absf(d.y) else (KEY_S if d.y>0 else KEY_W)
		if next!=code:
			if code!=KEY_NONE:await key(code,false)
			code=next;await key(code,true)
		await physics_frame;input_ticks+=1
	if code!=KEY_NONE:await key(code,false)
	return town.actor.position.distance_to(p)<tolerance+3
func walk_to(p: Vector2,level: int) -> bool:
	var a:=near(town.actor.position,level);var b:=near(p,level)
	if a<0 or b<0:return false
	for id: int in levels:graph.set_point_disabled(id,int(levels[id])!=level)
	var path: PackedInt64Array=graph.get_id_path(a,b)
	for id: int in levels:graph.set_point_disabled(id,false)
	if path.is_empty():return false
	for id in path:
		if not await move_exact(graph.get_point_position(id)):return false
	return await move_exact(p)
func stairs(id: String,up: bool) -> bool:
	var r: Dictionary={}
	for row: Dictionary in town.terrain.ramps:
		if row.id==id:r=row
	var endpoint:=Vector2(r.bottom[0],r.bottom[1]+50) if up else Vector2(r.top[0],r.top[1]-50)
	if not await walk_to(endpoint,int(r.low) if up else int(r.high)):return false
	var target_y:=float(r.top[1])-45 if up else float(r.bottom[1])+45
	var code:=KEY_W if up else KEY_S;await key(code,true)
	for i in range(200):
		await physics_frame;input_ticks+=1;traces.append([town.layout.key,town.actor.position.x,town.actor.position.y,town.terrain.actor_height])
		if (up and town.actor.position.y<target_y) or (not up and town.actor.position.y>target_y):break
	await key(code,false);await ticks(2)
	return town.terrain.actor_level==(int(r.high) if up else int(r.low))
func cross_bridge(index: int,east: bool) -> bool:
	var b: Dictionary=town.layout.bridges[index];var y: float=(float(b.walk_y[0])+float(b.walk_y[1]))*.5
	var start:=Vector2(b.center[0]+(-540 if east else 540),y)
	if not await walk_to(start,0):return false
	# Align on the native deck center before traversing the narrow low bridge.
	return await move_exact(Vector2(b.center[0]+(500 if east else -500),y))
func shot(name: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://artifacts-k/"+name+".png")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for map: String in ["wudang","mingwu"]:
		town=load("res://scenes/drafts/sect_maps_20261029k/"+map+".tscn").instantiate();root.add_child(town);await ticks(4);make_graph()
		town.view_mode=0;town.update_view();await shot(map+"_overview02");town.view_mode=1
		if map=="wudang":
			check(await stairs("MainRise",true),"wudang continuous spawn-gate-main stair")
			check(await stairs("HallRise",true),"wudang continuous court-hall stair")
			check(await walk_to(Vector2(2700,1190),2),"wudang continuous arrival main hall")
			await shot("wudang_hall02")
			check(await stairs("LibraryRise",false),"wudang east return stair")
			check(await walk_to(Vector2(3990,1870),1),"wudang scripture courtyard reachable")
			check(await stairs("ServiceRise",false),"wudang service route closes loop")
		else:
			check(await cross_bridge(0,true),"mingwu continuous spawn-guest bridge-east bank")
			check(await stairs("GuestRise",true),"mingwu flat bank to inner court")
			check(await stairs("ManorRise",true),"mingwu courtyard to manor")
			check(await walk_to(Vector2(4080,1350),2),"mingwu continuous arrival main hall")
			await shot("mingwu_hall02")
			check(await stairs("SideRise",false),"mingwu side court descent")
			check(await stairs("FreightRise",false),"mingwu freight court descent")
			check(await cross_bridge(1,false),"mingwu tea bridge returns west bank")
			check(await walk_to(Vector2(1620,1450),0),"mingwu tea workshop service route")
			await shot("mingwu_workshop02")
		town.queue_free();await process_frame;await process_frame
	var failures:=0
	for row: Dictionary in checks:
		if not row.pass:failures+=1
	var f:=FileAccess.open("res://artifacts-k/routes02.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"input_ticks":input_ticks,"traces":traces},"\t"));f.close()
	print("ROUTES ",checks.size()," FAILURES ",failures," INPUT ",input_ticks);quit(0 if failures==0 else 1)
