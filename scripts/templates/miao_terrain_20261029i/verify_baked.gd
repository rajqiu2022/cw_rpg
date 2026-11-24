extends "res://verify_terrain.gd"
func run() -> void:
	town=load("res://scenes/drafts/miao_terrain_20261029i/miao_town.tscn").instantiate();root.add_child(town);await ticks(4)
	check(bool(town.get_meta("terrain_baked",false)) and town.get_node("Terrain").get_child_count()>100,"terrain is saved as native editor scene nodes")
	check(town.get_node("Terrain/Platform1").position==Vector2(0,-120) and town.get_node("Terrain/Platform2").position==Vector2(0,-240),"reloaded terrace heights not applied twice")
	var hall_art: Node2D=town.get_node("Town/PocketHome8/Art");var before: Vector2=hall_art.position
	for i in range(20):await physics_frame
	check(hall_art.position==before,"reloaded building feet remain stable")
	check(town.get_node("Town/PocketInfill7").position==Vector2(2740,3080) and empty_at(Vector2(2680,2578.318),0),"new cottage position and cleared landing persist in saved scene")
	check(town.terrain.get_node("Cliff0").collision_layer==48,"baked cliff retains both adjacent physical layers")
	place(Vector2(4200,3128.318),0);await ticks(2);var count: int=town.terrain.get_child_count()
	await drive(KEY_W,65)
	check(town.terrain.actor_level==1 and town.actor.collision_mask==40,"saved-scene real W still enters upper physical floor")
	check(town.terrain.get_child_count()==count,"loading did not duplicate generated terrain")
	await shot("11-baked-stair-top")
	town.view_mode=0;town.update_view();town.get_node("UI").hide();await shot("12-baked-overview")
	var failed:=0
	for r: Dictionary in checks:
		if not r.pass:failed+=1
	var f:=FileAccess.open("res://artifacts-i/verification-baked.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"count":checks.size(),"failed":failed,"input_ticks":input_ticks},"\t"));f.close();print("MIAO_I_BAKED ",checks.size()," FAILED ",failed)
	town.queue_free();await ticks(3);quit(0 if failed==0 else 1)
