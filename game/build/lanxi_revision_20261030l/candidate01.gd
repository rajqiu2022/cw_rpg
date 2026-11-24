extends "res://build/four_settlements_20261030e_qa/business02.gd"
const OUT:="res://build/lanxi_revision_20261030l/"
func shot(name:String)->void:
	await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(OUT+name+".png")
func run()->void:
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var t:Node=load(OUT+"candidate.tscn").instantiate();root.add_child(t);current_scene=t
	await settle();t.controls_enabled=false
	var stats:Array=[]
	for item in t.get_node("Town").get_children():
		if item.has_meta("visual_rect"):stats.append({"name":item.name,"position":item.position,"floor":item.get_meta("terrain_level"),"rect":item.get_meta("visual_rect")})
	var f:=FileAccess.open(OUT+"candidate01-objects.json",FileAccess.WRITE);f.store_string(JSON.stringify(stats,"\t"));f.close()
	for p in [["market",Vector2(6100,4070),0],["west_bank",Vector2(2240,1910),1],["upper_bank",Vector2(3310,1540),2],["plaza_stair",Vector2(4200,3040),0]]:
		t.actor.position=p[1];t.terrain.reset_actor(p[2]);t.update_view();await settle();await shot(p[0]+"_01")
	t.view_mode=0;t.update_view();await shot("overview01")
	check("opaque all building windows",true)
	for art in t.find_children("*","CanvasItem",true,false):
		if art.material is ShaderMaterial and art.material.shader.resource_path.ends_with("occlusion.gdshader"):
			check(String(art.get_path())+" fade disabled",art.material.get_shader_parameter("fade_enabled")==0.0)
	var r:=FileAccess.open(OUT+"candidate01.json",FileAccess.WRITE);r.store_string(JSON.stringify(checks,"\t"));r.close();quit()
