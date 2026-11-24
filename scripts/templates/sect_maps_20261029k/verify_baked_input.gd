extends SceneTree
var checks: Array=[]
var town: Node2D
func check(ok: bool,label: String) -> void:
	checks.append({"pass":ok,"label":label})
	if not ok:print("FAIL ",label)
func key(code: Key,pressed: bool) -> void:
	var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
func drive(code: Key,n: int) -> void:
	await key(code,true)
	for i in range(n):await physics_frame
	await key(code,false);await physics_frame
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for map: String in ["wudang","mingwu"]:
		town=load("res://scenes/drafts/sect_maps_20261029k/"+map+".tscn").instantiate();root.add_child(town);await physics_frame;await physics_frame
		await drive(KEY_TAB,1);check(town.view_mode==0,map+" Tab overview");await drive(KEY_TAB,1);check(town.view_mode==1,map+" Tab follow")
		await drive(KEY_SPACE,1);check(town.show_details,map+" Space local details");await drive(KEY_ESCAPE,1);check(not town.show_details,map+" Esc closes details")
		var r: Dictionary=town.terrain.ramps[0];town.actor.position=Vector2(r.bottom[0],r.bottom[1]+40);town.terrain.reset_actor(0)
		await drive(KEY_W,ceili((float(r.ground_run)+float(r.rise)+100)/330.0*60)+10)
		check(town.terrain.actor_level==1,map+" saved scene actual stair ascent")
		if map=="mingwu":
			for bridge: Dictionary in town.layout.bridges:
				var c:=Vector2(bridge.center[0],(bridge.walk_y[0]+bridge.walk_y[1])*.5);town.actor.position=c;town.terrain.reset_actor(0)
				await drive(KEY_W,25);check(town.actor.position.y>float(bridge.walk_y[0]),bridge.name+" current-scale back rail blocks")
				town.actor.position=c;await drive(KEY_S,25);check(town.actor.position.y<float(bridge.walk_y[1]),bridge.name+" current-scale front rail blocks")
		town.queue_free();await process_frame;await process_frame
	var failures:=0
	for row: Dictionary in checks:
		if not row.pass:failures+=1
	var f:=FileAccess.open("res://artifacts-k/baked-input04.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"));f.close()
	print("BAKED_INPUT ",checks.size()," FAILURES ",failures);quit(0 if failures==0 else 1)
