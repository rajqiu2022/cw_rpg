extends "res://build/quest_map_audit_20261108/huilan_live.gd"

const GATE := &"ch2_s4_lingyue_gate"
const INNER := &"openworld_lingyue_inner_court"
const REPORT := &"q_ch2_main_04_report_lingyue"
const DISCIPLE := &"q_ch2_side_01_missing_disciple"

func finish() -> void:
	print("LINGYUE_LIVE checks=",checks," failures=",failures)
	quit(1 if failures else 0)

func set_foot(town: Node, point: Vector2, floor: int = -1) -> void:
	town.actor.global_position=point
	town.terrain.reset_actor(town.terrain.level_at(point) if floor<0 else floor)
	await physics_frame
	await physics_frame

func screenshot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/quest_map_audit_20261108/"+name+".png")

func body_at(actor: Player, point: Vector2, mask: int) -> Node:
	var feet: CollisionShape2D=actor.get_node("CollisionShape2D")
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=feet.shape
	query.transform=Transform2D(0.0,point)
	query.collision_mask=mask
	var hits:=actor.get_world_2d().direct_space_state.intersect_shape(query,4)
	return hits[0].collider if not hits.is_empty() else null

func portal_to(field: Node, target: StringName) -> ExitZone:
	for item: ExitZone in field.get("_exit_nodes"):
		if is_instance_valid(item) and not item.is_queued_for_deletion() and StringName(item.target_scene_id)==target:
			return item
	return null

func _run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router=root.get_node("SceneRouter")
	state=root.get_node("GameState")
	quests=root.get_node("QuestManager")
	dialogue=root.get_node("DialogPlayer")
	state.reset_for_new_game()
	quests.reset_for_new_game()
	router.reset_for_new_game()
	state.set_flag(&"chapter1_complete",true)
	state.set_flag(&"ch2_rescue_complete",true)
	var field:=await enter(GATE)
	if field==null:
		finish()
		return
	expect(area(field,"legacy_hotspot_1")==null,"rescue alone cannot skip hideout")
	var town: Node=field.native_town
	var registry: Script=load("res://build/three_towns_world_20261029j_system01/town_registry.gd")
	for name: String in ["MainHall","WestDorm","NorthDorm","EastDorm","LowerDorm","QuietPavilion","Kitchen"]:
		var building: Node2D=town.get_node("Town/"+name)
		var collider: StaticBody2D=building.get_node("Body")
		var floor: int=building.get_meta("terrain_level")
		var foot: Vector2=building.global_position
		var projected_y: float=foot.y-town.terrain.elevation(floor)
		expect(building.z_index<=town.foot_depth(projected_y) and building.z_index>=town.foot_depth(projected_y-135.0),"building uses projected foundation depth "+name)
		expect(collider.collision_layer==town.terrain.layer(floor),"building on its floor "+name)
		expect(body_at(town.actor,foot+Vector2(0,-109),town.terrain.layer(floor))==collider,"rear footprint blocks "+name)
		await set_foot(town,foot+Vector2(0,35),floor)
		expect(registry.actor_shape_clear(town.actor) and town.actor.z_index>building.z_index,"front foot clear and above building "+name)
		if name=="WestDorm":
			await screenshot("lingyue_dorm_front")
			await set_foot(town,foot+Vector2(-260,-14),floor)
			expect(registry.actor_shape_clear(town.actor) and town.actor.z_index>building.z_index,"left sloping foundation keeps foreground player visible")
			await screenshot("lingyue_dorm_left_edge")
	# The arch is the only open architectural footprint in this set.
	expect(body_at(town.actor,Vector2(1900,3040),16)==null,"mountain gate middle is open")
	for point: Vector2 in [Vector2(1800,3040),Vector2(2010,3040)]:
		expect(body_at(town.actor,point,16)!=null,"mountain gate pier blocks "+str(point))
	# Actual input stops on the front edge, then leaves the player on the foreground side.
	await set_foot(town,Vector2(1150,1650),1)
	var w:=InputEventKey.new()
	w.physical_keycode=KEY_W
	w.keycode=KEY_W
	w.pressed=true
	Input.parse_input_event(w)
	for i in range(36): await physics_frame
	w=w.duplicate() as InputEventKey
	w.pressed=false
	Input.parse_input_event(w)
	var stopped: Vector2=town.actor.global_position
	expect(stopped.y>1500.0 and stopped.y<1610.0 and registry.actor_shape_clear(town.actor),"walking stops at dorm front")
	await screenshot("lingyue_dorm_collision")
	# Real temple bell puzzle and side hand-in on the new layout.
	await play_at(field,"legacy_hotspot_2",&"huilan_openworld_bell",[1])
	expect(state.flags.get("huilan_bell_counterforce_understood",false),"bell sets actual clue")
	quests.accept(DISCIPLE)
	state.set_flag(&"defeated_masked_killer_elite",true)
	expect(await wait_for(func(): return area(field,"legacy_hotspot_0")!=null),"side quest hand-in opens")
	await play_at(field,"legacy_hotspot_0",&"ch2_missing_disciple_complete",[])
	expect(quests.is_completed(DISCIPLE),"missing disciple side quest completes")
	# Walk up to the real inner-court arrow and return through its exit.
	var portal:=portal_to(field,INNER)
	if expect(is_instance_valid(portal),"inner-court portal exists"):
		var entry: Dictionary=registry.town(GATE)
		expect(portal.global_position.is_equal_approx(entry.inner_entrance),"arrow sits at main hall doorway")
		await set_foot(town,entry.inner_arrival)
		await create_timer(2.1).timeout
		await screenshot("lingyue_main_door")
		var approach:=InputEventKey.new()
		approach.physical_keycode=KEY_W
		approach.keycode=KEY_W
		approach.pressed=true
		Input.parse_input_event(approach)
		expect(await wait_for(func():
			var zone:=portal_to(field,INNER)
			return zone!=null and zone.get("_in_range") and town.actor.global_position.y<entry.inner_arrival.y-2.0
		,2500),"real W walks from plaza to doorway")
		approach=approach.duplicate() as InputEventKey
		approach.pressed=false
		Input.parse_input_event(approach)
		var outer_instance:=field.get_instance_id()
		await press_space()
		expect(await wait_for(func(): return router.get_current_field_id()==INNER and current_scene!=null and current_scene.get_instance_id()!=outer_instance and current_scene.get("_current_scene")!=null and current_scene.get("_current_scene").scene_id==INNER),"real Space enters inner court")
		var inner:=current_scene
		if router.get_current_field_id()==INNER and inner!=null:
			var inner_instance:=inner.get_instance_id()
			await wait_for(func(): return inner.get_field_loading_state().get("complete",false) and not root.get_node("LoadingManager").get("_transition_active"))
			for exit: ExitZone in inner.get("_exit_nodes"):
				if StringName(exit.target_scene_id)!=GATE:continue
				var player: Player=inner.get("_player")
				player.global_position=exit.global_position
				expect(await wait_for(func():return exit.get("_in_range"),2000),"inner return arrow in range")
				await press_space()
				break
			if not expect(await wait_for(func(): return router.get_current_field_id()==GATE and current_scene!=null and current_scene.get_instance_id()!=inner_instance and current_scene.get("_current_scene")!=null and current_scene.get("_current_scene").scene_id==GATE and not root.get_node("LoadingManager").get("_transition_active")),"real Space returns from inner court"):
				finish()
				return
			field=current_scene
			expect(field.get("_player").global_position.distance_to(entry.inner_arrival)<1.0,"return lands in front of the same door")
	quests.accept(REPORT)
	state.set_flag(&"ch2_hideout_cleared",true)
	expect(await wait_for(func(): return area(field,"legacy_hotspot_1")!=null),"verified ledger opens Lingyue report")
	await play_at(field,"legacy_hotspot_1",&"ch2_lingyue_arrival",[])
	expect(quests.is_completed(REPORT) and state.flags.get("chapter2_complete",false),"Lingyue report completes chapter two")
	finish()
