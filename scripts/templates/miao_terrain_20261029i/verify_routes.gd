extends SceneTree
var town: Node2D
var graph:=AStar2D.new()
var ids: Dictionary={}
var points: Dictionary={}
var levels: Dictionary={}
var checks: Array=[]
var input_ticks:=0
var links: Array=[]
var traces: Array=[]
const CELL:=30
const OFFSET:=Vector2(-900,-600)

func check(value: bool,label: String,detail: Variant=null) -> void:
	checks.append({"pass":value,"label":label,"detail":detail})
	if not value:print("FAIL ",label," ",detail)
func ticks(n: int) -> void:
	for i in range(n):await physics_frame
func key(code: Key,pressed: bool) -> void:
	var e:=InputEventKey.new();e.physical_keycode=code;e.keycode=code;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events()
	await process_frame
func empty_at(p: Vector2,level: int) -> bool:
	var q:=PhysicsShapeQueryParameters2D.new();var shape:=RectangleShape2D.new();shape.size=Vector2(43,33);q.shape=shape;q.transform=Transform2D(0,p);q.collision_mask=8|town.terrain.layer(level)
	return town.get_world_2d().direct_space_state.intersect_shape(q,1).is_empty()
func node_near(p: Vector2,level: int) -> int:
	var best: int=-1;var distance:=INF;var center:=Vector2i(roundi((p.x-OFFSET.x)/CELL),roundi((p.y-OFFSET.y)/CELL))
	for x in range(center.x-3,center.x+4):
		for y in range(center.y-3,center.y+4):
			var lookup:=Vector3i(x,y,level)
			if not ids.has(lookup):continue
			var id:=int(ids[lookup]);var d: float=graph.get_point_position(id).distance_squared_to(p)
			if d<distance:distance=d;best=id
	return best
func make_graph() -> void:
	for y in range(190):
		for x in range(300):
			var p:=OFFSET+Vector2(x,y)*CELL;var level:=int(town.terrain.level_at(p))
			if not empty_at(p,level):continue
			var id:=graph.get_available_point_id();graph.add_point(id,p);var lookup:=Vector3i(x,y,level);ids[lookup]=id;points[id]=p;levels[id]=level
	for lookup: Vector3i in ids:
		for step: Vector3i in [Vector3i(1,0,0),Vector3i(0,1,0)]:
			if ids.has(lookup+step):graph.connect_points(ids[lookup],ids[lookup+step])
	for r: Dictionary in town.terrain.ramps:
		var a:=node_near(Vector2(r.bottom[0],r.bottom[1]+45),int(r.low));var b:=node_near(Vector2(r.top[0],r.top[1]-45),int(r.high))
		check(a>=0 and b>=0,"stair endpoints have ground navigation nodes "+r.id,[a,b])
		if a>=0 and b>=0:graph.connect_points(a,b);links.append({"ramp":r.id,"low":int(r.low),"high":int(r.high),"a":a,"b":b})
	print("NAV_NODES ",graph.get_point_count())
func walk_to(p: Vector2,level: int) -> bool:
	var start:=node_near(town.actor.global_position,level);var target:=node_near(p,level)
	if start<0 or target<0:return false
	# A same-floor approach may not take a shortcut up and down another stair.
	for id: int in levels:graph.set_point_disabled(id,int(levels[id])!=level)
	var route: PackedInt64Array=graph.get_id_path(start,target)
	for id: int in levels:graph.set_point_disabled(id,false)
	if route.is_empty():return false
	for id in route:
		if int(levels[id])!=level:return false
		var waypoint: Vector2=points[id];var code: Key=KEY_NONE;var previous:=Vector2.INF;var stuck:=0
		for i in range(100):
			var d: Vector2=waypoint-town.actor.global_position
			if d.length()<8:break
			if previous.distance_squared_to(town.actor.global_position)<.01:stuck+=1
			else:stuck=0
			if stuck>8:
				print("PATH_BLOCKED ",town.actor.global_position," target ",waypoint," mask ",town.actor.collision_mask," slides ",town.actor.get_slide_collision_count()," velocity ",town.actor.velocity," W ",Input.is_physical_key_pressed(KEY_W)," code ",code)
				if code!=KEY_NONE:await key(code,false)
				for ci in range(town.actor.get_slide_collision_count()):print("BLOCKER ",town.actor.get_slide_collision(ci).get_collider().get_path())
				return false
			previous=town.actor.global_position
			var next: Key=(KEY_D if d.x>0 else KEY_A) if absf(d.x)>absf(d.y) else (KEY_S if d.y>0 else KEY_W)
			if next!=code:
				if code!=KEY_NONE:await key(code,false)
				code=next;await key(code,true)
			await physics_frame;input_ticks+=1
		if code!=KEY_NONE:await key(code,false)
	await ticks(2);return town.actor.global_position.distance_to(p)<85
func drive(code: Key,n: int) -> void:
	await key(code,true)
	for i in range(n):await physics_frame;input_ticks+=1;traces.append([town.actor.global_position.x,town.actor.global_position.y,town.terrain.actor_height,town.terrain.actor_level])
	await key(code,false);await ticks(2)
func shot(name: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://artifacts-i/"+name+".png")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	town=load("res://scenes/drafts/miao_terrain_20261029i/miao_town.tscn").instantiate();root.add_child(town);await ticks(4)
	for npc: CharacterBody2D in town.get_node("Town").find_children("*","CharacterBody2D",false,false):
		if npc!=town.actor:npc.enabled=false
	check(int(town.terrain.heights[0])==0 and int(town.terrain.heights[1])==120 and int(town.terrain.heights[2])==240,"correct JSON numeric height oracle")
	check(empty_at(Vector2(2680,2578.318),0) and empty_at(Vector2(2680,2405),1),"moved cottage clears both real workshop landings")
	# Residual cliff point lies on the actual short horizontal edge, outside its portal.
	town.actor.global_position=Vector2(2825,2515);town.terrain.reset_actor(0);await ticks(2);await drive(KEY_W,30)
	check(town.actor.global_position.y>2464 and town.terrain.actor_level==0 and town.terrain.active_ramp==-1,"workshop cliff actual negative at correct edge",town.actor.global_position)
	# Inspect the new landing without the former foreground tree covering the stair.
	town.actor.global_position=Vector2(2680,2600);town.terrain.reset_actor(0);await ticks(2);await shot("08-clear-workshop-stair")
	make_graph()
	var source:=node_near(Vector2(1610,3900),0)
	for row: Array in [[Vector2(1750,1880),0],[Vector2(4200,2480),1],[Vector2(3800,1610),2],[Vector2(6740,2510),1],[Vector2(4350,3880),0],[Vector2(5600,4160),0]]:
		var target:=node_near(row[0],int(row[1]));var found:=source>=0 and target>=0 and not graph.get_id_path(source,target).is_empty()
		check(found,"layered route from default spawn "+str(row[0]),[source,target])
	var upper:=node_near(Vector2(3800,1610),2)
	for link: Dictionary in links:
		if link.low==0:graph.disconnect_points(link.a,link.b)
	check(graph.get_id_path(source,upper).is_empty(),"closing both low-to-middle stairs disconnects upper settlement")
	for link: Dictionary in links:
		if link.low==0:graph.connect_points(link.a,link.b)
		if link.low==1:graph.disconnect_points(link.a,link.b)
	check(graph.get_id_path(source,upper).is_empty(),"closing both middle-to-upper stairs disconnects ridge")
	for link: Dictionary in links:
		if link.low==1:graph.connect_points(link.a,link.b)
	# Actual continuous travel, with only the initial default-spawn setup.
	town.actor.global_position=Vector2(1610,3900);town.terrain.reset_actor(0);await ticks(2)
	var approached:=await walk_to(Vector2(4200,3125),0)
	check(approached,"real keys default spawn to required plaza lower approach",town.actor.global_position)
	if approached:
		var aligned:=await walk_to(Vector2(4200,3120),0)
		# Ground graph centers are 30px apart; center the stair by actual horizontal input.
		if town.actor.global_position.x<4198:await drive(KEY_D,ceili((4200-town.actor.global_position.x)/5.5))
		elif town.actor.global_position.x>4202:await drive(KEY_A,ceili((town.actor.global_position.x-4200)/5.5))
		await drive(KEY_W,85)
		check(town.terrain.actor_level==1,"same continuous journey climbs plaza stair",town.actor.global_position)
		var crossed:=await walk_to(Vector2(3800,1980),1)
		check(crossed,"real keys cross middle terrace to upper stair",town.actor.global_position)
		if crossed:
			if town.actor.global_position.x<3798:await drive(KEY_D,ceili((3800-town.actor.global_position.x)/5.5))
			elif town.actor.global_position.x>3802:await drive(KEY_A,ceili((town.actor.global_position.x-3800)/5.5))
			await drive(KEY_W,75)
			check(town.terrain.actor_level==2,"same journey climbs second required stair",town.actor.global_position)
			var arrived:=await walk_to(Vector2(3800,1610),2)
			check(arrived,"real keys arrive upper residential lane without actor teleport",town.actor.global_position)
			await shot("09-continuous-upper-arrival")
	town.view_mode=0;town.update_view();town.get_node("UI").hide();await shot("10-final-overview")
	var failed:=0
	for r: Dictionary in checks:
		if not r.pass:failed+=1
	var f:=FileAccess.open("res://artifacts-i/verification-routes.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"count":checks.size(),"failed":failed,"input_ticks":input_ticks,"nav_nodes":graph.get_point_count(),"trace":traces,"method":"Godot physical key events parse/flush; not OS keyboard; graph uses current per-level native physics and canonical ramp edges"},"\t"));f.close();print("MIAO_I_ROUTES ",checks.size()," FAILED ",failed," INPUT ",input_ticks)
	town.queue_free();await ticks(3);quit(0 if failed==0 else 1)
