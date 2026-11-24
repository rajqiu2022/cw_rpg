extends "res://build/world_sects_cities_20261031c_qa01/probe_base_ROOT_ONLY.gd"
const W := &"openworld_wudang_gate"
const T := &"openworld_wudang_taiji_court"
const P := &"openworld_wudang_purple_cloud_court"
const H := &"openworld_huashan_forecourt"
func sd() -> Dictionary:return field.call("get_sect_adoption_debug")
func near(id: StringName,at: Vector2) -> bool:
	var size: Vector2=Vector2(5800,5000) if id==H else Vector2(5200,4400)
	if not await setup(id,at/size,3006):return false
	records.append({"native_near":sd()})
	return need(foot().distance_to(at)<.04,"CURRENT3006_NEAR_EXACT")
func wall_negative(at: Vector2) -> bool:
	if not await near(W,at):return false
	var tail: Vector2=foot();var hits: Array[String]=[]
	for frame: int in range(30):
		key(KEY_W);await tick()
		if frame==24:tail=foot()
		for i: int in range(actor.get_slide_collision_count()):
			var collider: Object=actor.get_slide_collision(i).get_collider()
			if collider is Node:
				var path: String=String(collider.get_path())
				if not hits.has(path):hits.append(path)
	key(KEY_NONE);await tick();var closure_hit := false
	for path: String in hits:closure_hit=closure_hit or path.contains("/GateClosure")
	records.append({"new_gate_wall_negative_start":at,"end":foot(),"hits":hits})
	return need(closure_hit and foot().y>3800 and foot().distance_to(tail)<.1 and foot().distance_to(at)>15,"NO_LEFT_OR_RIGHT_WALL_BYPASS")
func opaque_ghost() -> bool:
	var node: Node=town.get_node("OpaqueArchitectureActorGhost")
	var state: Dictionary=node.call("get_debug_state")
	var source: Sprite2D=root.get_node(NodePath(state.actor_sprite)) as Sprite2D
	var overlay: Sprite2D=root.get_node(NodePath(state.overlay)) as Sprite2D
	var opaque := true;var count := 0
	for item: Node in town.get_node("Town").get_children():
		if not item.has_meta("fade"):continue
		var art: Sprite2D=item.get_node_or_null("Art") as Sprite2D
		if art==null:continue
		count+=1;opaque=opaque and art.modulate.a>.999 and art.self_modulate.a>.999
		if art.material is ShaderMaterial:opaque=opaque and float(art.material.get_shader_parameter("fade_enabled"))==0.0
	records.append({"real_actor_ghost":state,"whole_architecture_opaque":opaque,"architecture_count":count,"source_id":source.get_instance_id() if source!=null else 0,"overlay_id":overlay.get_instance_id() if overlay!=null else 0,"native_visual":town.get_meta("sect_native_visual31c",{})})
	return need(source!=null and overlay!=null and state.blocked and overlay.is_visible_in_tree() and absf(overlay.modulate.a-.42)<.001 and source.texture==overlay.texture and source.frame==overlay.frame and source.flip_h==overlay.flip_h and overlay.global_transform.is_equal_approx(source.global_transform) and opaque and count>0,"ONLY_SAME_LIVE_ACTOR_TRANSLUCENT_ARCHITECTURE_OPAQUE")
func _run() -> void:
	if not await boot("sects"):finish();return
	var registry: Script=load(cfg.registry) as Script
	if not need(registry.call("source_valid")==true,"MERGED_NATIVE_SOURCE_VALID"):finish();return
	if not await setup(W,null,3006):finish();return
	var state: Dictionary=sd();var old_arrow := false;var purple := false
	for row: Dictionary in state.portals:
		old_arrow=old_arrow or String(row.get("id",""))=="to_wudang_taiji_court"
		purple=purple or String(row.get("target_scene",""))==String(P)
	if not need(state.taiji_same_site_integrated and not old_arrow and purple and state.portals.size()==2,"NO_OLD_TAIJI_ARROW_REAL_PURPLE_DESTINATION_RETAINED"):finish();return
	if not await near(W,Vector2(1680,3890)):finish();return
	await shot("wudang_native_gate_enclosure")
	if not await walk(Vector2(1680,3690),65):finish();return
	if not await wall_negative(Vector2(800,3890)) or not await wall_negative(Vector2(2600,3890)):finish();return
	if not await near(W,Vector2(2700,1160)):finish();return
	if not await enter(P):finish();return
	# Only the original purple court's existing return; no extra sect tour/dialogs.
	var original: SceneScript=load("res://data/scenes/openworld_wudang_purple_cloud_court.tres") as SceneScript
	var return_uv:=Vector2.ZERO
	for row: Dictionary in original.map_layout.portals:
		if String(row.get("target_scene",""))==String(T):return_uv=row.pos
	if not need(return_uv!=Vector2.ZERO,"ORIGINAL_PURPLE_TO_TAIJI_RETURN_ROW"):finish();return
	if not await setup(P,return_uv,1) or not await enter(T):finish();return
	state=sd();records.append({"purple_return_to_same_site_alias":state})
	if not need(foot().distance_to(Vector2(2700,1240))<.05 and int(state.actor_level)==2,"PURPLE_RETURN_ALIAS_L2_EXACT"):finish();return
	if not await near(T,Vector2(1700,4200)) or not await enter(W):finish();return
	if not need(foot().distance_to(Vector2(1700,4100))<.05,"ALIAS_ORIGINAL_SOUTH_EXIT_TO_WGATE_NOT_WORLD"):finish();return
	if not await setup(H,null,3006) or not await near(H,Vector2(2700,3030)):finish();return
	var ramp_seen := false;var layer_ok := true
	for frame: int in range(145):
		if foot().y<=2764:break
		key(KEY_W);await tick();state=sd();ramp_seen=ramp_seen or int(state.active_ramp)>=0;layer_ok=layer_ok and float(state.actor_height)>=-.01 and float(state.actor_height)<=240.01
	key(KEY_NONE);await tick();state=sd();records.append({"one_actual_H_mainrise_up":state,"ramp_seen":ramp_seen})
	if not need(ramp_seen and layer_ok and int(state.actor_level)==1 and int(state.active_ramp)==-1 and absf(float(state.actor_height)-240)<.01 and foot().y<=2764,"ONE_TRUE_H_MAINRISE_UP"):finish();return
	await shot("huashan_native_cliff_and_stair")
	if not await walk(Vector2(2700,3030),145):finish();return
	state=sd()
	if not need(int(state.actor_level)==0 and int(state.active_ramp)==-1 and absf(float(state.actor_height))<.01,"SAME_H_STAIR_TRUE_DOWN"):finish();return
	if not await near(H,Vector2(2770,890)):finish();return
	if not opaque_ghost():finish();return
	await shot("huashan_opaque_hall_live_actor_ghost")
	finish()
