extends SceneTree
var town:Node2D
var checks:Array=[]
func _initialize()->void:run.call_deferred()
func key(code:int,ticks:int)->void:
	await physics_frame
	var e:=InputEventKey.new();e.physical_keycode=code;e.keycode=code;e.pressed=true;Input.parse_input_event(e);Input.flush_buffered_events()
	for i in range(ticks):await physics_frame
	e.pressed=false;Input.parse_input_event(e);Input.flush_buffered_events();await physics_frame
func check(name:String,ok:bool)->void:checks.append({"name":name,"ok":ok});print(name,": ",ok)
func shot(name:String)->void:
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://review-r/"+name+".png")
func run()->void:
	town=load("res://scenes/drafts/desert_town_20261029d/desert_town.tscn").instantiate();root.add_child(town);current_scene=town
	await physics_frame
	for pair in [["CaravanCourt",Vector2(2060,3090)],["HomeCourt1",Vector2(1450,3780)],["HomeCourt2",Vector2(3970,3780)],["HomeCourt3",Vector2(6260,3780)]]:
		town.actor.position=pair[1];town.update_view();await physics_frame
		check(pair[0]+"_no_rear_overlap",not town.has_node("Town/"+pair[0]+"/Art") and not town.has_node("Town/"+pair[0]+"/Edge0"))
		await shot(pair[0]+"01")
	town.actor.position=Vector2(2560,3990);town.update_view();await physics_frame
	await key(KEY_W,35)
	check("gate_opaque",town.get_node("Town/WallFront/Art").modulate.a==1.0 and town.get_node("Town/WallFront/Art").material.get_shader_parameter("fade_enabled")==0.0)
	check("hero_ghost",town.ghost.blocked and town.ghost.overlay.visible and town.ghost.overlay.modulate.a<.5)
	await shot("gate_ghost01")
	var ok:=true
	for c in checks:ok=ok and c.ok
	var f:=FileAccess.open("res://review-r/court01.json",FileAccess.WRITE);f.store_string(JSON.stringify({"ok":ok,"checks":checks},"\t"));f.close();quit(0 if ok else 1)
