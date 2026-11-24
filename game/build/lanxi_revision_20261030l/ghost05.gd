extends "res://build/four_settlements_20261030e_qa/business02.gd"
func snap(n:String)->void:
	await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/lanxi_revision_20261030l/"+n+".png")
func run()->void:
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var t:Node=load("res://build/lanxi_revision_20261030l/candidate.tscn").instantiate();root.add_child(t);current_scene=t
	t.controls_enabled=false;t.actor.position=Vector2(6100,4070);t.terrain.reset_actor(0);t.update_view();await settle();t.set_physics_process(false)
	var o:Sprite2D=t.visibility_ghost.overlay;var s:Sprite2D=t.actor.get_node("Sprite2D")
	print("SPRITES ",o.get_rect()," ",o.texture.get_size()," frames ",o.hframes," ",o.frame," ",o.modulate," tree ",o.is_visible_in_tree()," canvas ",o.get_global_transform_with_canvas()," source ",s.get_rect()," ",s.frame)
	await snap("ghost05_normal")
	o.modulate.a=1;await snap("ghost05_opaque")
	t.get_node("Town").hide();await snap("ghost05_isolated")
	quit()
