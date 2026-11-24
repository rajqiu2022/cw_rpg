extends RefCounted
## Fourth-layer candidate only: validate complete original C first, then compose
## explicit source-bound deltas. No C/Router/Field activation lives here.
const C = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const ROOT := "res://art/maps/luoyang_city_revision_retry2_20261015/"
const AUTHOR_PATH := ROOT+"author.json"
const AUTHOR_SHA := "cf904eae70c2f789e123c9249b4b47aea6fdb0c63cec7d99a61a4cffe66d935d"
const HOME_PATH := "res://data/maps/luoyang_home_candidates_20261015/home_author.json"
const HOME_SHA := "83448c815954c4efc4a081e642b591b190f72d6552bf49bd0bd40ca5edea96da"
const META := "city_frontage_revision_manifest_sha"
const FLAG := "--luoyang-city-revision-candidate-retry2-20261015"

static func _read(path: String,sha: String) -> Dictionary:
	if not C._hash(sha) or FileAccess.get_sha256(path).to_lower()!=sha.to_lower(): return {}
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

static func author() -> Dictionary:
	var value:=_read(AUTHOR_PATH,AUTHOR_SHA)
	if value.get("status")!="AUTHOR_CANDIDATE_NOT_PUBLISHED_NOT_FORMAL" or value.get("scenes",[]).size()!=2 or value.get("home_author_sha256")!=HOME_SHA: return {}
	for path: String in value.get("source_sha256",{}):
		if not path.begins_with("res://") or ".." in path or FileAccess.get_sha256(path).to_lower()!=String(value.source_sha256[path]).to_lower(): return {}
	return value

static func homes() -> Dictionary:
	var value:=_read(HOME_PATH,HOME_SHA)
	if value.get("room_count")!=9 or value.get("formal_enabled")!=false: return {}
	for path: String in value.get("source_sha256",{}):
		if not path.begins_with("game/"): return {}
		if FileAccess.get_sha256("res://"+path.trim_prefix("game/")).to_lower()!=String(value.source_sha256[path]).to_lower(): return {}
	return value

static func spec_for(authoring: Dictionary,id: StringName) -> Dictionary:
	for value: Dictionary in authoring.get("scenes",[]):
		if value.get("scene_id")==String(id): return value
	return {}

static func _find(items: Array,key: String,value: String) -> Dictionary:
	var found: Dictionary={}
	for item: Dictionary in items:
		if item.get(key)==value:
			if not found.is_empty(): return {}
			found=item
	return found

static func _xy(p: Vector2) -> Array: return [float(p.x),float(p.y)]
static func _rect_polygon(center: Vector2,half: Vector2) -> Array:
	return [_xy(center-half),_xy(center+Vector2(half.x,-half.y)),_xy(center+half),_xy(center+Vector2(-half.x,half.y))]

static func compose(original: Dictionary,spec: Dictionary,home: Dictionary) -> Dictionary:
	# Pure: no files, resources, nodes, global navigation caches or renderer.
	if spec.get("scene_id") not in ["ch4_s3_luoyang_market","ch4_s2_canal_docks"] or not original.get("objects") is Array or not original.get("gameplay_slots") is Dictionary or not original.get("routes") is Array: return {}
	if original.get("canonical_scene_id")!=spec.get("scene_id") or original.get(spec.get("expected_parent_metadata_key",""))!=spec.get("expected_parent_metadata_sha"): return {}
	if spec.has("expected_object_ids"):
		var ids: Array=[]
		for object: Dictionary in original.objects: ids.append(object.id)
		if not C._equal_value(ids,spec.expected_object_ids) or not C._equal_value(original.gameplay_slots,spec.expected_gameplay_slots) or not C._equal_value(original.routes,spec.expected_routes): return {}
	var record:=original.duplicate(true)
	for edit: Dictionary in spec.get("object_edits",[]):
		var object:=_find(record.objects,"id",String(edit.id))
		if object.is_empty(): return {}
		for key: String in edit.before:
			if not C._equal_value(object.get(key),edit.before[key]): return {}
		var foot:=C._vec(object.world_foot_px)
		if edit.kind=="extend_solid_front_to_original_worldfoot":
			for polygon: Array in object.solid_polygons_px:
				var front: float=-INF
				for point: Variant in polygon: front=maxf(front,C._vec(point).y)
				if front>=foot.y: continue
				for index in polygon.size():
					var point:=C._vec(polygon[index])
					if point.y==front: polygon[index]=_xy(Vector2(point.x,foot.y))
			if not C._equal_value(object.world_foot_px,edit.before.world_foot_px): return {}
		elif edit.kind=="translate_back_or_side_court":
			var delta:=C._vec(edit.to_foot_px)-foot
			for key: String in ["world_foot_px","physical_center_px","world_origin_px"]:
				if object.has(key): object[key]=_xy(C._vec(object[key])+delta)
			object.depth_foot_y=float(C._vec(edit.to_foot_px).y)
			for polygon: Array in object.solid_polygons_px:
				for index in polygon.size(): polygon[index]=_xy(C._vec(polygon[index])+delta)
			object.city_revision_translation_px=_xy(delta)
		else: return {}
	for move: Dictionary in spec.get("portal_moves",[]):
		var slot:=_find(record.gameplay_slots.portals,"source_id",String(move.id))
		if slot.is_empty() or C._vec(slot.foot_px)!=C._vec(move.old_foot_px): return {}
		var foot:=C._vec(move.foot_px)
		slot.foot_px=_xy(foot); slot.arrival_foot_px=_xy(foot)
		slot.interaction_polygon_px=_rect_polygon(foot,Vector2(48,24))
		slot.passage_path_px=[_xy(foot+Vector2(0,18)),_xy(foot)]
	for change: Dictionary in spec.get("route_terminal_replacements",[]):
		var route:=_find(record.routes,"id",String(change.route_id))
		if route.is_empty() or C._vec(route.points_px.back())!=C._vec(change.old_end_px): return {}
		route.points_px[route.points_px.size()-1]=change.new_end_px.duplicate()
	for route: Dictionary in spec.get("append_routes",[]):
		if not _find(record.routes,"id",String(route.id)).is_empty(): return {}
		record.routes.append(route.duplicate(true))
	if spec.has("entry_return_move"):
		var change: Dictionary=spec.entry_return_move
		if C._vec(record.entry_foot_px)!=C._vec(change.old_foot_px) or C._vec(record.return_foot_px)!=C._vec(change.old_foot_px): return {}
		record.entry_foot_px=change.foot_px.duplicate(); record.return_foot_px=change.foot_px.duplicate()
	if spec.has("interaction_to_npc"):
		var change: Dictionary=spec.interaction_to_npc
		var interaction:=_find(record.gameplay_slots.interactions,"source_id",String(change.interaction_id))
		if interaction.is_empty() or interaction.get("object_id")!=change.object_id or C._vec(interaction.stand_px)!=C._vec(change.foot_px): return {}
		record.gameplay_slots.interactions.erase(interaction)
		record.gameplay_slots.npcs.append({"source_id":change.npc_id,"foot_px":change.foot_px.duplicate()})
	if spec.get("room_count",0)==9:
		if home.get("rooms",[]).size()!=9: return {}
		for room: Dictionary in home.rooms:
			var object:=_find(record.objects,"id",String(room.building_id))
			if object.is_empty() or C._vec(room.return_foot_px)!=C._vec(object.world_foot_px)+Vector2(0,24): return {}
			var foot:=C._vec(room.return_foot_px)
			record.gameplay_slots.portals.append({"source_id":room.candidate_entry_portal.id,"foot_px":_xy(foot),"arrival_foot_px":_xy(foot),"interaction_polygon_px":_rect_polygon(foot,Vector2(20,16)),"passage_path_px":[_xy(foot+Vector2(0,24)),_xy(foot)]})
	record.walk_path=ROOT+String(spec.scene_id)+"/walk.png"
	record.city_revision_parent_sha=spec.parent_manifest_sha256
	return record

static func _portal_from_slot(portal: Dictionary,slot: Dictionary) -> void:
	portal.pos=C._vec(slot.foot_px)/C.SIZE
	portal.arrival_foot_px=C._vec(slot.arrival_foot_px)
	portal.interaction_polygon_px=C._polygon(slot.interaction_polygon_px)
	portal.passage_path_px=slot.passage_path_px.duplicate(true)

static func apply_candidate(original_scene: SceneScript,record: Dictionary,spec: Dictionary,home: Dictionary) -> SceneScript:
	var scene: SceneScript=C.BASE._independent_copy(original_scene)
	if scene==null: return null
	scene.map_layout.visual_objects.clear()
	for authored: Dictionary in record.objects:
		var entry:=authored.duplicate(true)
		var foot:=C._vec(authored.world_foot_px); var render:=C._vec(authored.render_size_px)
		entry.pos=(foot+(Vector2(.5,.5)-C._vec(authored.foot_uv))*render)/C.SIZE
		entry.render_size_px=render; entry.centered=true
		entry.sort_by_feet=authored.get("role","")!="ground_overlay"
		if not entry.sort_by_feet: entry.z_index=-2; entry.ghost_occlusion=false
		entry.depth_sort_foot_y=foot.y/C.SIZE.y
		entry.city_v3_solid_polygons_px=authored.solid_polygons_px.duplicate(true); entry.erase("solid_polygons_px")
		scene.map_layout.visual_objects.append(entry)
	scene.map_layout.walkable_mask_path=record.walk_path
	for move: Dictionary in spec.get("portal_moves",[]):
		var portal:=_find(scene.map_layout.portals,"id",String(move.id))
		var slot:=_find(record.gameplay_slots.portals,"source_id",String(move.id))
		if portal.is_empty() or slot.is_empty(): return null
		_portal_from_slot(portal,slot)
	if spec.has("entry_return_move"): scene.player_spawn=C._vec(record.entry_foot_px)/C.SIZE
	if spec.has("interaction_to_npc"):
		var change: Dictionary=spec.interaction_to_npc
		var interaction:=_find(scene.map_layout.interactions,"id",String(change.interaction_id))
		if interaction.is_empty() or interaction.get("action")!=change.action or interaction.get("hide_flag")!=change.hide_flag: return null
		scene.map_layout.interactions.erase(interaction)
		var npc: Dictionary={"npc_id":change.npc_id,"npc_name":change.npc_name,"pos":C._vec(change.foot_px)/C.SIZE,"scale":float(change.scale),"sprite_path":change.sprite_path,"interaction_action":interaction.action,"hide_flag":interaction.hide_flag}
		if interaction.has("require_flag"): npc.require_flag=interaction.require_flag
		scene.npcs.append(npc)
	if spec.get("room_count",0)==9:
		for room: Dictionary in home.rooms:
			var portal: Dictionary=room.candidate_entry_portal.duplicate(true)
			portal.pos=C._vec(room.return_foot_px)/C.SIZE; portal.size=C._vec(portal.size); portal.target_pos=C._vec(portal.target_pos)
			portal.enabled=true; portal.candidate_only=true; portal.router_install_status="PENDING_EXPLICIT_FLAT_ID_RESOLVER"
			_portal_from_slot(portal,_find(record.gameplay_slots.portals,"source_id",String(portal.id)))
			scene.map_layout.portals.append(portal)
	scene.set_meta("city_frontage_revision_author_sha",AUTHOR_SHA)
	scene.set_meta("city_frontage_revision_runtime_status","CANDIDATE_NOT_ROUTER_INSTALLED_NOT_FORMAL")
	return scene

static func strict_arrival_receipts(spec: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for override: Dictionary in spec.get("fresh_arrival_overrides",[]):
		var key: String=override.route_key
		if not C.FRESH_AUTHORED_ROUTES.has(key): return []
		var old: Dictionary=C.FRESH_AUTHORED_ROUTES[key]
		var parts:=key.split("->")
		if parts.size()!=2 or old.slot!=override.slot or old.foot!=C._vec(override.old_foot_px) or old.uv!=C._vec(override.authored_uv): return []
		if not C._fresh_source_portal_matches(StringName(parts[0]),StringName(parts[1]),old.uv,old): return []
		result.append({"route_key":key,"strict_original_source_portal_matches":true,"original_foot_px":override.old_foot_px,"revised_foot_px":override.foot_px,"authored_uv":override.authored_uv,"slot":override.slot,"runtime_map_installed":false})
	return result

static func serialized_equal(actual: SceneScript,expected: SceneScript) -> bool:
	if actual==null or expected==null or actual.map_layout==null or expected.map_layout==null: return false
	for resource_pair: Array in [[actual,expected],[actual.map_layout,expected.map_layout]]:
		for property: Dictionary in resource_pair[1].get_property_list():
			var key: String=property.name
			if (int(property.usage)&PROPERTY_USAGE_STORAGE)==0 or key in ["script","map_layout","resource_path","resource_name","resource_local_to_scene"]: continue
			if key=="visual_objects":
				if not C.equal_visual_serialized_value(resource_pair[0].get(key),resource_pair[1].get(key),["visual_objects"]): return false
			elif not C._equal_value(resource_pair[0].get(key),resource_pair[1].get(key)): return false
	return true
