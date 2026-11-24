extends "res://verify_routes.gd"
func run() -> void:
	town=load("res://scenes/drafts/miao_terrain_20261029i/miao_town.tscn").instantiate();root.add_child(town);await ticks(4)
	for npc: CharacterBody2D in town.get_node("Town").find_children("*","CharacterBody2D",false,false):
		if npc!=town.actor:npc.enabled=false
	make_graph();checks.clear()
	# Only the failed/unreached continuous journey. Prior 15 route/graph successes retained.
	var approached:=await walk_to(Vector2(4200,3125),0)
	check(approached,"real keys default spawn to required plaza lower approach",town.actor.global_position)
	if approached:
		if town.actor.global_position.x<4198:await drive(KEY_D,ceili((4200-town.actor.global_position.x)/5.5))
		elif town.actor.global_position.x>4202:await drive(KEY_A,ceili((town.actor.global_position.x-4200)/5.5))
		await drive(KEY_W,85)
		check(town.terrain.actor_level==1,"same continuous journey climbs plaza stair",town.actor.global_position)
		var crossed:=await walk_to(Vector2(3800,1980),1)
		check(crossed,"real keys cross middle terrace to upper stair",town.actor.global_position)
		if crossed:
			if town.actor.global_position.x<3798:await drive(KEY_D,ceili((3800-town.actor.global_position.x)/5.5))
			elif town.actor.global_position.x>3802:await drive(KEY_A,ceili((town.actor.global_position.x-3800)/5.5))
			await drive(KEY_W,75)
			check(town.terrain.actor_level==2,"same journey climbs second required stair",town.actor.global_position)
			var arrived:=await walk_to(Vector2(3800,1610),2)
			check(arrived,"real keys arrive upper residential lane without actor teleport",town.actor.global_position)
			await shot("09-continuous-upper-arrival")
	town.view_mode=0;town.update_view();town.get_node("UI").hide();await shot("10-final-overview")
	var failed:=0
	for r: Dictionary in checks:
		if not r.pass:failed+=1
	var f:=FileAccess.open("res://artifacts-i/verification-journey.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"count":checks.size(),"failed":failed,"input_ticks":input_ticks,"trace":traces,"transitions":town.terrain.transitions},"\t"));f.close();print("MIAO_I_JOURNEY ",checks.size()," FAILED ",failed," INPUT ",input_ticks)
	town.queue_free();await ticks(3);quit(0 if failed==0 else 1)
