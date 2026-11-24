extends "res://scripts/drafts/town_layout_20261029r/court01.gd"
func run()->void:
	town=load("res://scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn").instantiate();root.add_child(town);current_scene=town
	await physics_frame
	for sample in [["LaneStairs",Vector2(3700,2100),0,1,100],["LookoutStairs",Vector2(3700,1370),1,2,64],["WestLaneStairs",Vector2(1300,1290),1,2,64]]:
		town.actor.position=sample[1];town.update_view();town.terrain.reset_actor(sample[2]);await physics_frame
		await shot(str(sample[0])+"_below02")
		await key(KEY_W,sample[4])
		check(str(sample[0])+"_ascended",town.terrain.actor_level==sample[3] and town.terrain.active_ramp==-1)
		await shot(str(sample[0])+"_above02")
		await key(KEY_S,sample[4])
		check(str(sample[0])+"_descended",town.terrain.actor_level==sample[2] and town.terrain.active_ramp==-1)
	town.actor.position=Vector2(3250,2050);town.update_view();await physics_frame;await key(KEY_W,50)
	check("face_not_walkable",town.terrain.actor_level==0 and town.actor.position.y>1945)
	await shot("terrace_front02")
	var ok:=true
	for c in checks:ok=ok and c.ok
	var f:=FileAccess.open("res://review-r/terrain02.json",FileAccess.WRITE);f.store_string(JSON.stringify({"ok":ok,"checks":checks,"transitions":town.terrain.transitions},"\t"));f.close();quit(0 if ok else 1)
