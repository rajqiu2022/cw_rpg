extends "res://build/four_settlements_20261030e_qa/business02.gd"
const LOCAL:="res://build/lanxi_revision_20261030l/"
func shot(name:String)->void:
	for i in range(3):await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(LOCAL+name+".png")
func finish(ok:bool)->void:
	for c in checks:ok=ok and c.ok
	var f:=FileAccess.open(LOCAL+"layout07.json",FileAccess.WRITE);f.store_string(JSON.stringify({"ok":ok,"checks":checks},"\t"));f.close();quit(0 if ok else 1)
func run()->void:
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var t:Node=load(LOCAL+"candidate.tscn").instantiate();root.add_child(t);current_scene=t;await settle()
	for r in t.terrain.ramps:
		t.actor.position=Vector2(r.bottom[0],r.bottom[1]+30);t.terrain.reset_actor(r.low);t.update_view();await settle()
		check(r.id+" bottom clear",t.foot_clear(t.actor.position));await key(KEY_W,78)
		check(r.id+" actual ascent",t.terrain.actor_level==int(r.high) and t.terrain.active_ramp<0)
		if r.id=="PlazaStair":await shot("plaza07")
		await key(KEY_S,78);check(r.id+" actual descent",t.terrain.actor_level==int(r.low) and t.terrain.active_ramp<0)
	for name:String in t.moved_objects:
		var row:Dictionary=t.moved_objects[name];var old:=Vector2(row.old[0],row.old[1]);var next:=Vector2(row.new[0],row.new[1]);var foot:=Vector2(row.return_foot[0],row.return_foot[1])
		t.actor.position=foot;t.terrain.reset_actor(t.terrain.level_at(foot));await settle()
		check(name+" same floor",t.terrain.level_at(old)==t.terrain.level_at(next));check(name+" new front clear",t.foot_clear(foot))
		var before:Vector2=t.actor.position;await key(KEY_S,8);check(name+" front walking",t.actor.position.y>before.y+25)
	# Check precise compatibility: a new house footprint covering an old legal lane.
	t.actor.position=Vector2(2690,1330);t.terrain.reset_actor(1);await settle()
	check("legacy lane was legal",t.legacy_clear(t.actor.position));check("new home covers legacy lane",not t.foot_clear(t.actor.position))
	await t.restore_revised_foot();check("covered legal foot relocated",t.migrated_foot and t.foot_clear(t.actor.position))
	var stable:Vector2=t.actor.position;await t.restore_revised_foot();check("clear foot exact",t.actor.position==stable)
	for p in [["west_bank07",Vector2(2240,1910),1],["upper_bank07",Vector2(3310,1540),2],["market07",Vector2(6100,4070),0]]:
		t.actor.position=p[1];t.terrain.reset_actor(p[2]);t.update_view();await settle();await shot(p[0])
	t.view_mode=0;t.update_view();await shot("overview07");finish(true)
