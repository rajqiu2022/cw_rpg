extends SceneTree
var town: Node2D
var checks: Array=[]
var traces: Array=[]
var input_ticks:=0
func check(ok: bool,label: String,detail: Variant=null) -> void:
	checks.append({"pass":ok,"label":label,"detail":detail})
	if not ok:print("FAIL ",label," ",detail)
func ticks(n: int) -> void:
	for i in range(n):await physics_frame
func key(code: Key,pressed: bool) -> void:
	var e:=InputEventKey.new();e.physical_keycode=code;e.keycode=code;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
func drive(code: Key,n: int) -> void:
	await key(code,true)
	for i in range(n):
		await physics_frame;input_ticks+=1;traces.append([town.layout.key,town.actor.position.x,town.actor.position.y,town.terrain.actor_height,town.terrain.actor_level])
	await key(code,false);await ticks(2)
func shot(name: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://artifacts-k/"+name+".png")
func empty_at(p: Vector2,level: int) -> bool:
	var q:=PhysicsShapeQueryParameters2D.new();var shape:=RectangleShape2D.new();shape.size=Vector2(39,29);q.shape=shape;q.transform=Transform2D(0,p);q.collision_mask=8|town.terrain.layer(level)
	return town.get_world_2d().direct_space_state.intersect_shape(q,1).is_empty()
func place(p: Vector2,level: int) -> void:
	town.actor.position=p;town.terrain.reset_actor(level);town.update_view();await ticks(2)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for map: String in ["wudang","mingwu"]:
		town=load("res://scenes/drafts/sect_maps_20261029k/"+map+".tscn").instantiate();root.add_child(town);await ticks(4)
		check(town.actor.get_script().resource_path.ends_with("preview_player.gd"),map+" canonical hero adapter")
		check(empty_at(town.actor.position,0),map+" spawn clear")
		town.view_mode=0;town.update_view();await shot(map+"_overview01");town.view_mode=1
		for r: Dictionary in town.terrain.ramps:
			var top:=Vector2(r.top[0],r.top[1]);var bottom:=Vector2(r.bottom[0],r.bottom[1]);var low:=int(r.low);var high:=int(r.high)
			check(empty_at(bottom+Vector2(0,55),low) and empty_at(top-Vector2(0,55),high),map+" "+r.id+" both landings clear")
			await place(bottom+Vector2(0,50),low)
			var count:=ceili((float(r.ground_run)+float(r.rise)+120)/330.0*60)+12
			await drive(KEY_W,count)
			check(town.terrain.actor_level==high and absf(town.terrain.actor_height-town.terrain.elevation(high))<.01,map+" "+r.id+" actual ascent",[town.actor.position,town.terrain.actor_level,town.terrain.actor_height])
			await drive(KEY_S,count)
			check(town.terrain.actor_level==low and absf(town.terrain.actor_height-town.terrain.elevation(low))<.01,map+" "+r.id+" actual descent",[town.actor.position,town.terrain.actor_level])
			await place((top+bottom)*.5,low);town.terrain.active_ramp=town.terrain.ramps.find(r);town.terrain.apply_actor_mask();town.terrain.after_move();town.update_view()
			if r.id in ["MainRise","GuestRise"]:await shot(map+"_stair01")
			await drive(KEY_D,60)
			check(town.actor.position.x<top.x+float(town.terrain.data.portal_half_width),map+" "+r.id+" side rail blocks")
		var r0: Dictionary=town.terrain.ramps[0]
		await place(Vector2(r0.top[0]-float(town.terrain.data.facade_opening_half_width)-100,r0.top[1]+75),0)
		await drive(KEY_W,35);check(town.actor.position.y>float(r0.top[1]),map+" cliff cannot bypass stair")
		for bridge: Dictionary in town.layout.bridges:
			var c:=Vector2(bridge.center[0],bridge.center[1]-10)
			await place(c-Vector2(500,0),0);await drive(KEY_D,190)
			check(town.actor.position.x>c.x+480,map+" "+bridge.name+" actual crossing",town.actor.position)
			await place(c,0);await drive(KEY_W,28);check(town.actor.position.y>float(bridge.walk_y[0]),map+" "+bridge.name+" rail blocks water")
			check(not empty_at(c+Vector2(0,180),0),map+" "+bridge.name+" water negative")
		await place(Vector2(2700,1220) if map=="wudang" else Vector2(4080,1350),2);await shot(map+"_hall01")
		town.queue_free();await process_frame;await process_frame
	var failures:=0
	for row: Dictionary in checks:
		if not row.pass:failures+=1
	var f:=FileAccess.open("res://artifacts-k/verify01.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"input_ticks":input_ticks,"traces":traces},"\t"));f.close()
	print("SECT_CHECKS ",checks.size()," FAILURES ",failures," INPUT ",input_ticks);quit(0 if failures==0 else 1)
