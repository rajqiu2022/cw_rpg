extends "res://build/four_settlements_20261030e_qa/business02.gd"
func run()->void:
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var t:Node=load("res://build/lanxi_revision_20261030l/candidate.tscn").instantiate();root.add_child(t);current_scene=t
	t.controls_enabled=false;t.actor.position=Vector2(6100,4070);t.terrain.reset_actor(0);t.update_view();await settle()
	var ghost:Node=t.visibility_ghost;var sprite:Sprite2D=t.actor.get_node("Sprite2D");var rows:Array=[]
	for art in ghost.occluders:
		var foot:Vector2=t.terrain.projected_foot();var hit:=false
		for h in [25.0,60.0,95.0,125.0]:hit=hit or ghost.opaque_at(art,foot-Vector2(0,h))
		if hit:rows.append({"path":art.get_path(),"depth":ghost.depth(art),"visible":art.is_visible_in_tree()})
	var data:Dictionary={"actor":t.actor.position,"foot":t.terrain.projected_foot(),"sprite_transform":sprite.global_transform,"sprite_texture":sprite.texture.resource_path,"actor_depth":ghost.depth(sprite),"overlay_visible":ghost.overlay.visible,"overlay_transform":ghost.overlay.global_transform,"blocked":ghost.blocked,"occluders":rows}
	var f:=FileAccess.open("res://build/lanxi_revision_20261030l/ghost03.json",FileAccess.WRITE);f.store_string(JSON.stringify(data,"\t"));f.close();print(data);quit()
