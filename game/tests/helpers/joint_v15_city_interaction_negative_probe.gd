extends RefCounted
## NEW genuine input negatives. No trigger invocation, mocked Area overlap,
## teleports, disabled NPCs or injected result/event. Source polygons and actual
## Physics Area geometry are checked separately before ordinary movement/input.
const CITY := preload("res://scripts/city/luoyang_layered_v3_contract.gd")
const IDS: Array[String]=["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]
const BODY := Vector2(34,24)
var phase: RefCounted
var tree: SceneTree
var driver: RefCounted
var probe: RefCounted
var field: Node
var checks: int=0
var failures: int=0
var records: Array[Dictionary]=[]
var identities: Dictionary={}

func _check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failures+=1
	phase.call("_check",ok,"city interaction negative: "+label)
	return ok

func _point(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size()==2: return Vector2(float(value[0]),float(value[1]))
	return Vector2(INF,INF)

func _polygon(value: Variant) -> PackedVector2Array:
	var polygon:=PackedVector2Array()
	if value is Array:
		for vertex: Variant in value: polygon.append(_point(vertex))
	return polygon

func _body(p: Vector2) -> PackedVector2Array:
	var r:=Rect2(p-BODY*.5,BODY)
	return PackedVector2Array([r.position,r.position+Vector2(r.size.x,0),r.end,r.position+Vector2(0,r.size.y)])

func _source_relation(p: Vector2,polygon: PackedVector2Array,overlapping: bool) -> bool:
	return not Geometry2D.is_point_in_polygon(p,polygon) and (not Geometry2D.intersect_polygons(_body(p),polygon).is_empty())==overlapping

func _target_area(id: String) -> Area2D:
	for node: Area2D in field.get("_trigger_areas"):
		if not is_instance_valid(node): continue
		var data: Dictionary=node.get_meta("trigger_data",{})
		if String(data.get("id",""))==id: return node
	return null

func _area_binding(area: Area2D,source: PackedVector2Array) -> bool:
	var container: Node2D=field.get("world_container") as Node2D
	var found: int=0
	for child: Node in area.get_children():
		if child is CollisionShape2D and not child.disabled: return false
		if not child is CollisionPolygon2D or child.disabled: continue
		var actual:=PackedVector2Array()
		for vertex: Vector2 in child.polygon: actual.append(container.to_local(child.to_global(vertex)))
		if actual!=source: return false
		found+=1
	return found==1 and area.collision_layer==4 and area.collision_mask==2

func _actual_area_query(p: Vector2,target: Area2D,overlapping: bool) -> bool:
	var player: Node2D=field.get("_player") as Node2D
	var collision: CollisionShape2D=player.get_node("CollisionShape2D") as CollisionShape2D
	var container: Node2D=field.get("world_container") as Node2D
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=collision.shape
	query.transform=collision.global_transform
	query.transform.origin+=container.to_global(p)-player.global_position
	query.exclude=[player.get_rid()]
	query.collision_mask=4
	query.collide_with_areas=true
	query.collide_with_bodies=false
	var hits: Array[Dictionary]=player.get_world_2d().direct_space_state.intersect_shape(query,256)
	if hits.size()>=256: return false
	var target_hit: bool=false
	for hit: Dictionary in hits:
		if hit.get("collider")==target: target_hit=true
		else: return false # Avoid another normal NPC/exit/trigger consuming Space.
	return target_hit==overlapping

func _choose_station(polygon: PackedVector2Array,target: Area2D,overlapping: bool) -> Vector2:
	var candidates: Dictionary={}
	for index in polygon.size():
		var a: Vector2=polygon[index]
		var b: Vector2=polygon[(index+1)%polygon.size()]
		var normal: Vector2=(b-a).orthogonal().normalized()
		for along in 9:
			var center: Vector2=a.lerp(b,float(along)/8)
			for offset: float in [1.0,3.0,6.0,9.0,12.0,16.0,20.0,24.0,32.0,40.0,64.0]:
				candidates[center+normal*offset]=true
				candidates[center-normal*offset]=true
	var best:=Vector2(INF,INF)
	var distance: float=INF
	var player: Node2D=field.get("_player") as Node2D
	for p: Vector2 in candidates:
		if not _source_relation(p,polygon,overlapping) or not bool(probe.call("clear",p)) or not _actual_area_query(p,target,overlapping): continue
		var d: float=p.distance_squared_to(player.position)
		if d<distance: distance=d; best=p
	return best

func _state() -> Dictionary:
	var result: Dictionary=phase.call("_state")
	var save: Node=tree.root.get_node("SaveManager")
	var game: Node=tree.root.get_node("GameState")
	result["player"]=save.call("_serialize_stats",game.get("player"))
	var party: Array[Dictionary]=[]
	for member: Resource in game.get("party"): party.append(save.call("_serialize_stats",member))
	result["party"]=party
	result["scene_instance_id"]=tree.current_scene.get_instance_id() if is_instance_valid(tree.current_scene) else 0
	result["scene_file_path"]=tree.current_scene.scene_file_path if is_instance_valid(tree.current_scene) else ""
	result["normal_slot"]=save.get("active_slot")
	return result

func _no_effect_input(region: String,id: String,kind: String,mode: String,area: Area2D,sprite: Sprite2D,polygon: PackedVector2Array,source_overlap: bool) -> bool:
	var player: Node2D=field.get("_player") as Node2D
	var input_feet: Vector2=player.position
	var before: Dictionary=_state()
	var event_start: int=(phase.get("events") as Array).size()
	var relation: bool=_source_relation(player.position,polygon,source_overlap)
	var actual_overlap: bool=area.overlaps_body(player)
	var predicates: Dictionary={"full875_and17_and_physics":probe.call("clear",player.position),"source_foot_outside":not Geometry2D.is_point_in_polygon(player.position,polygon),"source_body_overlap":not Geometry2D.intersect_polygons(_body(player.position),polygon).is_empty(),"actual_area_overlap":actual_overlap}
	if not _check(relation and actual_overlap==source_overlap and bool(predicates.full875_and17_and_physics),"actual arrived foot/body/Area still matches independent negative station"): return false
	var input: Dictionary={"mode":"space"}
	if mode=="space": await driver.call("key",KEY_SPACE)
	else:
		input=await probe.call("click_entity",sprite)
		_check(bool(input.get("ok",false)) and float(input.get("alpha",0))>.12,"wrong-side mouse really hits current visible entity, not arbitrary ground")
	await driver.call("completed_actor_stage")
	for tick in 3: await tree.physics_frame
	await driver.call("completed_actor_stage")
	var after: Dictionary=_state()
	var unchanged: bool=before==after and (phase.get("events") as Array).size()==event_start and not bool(tree.root.get_node("DialogPlayer").call("is_playing"))
	_check(unchanged,"normal "+mode+" rejected "+kind+" with zero dialogue/action/reward/navigation/domain effects")
	# An unexpectedly accepted action may have freed Field/Player. Preserve the
	# actual pre-input feet without dereferencing a released actor on this FAIL.
	var record: Dictionary={"region_id":region,"source_id":id,"kind":kind,"mode":mode,"dry_run":false,"predicates":predicates,"actual_feet_px":[input_feet.x,input_feet.y],"input":input,"before":before,"after":after,"events":(phase.get("events") as Array).slice(event_start),"unchanged":unchanged,"current_prop_frame":sprite.frame if is_instance_valid(sprite) else -1}
	records.append(record)
	_check(bool(phase.call("_write","negative_"+region+"_"+id+"_"+kind+"_"+mode+".json",record)),"negative actual input/state record flush/readback succeeded")
	if is_instance_valid(field) and tree.current_scene==field: await phase.call("_capture","negative_"+region+"_"+id+"_"+kind+"_"+mode)
	return unchanged and is_instance_valid(field) and tree.current_scene==field

func _padding_point(sprite: Sprite2D,target: Area2D) -> Dictionary:
	var alpha: RefCounted=probe.get("alpha")
	var rect: Rect2=sprite.get_rect()
	var viewport_rect: Rect2=tree.root.get_visible_rect()
	var player: Node2D=field.get("_player") as Node2D
	var best:=Vector2(INF,INF)
	var distance: float=INF
	var tested: int=0
	for y in range(1,ceili(rect.size.y),4):
		for x in range(1,ceili(rect.size.x),4):
			var local: Vector2=rect.position+Vector2(x,y)
			var world: Vector2=sprite.to_global(local)
			var viewport: Vector2=sprite.get_canvas_transform()*world
			if not viewport_rect.has_point(viewport) or float(alpha.call("alpha_at",sprite,world))!=0: continue
			tested+=1
			var other_visible: bool=false
			for npc: Node in field.get("_npc_nodes"):
				if float(alpha.call("alpha_at",npc.get("sprite"),world))>0: other_visible=true; break
			for zone: Node in field.get("_exit_nodes"):
				var marker: Sprite2D=zone.get("marker_visual") as Sprite2D
				if marker!=null and float(alpha.call("alpha_at",marker,world))>0: other_visible=true; break
			for original: Dictionary in (phase.get("manifest") as Dictionary).objects:
				var actual: Sprite2D=probe.call("prop",String(original.id)) as Sprite2D
				if actual!=sprite and actual!=null and float(alpha.call("alpha_at",actual,world))>0: other_visible=true; break
			if other_visible: continue
			var query:=PhysicsPointQueryParameters2D.new()
			query.position=world
			query.collision_mask=4
			query.collide_with_areas=true
			query.collide_with_bodies=false
			var hits: Array[Dictionary]=player.get_world_2d().direct_space_state.intersect_point(query,256)
			var other_area: bool=hits.size()>=256
			for hit: Dictionary in hits:
				if hit.get("collider")!=target: other_area=true
			if other_area: continue
			var d: float=world.distance_squared_to(player.global_position)
			if d<distance: best=world; distance=d
	if not best.is_finite(): return {"found":false,"tested_exact_zero_alpha":tested,"scope":"FINITE_VISIBLE_PADDING_SEARCH_NOT_ABSENCE_PROOF"}
	return {"found":true,"world_px":[best.x,best.y],"viewport_px":[(sprite.get_canvas_transform()*best).x,(sprite.get_canvas_transform()*best).y],"current_alpha":alpha.call("alpha_at",sprite,best),"texture_path":sprite.texture.resource_path,"texture_sha256":FileAccess.get_sha256(sprite.texture.resource_path),"frame":sprite.frame,"hframes":sprite.hframes,"vframes":sprite.vframes,"region_enabled":sprite.region_enabled,"flip_h":sprite.flip_h,"flip_v":sprite.flip_v,"tested_exact_zero_alpha":tested}

func _padding_case(region: String,id: String,slot: Dictionary,area: Area2D,sprite: Sprite2D,polygon: PackedVector2Array) -> void:
	var approach: Dictionary=await probe.call("move_to",_point(slot.stand_px))
	if not _check(bool(approach.get("ok",false)),"ordinary full body input reaches real positive interaction stand before padding negative"): return
	await driver.call("completed_actor_stage")
	var player: Node2D=field.get("_player") as Node2D
	if not _check(Geometry2D.is_point_in_polygon(player.position,polygon) and area.overlaps_body(player) and bool(probe.call("clear",player.position)),"padding test has legally active actor/Area; rejection cannot be attributed to being too far away"): return
	var sample: Dictionary=_padding_point(sprite,area)
	if not _check(bool(sample.get("found",false)) and float(sample.get("current_alpha",INF))==0,"actual current frame has on-screen exact-zero filtered padding with no other target hit"): return
	var before: Dictionary=_state()
	var event_start: int=(phase.get("events") as Array).size()
	var input: Dictionary=await driver.call("pointer",_point(sample.viewport_px))
	await driver.call("completed_actor_stage")
	for tick in 3: await tree.physics_frame
	await driver.call("completed_actor_stage")
	var after: Dictionary=_state()
	var unchanged: bool=before==after and (phase.get("events") as Array).size()==event_start and not bool(tree.root.get_node("DialogPlayer").call("is_playing"))
	_check(unchanged,"normal transparent padding click cannot execute the nearby enabled original action")
	var record: Dictionary={"region_id":region,"source_id":id,"kind":"current_frame_padding","mode":"mouse","dry_run":false,"sample":sample,"input":input,"before":before,"after":after,"events":(phase.get("events") as Array).slice(event_start),"unchanged":unchanged,"approach":approach}
	records.append(record)
	_check(bool(phase.call("_write","negative_"+region+"_"+id+"_padding_mouse.json",record)),"padding negative evidence checked persistence")
	if is_instance_valid(field) and tree.current_scene==field: await phase.call("_capture","negative_"+region+"_"+id+"_padding_mouse")

func run(owner: RefCounted) -> Dictionary:
	phase=owner
	tree=phase.get("tree") as SceneTree
	driver=phase.get("driver") as RefCounted
	for region: String in IDS:
		var old: SceneScript=CITY.legacy_scene(StringName(region))
		if not _check(old!=null,"immutable original interaction identities available"): continue
		for original: Dictionary in old.map_layout.interactions:
			phase.call("_public_fixture",original)
			if not _check(bool(await phase.call("_open",region)),"normal current native city opens required flag/quest fixture"): continue
			field=phase.get("field")
			probe=phase.get("probe")
			var id: String=String(original.id)
			var manifest: Dictionary=phase.get("manifest")
			var slot: Dictionary=phase.call("_slot",manifest.gameplay_slots.interactions,id)
			var area: Area2D=_target_area(id)
			var sprite: Sprite2D=probe.call("prop",String(slot.get("object_id",""))) as Sprite2D
			var polygon: PackedVector2Array=_polygon(slot.get("interaction_polygon_px"))
			if not _check(area!=null and sprite!=null and polygon.size()>=3 and not Geometry2D.triangulate_polygon(polygon).is_empty() and _area_binding(area,polygon),"original identity maps exact source polygon to one actual enabled Area and current independent entity"): continue
			identities[region+"/"+id]=true
			var still_field: bool=true
			for overlapping: bool in [true,false]:
				if not still_field: break
				var kind: String="wrong_side_body_overlap" if overlapping else "safe_feet_no_body_area_overlap"
				var station: Vector2=_choose_station(polygon,area,overlapping)
				if not _check(station.is_finite(),"bounded independently legal "+kind+" station exists; no fake empty-domain PASS"): continue
				var approach: Dictionary=await probe.call("move_to",station)
				if not _check(bool(approach.get("ok",false)),"actual normal input path reaches "+kind+" without teleport/physics suppression"): continue
				await driver.call("completed_actor_stage")
				for mode: String in ["space","mouse"]:
					still_field=await _no_effect_input(region,id,kind,mode,area,sprite,polygon,overlapping)
					if not still_field: break
			if still_field: await _padding_case(region,id,slot,area,sprite,polygon)
	_check(identities.size()==11 and records.size()==55,"all original11 identities each have 2 wrong-side +2 area-exclusion +1 genuine current-padding actual inputs")
	var result: Dictionary={"scope":"ALL11_CITY_ORIGINAL_INTERACTION_ACTUAL_INPUT_NEGATIVES_NOT_FULL_ANIMATION_OR_VISUAL","checks":checks,"failures":failures,"complete":failures==0 and identities.size()==11 and records.size()==55,"interaction_ids":identities.keys(),"records":records.duplicate(true),"engine_pid":OS.get_process_id(),"source_sha256":FileAccess.get_sha256(get_script().resource_path)}
	_check(bool(phase.call("_write","actual_city_interaction_input_negatives.json",result)),"complete negative index checked readback")
	result.checks=checks
	result.failures=failures
	result.complete=failures==0 and identities.size()==11 and records.size()==55
	driver=null
	probe=null
	field=null
	phase=null
	tree=null
	return result
