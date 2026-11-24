extends RefCounted
## NEW joint city physical/current-alpha sibling. Normal production Field;
## no dev preview/dry-action interface and no inherited v2 result credit.
const INPUT := preload("res://tests/helpers/v15_input_driver.gd")
const GEOMETRY := preload("res://tests/helpers/v15_geometry_oracle.gd")
const SIZE := Vector2(3072, 2048)
const BODY := Vector2(34, 24)
const IDLE_REFERENCES := {
	"down": {"height": 132, "sha256": "0b53fb179bf82722d90fd13594fd845de40a4f4eec06d8ed6944d86b2fc626df"},
	"up": {"height": 131, "sha256": "c982bd8dc7b1de46d24835da7305c71077d2b1179df6aaf6692097c75a615809"},
	"left": {"height": 130, "sha256": "04277efa95835ec19346cc5b8dbe4bc91b621319f6ce79574a97bc6d00caf2f9"},
	"right": {"height": 130, "sha256": "9abb983cfc2225a98a5e5831951c90e9a4800229d04f4e53666a4047cff59cb4"},
}
var owner: SceneTree
var field: Control
var driver: RefCounted = INPUT.new()
var alpha: RefCounted = GEOMETRY.new()
var report: Callable
var capture: Callable
var manifest: Dictionary
var walk: Image
var solids: Dictionary = {}
var object_ids: Dictionary = {}
var blocking_ids: Dictionary = {}
var data: Dictionary = {"routes": [], "objects": [], "actions": [], "npcs": []}
var raw_cache: Dictionary = {}
var shore_nav_bound: Dictionary = {}

func configure(tree: SceneTree, actual_field: Control, original: Dictionary, checker: Callable, screenshot: Callable) -> bool:
	owner = tree
	field = actual_field
	manifest = original.duplicate(true)
	report = checker
	capture = screenshot
	driver.configure(tree)
	walk = Image.load_from_file(String(manifest.get("walk_path", "")))
	if walk == null or walk.get_size() != Vector2i(SIZE): return false
	walk.convert(Image.FORMAT_RGBA8)
	if String(manifest.get("pixel_sampling", "")) != "round_world_pixel" or float(manifest.get("physical_navigation_margin_px", -1)) != 0: return false
	for object: Dictionary in manifest.get("objects", []):
		var id: String = String(object.get("id", ""))
		if id.is_empty() or object_ids.has(id) or typeof(object.get("blocking")) != TYPE_BOOL: return false
		object_ids[id] = true
		var polygons: Array[PackedVector2Array] = []
		for original_polygon: Array in object.get("solid_polygons_px", []):
			var polygon := PackedVector2Array()
			for p: Variant in original_polygon: polygon.append(point(p))
			if polygon.size() < 3 or Geometry2D.triangulate_polygon(polygon).is_empty(): return false
			polygons.append(polygon)
		var size: Vector2 = point(object.get("collision_size_px", [0, 0]))
		if size.x > 0 and size.y > 0: polygons.append(rect_polygon(Rect2(point(object.physical_center_px) - size * .5, size)))
		if bool(object.blocking) != (not polygons.is_empty()): return false
		if bool(object.blocking):
			blocking_ids[id] = true
			solids[id] = polygons
	return not object_ids.is_empty() and object_ids.size() == manifest.objects.size()

func point(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size() == 2: return Vector2(float(value[0]), float(value[1]))
	return Vector2(INF, INF)

func _check(ok: bool, label: String) -> void:
	report.call(ok, label)

func rect_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)])

func raw_evidence(p: Vector2) -> Dictionary:
	if not p.is_finite() or p.x < 17 or p.y < 12 or p.x + 17 >= SIZE.x or p.y + 12 >= SIZE.y: return {"clear": false, "kind": "body_out_of_domain"}
	var minimum: Vector2i=Vector2i(roundi(p.x-17),roundi(p.y-12))
	var maximum: Vector2i=Vector2i(roundi(p.x+17),roundi(p.y+12))
	if minimum.x<0 or minimum.y<0 or maximum.x>=walk.get_width() or maximum.y>=walk.get_height(): return {"clear":false,"kind":"rounded_body_out_of_domain","minimum":[minimum.x,minimum.y],"maximum":[maximum.x,maximum.y]}
	# Complete inclusive ordinary-body pixel footprint, independently read PNG.
	for y in range(minimum.y, maximum.y + 1):
		for x in range(minimum.x, maximum.x + 1):
			var c: Color = walk.get_pixel(x, y)
			if c.r < .5 or c.a < .5: return {"clear": false, "kind": "body_raw_nav", "pixel": [x, y], "rgba": [c.r, c.g, c.b, c.a]}
	var body: PackedVector2Array = rect_polygon(Rect2(p - BODY * .5, BODY))
	for id: String in solids:
		for solid: PackedVector2Array in solids[id]:
			if not Geometry2D.intersect_polygons(body, solid).is_empty(): return {"clear": false, "kind": "source_solid", "id": id}
	for index in 17:
		var q: Vector2 = p if index == 0 else p + Vector2(cos(TAU * (index - 1) / 16) * 10, sin(TAU * (index - 1) / 16) * 6)
		if q.x < 0 or q.y < 0 or q.x >= SIZE.x or q.y >= SIZE.y: return {"clear": false, "kind": "shoe_out_of_domain"}
		var pixel := Vector2i(clampi(roundi(q.x), 0, 3071), clampi(roundi(q.y), 0, 2047))
		var c: Color = walk.get_pixelv(pixel)
		if c.r < .5 or c.a < .5: return {"clear": false, "kind": "shoe_raw_nav", "shoe": index, "pixel": [pixel.x, pixel.y]}
		for id: String in solids:
			for solid: PackedVector2Array in solids[id]:
				if Geometry2D.is_point_in_polygon(q, solid): return {"clear": false, "kind": "shoe_source_solid", "shoe": index, "id": id}
	return {"clear": true, "body_pixels": 875, "shoe_samples": 17, "margin_px": 0}

func raw_clear(p: Vector2) -> bool:
	if not raw_cache.has(p): raw_cache[p] = raw_evidence(p)
	return bool((raw_cache[p] as Dictionary).get("clear", false))

func physical_clear(p: Vector2) -> bool:
	if not is_instance_valid(field) or owner.current_scene!=field or not field.is_inside_tree() or field.is_queued_for_deletion() or bool(field.get("_scene_rebuilding")): return false
	var player: Node2D = field.get("_player") as Node2D
	if not is_instance_valid(player) or not player.is_inside_tree() or player.is_queued_for_deletion(): return false
	var shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var container: Node2D = field.get("world_container") as Node2D
	if shape == null or not shape.shape is RectangleShape2D or not is_instance_valid(container) or not container.is_inside_tree(): return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape
	query.transform = shape.global_transform
	query.transform.origin += container.to_global(p) - player.global_position
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]
	query.collide_with_areas = false
	var space: World2D=player.get_world_2d()
	return space!=null and space.direct_space_state!=null and space.direct_space_state.intersect_shape(query, 1).is_empty()

func clear(p: Vector2) -> bool:
	return raw_clear(p) and physical_clear(p)

func segment(a: Vector2, b: Vector2) -> Dictionary:
	var n: int = maxi(1, ceili(a.distance_to(b) / 4))
	for i in range(n + 1):
		var p: Vector2 = a.lerp(b, float(i) / n)
		if not clear(p): return {"clear": false, "point": [p.x, p.y], "raw": raw_evidence(p), "physical_clear": physical_clear(p), "index": i}
	return {"clear": true, "centers": n + 1, "max_step_px": a.distance_to(b) / n}

func move_to(p: Vector2) -> Dictionary:
	var player: Node2D = field.get("_player") as Node2D
	var path: PackedVector2Array = driver.plan(player.position, p, SIZE, clear, segment)
	if path.size() < 2: return {"ok": false, "reason": "no_finite_legal_input_path", "target": [p.x, p.y], "raw": raw_evidence(p), "physical_clear": physical_clear(p)}
	return await driver.follow(field, path, clear, segment)

func prop(id: String) -> Sprite2D:
	for node: Sprite2D in field.get("_scene_object_nodes"):
		if String(node.name) == "SceneObject_" + id: return node
	return null

func run_routes() -> void:
	_check(not manifest.routes.is_empty(), "all current authored city routes, not prior preview paths")
	for route: Dictionary in manifest.routes:
		var points := PackedVector2Array()
		for p: Variant in route.points_px: points.append(point(p))
		var entry: Dictionary = await move_to(points[0])
		_check(bool(entry.get("ok", false)), "normal input reaches route start: " + String(route.id))
		var driven: Dictionary = await driver.follow(field, points, clear, segment) if bool(entry.get("ok", false)) else {"ok": false, "not_run": true}
		_check(bool(driven.get("ok", false)), "entire authored route actual input/full17/34x24/physics: " + String(route.id))
		data.routes.append({"id": route.id, "approach": entry, "drive": driven})
		await capture.call("route_" + String(route.id))

func run_objects() -> void:
	var player: Node2D = field.get("_player") as Node2D
	var actor: Sprite2D = player.get("sprite") as Sprite2D
	var shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	_check(shape != null and not shape.disabled and shape.shape is RectangleShape2D and shape.shape.size == BODY and shape.position == Vector2.ZERO, "ordinary actor keeps real enabled centered 34x24 Rectangle, never travel circle")
	_check(absf(actor.scale.y - .945 * .91) < .000001 and absf(float(player.call("get_depth_sort_y")) - player.global_position.y) < .01, "normal adult .91 visual scale and grounded foot; no tiny-world identity")
	var source: Image = alpha.image_for(actor)
	var current: Rect2i = alpha.frame(actor, source)
	var top := current.size.y
	var bottom := -1
	for y in current.size.y:
		for x in current.size.x:
			if source.get_pixelv(current.position + Vector2i(x, y)).a > .12:
				top = mini(top, y)
				bottom = maxi(bottom, y)
	# 113.5134 is DOWN reference, not a blanket current-facing height.
	var facing := ""
	for direction: String in IDLE_REFERENCES:
		var path: String = "res://art/characters/weapon_variants/lengguyun/v7_idle_stable/sword/lengguyun_sword_idle_%s_25d_4f.png" % direction
		if actor.texture.resource_path == path: facing = direction
	_check(not facing.is_empty() and String(player.get("_direction")) == facing, "actual idle texture/facing identity matches one precise independently measured adult source")
	if not facing.is_empty():
		var expected: Dictionary = IDLE_REFERENCES[facing]
		_check(FileAccess.get_sha256(actor.texture.resource_path).to_lower() == String(expected.sha256), "actual facing original PNG exact SHA, not mutable self-reference")
		_check(bottom >= top and bottom - top + 1 == int(expected.height), "current idle-frame alpha height equals its exact facing reference (DOWN132/UP131/LR130), never widened tolerance")
		_check(absf((bottom - top + 1) * actor.scale.y - float(expected.height) * .945 * .91) < .0001, "actual current-frame effective alpha height uses actual Sprite scale and precise facing reference")
		_check(absf(float(manifest.ordinary_actor_effective_height_px) - 132 * .945 * .91) < .000001, "manifest adult height is explicitly DOWN132 reference, not all facing equality")
		data["adult_current_frame_height"] = {"facing": facing, "frame": actor.frame, "path": actor.texture.resource_path, "sha256": FileAccess.get_sha256(actor.texture.resource_path), "source_alpha_height_px": bottom - top + 1, "source_reference_height_px": expected.height, "actual_scale": actor.scale.y, "effective_height_px": (bottom - top + 1) * actor.scale.y, "down_reference_px": manifest.ordinary_actor_effective_height_px}
	_runtime_collision_inventory()
	for object: Dictionary in manifest.objects:
		var id: String = String(object.id)
		var sprite: Sprite2D = prop(id)
		_check(sprite != null and sprite.texture.resource_path == String(object.texture), "independent runtime PNG binding: " + id)
		if sprite == null: continue
		_check((sprite.get_rect().size * sprite.scale.abs()).distance_to(point(object.render_size_px)) < .01 and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "actual rendered dimensions/filter: " + id)
		_check(_physical_binding(id), "actual StaticBody geometry exactly matches original world solids: " + id)
		var collision: Dictionary = await _collision_trial(id) if blocking_ids.has(id) else {"blocking": false, "actual_static_body_absent": _physical_binding(id), "scope": "nonblocking; no fictional solid stop"}
		var alpha_record: Dictionary
		if object.get("role","")=="ground_overlay":
			var global_alpha_depth: int = alpha.effective_z(sprite)
			_check(not blocking_ids.has(id) and sprite.z_index==-2 and object.get("ghost_occlusion")==false,"ground-only mud overlay is neither solid nor occluding foreground: "+id)
			alpha_record={"scope":"GROUND_OVERLAY_NEGATIVE_NOT_STRONG_FOREGROUND_CREDIT","effective_z":global_alpha_depth,"ghost_occlusion":false}
		elif object.get("role","")=="water_decoration":
			alpha_record=await _water_decoration_domain_trial(object)
		else: alpha_record=await _alpha_trial(object)
		var record: Dictionary = {"id": id, "blocking": blocking_ids.has(id), "collision": collision, "alpha": alpha_record}
		data.objects.append(record)
	_check(data.objects.size() == object_ids.size(), "every current city declared visual entity tested independently, no old ten-object count or first-success early exit")
	for npc: Node in (field.get("_actor_layer") as Node).get_children():
		if not npc is NPCNode: continue
		var rows: Array = []
		for tick in 8:
			await driver.completed_actor_stage()
			var foot: float = npc.get_depth_sort_y()
			_check(npc.z_index == clampi(floori(foot / 8), 0, 255), "normally spawned original NPC ordinary foot band: " + String(npc.npc_id))
			rows.append({"foot": foot, "band": npc.z_index, "frame": npc.sprite.frame})
		data.npcs.append({"id": npc.npc_id, "rows": rows})
	_check(data.npcs.size() == (field.get("_npc_nodes") as Array).size(), "all normally spawned current gate-visible NPCs observed; other gated identities tested in normal action phase")

func _water_decoration_domain_trial(object: Dictionary) -> Dictionary:
	# Closed continuous axis separation of FULL draw rectangles. This covers
	# every texel/frame, including weak alpha; no coarse station absence credit.
	var player: Node2D=field.get("_player") as Node2D
	var actor: Sprite2D=player.get("sprite") as Sprite2D
	var container: Node2D=field.get("world_container") as Node2D
	var sprite: Sprite2D=prop(String(object.id))
	_check(not blocking_ids.has(String(object.id)) and object.get("walk_support")==false and object.get("ghost_occlusion")==false,"explicit actual water decoration has no walking support, solid footprint or false ghost")
	await driver.completed_actor_stage()
	var actual_depth_entries: Array=field.call("get_v14_depth_order_debug")
	var boat_depth: Array[Dictionary]=[]
	for entry: Dictionary in actual_depth_entries:
		if String(entry.get("id",""))==String(object.id): boat_depth.append(entry)
	var actual_foot: float=container.to_global(point(object.world_foot_px)).y
	var ordinary_band: int=clampi(floori(actual_foot/8),0,255)
	_check(boat_depth.size()==1 and boat_depth[0].get("actor")==false and absf(float(boat_depth[0].get("foot_y",INF))-actual_foot)<.01 and int(boat_depth[0].get("band",-1))==ordinary_band and sprite.z_index==ordinary_band,"water decoration remains an actual ordinary-depth entity rather than disappearing to avoid ghost")
	var prop_bounds: Rect2=alpha.bounds_in(sprite,container).grow(1.0)
	var nav_max_x: int=-1
	var legal_nav_cells: int=0
	for y in walk.get_height():
		for x in walk.get_width():
			var c: Color=walk.get_pixel(x,y)
			if c.r>=.5 and c.a>=.5: nav_max_x=maxi(nav_max_x,x); legal_nav_cells+=1
	# Every legal 875-pixel body has its mandatory right endpoint rounded to a
	# white cell. CLOSED upper endpoint +.5 is conservative at rounding ties.
	var legal_player_root_upper: float=float(nav_max_x)+.5-BODY.x*.5
	var player_sources: Dictionary=_all_player_drawrect_sources(actor)
	var source_valid: bool=bool(player_sources.get("valid",false)) and nav_max_x>=0
	var rightmost_actor: float=legal_player_root_upper+float(player_sources.get("right_extent_px",INF))
	var actor_records: Array[Dictionary]=[{"actor":"normal_player_all_five_weapon_families","root_upper_x":legal_player_root_upper,"sources":player_sources,"rightmost_draw_x":rightmost_actor}]
	var total_frames: int=int(player_sources.get("frame_count",0))
	for npc: Node in (field.get("_actor_layer") as Node).get_children():
		if not npc is NPCNode: continue
		var npc_sources: Dictionary=_all_npc_drawrect_sources(npc as NPCNode,container)
		source_valid=source_valid and bool(npc_sources.get("valid",false))
		total_frames+=int(npc_sources.get("frame_count",0))
		rightmost_actor=maxf(rightmost_actor,float(npc_sources.get("rightmost_draw_x",INF)))
		actor_records.append(npc_sources)
	var source_alpha: Image=alpha.image_for(sprite)
	var source_alpha_pixels: int=0
	if source_alpha!=null:
		for y in source_alpha.get_height():
			for x in source_alpha.get_width():
				if source_alpha.get_pixel(x,y).a>0: source_alpha_pixels+=1
	var gap: float=prop_bounds.position.x-rightmost_actor
	var separated: bool=source_valid and legal_nav_cells>0 and source_alpha_pixels>0 and total_frames>0 and gap>0
	_check(separated,"whole continuous legal Player domain + all permitted weapon frames + actual NPC full patrol/frame domains strictly separated from actual filtered boat rectangle")
	var record: Dictionary={"scope":"CONTINUOUS_FULL_DRAWRECT_AXIS_SEPARATION_NOT_STRONG_ALPHA_CREDIT","method":"continuous_full_drawrect_axis_separation","complete":separated,"region_id":String(manifest.get("canonical_scene_id","")),"object_id":String(object.id),"manifest_sha256":FileAccess.get_sha256("res://art/maps/luoyang_modular_v3_street_detail_proposal/root_material_v1/"+String(manifest.get("canonical_scene_id",""))+"/art_contract.json"),"source_path":sprite.texture.resource_path,"source_sha256":FileAccess.get_sha256(sprite.texture.resource_path),"prop_actual_world_rect_with_linear_margin":[prop_bounds.position.x,prop_bounds.position.y,prop_bounds.size.x,prop_bounds.size.y],"linear_filter_margin_world_px":1.0,"nav_sha256":FileAccess.get_sha256(String(manifest.walk_path)),"all_nav_cells_read":walk.get_width()*walk.get_height(),"legal_nav_cells":legal_nav_cells,"nav_max_white_x":nav_max_x,"source_alpha_pixels":source_alpha_pixels,"source_frame_count":total_frames,"actor_domains":actor_records,"actor_domain_scope":"ALL_PLAYER_WEAPONS_AND_CURRENT_NORMAL_NPC_GATE_FIXTURE","intersection_count":0 if separated else -1,"minimum_gap_px":gap,"negative_stations":[],"actual_depth_entries":boat_depth}
	if not separated:
		# Geometry/nav can change. A potential reachable overlap remains a genuine
		# unresolved FAIL; don't mutate water, waive it or call DENIED.
		record["status"]="INCONCLUSIVE_REQUIRES_ACTUAL_ALPHA_STATION"
		return record
	var station:=Vector2(INF,INF)
	var nearest: float=INF
	for route: Dictionary in manifest.routes:
		for original: Variant in route.get("points_px",[]):
			var candidate_point: Vector2=point(original)
			var distance: float=candidate_point.distance_squared_to(prop_bounds.get_center())
			var legal: bool=clear(candidate_point)
			for direction: Vector2 in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]: legal=legal and clear(candidate_point+direction*2)
			if legal and distance<nearest: station=candidate_point; nearest=distance
	_check(station.is_finite(),"water decoration has an independently legal accessible shoreline negative witness")
	if not station.is_finite(): return record
	for direction: Vector2 in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		var approach: Dictionary=await move_to(station)
		var drive: Dictionary=await move_to(station+direction*2)
		await driver.completed_actor_stage()
		var hits: Dictionary=alpha.strong_intersection(actor,sprite)
		var debug: Dictionary=field.call("get_v14_modular_overlap_debug")
		var target_pixels: int=int((debug.get("prop_hits",{}) as Dictionary).get(String(object.id),0))
		_check(bool(approach.get("ok",false)) and bool(drive.get("ok",false)) and clear(player.position) and int(hits.get("hits",-1))==0 and target_pixels==0 and exact_union(debug),"normal shoreline input/current frame has no boat overlap or rectangular false fade")
		(record.negative_stations as Array).append({"actual_root_px":[player.position.x,player.position.y],"current_alpha":hits,"prop_ghost_pixels":target_pixels,"direction":[direction.x,direction.y],"actual_input":drive})
		await capture.call(String(object.id)+"_shore_negative_"+str((record.negative_stations as Array).size()))
	record["status"]="DENIED_CONTINUOUS_DOMAIN_NOT_STRONG_ALPHA_CREDIT"
	return record

func _all_player_drawrect_sources(actual: Sprite2D) -> Dictionary:
	var rows: Array[Dictionary]=[]
	var valid: bool=absf(actual.scale.x-.945*.91)<.000001 and absf(actual.position.x)<.000001 and actual.rotation==0 and actual.vframes==1
	var extent: float=0
	var frames: int=0
	for weapon: String in ["sword","dao","staff","palm","hidden"]:
		for state: String in ["idle","walk"]:
			for direction: String in ["down","up","left","right"]:
				var count: int=4 if state=="idle" else 8
				var path: String="res://art/characters/weapon_variants/lengguyun/v7_idle_stable/%s/lengguyun_%s_%s_%s_25d_%df.png"%[weapon,weapon,state,direction,count]
				var image: Image=Image.load_from_file(path)
				var good: bool=image!=null and not image.is_empty() and image.get_width()==image.get_height()*count and FileAccess.get_sha256(path).length()==64
				valid=valid and good
				var cell: int=image.get_height() if good else 0
				# Whole Sprite rect also bounds every flipped/current frame. Extra
				# 1px covers linear sampling, not an alpha threshold relaxation.
				var right: float=float(cell)*.5*.945*.91+1
				extent=maxf(extent,right)
				frames+=count if good else 0
				rows.append({"weapon":weapon,"state":state,"direction":direction,"path":path,"sha256":FileAccess.get_sha256(path),"size":[image.get_width(),image.get_height()] if good else [],"frames":count,"cell_px":cell,"actual_normal_scale":actual.scale.x,"ground_offset_y":-float(cell)*.945*.91*.45,"right_extent_px":right,"valid":good})
	return {"valid":valid,"frame_count":frames,"right_extent_px":extent,"sources":rows,"Player_script_sha256":FileAccess.get_sha256("res://scripts/field/player.gd")}

func _all_npc_drawrect_sources(npc: NPCNode,container: Node2D) -> Dictionary:
	var paths: Dictionary={}
	for original: String in [npc.sprite_path,npc.walk_sprite_path]:
		if original.is_empty(): continue
		paths[original]=true
		for old_direction: String in ["down","up","left","right"]:
			if not original.contains("_"+old_direction+"_"): continue
			for direction: String in ["down","up","left","right"]:
				var directional: String=original.replace("_"+old_direction+"_","_"+direction+"_")
				var candidates: Array[String]=[directional]
				for version in range(2,10): candidates.append(directional.replace("_v%d_"%version,"_"))
				for candidate_path: String in candidates:
					for state in ["idle","walk"]:
						var path: String=candidate_path.replace("_idle_","_"+state+"_").replace("_walk_","_"+state+"_")
						if FileAccess.file_exists(path): paths[path]=true
	for original: String in npc.conversation_sprite_paths.values():
		if not original.is_empty(): paths[original]=true
	paths[npc.sprite.texture.resource_path]=true
	var valid: bool=npc.get_parent()==container or (npc.get_parent() is Node2D and (npc.get_parent() as Node2D).global_transform==container.global_transform)
	valid=valid and npc.rotation==0 and npc.scale==Vector2.ONE and npc.sprite.rotation==0 and absf(npc.sprite.position.x)<.000001
	var rows: Array[Dictionary]=[]
	var extent: float=0
	var frames: int=0
	for path: String in paths:
		var image: Image=Image.load_from_file(path)
		var good: bool=image!=null and not image.is_empty() and image.get_width()%image.get_height()==0
		valid=valid and good
		if not good: rows.append({"path":path,"valid":false}); continue
		var cell: int=image.get_height()
		var used: Rect2i=image.get_region(Rect2i(0,0,cell,cell)).get_used_rect()
		var scale_value: float=npc.sprite_scale if npc.sprite_scale>0 else 128.0/maxf(image.get_width(),image.get_height())
		if bool(npc.get("_calibrate_adult_body")):
			valid=valid and used.size.y>0
			scale_value*=140.0/maxi(1,used.size.y)
		if path==npc.sprite.texture.resource_path: valid=valid and absf(scale_value-npc.sprite.scale.x)<.000001
		var right: float=float(cell)*.5*scale_value+1
		extent=maxf(extent,right)
		frames+=int(image.get_width()/cell)
		rows.append({"path":path,"sha256":FileAccess.get_sha256(path),"frames":image.get_width()/cell,"cell_px":cell,"scale":scale_value,"calibrated_first_frame_used_rect":[used.position.x,used.position.y,used.size.x,used.size.y],"right_extent_px":right,"valid":good})
	var origin: Vector2=npc.get("_patrol_origin")
	var travel: float=absf(npc.patrol_axis.normalized().x)*npc.patrol_distance if npc.movement_mode=="patrol" else 0
	var root_upper: float=origin.x+travel
	# Current normal NPCNode executes only axis/sin patrol. A future nonempty
	# authored path must not silently acquire this axis-only complete-domain proof.
	var authored_path_empty: bool=true
	var current_definition: SceneScript=field.get("_current_scene") as SceneScript
	var found_identity: bool=false
	if current_definition!=null:
		for declaration: Dictionary in current_definition.npcs:
			if String(declaration.get("npc_id",""))!=String(npc.npc_id): continue
			found_identity=true
			var authored: Variant=declaration.get("patrol_path",[])
			authored_path_empty=authored is Array and authored.is_empty() or authored is PackedVector2Array and authored.is_empty()
	for slot: Dictionary in manifest.gameplay_slots.npcs:
		if String(slot.get("source_id",""))==String(npc.npc_id):
			var authored: Variant=slot.get("patrol_path_px",[])
			authored_path_empty=authored_path_empty and authored is Array and authored.is_empty()
	valid=valid and found_identity and authored_path_empty
	return {"actor":String(npc.npc_id),"valid":valid and not paths.is_empty(),"frame_count":frames,"root_upper_x":root_upper,"actual_patrol_origin":[origin.x,origin.y],"patrol_axis":[npc.patrol_axis.x,npc.patrol_axis.y],"patrol_distance":npc.patrol_distance,"authored_patrol_path_empty":authored_path_empty,"actual_movement_method":"NPCNode_axis_sin_or_idle","rightmost_draw_x":root_upper+extent,"sources":rows,"NPC_script_sha256":FileAccess.get_sha256("res://scripts/field/npc_node.gd")}

func water_proofs() -> Array[Dictionary]:
	var proofs: Array[Dictionary]=[]
	for object: Dictionary in manifest.objects:
		if object.get("role","")=="water_decoration": proofs.append(await _water_decoration_domain_trial(object))
	return proofs

func _runtime_collision_inventory() -> void:
	var container: Node2D = field.get("world_container") as Node2D
	var player: Node2D = field.get("_player") as Node2D
	var expected_npcs: Dictionary = {}
	var definition: SceneScript = field.get("_current_scene") as SceneScript
	for npc: Dictionary in definition.npcs: expected_npcs[String(npc.npc_id)] = true
	var pending: Array[Node] = [container]
	var gameplay: Dictionary = {}
	var npc_ids: Dictionary = {}
	var map_bounds := 0
	var unknown: Array[String] = []
	var records: Array[Dictionary] = []
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		pending.append_array(node.get_children())
		if not node is PhysicsBody2D or node == player: continue
		var id: String = String(node.name)
		var category := "UNKNOWN"
		if node.get_parent() is NPCNode:
			var parent: NPCNode = node.get_parent() as NPCNode
			id = parent.npc_id
			category = "normal_npc"
			_check(expected_npcs.has(id) and not npc_ids.has(id) and node == parent.get("_body_collider"), "normal NPC owns exactly its original real collision body: " + id)
			npc_ids[id] = true
		elif id.begins_with("CityV3Physical_"):
			id = id.trim_prefix("CityV3Physical_")
			category = "declared_independent_prop"
			_check(blocking_ids.has(id) and not gameplay.has(id), "one actual physical body per original declared independent object: " + id)
			gameplay[id] = true
		elif id == "MapBounds":
			category = "outer_canvas_boundary"
			map_bounds += 1
			var expected_sizes: Array[Vector2] = [Vector2(3112, 40), Vector2(3112, 40), Vector2(40, 2088), Vector2(40, 2088)]
			var expected_centres: Array[Vector2] = [Vector2(1536, -20), Vector2(1536, 2068), Vector2(-20, 1024), Vector2(3092, 1024)]
			_check(node.get_child_count() == 4 and node.transform == Transform2D.IDENTITY, "only declared outer canvas boundary remains")
			for index in mini(4, node.get_child_count()):
				var shape: CollisionShape2D = node.get_child(index) as CollisionShape2D
				_check(shape != null and shape.shape is RectangleShape2D and shape.shape.size == expected_sizes[index] and shape.position == expected_centres[index], "outer boundary exact geometry is outside logical canvas, not an interior legacy box")
		else:
			unknown.append(str(node.get_path()))
		records.append({"id": id, "path": str(node.get_path()), "category": category})
	_check(gameplay.size() == blocking_ids.size() and npc_ids.size() == (field.get("_npc_nodes") as Array).size() and map_bounds == 1 and unknown.is_empty(), "collision inventory is exactly current blocking subset + actual normally spawned NPCs + four outer bounds; no stale guard-post boxes")
	for id: String in blocking_ids: _check(gameplay.has(id), "each actual declared blocking ID has its own body: " + id)
	for id: String in object_ids:
		if not blocking_ids.has(id): _check(not gameplay.has(id), "nonblocking visual has no undeclared body: " + id)
	_check(definition.map_layout.blockers.is_empty() and definition.collision_rects.is_empty(), "independent runtime layout contains no old gate blocker arrays")
	data["actual_collision_inventory"] = {"objects": gameplay.keys(), "npcs": npc_ids.keys(), "map_bounds": map_bounds, "unknown": unknown, "records": records}

func _physical_binding(id: String) -> bool:
	var parent: Node2D = field.get("_collision_layer") as Node2D
	var container: Node2D = field.get("world_container") as Node2D
	if parent == null or container == null or parent.global_transform != container.global_transform: return false
	var body: StaticBody2D = parent.get_node_or_null("CityV3Physical_" + id) as StaticBody2D
	if not blocking_ids.has(id): return body == null
	if body == null or body.transform != Transform2D.IDENTITY or body.collision_layer != 1: return false
	var actual: Array[PackedVector2Array] = []
	for node: Node in body.get_children():
		if node is CollisionPolygon2D:
			if node.disabled or node.transform != Transform2D.IDENTITY: return false
			actual.append(node.polygon)
		elif node is CollisionShape2D and node.shape is RectangleShape2D:
			if node.disabled or node.rotation != 0 or node.scale != Vector2.ONE: return false
			actual.append(rect_polygon(Rect2(node.position - node.shape.size * .5, node.shape.size)))
		else: return false
	return actual == solids[id]

func _polygon_bounds(polygon: PackedVector2Array) -> Rect2:
	var bounds: Rect2=Rect2(polygon[0],Vector2.ZERO)
	for vertex: Vector2 in polygon: bounds=bounds.expand(vertex)
	return bounds

func _connected_exterior(id: String) -> Dictionary:
	# Conservative configuration-space grouping is ONLY a waypoint proposal.
	# It never replaces exact source polygons, 875 pixels, 17 shoes or Physics.
	# Adjacent wall/wing gaps narrower than an ordinary body cannot be bypass
	# stations just because their individual source rectangles do not touch.
	var entries: Array[Dictionary]=[]
	for solid_id: String in solids:
		for index in (solids[solid_id] as Array).size():
			var bounds: Rect2=_polygon_bounds((solids[solid_id] as Array)[index])
			entries.append({"id":solid_id,"polygon_index":index,"bounds":bounds,"forbidden_bounds":Rect2(bounds.position-BODY*.5,bounds.size+BODY)})
	var selected: Array[int]=[]
	for index in entries.size():
		if String(entries[index].id)==id and int(entries[index].polygon_index)==0: selected.append(index); break
	var cursor: int=0
	while cursor<selected.size():
		var current: Rect2=entries[selected[cursor]].forbidden_bounds
		for index in entries.size():
			if not selected.has(index) and current.intersects(entries[index].forbidden_bounds,true): selected.append(index)
		cursor+=1
	var envelope: Rect2=entries[selected[0]].bounds
	var members: Array[Dictionary]=[]
	for index in selected:
		envelope=envelope.merge(entries[index].bounds)
		members.append({"id":entries[index].id,"polygon_index":entries[index].polygon_index})
	return {"bounds":envelope,"members":members,"method":"conservative_body_expanded_solid_AABB_connected_waypoints_only"}

func _legal_exterior_station(wanted: Vector2,bounds: Rect2,corner: int) -> Dictionary:
	var considered: int=0
	# A finite local station search, never a complete-domain absence proof.
	# Stay outside BOTH component axes; do not pick another interior wall corner.
	for radius in range(0,97,8):
		for dy in range(-radius,radius+1,8):
			for dx in range(-radius,radius+1,8):
				if maxi(absi(dx),absi(dy))!=radius: continue
				var candidate: Vector2=wanted+Vector2(dx,dy)
				var left: bool=corner<2
				var bottom: bool=corner==0 or corner==3
				if (candidate.x>bounds.position.x-17 if left else candidate.x<bounds.end.x+17): continue
				if (candidate.y<bounds.end.y+12 if bottom else candidate.y>bounds.position.y-12): continue
				considered+=1
				if clear(candidate): return {"found":true,"point":[candidate.x,candidate.y],"raw":raw_evidence(candidate),"physical_clear":true,"considered":considered,"radius_px":radius}
	return {"found":false,"wanted":[wanted.x,wanted.y],"considered":considered,"max_radius_px":96,"step_px":8,"not_complete_domain":true}

func _own_body_overlap(id: String,p: Vector2) -> bool:
	var body: PackedVector2Array=rect_polygon(Rect2(p-BODY*.5,BODY))
	for solid: PackedVector2Array in solids[id]:
		if not Geometry2D.intersect_polygons(body,solid).is_empty(): return true
	return false

func _physical_hits(p: Vector2) -> Array[Dictionary]:
	var records: Array[Dictionary]=[]
	if not is_instance_valid(field) or owner.current_scene!=field or not field.is_inside_tree(): return records
	var player: CharacterBody2D=field.get("_player") as CharacterBody2D
	var container: Node2D=field.get("world_container") as Node2D
	if not is_instance_valid(player) or not player.is_inside_tree() or not is_instance_valid(container): return records
	var shape: CollisionShape2D=player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape==null or not shape.shape is RectangleShape2D: return records
	var query: PhysicsShapeQueryParameters2D=PhysicsShapeQueryParameters2D.new()
	query.shape=shape.shape
	query.transform=shape.global_transform
	query.transform.origin+=container.to_global(p)-player.global_position
	query.collision_mask=player.collision_mask
	query.exclude=[player.get_rid()]
	query.collide_with_areas=false
	var space: World2D=player.get_world_2d()
	if space==null or space.direct_space_state==null: return records
	for hit: Dictionary in space.direct_space_state.intersect_shape(query,128):
		var collider: Object=hit.get("collider") as Object
		var rid: RID=hit.get("rid")
		records.append({"path":str((collider as Node).get_path()) if is_instance_valid(collider) and collider is Node else "INVALID","rid":rid.get_id(),"shape":int(hit.get("shape",-1))})
	return records

func _hits_own(id: String,hits: Array[Dictionary]) -> bool:
	for hit: Dictionary in hits:
		if String(hit.path).ends_with("/CityV3Physical_"+id): return true
	return false

func _stop_station(id: String,bounds: Rect2,inside: Vector2,shore: bool) -> Dictionary:
	# Prefer the original down-side trial when it is actually legal. A continuous
	# wall needs an exposed side of THIS polygon, not a point in the next wall.
	var proposals: Array[Dictionary]=[]
	if not shore: proposals.append({"point":Vector2(inside.x,bounds.end.y+30),"direction":Vector2.UP,"action":"move_up"})
	proposals.append({"point":Vector2(bounds.position.x-40,bounds.get_center().y),"direction":Vector2.RIGHT,"action":"move_right"})
	if not shore:
		proposals.append({"point":Vector2(bounds.end.x+40,bounds.get_center().y),"direction":Vector2.LEFT,"action":"move_left"})
		proposals.append({"point":Vector2(inside.x,bounds.position.y-30),"direction":Vector2.DOWN,"action":"move_down"})
	var rejected: Array[Dictionary]=[]
	for proposal: Dictionary in proposals:
		var start: Vector2=proposal.point
		var direction: Vector2=proposal.direction
		if not clear(start):
			rejected.append({"start":[start.x,start.y],"raw":raw_evidence(start),"physical_hits":_physical_hits(start)})
			continue
		for distance in range(4,97,4):
			var next: Vector2=start+direction*distance
			if _own_body_overlap(id,next):
				var hits: Array[Dictionary]=_physical_hits(next)
				if _hits_own(id,hits): return {"found":true,"point":[start.x,start.y],"direction":[direction.x,direction.y],"action":proposal.action,"first_own_contact_body_center":[next.x,next.y],"contact_distance_px":distance,"contact_hits":hits,"max_ray_step_px":4,"rejected_proposals":rejected}
				break
			if not clear(next): break
	return {"found":false,"rejected_proposals":rejected,"finite_station_search_not_absence_proof":true}

func _is_exact_shore_rail(id: String) -> bool:
	return String(manifest.get("canonical_scene_id",""))=="ch4_s2_canal_docks" and id in ["quay_rail_400","quay_rail_720","quay_rail_1040","quay_rail_1360","quay_rail_1680"]

func _shore_axis_bound() -> Dictionary:
	if not shore_nav_bound.is_empty(): return shore_nav_bound
	var max_x: int=-1
	var whites: int=0
	for y in walk.get_height():
		for x in walk.get_width():
			var c: Color=walk.get_pixel(x,y)
			if c.r>=.5 and c.a>=.5: max_x=maxi(max_x,x); whites+=1
	var hash: HashingContext=HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(walk.get_data())
	shore_nav_bound={"method":"entire_original_nav_mandatory_right_body_pixel_continuous_upper_bound","nav_path":manifest.walk_path,"nav_sha256":FileAccess.get_sha256(String(manifest.walk_path)),"decoded_RGBA8_sha256":hash.finish().hex_encode(),"all_nav_cells_read":walk.get_width()*walk.get_height(),"white_cells":whites,"max_white_x":max_x,"legal_body_center_x_strict_upper":float(max_x)+.5-17,"body_pixels":875,"shoe_samples":17,"rounding_contract":"round_world_pixel; mandatory right endpoint must be white; upper is conservative at tie"}
	return shore_nav_bound

func _shore_bypass(id: String,bounds: Rect2) -> Dictionary:
	var axis: Dictionary=_shore_axis_bound()
	var water: Vector2=Vector2(bounds.end.x+40,bounds.get_center().y)
	var black_body: int=0
	var denied_shoes: int=0
	for y in range(roundi(water.y-12),roundi(water.y+12)+1):
		for x in range(roundi(water.x-17),roundi(water.x+17)+1):
			if x<0 or y<0 or x>=walk.get_width() or y>=walk.get_height(): continue
			var c: Color=walk.get_pixel(x,y)
			if c.r<.5 or c.a<.5: black_body+=1
	for index in 17:
		var q: Vector2=water if index==0 else water+Vector2(cos(TAU*(index-1)/16)*10,sin(TAU*(index-1)/16)*6)
		var pixel: Vector2i=Vector2i(roundi(q.x),roundi(q.y))
		if pixel.x<0 or pixel.y<0 or pixel.x>=walk.get_width() or pixel.y>=walk.get_height(): denied_shoes+=1; continue
		var c: Color=walk.get_pixelv(pixel)
		if c.r<.5 or c.a<.5: denied_shoes+=1
	var east_outside_minimum: float=bounds.end.x+17
	_check(int(axis.white_cells)>0 and int(axis.all_nav_cells_read)==6291456 and east_outside_minimum>float(axis.legal_body_center_x_strict_upper),"complete original nav proves no full-body water-side exterior station: "+id)
	_check(black_body==875 and denied_shoes==17 and not raw_clear(water),"water-side original PNG rejects all875 body pixels and17 shoes, no white-water bypass: "+id)
	var water_hits: Array[Dictionary]=_physical_hits(water)
	var points: PackedVector2Array=PackedVector2Array([Vector2(bounds.position.x-40,bounds.end.y+30),Vector2(bounds.position.x-40,bounds.position.y-30)])
	var stations: Array[Dictionary]=[]
	for p: Vector2 in points:
		var legal: bool=clear(p)
		stations.append({"point":[p.x,p.y],"raw":raw_evidence(p),"physical_clear":physical_clear(p),"legal":legal})
		_check(legal,"exact shore barrier has actual complete-body legal inland end station: "+id)
	var legs: Array[Dictionary]=[]
	var all_legs: bool=bool(stations[0].legal) and bool(stations[1].legal)
	if all_legs:
		var entry: Dictionary=await move_to(points[0])
		_check(bool(entry.get("ok",false)),"normal input reaches inland shore bypass: "+id)
		all_legs=bool(entry.get("ok",false))
		for target_index in [1,0,1,0]:
			if not all_legs: break
			var player: Node2D=field.get("_player") as Node2D
			var edge: Dictionary=segment(player.position,points[target_index])
			var drive: Dictionary=await driver.follow(field,PackedVector2Array([player.position,points[target_index]]),clear,segment) if bool(edge.get("clear",false)) else {"ok":false,"planned_edge":edge}
			legs.append({"edge":edge,"drive":drive,"target_index":target_index})
			all_legs=all_legs and bool(drive.get("ok",false))
			_check(bool(drive.get("ok",false)),"real continuous inland up/down shore path <=4px/full875/17/Physics: "+id)
	_check(all_legs and legs.size()==4,"both directions repeated along inland side of exact shore barrier: "+id)
	return {"strategy":"exact_five_shore_barriers_inland_bidirectional_water_negative","axis_proof":axis,"east_outside_minimum_x":east_outside_minimum,"water_witness":[water.x,water.y],"water_body_black_pixels":black_body,"water_denied_shoes":denied_shoes,"water_raw":raw_evidence(water),"water_physical_clear":physical_clear(water),"water_physics_hits":water_hits,"water_Physics_is_independent_no_body_hit_claim":true,"land_stations":stations,"land_bypass":legs,"completed":all_legs and legs.size()==4}

func _collision_trial(id: String) -> Dictionary:
	var polygon: PackedVector2Array = (solids[id] as Array)[0]
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for vertex: Vector2 in polygon: bounds = bounds.expand(vertex)
	var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(polygon)
	var inside: Vector2 = (polygon[triangles[0]]+polygon[triangles[1]]+polygon[triangles[2]])/3 if triangles.size()>=3 else Vector2(INF,INF)
	_check(not raw_clear(inside) and not physical_clear(inside), "independent source footprint and actual Physics2D reject interior: " + id)
	var shore: bool=_is_exact_shore_rail(id)
	var witness: Dictionary=_stop_station(id,bounds,inside,shore)
	_check(bool(witness.get("found",false)),"reachable exposed side belongs to this actual polygon/full-body Physics: "+id)
	var approach: Dictionary = await move_to(point(witness.point)) if bool(witness.get("found",false)) else {"ok":false,"witness":witness}
	_check(bool(approach.get("ok", false)), "normal input reaches exterior front-stop witness: " + id)
	var stop: Dictionary = {"not_run": true}
	if bool(approach.get("ok", false)):
		var player: Node2D = field.get("_player") as Node2D
		var initial: Vector2 = player.position
		var all_clear := true
		var direction: Vector2=point(witness.direction)
		var samples: PackedVector2Array=PackedVector2Array([initial])
		var physics_frame_start: int=Engine.get_physics_frames()
		for tick in 30:
			var previous: Vector2=player.position
			driver.release_movement()
			Input.action_press(String(witness.action))
			await owner.physics_frame
			await driver.completed_actor_stage()
			all_clear = all_clear and clear(player.position) and bool(segment(previous,player.position).get("clear",false))
			samples.append(player.position)
			driver.observed_positions.append(player.position)
		driver.release_movement()
		await driver.completed_actor_stage()
		var final: Vector2=player.position
		var inward_step: float=480.0/Engine.physics_ticks_per_second
		var next: Vector2=final+direction*inward_step
		var next_hits: Array[Dictionary]=_physical_hits(next)
		var stationary: bool=samples.size()==31
		for index in range(maxi(0,samples.size()-5),samples.size()): stationary=stationary and samples[index].distance_to(final)<.01
		var own_contact: bool=_own_body_overlap(id,next) and _hits_own(id,next_hits)
		# Record one further REAL normal input tick; hypothetical query alone is not
		# a gameplay stop. No bbox Y threshold from another part of a concave hall.
		Input.action_press(String(witness.action))
		await owner.physics_frame
		await owner.physics_frame
		driver.release_movement()
		await driver.completed_actor_stage()
		var final_after: Vector2=player.position
		all_clear=all_clear and clear(final_after) and bool(segment(final,final_after).get("clear",false))
		stop = {"start": [initial.x, initial.y], "end": [final_after.x, final_after.y], "all_clear": all_clear, "physics_ticks": Engine.get_physics_frames()-physics_frame_start,"normal_input_cycles":30,"each_observation_after_natural_actor_stage":true,"direction":witness.direction,"witness":witness,"stationary_last_five":stationary,"next_requested_body_center":[next.x,next.y],"next_step_px":inward_step,"next_source_own_body_overlap":_own_body_overlap(id,next),"next_actual_Physics_hits":next_hits,"next_hits_own":_hits_own(id,next_hits),"additional_normal_input_displacement_px":final_after.distance_to(final),"samples":_scalar_evidence(samples)}
		_check(all_clear and (final-initial).dot(direction)>1 and stationary and own_contact and final_after.distance_to(final)<.01 and not _own_body_overlap(id,final_after), "real ordinary input advances then stops at local own polygon/full-body Physics and next real inward input stays stopped: " + id)
	if shore:
		var shoreline: Dictionary=await _shore_bypass(id,bounds)
		await capture.call("solid_"+id)
		return {"interior":[inside.x,inside.y],"raw_interior":raw_evidence(inside),"stop":stop,"shoreline":shoreline,"bypass_is_finite_trial_not_complete_domain":true,"water_no_station_is_entire_original_nav_axis_proof_not_empty_search":true}
	var bypass_points := PackedVector2Array([Vector2(bounds.position.x - 40, bounds.end.y + 30), Vector2(bounds.position.x - 40, bounds.position.y - 30), Vector2(bounds.end.x + 40, bounds.position.y - 30), Vector2(bounds.end.x + 40, bounds.end.y + 30)])
	var original_corners: Array[Dictionary]=[]
	var all_original_corners_clear: bool=true
	for target: Vector2 in bypass_points:
		var legal: bool=clear(target)
		all_original_corners_clear=all_original_corners_clear and legal
		original_corners.append({"point":[target.x,target.y],"clear":legal,"raw":raw_evidence(target),"physical_clear":physical_clear(target)})
	var exterior: Dictionary={"bounds":bounds,"members":[{"id":id,"polygon_index":0}],"method":"original_four_legal_exterior_corners"}
	if not all_original_corners_clear:
		exterior=_connected_exterior(id)
		var joined: Rect2=exterior.bounds
		bypass_points=PackedVector2Array([Vector2(joined.position.x-40,joined.end.y+30),Vector2(joined.position.x-40,joined.position.y-30),Vector2(joined.end.x+40,joined.position.y-30),Vector2(joined.end.x+40,joined.end.y+30)])
	var bypass: Array = []
	var stations: Array[Dictionary]=[]
	for index in bypass_points.size():
		var station: Dictionary=_legal_exterior_station(bypass_points[index],exterior.bounds,index)
		stations.append(station)
		_check(bool(station.found),"actual complete-body legal exterior station (missing remains FAIL): "+id+" corner "+str(index))
		if not bool(station.found): break
		var target: Vector2=point(station.point)
		var drive: Dictionary = await move_to(target)
		bypass.append(drive)
		_check(bool(drive.get("ok", false)), "actual continuous exterior bypass / independent full-body path: " + id)
		if not bool(drive.get("ok", false)): break
	var all_bypass_legs: bool=bypass.size()==4 and stations.size()==4
	for drive: Dictionary in bypass: all_bypass_legs=all_bypass_legs and bool(drive.get("ok",false))
	_check(all_bypass_legs,"all four actual exterior legs completed around individual or connected solids: "+id)
	await capture.call("solid_" + id)
	var exterior_bounds: Rect2=exterior.bounds
	return {"interior": [inside.x, inside.y], "raw_interior": raw_evidence(inside), "stop": stop, "bypass": bypass,"original_corner_evidence":original_corners,"exterior_strategy":exterior.method,"exterior_members":exterior.members,"exterior_bounds":[exterior_bounds.position.x,exterior_bounds.position.y,exterior_bounds.size.x,exterior_bounds.size.y],"exterior_stations":stations, "bypass_is_finite_trial_not_complete_domain": true}

func _alpha_trial(object: Dictionary) -> Dictionary:
	var player: Node2D = field.get("_player") as Node2D
	var sprite: Sprite2D = player.get("sprite") as Sprite2D
	var container: Node2D = field.get("world_container") as Node2D
	var target_prop: Sprite2D = prop(String(object.id))
	var bounds: Rect2 = alpha.bounds_in(target_prop, container)
	var stations: Dictionary = {}
	var trials: Array = []
	var considered := 0
	# Bounded station discovery only. Failure does NOT prove alpha absence.
	for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var orientation: Dictionary = await move_to(player.position + direction * 2)
		await driver.completed_actor_stage()
		if not bool(orientation.get("ok", false)): continue
		var xs: Array[float] = [bounds.position.x - 20, bounds.position.x + 20, bounds.get_center().x, bounds.end.x - 20, bounds.end.x + 20]
		var ys: Array[float] = []
		for d: float in [-256.0, -128.0, -64.0, -32.0, -16.0, -8.0, -2.0, 2.0, 8.0, 16.0, 32.0, 64.0]: ys.append(float(object.depth_foot_y) + d)
		for y in range(maxi(16, floori(bounds.position.y)), mini(2032, ceili(bounds.end.y) + 116), 16): ys.append(float(y))
		for y: float in ys:
			for x: float in xs:
				considered += 1
				var p := Vector2(x, y)
				if not clear(p) or not bool(segment(p - direction * 2, p).get("clear", false)): continue
				var actor_foot: float = float(player.call("get_depth_sort_y")) + container.to_global(p).y - player.global_position.y
				var prop_foot: float = container.to_global(point(object.world_foot_px)).y
				if absf(actor_foot - prop_foot) <= .01: continue
				var relation: String = "front" if actor_foot > prop_foot else "behind"
				if stations.has(relation): continue
				var hits: Dictionary = alpha.strong_intersection(sprite, target_prop, container.to_global(p) - player.global_position)
				if int(hits.get("hits", 0)) > 0: stations[relation] = {"point": p, "direction": direction, "current_search_frame": hits}
			if stations.size() == 2: break
		if stations.size() == 2: break
	for relation: String in ["behind", "front"]:
		_check(stations.has(relation), "finite actual-facing legal strong-alpha station discovered (empty = NOT_PROVEN, never waived): " + String(object.id) + " " + relation)
		if not stations.has(relation): continue
		var station: Dictionary = stations[relation]
		var target: Vector2 = station.point
		var direction: Vector2 = station.direction
		var approach: Dictionary = await move_to(target - direction * 2)
		var leg: Dictionary = await driver.drive(field, target, clear) if bool(approach.get("ok", false)) else {"ok": false}
		await driver.completed_actor_stage()
		var hits: Dictionary = alpha.strong_intersection(sprite, target_prop)
		var actor_front: bool = alpha.actual_in_front(player, target_prop)
		var feet_relation: bool = float(player.call("get_depth_sort_y")) > container.to_global(point(object.world_foot_px)).y
		var debug: Dictionary = field.call("get_v14_modular_overlap_debug")
		# Preserve the exact first-assertion cache/actor observation. Later natural
		# stages may diagnose timing but MUST NOT replace or green this assertion.
		var assertion_snapshot: Dictionary=_alpha_observation(target_prop)
		_check(bool(approach.get("ok", false)) and bool(leg.get("ok", false)), "normal input and actual-facing final leg reach alpha witness: " + String(object.id) + " " + relation)
		_check(raw_clear(player.position) and physical_clear(player.position) and int(hits.get("hits", 0)) > 0, "real current-frame strong alpha with full17/34x24 and Physics2D clearance: " + String(object.id) + " " + relation)
		_check(feet_relation == (relation == "front") and actor_front == feet_relation, "completed normal node stage actual feet/order incl same-band siblings: " + String(object.id) + " " + relation)
		var hit_count: int = int((debug.get("prop_hits", {}) as Dictionary).get(String(object.id), 0))
		_check(hit_count > 0 if relation == "behind" else hit_count == 0, "only genuinely covered pixels ghost; player in front is not faded: " + String(object.id) + " " + relation)
		_check(exact_union(debug), "independent current-frame LINEAR union byteexact, not rectangular whole-person fade: " + String(object.id) + " " + relation)
		var trial: Dictionary={"relation": relation, "actual_point": [player.position.x, player.position.y], "actual_alpha": hits, "raw": raw_evidence(player.position), "physical_clear": physical_clear(player.position), "actor_front": actor_front, "actor_band": player.z_index, "prop_band": target_prop.z_index, "actor_index": player.get_index(), "prop_index": target_prop.get_index(), "approach": approach, "final_leg": leg, "ghost_target_pixels": hit_count, "union_pixels": debug.get("pixels", 0),"first_assertion_snapshot":assertion_snapshot}
		await driver.completed_actor_stage()
		trial["second_natural_stage_snapshot"]=_alpha_observation(target_prop)
		trial["second_natural_stage_alpha"]=alpha.strong_intersection(sprite,target_prop)
		trial["second_natural_stage_raw"]=raw_evidence(player.position)
		trial["second_natural_stage_physical_clear"]=physical_clear(player.position)
		trial["second_stage_is_diagnostic_not_assertion_replacement"]=true
		trials.append(trial)
		await capture.call(String(object.id) + "_" + relation)
	return {"discovery_is_not_absence_proof": true, "considered": considered, "records": trials, "scope": "actual_current_idle_frame_only", "missing_relation_is_fail": trials.size() != 2}

func _scalar_evidence(value: Variant) -> Variant:
	# Never retain Node/Image/Texture/Callable references in JSON evidence.
	match typeof(value):
		TYPE_NIL,TYPE_BOOL,TYPE_INT,TYPE_FLOAT,TYPE_STRING: return value
		TYPE_STRING_NAME,TYPE_NODE_PATH: return String(value)
		TYPE_VECTOR2,TYPE_VECTOR2I: return [value.x,value.y]
		TYPE_RECT2,TYPE_RECT2I: return [value.position.x,value.position.y,value.size.x,value.size.y]
		TYPE_TRANSFORM2D: return [value.x.x,value.x.y,value.y.x,value.y.y,value.origin.x,value.origin.y]
		TYPE_ARRAY,TYPE_PACKED_VECTOR2_ARRAY:
			var values: Array=[]
			for item: Variant in value: values.append(_scalar_evidence(item))
			return values
		TYPE_DICTIONARY:
			var values: Dictionary={}
			for key: Variant in value: values[String(key)]=_scalar_evidence(value[key])
			return values
		TYPE_OBJECT:
			if not is_instance_valid(value): return {"valid":false}
			if value is Image:
				var digest: HashingContext=HashingContext.new()
				digest.start(HashingContext.HASH_SHA256)
				digest.update(value.get_data())
				return {"size":[value.get_width(),value.get_height()],"format":value.get_format(),"rgba_or_format_bytes_sha256":digest.finish().hex_encode()}
			# Original source SHA is already bound by manifest/current-alpha checks;
			# this cache snapshot needs identity, not rereading every prop PNG twice.
			if value is Texture2D: return {"instance_id":value.get_instance_id(),"path":value.resource_path,"size":[value.get_width(),value.get_height()]}
			return {"class":value.get_class(),"instance_id":value.get_instance_id()}
	return {"type":typeof(value),"value":str(value)}

func _sprite_observation(sprite: Sprite2D) -> Dictionary:
	if not is_instance_valid(sprite): return {"valid":false}
	return {"valid":true,"path":str(sprite.get_path()) if sprite.is_inside_tree() else "DETACHED","instance_id":sprite.get_instance_id(),"inside_tree":sprite.is_inside_tree(),"queued":sprite.is_queued_for_deletion(),"texture":_scalar_evidence(sprite.texture),"frame":sprite.frame,"hframes":sprite.hframes,"vframes":sprite.vframes,"region_enabled":sprite.region_enabled,"region_rect":_scalar_evidence(sprite.region_rect),"rect":_scalar_evidence(sprite.get_rect()),"flip_h":sprite.flip_h,"flip_v":sprite.flip_v,"global_transform":_scalar_evidence(sprite.global_transform),"local_transform":_scalar_evidence(sprite.transform),"visible":sprite.is_visible_in_tree(),"texture_filter":sprite.texture_filter,"z_index":sprite.z_index,"z_relative":sprite.z_as_relative,"sibling_index":sprite.get_index(),"modulate_alpha":sprite.modulate.a,"self_modulate_alpha":sprite.self_modulate.a}

func _alpha_observation(target: Sprite2D) -> Dictionary:
	var live: bool=is_instance_valid(field) and owner.current_scene==field and field.is_inside_tree() and not field.is_queued_for_deletion()
	var snapshot: Dictionary={"ticks_usec":Time.get_ticks_usec(),"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames(),"field_live_current_identity":live,"current_scene_instance_id":owner.current_scene.get_instance_id() if is_instance_valid(owner.current_scene) else 0,"field_instance_id":field.get_instance_id() if is_instance_valid(field) else 0}
	if not live: return snapshot
	var player: Node2D=field.get("_player") as Node2D
	snapshot["rebuilding"]=bool(field.get("_scene_rebuilding"))
	snapshot["scene_id"]=String((field.get("_current_scene") as SceneScript).scene_id)
	if not is_instance_valid(player): snapshot["player_valid"]=false; return snapshot
	snapshot["player"]={"instance_id":player.get_instance_id(),"inside_tree":player.is_inside_tree(),"queued":player.is_queued_for_deletion(),"local_position":_scalar_evidence(player.position),"global_transform":_scalar_evidence(player.global_transform),"depth_sort_y":float(player.call("get_depth_sort_y")),"z_index":player.z_index,"sibling_index":player.get_index(),"sprite":_sprite_observation(player.get("sprite") as Sprite2D)}
	snapshot["target_prop"]=_sprite_observation(target)
	var helper: RefCounted=field.get("_v14_modular_overlap") as RefCounted
	if helper==null: snapshot["helper_valid"]=false; return snapshot
	snapshot["helper_script"]={"path":helper.get_script().resource_path,"sha256":FileAccess.get_sha256(helper.get_script().resource_path)}
	snapshot["debug"]=_scalar_evidence(field.call("get_v14_modular_overlap_debug"))
	snapshot["helper_signature"]=_scalar_evidence(helper.get("_signature"))
	var registered: Array[Dictionary]=[]
	for entry: Dictionary in helper.get("_props"):
		var sprite: Sprite2D=entry.get("sprite") as Sprite2D if is_instance_valid(entry.get("sprite")) else null
		var row: Dictionary={"id":String(entry.get("id","")),"sprite":_sprite_observation(sprite),"foot_local":_scalar_evidence(entry.get("foot_local"))}
		if sprite!=null:
			var foot: Vector2=entry.foot_local
			row["actual_global_foot_y"]=sprite.to_global(foot).y
			row["strictly_behind_player_foot"]=sprite.to_global(foot).y>float(player.call("get_depth_sort_y"))
		registered.append(row)
	snapshot["registered_occluding_props"]=registered
	return snapshot

func exact_union(debug: Dictionary) -> bool:
	var player: Node2D = field.get("_player") as Node2D
	var actor: Sprite2D = player.get("sprite") as Sprite2D
	var image: Image = alpha.image_for(actor)
	var frame: Rect2i = alpha.frame(actor, image)
	if frame.size.x <= 0: return false
	var expected := Image.create(frame.size.x, frame.size.y, false, Image.FORMAT_RGBA8)
	expected.fill(Color(0, 0, 0, 0))
	var container: Node2D = field.get("world_container") as Node2D
	var pixels := 0
	for y in frame.size.y:
		for x in frame.size.x:
			if image.get_pixelv(frame.position + Vector2i(x, y)).a <= 0: continue
			var uv := Vector2((x + .5) / frame.size.x, (y + .5) / frame.size.y)
			if actor.flip_h: uv.x = 1 - uv.x
			if actor.flip_v: uv.y = 1 - uv.y
			var world: Vector2 = actor.to_global(actor.get_rect().position + uv * actor.get_rect().size)
			var remainder := 1.0
			for object: Dictionary in manifest.objects:
				var sprite: Sprite2D = prop(String(object.id))
				if object.get("role","")=="ground_overlay" or object.get("ghost_occlusion",true)==false: continue
				if sprite == null or container.to_global(point(object.world_foot_px)).y <= float(player.call("get_depth_sort_y")) or not alpha.actual_in_front(sprite, player): continue
				remainder *= 1 - float(alpha.alpha_at(sprite, world))
			var value: float = 1 - remainder
			if value > 0:
				expected.set_pixel(x, y, Color(1, 1, 1, value))
				pixels += 1
	if pixels == 0: return not bool(debug.get("active", false)) and int(debug.get("pixels", -1)) == 0
	var actual: Image = debug.get("mask_image") as Image
	return debug.get("space") == "actor_frame" and bool(debug.get("active", false)) and actual != null and actual.get_size() == frame.size and actual.get_data() == expected.get_data()

func click_entity(sprite: Sprite2D) -> Dictionary:
	var player: Node2D = field.get("_player") as Node2D
	var image: Image = alpha.image_for(sprite)
	var current: Rect2i = alpha.frame(sprite, image)
	var best := Vector2(INF, INF)
	var distance := INF
	for y in current.size.y:
		for x in current.size.x:
			if image.get_pixelv(current.position + Vector2i(x, y)).a <= .12: continue
			var uv: Vector2 = Vector2((x+.5)/current.size.x,(y+.5)/current.size.y)
			if sprite.flip_h: uv.x=1-uv.x
			if sprite.flip_v: uv.y=1-uv.y
			var world: Vector2 = sprite.to_global(sprite.get_rect().position + uv * sprite.get_rect().size)
			if alpha.alpha_at(sprite,world)<=.12: continue
			var d: float = world.distance_squared_to(player.global_position)
			if d < distance:
				distance = d
				best = world
	if not best.is_finite(): return {"ok": false, "reason": "no_actual_source_alpha_click"}
	# Actual input can synchronously destroy the source Field/Sprite. Freeze
	# current-frame identity and alpha BEFORE input; never dereference it after.
	var actual_alpha: float = alpha.alpha_at(sprite, best)
	if actual_alpha <= .12: return {"ok": false, "reason": "actual_click_alpha_not_strong"}
	var texture: Texture2D = sprite.texture
	var image_hash := HashingContext.new()
	image_hash.start(HashingContext.HASH_SHA256)
	image_hash.update(image.get_data())
	var source_identity: Dictionary = {"sprite_instance_id":sprite.get_instance_id(),"sprite_path":String(sprite.get_path()),"texture_instance_id":texture.get_instance_id(),"texture_path":texture.resource_path,"texture_source_sha256":FileAccess.get_sha256(texture.resource_path) if FileAccess.file_exists(texture.resource_path) else "IN_MEMORY_CURRENT_TEXTURE","current_image_RGBA_sha256":image_hash.finish().hex_encode(),"current_frame":[current.position.x,current.position.y,current.size.x,current.size.y],"flip_h":sprite.flip_h,"flip_v":sprite.flip_v,"global_transform":str(sprite.global_transform),"alpha_sampled_before_input":true}
	var weak_sprite: WeakRef = weakref(sprite)
	var viewport_point: Vector2 = sprite.get_canvas_transform() * best
	var record: Dictionary = await driver.pointer(viewport_point)
	record["ok"] = true
	record["alpha"] = actual_alpha
	record["source_identity_before_input"] = source_identity
	record["source_sprite_alive_after_input"] = weak_sprite.get_ref() != null
	record["world"] = [best.x, best.y]
	return record

func release() -> void:
	driver.release()
	alpha.release()
	walk = null
	shore_nav_bound.clear()
	raw_cache.clear()
	solids.clear()
	object_ids.clear()
	blocking_ids.clear()
	manifest.clear()
	field = null
	owner = null
	report = Callable()
	capture = Callable()
