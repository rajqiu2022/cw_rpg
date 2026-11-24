extends "res://scripts/drafts/town_layout_20261029r/court01.gd"
func run()->void:
	town=load("res://scenes/drafts/desert_town_20261029d/desert_town.tscn").instantiate();root.add_child(town);current_scene=town;await physics_frame
	town.actor.position=Vector2(1450,3780);town.update_view();await shot("west_home_final03")
	town.actor.position=Vector2(800,3590);town.update_view();await physics_frame;await key(KEY_A,60)
	check("west_wall_blocks",town.actor.position.x>430 and town.actor.position.x<800)
	await shot("west_wall_final03")
	for pair in [["HomeCourt2",Vector2(3970,3780)],["HomeCourt3",Vector2(6260,3780)]]:
		town.actor.position=pair[1];town.update_view();await shot(str(pair[0])+"_final03")
	var ok:=true
	for c in checks:ok=ok and c.ok
	var f:=FileAccess.open("res://review-r/west03.json",FileAccess.WRITE);f.store_string(JSON.stringify({"ok":ok,"checks":checks},"\t"));f.close();quit(0 if ok else 1)
