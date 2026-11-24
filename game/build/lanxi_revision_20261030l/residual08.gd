extends "res://build/lanxi_revision_20261030l/layout07.gd"
func finish(ok:bool)->void:
	for c in checks:ok=ok and c.ok
	var f:=FileAccess.open(LOCAL+"residual08.json",FileAccess.WRITE);f.store_string(JSON.stringify({"ok":ok,"checks":checks},"\t"));f.close();quit(0 if ok else 1)
func run()->void:
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var t:Node=load(LOCAL+"candidate.tscn").instantiate();root.add_child(t);current_scene=t;await settle()
	t.actor.position=Vector2(2480,1315);t.terrain.reset_actor(1);await settle();var before:Vector2=t.actor.position;await key(KEY_S,12)
	check("PocketHome6 corrected front walking",t.actor.position.y>before.y+50);await shot("home08")
	t.controls_enabled=false;t.actor.position=Vector2(2660,1220);t.terrain.reset_actor(1);await settle()
	print("legacy probe ",t.actor.position);check("legacy lane was legal",t.legacy_clear(t.actor.position));check("new home covers legal lane",not t.foot_clear(t.actor.position))
	await t.restore_revised_foot();check("covered legal foot relocated",t.migrated_foot and t.foot_clear(t.actor.position));check("authored front",t.actor.position==Vector2(2480,1315))
	var valid:Vector2=t.actor.position;await t.restore_revised_foot();check("clear foot preserved",t.actor.position==valid)
	t.actor.position=Vector2(2220,1320);t.terrain.reset_actor(1);await settle();check("old blocked foot rejected",not t.legacy_clear(t.actor.position));await t.restore_revised_foot();check("old blocked foot not silently moved",t.actor.position==Vector2(2220,1320))
	for actor in t.get_node("Town").get_children():
		if actor is CharacterBody2D and actor!=t.actor:
			print("NPC_ROUTE ",actor.name," ",actor.route," floor ",actor.floor_level)
	finish(true)
