extends "res://build/lanxi_revision_20261030l/ghost05.gd"
func snap(n:String)->void:
	for i in range(3):await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/lanxi_revision_20261030l/"+n+".png")
func run()->void:
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var t:Node=load("res://build/lanxi_revision_20261030l/candidate.tscn").instantiate();root.add_child(t);current_scene=t
	t.controls_enabled=false;t.actor.position=Vector2(6100,4070);t.terrain.reset_actor(0);t.update_view();await settle();t.set_physics_process(false)
	var o:Sprite2D=t.visibility_ghost.overlay
	o.show();o.modulate.a=.42;await snap("ghost06_half")
	o.hide();await snap("ghost06_none")
	quit()
