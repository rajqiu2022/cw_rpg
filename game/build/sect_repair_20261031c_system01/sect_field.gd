extends "res://build/sect_completion_20261030a_system01/sect_field.gd"
## Only two adopted original outdoor IDs; unchanged draft controller/terrain.
const ADOPTION=preload("res://build/sect_repair_20261031c_system01/adoption_contract.gd")
var _adoption_spawn: Dictionary={}

func _load_scene(id: StringName) -> SceneScript:
	if not ADOPTION.IDS.has(id) or not REG.source_valid():return null
	var original:=load("res://data/scenes/"+String(id)+".tres") as SceneScript
	if original==null:return null
	var copy:=original.duplicate(false) as SceneScript
	copy.actor_positions_are_feet=true
	return copy

func _setup_scene(scene: SceneScript,spawn: Variant=null,progressive: bool=false) -> void:
	if scene==null or not ADOPTION.IDS.has(scene.scene_id):_adoption_reject("门派身份不匹配");return
	var data:=ADOPTION.town(scene.scene_id)
	var foot: Vector2=spawn*data.size if spawn is Vector2 else data.arrival
	if not ADOPTION.safe_native(scene.scene_id,foot):_adoption_reject("门派落脚未通过完整净空校验");return
	if is_instance_valid(native_town):
		native_town.controls_enabled=false;world_container.remove_child(native_town);native_town.queue_free();native_town=null
	super._setup_scene(scene,foot/data.size,progressive)
	if _field_loading_failed or not is_instance_valid(native_town):_adoption_reject("原门派业务或原生宿主未就绪");return
	if not bool(native_town.get("native_visual_ready")):_adoption_reject("原生岩阶来源未通过严格校验");return
	_restore_native_terrain(foot)
	_adoption_spawn=SceneRouter.get_field_payload().get("sect_adoption_spawn_report",{}).duplicate(true)
	_field_loading_stage="新版室外与原业务入口已就绪"

func _adoption_reject(reason: String) -> void:
	if is_instance_valid(native_town):native_town.controls_enabled=false
	_player=null;_field_loading_failed=true;_scene_rebuilding=false;_field_loading_stage=reason

func prepare_rows(scene: SceneScript) -> void:
	var authored:=ADOPTION.raw(scene.scene_id)
	if scene.scene_id in [ADOPTION.WUDANG,ADOPTION.TAIJI]:
		# Merge only original rows of the already-rendered same outdoor site.
		# No duplicate "enter taiji" portal; original purple-cloud target survives.
		var gate:=load("res://data/scenes/openworld_wudang_gate.tres") as SceneScript
		var taiji:=load("res://data/scenes/openworld_wudang_taiji_court.tres") as SceneScript
		npc_rows=gate.npcs.duplicate(true);portal_rows=[];interaction_rows=[]
		var return_id: String="return_wudang_gate" if scene.scene_id==ADOPTION.TAIJI else "return_world"
		var return_source: SceneScript=taiji if scene.scene_id==ADOPTION.TAIJI else gate
		for original: Dictionary in return_source.map_layout.portals:
			if String(original.get("id",""))==return_id:portal_rows.append(original.duplicate(true))
		for original: Dictionary in taiji.map_layout.portals:
			if String(original.get("id",""))=="to_wudang_purple_cloud_court":portal_rows.append(original.duplicate(true))
		interaction_rows.append_array(gate.map_layout.interactions.duplicate(true))
		interaction_rows.append_array(taiji.map_layout.interactions.duplicate(true))
		interaction_rows.append_array(_legacy_hotspots_to_interactions(gate.hotspots))
		interaction_rows.append_array(_legacy_hotspots_to_interactions(taiji.hotspots))
	else:
		npc_rows=scene.npcs.duplicate(true);portal_rows=scene.map_layout.portals.duplicate(true)
		interaction_rows=scene.map_layout.interactions.duplicate(true)
		interaction_rows.append_array(_legacy_hotspots_to_interactions(scene.hotspots))
	if npc_rows.size()!=authored.original_npcs.size() or portal_rows.size()!=2 or not interaction_rows.is_empty():
		_field_loading_failed=true;push_error("[Sect31c] Original business row shape changed");return
	for npc: Dictionary in npc_rows:
		if not authored.npc_feet.has(String(npc.get("npc_id",""))):_field_loading_failed=true;return
		npc.pos=ADOPTION.vec(authored.npc_feet[String(npc.npc_id)])/_world_size
	for portal: Dictionary in portal_rows:
		if not authored.portal_feet.has(String(portal.get("id",""))):_field_loading_failed=true;return
		portal.pos=ADOPTION.vec(authored.portal_feet[String(portal.id)])/_world_size
		portal.size=Vector2(120,90)/_world_size;portal.show_destination_label=true
	if scene.scene_id==ADOPTION.WUDANG:
		# The World door now leads to this outdoor map. Keep the assembly
		# available from the same destination, including pre-story visits.
		var assembly_foot: Vector2=ADOPTION.ASSEMBLY_GATE_FOOT
		if not ADOPTION.safe_native(scene.scene_id,assembly_foot):
			_field_loading_failed=true;return
		portal_rows.append({
			"id":"wudang_to_wulin_assembly", "label":"前往武林会场",
			"target_scene":String(ADOPTION.ASSEMBLY), "target_pos":Vector2(0.11,0.78),
			"pos":assembly_foot/_world_size, "size":Vector2(120,90)/_world_size,
			"show_destination_label":true
		})

func _restore_native_terrain(foot: Vector2) -> void:
	var terrain: Node=native_town.terrain
	terrain.reset_actor(terrain.level_at(foot))
	var ramp:=ADOPTION.ramp_at(_current_scene.scene_id,foot)
	if ramp>=0:
		terrain.actor_level=int(terrain.ramps[ramp].low);terrain.active_ramp=ramp
		terrain.apply_actor_mask();terrain.after_move()
	terrain.project_actor();native_town.update_view();_world_camera.force_update_scroll()

func rebuild_business() -> void:
	super.rebuild_business()
	for zone in _exit_nodes:
		if not is_instance_valid(zone) or String(zone.action)!="world_map":continue
		# The original row/action is retained. Reuse the existing native registry's
		# exact World-return route, avoiding generic gateway overwrite of real feet.
		for connection: Dictionary in zone.exit_action_triggered.get_connections():
			zone.exit_action_triggered.disconnect(connection.callable)
		zone.exit_action_triggered.connect(_on_original_world_action)

func _on_original_world_action(action: String) -> void:
	if action!="world_map" or not is_instance_valid(native_town) or not native_town.controls_enabled:return
	if _current_scene==null or SceneRouter.get_current_field_id()!=_current_scene.scene_id or native_town.terrain.actor_level!=0 or native_town.terrain.active_ramp>=0:return
	if not ADOPTION.safe_native(_current_scene.scene_id,_player.position) or not REG.actor_shape_clear(_player):return
	REG.leave_town(_current_scene.scene_id)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(native_town) or not is_instance_valid(_player):return
	var owned: bool=is_inside_tree() and not is_queued_for_deletion() and get_tree().current_scene==self and _current_scene!=null and SceneRouter.get_current_field_id()==_current_scene.scene_id
	native_town.controls_enabled=owned and _player.can_move and not _system_panel_open and not DialogPlayer.is_playing() and not native_town.show_details and not _scene_rebuilding and not bool(LoadingManager.get("_transition_active"))
	if not owned or _scene_rebuilding or bool(LoadingManager.get("_transition_active")):return
	SceneRouter.set_field_return_spawn(_player.position/_world_size)

func interact() -> void:
	if not is_instance_valid(native_town) or not native_town.controls_enabled or DialogPlayer.is_playing() or _system_panel_open:return
	var level: int=native_town.terrain.actor_level
	for npc in _npc_nodes:
		if is_instance_valid(npc) and npc.get_meta("sect_floor",-1)==level and npc.try_interact():return
	for zone in _exit_nodes:
		if is_instance_valid(zone) and zone.get_meta("sect_floor",-1)==level and zone.try_interact():return
	# The original controllers implement this bounded Space explanation inline;
	# adapt it here without set_script, synthetic input or new story dialogs.
	var nearest: Node2D;var distance:=220.0
	for item: Node in native_town.get_node("Town").get_children():
		if not item is Node2D or not item.has_meta("label") or int(item.get_meta("terrain_level",0))!=level:continue
		var delta: float=_player.global_position.distance_to(item.global_position)
		if delta<distance:distance=delta;nearest=item
	native_town.get_node("UI/Detail/Text").text=str(nearest.get_meta("label")) if nearest!=null else "WASD移动，靠近人物或出入口按空格交互。"
	native_town.show_details=true;native_town.update_view()

func _on_exit_triggered(target: String,pos: Vector2,source: Vector2) -> void:
	if not is_instance_valid(native_town) or _current_scene==null:return
	var authored:=ADOPTION.raw(_current_scene.scene_id)
	if _current_scene.scene_id in [ADOPTION.WUDANG,ADOPTION.TAIJI] and target==String(ADOPTION.PURPLE):
		source=ADOPTION.vec(authored.purple_return)/_world_size
	elif _current_scene.scene_id==ADOPTION.TAIJI and target==String(ADOPTION.WUDANG):
		# Keep original return target/UV. Entry explicitly restores the gate identity
		# at its authored outer entry, never alias->World or a default World foot.
		source=ADOPTION.vec(authored.arrival)/_world_size
	elif target==String(authored.inner_source):source=ADOPTION.vec(authored.inner_return)/_world_size
	super._on_exit_triggered(target,pos,source)

func get_sect_adoption_debug() -> Dictionary:
	if not is_instance_valid(native_town):return {"configured":false}
	return {"configured":true,"id":_current_scene.scene_id,"source_scene":row.scene,"version":ADOPTION.VERSION,"actor_foot":_player.position,"actor_level":native_town.terrain.actor_level,"actor_height":native_town.terrain.actor_height,"active_ramp":native_town.terrain.active_ramp,"controls_enabled":native_town.controls_enabled,"spawn_report":_adoption_spawn.duplicate(true),"npcs":npc_rows.duplicate(true),"portals":portal_rows.duplicate(true),"interactions":interaction_rows.duplicate(true),"native_instance":native_town.get_instance_id(),"source_scene_business_retained":true,"taiji_same_site_integrated":_current_scene.scene_id in [ADOPTION.WUDANG,ADOPTION.TAIJI],"retired_same_site_arrow":"to_wudang_taiji_court" if _current_scene.scene_id in [ADOPTION.WUDANG,ADOPTION.TAIJI] else "","original_taiji_business_destination":String(ADOPTION.PURPLE) if _current_scene.scene_id in [ADOPTION.WUDANG,ADOPTION.TAIJI] else "","opaque_actor_ghost":native_town.repair_ghost.get_debug_state()}
