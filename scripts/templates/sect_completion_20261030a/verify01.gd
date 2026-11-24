extends SceneTree
var checks:Array=[]
var town:Node2D
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks.append({"ok":ok,"label":label});print(label,": ",ok)
func key(code:int,ticks:int)->void:
	var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=true;Input.parse_input_event(e);Input.flush_buffered_events()
	for i in range(ticks):await physics_frame
	e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=false;Input.parse_input_event(e);Input.flush_buffered_events();await physics_frame
func shot(name:String)->void:
	await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://review/"+name+".png")
func own_branch(n:Node,scene:Node)->void:
	n.owner=scene
	for c in n.get_children():own_branch(c,scene)
func run()->void:
	for file in DirAccess.get_files_at("res://art/modules/sect_completion_20261030a"):
		if not file.ends_with(".png"):continue
		var path:="res://art/modules/sect_completion_20261030a/"+file
		var im:=Image.load_from_file(path);im.convert(Image.FORMAT_RGBA8)
		var tex:Texture2D=load(path);var imported:=tex.get_image();imported.convert(Image.FORMAT_RGBA8)
		check(im.get_data()==imported.get_data(),"exact import "+file)
	for name in ["lingyue","lieyun","mingwu"]:
		var path:="res://scenes/drafts/sect_completion_20261030a/"+name+".tscn"
		town=load(path).instantiate();root.add_child(town);await physics_frame
		town.view_mode=0;town.update_view();await shot(name+"_overview01")
		if name!="mingwu":
			town.view_mode=1
			for r in town.terrain.ramps:
				town.actor.position=Vector2(r.bottom[0],r.bottom[1]+40);town.terrain.reset_actor(r.low);town.update_view()
				await key(KEY_W,85)
				check(town.terrain.actor_level==r.high and town.terrain.active_ramp<0,name+" ascend "+r.id)
				if r.id in ["CourtRise","WardRise"]:await shot(name+"_rise01")
				await key(KEY_S,85)
				check(town.terrain.actor_level==r.low and town.terrain.active_ramp<0,name+" descend "+r.id)
			town.actor.position=Vector2(town.layout.spawn[0],town.layout.spawn[1]);town.terrain.reset_actor(0);town.update_view()
			await key(KEY_W,110)
			check(town.actor.position.y<town.get_node("Town/MountainGate").position.y-40,name+" true gate passage")
			await shot(name+"_gate01")
			town.actor.position=Vector2(town.layout.spawn[0],town.layout.spawn[1]);town.terrain.reset_actor(0);town.update_view()
			own_branch(town.terrain,town);town.set_meta("terrain_baked",true)
			var packed:=PackedScene.new();check(packed.pack(town)==OK and ResourceSaver.save(packed,path)==OK,name+" native geometry saved")
		town.queue_free();await process_frame;await process_frame
	var fail:=0
	for c in checks:if not c.ok:fail+=1
	var f:=FileAccess.open("res://review/verify01.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":fail},"\t"));f.close();quit(0 if fail==0 else 1)
