extends RefCounted
## One exact new room. Existing six-room compiler/session/other rooms unchanged.
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const Content = preload("res://build/luoyang_regions_20261027d_source01/region_content_compiler.gd")
const Donor = preload("res://build/luoyang_regions_20261027d_source01/room_furniture_terminal.gd")
const Scope = preload("res://build/luoyang_regions_20261027d_source01/region_room_compiler.gd")
const HOME := "res://build/luoyang_yihongyuan_20261029n_system01/"
const ID := "yihongyuan27n_interior"
const LOGICAL := "ch4_s3_luoyang_market"
const CIVIC := "luoyang_civic_market_region_27d"
const RETURN := Vector2(5206.18,4280)

static func media(path: String, pins: Dictionary) -> bool:
	if not FileAccess.file_exists(path): return false
	pins[path] = FileAccess.get_sha256(path)
	if not path.ends_with(".png"): return true
	var sidecar: String = path + ".import"
	if not FileAccess.file_exists(sidecar): return false
	var re := RegEx.new(); re.compile('path="(res://[^"\\r\\n]+\\.ctex)"')
	var found: RegExMatch = re.search(FileAccess.get_file_as_string(sidecar))
	if found == null or not FileAccess.file_exists(found.get_string(1)): return false
	pins[sidecar] = FileAccess.get_sha256(sidecar)
	pins[found.get_string(1)] = FileAccess.get_sha256(found.get_string(1))
	return true

static func points(raw: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p: Variant in raw: result.append(Core.vec(p))
	return result

static func compile(author: Dictionary, market: Dictionary) -> Dictionary:
	var path: String = HOME + "interior_definition_CANDIDATE.json"
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	if spec.get("id") != ID or Core.vec(spec.get("world_size_px")) != Vector2(1536,1024): return Core.fail("YIHONG_ROOM_DEFINITION")
	var lore_path: String = String(spec.lore_spec)
	var lore: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(lore_path))
	var sources: Dictionary = market.sources.duplicate(true)
	sources[path] = FileAccess.get_sha256(path); sources[lore_path] = FileAccess.get_sha256(lore_path)
	if not media(spec.shell.texture,sources): return Core.fail("YIHONG_NATIVE_SHELL_SOURCE")
	var inputs: Dictionary = {LOGICAL:market}
	for binding: Dictionary in spec.furniture_donors:
		var donor_author: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(binding.path))
		var available: Dictionary = {}
		for item: Dictionary in donor_author.furniture:
			if not media(item.texture,available): return Core.fail("YIHONG_DONOR_MEDIA",item.texture)
		var request: Dictionary = binding.duplicate(true); request.sha256=FileAccess.get_sha256(binding.path)
		var built: Dictionary = Donor.build(request,available)
		if built.get("ok")!=true: return built
		inputs[binding.logical_id]=built.terminal
	var boundary: Array=[]
	# Explicit source-native wall bands follow the authored hall floor, not a
	# guessed whole-image rectangle and not an extruded synthetic room wall.
	boundary=[[[0,0],[1536,0],[1536,448],[0,448]],[[0,448],[240,448],[122,822],[0,822]],[[1292,448],[1536,448],[1536,822],[1400,822]],[[0,822],[650,822],[650,1024],[0,1024]],[[898,822],[1536,822],[1536,1024],[898,1024]],[[650,941],[898,941],[898,1024],[650,1024]]]
	var door: Dictionary={"id":"yihongyuan27n_exit","foot_px":spec.exit_foot_px,"source_spawn_px":spec.exit_source_spawn_px,"size_px":[88,42],"target_scene":CIVIC,"target_world_size_px":[6144,4608],"target_foot_px":[RETURN.x,RETURN.y],"label":"返回怡红院门前"}
	var room: Dictionary={"id":ID,"world_size_px":spec.world_size_px,"safe_spawn_uv":[.5,850.0/1024.0],"ground":[{"id":"native_hall_floor","rect":[[0,0],[1536,1024]],"texture_role":"yihongyuan_native_hall","period_px":[1536,1024]}],"enclosure":{"wall_ground_polygons_px":boundary},"furniture_instances":spec.furniture_instances,"portals":[door],"routes":[{"id":"central_reception_aisle","points_px":[[768,850],[768,590]]},{"id":"central_door_approach","points_px":[[768,850],[768,920]]}]}
	var parent: Dictionary={"rooms":[room]}
	var materialized: Dictionary=Content.room_definition(parent,ID,inputs,sources)
	if materialized.get("ok")!=true:return materialized
	var terminal: Dictionary=materialized.inputs[ID]
	var placements: Dictionary={}; var daily: Dictionary={}
	var ordinal: int=0
	for npc: Dictionary in lore.npcs:
		var id: String="yihongyuan27n_"+["matron","waiter","merchant","scholar","elder_guest","woman_guest"][ordinal]
		var foot: Vector2=Core.vec(npc.foot_px)
		if ordinal==0:foot=Vector2(1150,520) # Behind counter; 64px from clear front foot1150,584.
		if not media(npc.sprite,sources):return Core.fail("YIHONG_NPC_SPRITE",id)
		var portrait: String=String(npc.get("portrait","") if npc.get("portrait")!=null else "")
		if not portrait.is_empty() and not media(portrait,sources):return Core.fail("YIHONG_NPC_PORTRAIT",id)
		var image:=Image.load_from_file(npc.sprite)
		var cell: Image=image.get_region(Rect2i(0,0,mini(image.get_width(),image.get_height()),image.get_height()))
		var bounds: Rect2i=cell.get_used_rect()
		if bounds.size.y<=0:return Core.fail("YIHONG_NPC_ALPHA",id)
		var calibrated: bool=ordinal==1
		var ratio: float=(120.0/140.0) if calibrated else 120.0/float(bounds.size.y)
		var talks: bool=npc.get("dialogue") is Dictionary
		var data: Dictionary={"npc_id":id,"npc_name":npc.role,"sprite_path":npc.sprite,"portrait_path":portrait,"dialog_id":("yihongyuan_daily_"+id if talks else ""),"interaction_action":"","scale":ratio,"movement_mode":("seated" if ordinal>=4 else "idle"),"conversation_base_facing":"front","dialog_variants":[]}
		terminal.npcs.append({"data":data,"foot_px":foot,"ground_anchored":true,"body_offset_px":Vector2.ZERO,"half_body":Vector2(cell.get_width()*ratio*.07,image.get_height()*ratio*.09),"default_active":true})
		placements[id]=[foot.x,foot.y]
		if talks:daily[id]={"hero":npc.dialogue.hero,"lines":[npc.dialogue.npc]}
		ordinal+=1
	terminal.sources.merge(sources,true)
	materialized.region.districts[0].actors=placements
	materialized.region.districts[0].legacy_version_migrations={}
	materialized.region["portal_region_return_feet"]={ID:{"yihongyuan27n_exit":spec.exit_source_spawn_px}}
	var local: Dictionary=author.duplicate(true)
	local.regions[ID]=materialized.region
	local.texture_roles["yihongyuan_native_hall"]={"path":spec.shell.texture,"source_sha256":{spec.shell.texture:sources[spec.shell.texture],spec.shell.texture+".import":sources[spec.shell.texture+".import"]}}
	var out: Dictionary=Content.compile(local,ID,materialized.inputs)
	if out.get("ok")!=true:return out
	for actor: Dictionary in out.npcs:actor.logical_id=LOGICAL;actor.slot_key=LOGICAL+"/"+actor.data.npc_id
	out["source_context_ids"]=[LOGICAL];out["room_source_logical_id"]=LOGICAL
	out["navigation_kind"]="AUTHORED_INTERIOR";out["room_enclosure"]={"wall_ground_polygons_px":boundary,"native_complete_shell":spec.shell.texture}
	out["physical_phase_scope"]=Scope.source_scope(inputs,[LOGICAL])
	out["room_display_name"]=spec.display_name;out["yihongyuan_daily"]=daily
	out["yihongyuan_zones"]=spec.zones;out["future_story_anchors"]=spec.future_story_anchors
	for portal: Dictionary in out.portals:portal.data["region27d_target"]={"region_id":CIVIC,"logical_id":LOGICAL,"foot_px":[RETURN.x,RETURN.y]}
	if not Core.safe_body(out,Vector2(768,850),Vector2(17,12)):return Core.fail("YIHONG_ARRIVAL_BODY")
	if not Core.safe_body(out,Vector2(1150,584),Vector2(17,12)):return Core.fail("YIHONG_COUNTER_FRONT")
	if not Core.safe_segment(out,Vector2(768,850),Vector2(768,586),Vector2(17,12)) or not Core.npc_route_clear(out,Vector2(768,850),Vector2(768,586),Vector2(17,12)):return Core.fail("YIHONG_AISLE_TO_RECEPTION")
	if not Core.safe_segment(out,Vector2(768,586),Vector2(1152,586),Vector2(17,12)) or not Core.npc_route_clear(out,Vector2(768,586),Vector2(1152,586),Vector2(17,12)):return Core.fail("YIHONG_COUNTER_APPROACH")
	if Vector2(1150,584).distance_to(Vector2(1150,520))>80:return Core.fail("YIHONG_MATRON_REACH")
	return out
