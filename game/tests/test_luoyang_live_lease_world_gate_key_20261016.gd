extends "res://tests/helpers/luoyang_live_lease_key_20261016.gd"
## One real world->Gate->world->sameGate; no other city, room, crowd or story replay.
func _run() -> void:
	await _lease_run("WORLD_GATE_KEY",180000)
func _exercise() -> bool:
	var router: Node=root.get_node("SceneRouter")
	var original: SceneScript=ResourceLoader.load("res://data/scenes/world_map_jianghu.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var portals: Array=[]
	for item: Dictionary in original.map_layout.portals:
		if String(item.get("target_scene",""))=="ch4_s0_luoyang_gate": portals.append(item)
	if not check(portals.size()==1,"One immutable original world Luoyang entry"): return false
	var entry: Vector2=portals[0].pos*Vector2(12288,8192)
	var setup: Vector2=entry+Vector2(0,96)
	var started: int=Time.get_ticks_usec()
	var accepted: bool=router.call("go_field_smart",StringName(WORLD_ID),setup/Vector2(12288,8192),"",15)
	records.append({"kind":"PUBLIC_WORLD_NEAR_SETUP_NOT_TRAVEL","accepted":accepted,"public_usec":Time.get_ticks_usec()-started,"entry":entry,"setup":setup})
	if not check(accepted,"Legal public current15 near-world setup") or not await _wait_target(WORLD_ID) or not _bind_world(): return false
	if not await _walk(PackedVector2Array([(field.get("_player") as Node2D).position,entry])) or not _zone("ch4_s0_luoyang_gate"): return false
	if not await _space("ch4_s0_luoyang_gate","FIRST_COLD_GATE") or not _bind_city("ch4_s0_luoyang_gate"): return false
	if not await _walk(PackedVector2Array([(field.get("_player") as Node2D).position,Vector2(1536,1800),Vector2(1536,1860)])) or not _zone("","world_map") or not _retain(): return false
	var first_id: int=field.get_instance_id()
	if not await _space(WORLD_ID,"REAL_EXIT_TO_WORLD") or not _bind_world(): return false
	var parked: Dictionary=router.call("get_resident_city_state")
	var old_player: CharacterBody2D=retained_field.get("_player") as CharacterBody2D
	if not check(parked.get("occupied")==true and parked.get("parked")==true and parked.get("excursion_kind")=="world" and parked.field_id==first_id and not retained_field.is_inside_tree() and not old_player.is_inside_tree() and not PhysicsServer2D.body_get_space(old_player.get_rid()).is_valid() and parked.estimated_bytes<=LEASE.LIMIT_BYTES,"Real world ready while only original city retained outside tree/Physics",parked): return false
	# Actual prepare cancellation, not private portal activation; normal final entry remains Space.
	var world_field: Node=field
	var world_foot: Vector2=(field.get("_player") as Node2D).position
	if not check(bool(router.call("go_field_smart",&"ch4_s0_luoyang_gate",Vector2(1536,1860)/Vector2(3072,2048),"",-1,C.VERSION)),"Public warm queued for controlled cancellation"): return false
	var queued: Dictionary=router.call("get_resident_city_state")
	var token: int=int(queued.get("return",{}).get("token",0))
	if not check(token>0 and router.call("cancel_public_city_preparation",token),"Actual queued warm public cancellation"): return false
	await process_frame;await physics_frame
	if not check(current_scene==world_field and (field.get("_player") as Node2D).position==world_foot and bool(field.get("_player").get("can_move")) and not router.call("cancel_public_city_preparation",token),"Cancel restores original world/foot and stale token rejected"): return false
	if not await _walk(PackedVector2Array([world_foot,entry])) or not _zone("ch4_s0_luoyang_gate"): return false
	if not await _space("ch4_s0_luoyang_gate","SECOND_GATE_AFTER_REAL_WORLD",true) or not _bind_city("ch4_s0_luoyang_gate") or not _same_retained(): return false
	if not check((field.get("_player") as Node2D).position==Vector2(1536,1860),"World return exact original city departure feet"): return false
	return await _walk(PackedVector2Array([Vector2(1536,1860),Vector2(1568,1860)])) and await _capture("same_gate_after_real_world_reentry")
