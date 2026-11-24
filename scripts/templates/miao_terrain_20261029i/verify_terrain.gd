extends SceneTree
var town: Node2D
var checks: Array=[]
var traces: Array=[]
var input_ticks:=0

func check(value: bool,label: String,detail: Variant=null) -> void:
	checks.append({"pass":value,"label":label,"detail":detail})
	if not value:print("FAIL ",label," ",detail)
func ticks(n: int) -> void:
	for i in range(n):await physics_frame
func key(code: Key,pressed: bool) -> void:
	var event:=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=pressed;Input.parse_input_event(event);Input.flush_buffered_events()
func drive(code: Key,n: int) -> Array:
	key(code,true);var samples: Array=[]
	for i in range(n):
		await physics_frame;input_ticks+=1
		samples.append([town.actor.global_position.x,town.actor.global_position.y,town.terrain.actor_height,town.terrain.actor_level,town.terrain.active_ramp])
	key(code,false);await ticks(2);return samples
func place(p: Vector2,level: int) -> void:
	town.actor.global_position=p;town.terrain.reset_actor(level);town.update_view()
func empty_at(p: Vector2,level: int) -> bool:
	var q:=PhysicsShapeQueryParameters2D.new();var shape:=RectangleShape2D.new();shape.size=Vector2(35,25);q.shape=shape;q.transform=Transform2D(0,p);q.collision_mask=8|town.terrain.layer(level)
	return town.get_world_2d().direct_space_state.intersect_shape(q,1).is_empty()
func shot(name: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://artifacts-i/"+name+".png")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	town=load("res://scenes/drafts/miao_terrain_20261029i/miao_town.tscn").instantiate();root.add_child(town);await ticks(5)
	var terrain: Node2D=town.terrain;var actor_id: int=town.actor.get_instance_id()
	check(int(terrain.heights[0])==0 and int(terrain.heights[1])==120 and int(terrain.heights[2])==240,"three authoritative heights")
	check(town.actor.collision_mask==24,"default valley physical collision mask")
	for npc: CharacterBody2D in town.get_node("Town").find_children("*","CharacterBody2D",false,false):
		if npc==town.actor:continue
		var clear:=true;var same_level:=true
		for i in range(31):
			var p: Vector2=npc.route[0].lerp(npc.route[-1],float(i)/30.0)
			clear=clear and empty_at(p,npc.floor_level);same_level=same_level and terrain.level_at(p)==npc.floor_level
		check(clear and same_level,"resident route physically clear on assigned terrace "+npc.name,[clear,same_level,npc.floor_level]);npc.enabled=false
	for ramp: Dictionary in terrain.ramps:
		var top:=Vector2(ramp.top[0],ramp.top[1]);var bottom:=Vector2(ramp.bottom[0],ramp.bottom[1]);var low:=int(ramp.low);var high:=int(ramp.high)
		check(empty_at(top-Vector2(0,45),high) and empty_at(bottom+Vector2(0,45),low),"both actual stair landings clear "+ramp.id)
		place(bottom+Vector2(0,45),low);await ticks(2)
		var up: Array=await drive(KEY_W,65)
		var intermediate:=0;var monotone:=true;var prior:=float(up[0][2])
		for p: Array in up:
			if float(p[2])>terrain.elevation(low)+1 and float(p[2])<terrain.elevation(high)-1:intermediate+=1
			monotone=monotone and float(p[2])>=prior-.01;prior=float(p[2])
		check(terrain.actor_level==high and terrain.active_ramp==-1 and intermediate>=10 and monotone,"real W climbs continuous height and commits upper floor "+ramp.id,[town.actor.global_position,terrain.actor_height,intermediate])
		check(town.actor.collision_mask==(8|terrain.layer(high)),"upper floor collision mask committed "+ramp.id)
		traces.append({"ramp":ramp.id,"direction":"up","samples":up})
		if ramp.id=="PlazaStair":await shot("02-plaza-top")
		# Down begins at the actual location reached by W, rather than a teleported upper success.
		var down: Array=await drive(KEY_S,65);intermediate=0;monotone=true;prior=float(down[0][2])
		for p: Array in down:
			if float(p[2])>terrain.elevation(low)+1 and float(p[2])<terrain.elevation(high)-1:intermediate+=1
			monotone=monotone and float(p[2])<=prior+.01;prior=float(p[2])
		check(terrain.actor_level==low and terrain.active_ramp==-1 and intermediate>=10 and monotone,"real S returns continuously to lower floor "+ramp.id,[town.actor.global_position,terrain.actor_height,intermediate])
		traces.append({"ramp":ramp.id,"direction":"down","samples":down})
		# A new approach outside the portal must hit the same cliff used by rendering.
		place(top+Vector2(145 if ramp.id=="WorkshopStair" else 265,65),low);await ticks(2);var before: Vector2=town.actor.global_position
		await drive(KEY_W,30)
		check(town.actor.global_position.y>top.y+14 and terrain.actor_level==low and terrain.active_ramp==-1,"non-stair cliff blocks actual W "+ramp.id,[before,town.actor.global_position])
		# Enter from an actual lower landing and try leaving midway through the cheek.
		place(bottom+Vector2(0,25),low);await ticks(2);await drive(KEY_W,21)
		var mid: Vector2=town.actor.global_position;var mid_height:=float(terrain.actor_height)
		await drive(KEY_D,40)
		check(terrain.active_ramp>=0 and town.actor.global_position.x<=top.x+99 and absf(terrain.actor_height-mid_height)<.1,"mid-ramp side rail blocks lateral escape "+ramp.id,[mid,town.actor.global_position,mid_height,terrain.actor_height])
		if ramp.id=="UpperLaneStair":await shot("03-upper-stair-middle")
	# The real room uses its own floor collision layer and retains the outdoor XY/Z state.
	place(Vector2(1750,1880),0);await ticks(2);var return_foot: Vector2=town.actor.global_position
	town.enter_hall();await ticks(2);check(town.in_hall and town.actor.collision_mask==1 and town.actor.get_instance_id()==actor_id,"cached room uses same actor with indoor mask")
	town.leave_hall();await ticks(2);check(not town.in_hall and town.actor.global_position==return_foot and terrain.actor_level==0 and town.actor.collision_mask==24,"room restores exact ground foot and height")
	for row: Array in [[Vector2(4200,3150),0,"04-plaza-bottom"],[Vector2(3800,1700),2,"05-upper-lane"],[Vector2(2680,2610),0,"06-workshop-bottom"]]:
		place(row[0],int(row[1]));await ticks(2);await shot(row[2])
	town.view_mode=0;town.update_view();await shot("01-overview-hud");town.get_node("UI").hide();await shot("07-overview")
	var failed:=0
	for r: Dictionary in checks:
		if not r.pass:failed+=1
	var f:=FileAccess.open("res://artifacts-i/verification-terrain.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"count":checks.size(),"failed":failed,"input_ticks":input_ticks,"traces":traces,"transitions":terrain.transitions,"scope":"New three-height terrain: actual W/S four ramps, side escape and nonportal cliffs, 8resident routes and same cached room; not formal World or whole-city final ART."},"\t"));f.close()
	print("MIAO_I ",checks.size()," FAILED ",failed," INPUT ",input_ticks)
	town.queue_free();await ticks(3);quit(0 if failed==0 else 1)
