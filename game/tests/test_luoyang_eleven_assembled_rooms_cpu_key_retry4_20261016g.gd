extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## Source-only 60s; no C.prepare, city pipeline, or repeated smith four-station test.
const KEY_READY:=true
const REGISTRY="res://data/maps/luoyang_assembled_interiors_20261016g/registry_route_retry1.json"
const REGISTRY_SHA="30e9683090a85395b64fe886768df536c346528a2d51d6d28ead4ef61d441596"
const MODULE="res://scripts/city/luoyang_assembled_interiors_20261016g.gd"
const MODULE_SHA="8a9b8ee35d6b0eba6f435a0590e28269aa13b3d6fd0d09783de899712c2d046f"
const RAW=preload("res://tests/helpers/luoyang_eleven_rooms_raw_polygon_oracle_v2_20261016g.gd")
const RAW_SHA="0f00d4a8a7bc7f514d4b0859275c2eb6d03296dd81eaa170416694c6068b2835"
const TYPES=["smithy","small_home","general_stall","scholar_study","inn_hall","guest_room","herbal_shop","cloth_shop","pawnshop","warehouse","mansion_reception"]
const SOURCE_SIZE:=Vector2(1536,1024)
const ACTUAL_WORLD:=Vector2(1920,1280)
var catalogue: Dictionary={}
var layout_plan: Dictionary={}
var asset_contracts: Dictionary={}
var output: String
var total_samples:=0
func _v(value: Variant) -> Vector2: return value if value is Vector2 else Vector2(value[0],value[1])
func _poly(raw: Array) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for point: Array in raw: result.append(_v(point))
	return result
func _equal(a: Variant,b: Variant) -> bool:
	if a is Resource and b is Resource:
		if a is Script or b is Script: return a is Script and b is Script and a.resource_path==b.resource_path
		return _equal(_storage(a),_storage(b))
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _equal(a[key],b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size(): return false
		for i: int in a.size():
			if not _equal(a[i],b[i]): return false
		return true
	return typeof(a)==typeof(b) and a==b
func _storage(resource: Resource) -> Dictionary:
	var result: Dictionary={}
	for property: Dictionary in resource.get_property_list():
		if (int(property.usage)&PROPERTY_USAGE_STORAGE)!=0: result[property.name]=resource.get(property.name)
	return result
func precheck() -> bool:
	if not check(KEY_READY,"Unfrozen source/schema draft refuses"): return false
	if not track(REGISTRY,REGISTRY_SHA) or not track(MODULE,MODULE_SHA) or not track("res://tests/helpers/luoyang_eleven_rooms_raw_polygon_oracle_v2_20261016g.gd",RAW_SHA): return false
	catalogue=JSON.parse_string(FileAccess.get_file_as_string(REGISTRY))
	if not check(catalogue.get("coordinate_contract")=="source_feet_assembled_interiors_20261016g" and catalogue.get("rooms",{}).size()==11 and not catalogue.get("source_sha256",{}).is_empty(),"Exact11 source-bound rows, not IDs inflated into types"): return false
	for path: String in catalogue.source_sha256:
		if not track(path,catalogue.source_sha256[path]): return false
	if not track("F:/Code/RPG_GAME/prompts/qa/luoyang_interiors_assembly_20261016g/room_layouts_draft.json","98d413bf227fc7c5bdd05288c146080f4e7e9c4e45ccbd53ee858abbbc5e760d"): return false
	layout_plan=JSON.parse_string(FileAccess.get_file_as_string("F:/Code/RPG_GAME/prompts/qa/luoyang_interiors_assembly_20261016g/room_layouts_draft.json"))
	var art_path: String="F:/Code/RPG_GAME/assets/raw/luoyang_interiors_assembly_20261016g/manifest_v2.json"
	if not track(art_path,"1a8da8e6243a36f67c78b9eba8835658ac4320554d4738d15e653000d1fe6944"): return false
	var art: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(art_path))
	for asset: Dictionary in art.assets:
		var batch_path: String="F:/Code/RPG_GAME/"+String(asset.batch_path)
		if not track(batch_path,String(asset.batch_sha256)): return false
		var batch: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(batch_path))
		for member: Dictionary in batch.assets:
			if member.id==asset.id: asset_contracts[member.id]=member
	if not check(asset_contracts.size()==28,"Corrected manifest_v2 actual seven batches, not old manifest batch00 links"): return false
	for path: String in [get_script().resource_path,"res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"]:
		if not track(path,FileAccess.get_sha256(path)): return false
	return true
func _oracle_units() -> bool:
	var box: Array=[[[0,0],[256,0],[256,256],[0,256]]]
	var probe:=RAW.new()
	if not check(probe.configure(box,[],Vector2(256,256),Vector2(256,256)) and probe.clear(Vector2(17,12)) and not probe.clear(Vector2(16.5,12)),"Closed floor boundary fullbody accepts edge, rejects outside without epsilon"): return false
	var obstacle: Array=[{"id":"edge","points_px":[[100,100],[120,100],[120,120],[100,120]]}]
	if not check(probe.configure(box,obstacle,Vector2(256,256),Vector2(256,256)) and not probe.clear(Vector2(83,112)) and not probe.clear(Vector2(110,88)) and probe.clear(Vector2(82,112)),"Closed right/bottom body touch rejects, one-pixel separated body clears"): return false
	var regions: Array=[[[0,0],[128,0],[128,256],[0,256]],[[128,0],[256,0],[256,256],[128,256]]]
	if not check(probe.configure(regions,[],Vector2(256,256),Vector2(256,256)) and probe.clear(Vector2(128,128)),"Continuous body may span exact union floor seam"): return false
	var zones: Array=[[[100,100],[120,100],[120,120],[100,120]]]
	if not check(probe.configure(box,[],Vector2(256,256),Vector2(256,256),zones) and probe.clear(Vector2(97,112)) and not probe.clear(Vector2(100,112)),"Visual forbidden is foot-only, not a second native-body expansion"): return false
	return true
func _imports() -> bool:
	var receipt_path: String="res://data/maps/luoyang_assembled_interiors_20261016g/import_publication_receipt_v2.json"
	if not track(receipt_path,"a91aa2696a208344194ab59512a8dc668ad16e1ac94a2d5f87c6ccd145861af5"): return false
	var receipt: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(receipt_path))
	if not check(receipt.previous_numeric_ticks_not_exact and receipt.copy_and_import_not_repeated and receipt.leaves.size()==84,"v2 stringticks is current observation only, not reconstructed copy-time proof"): return false
	if not track(String(receipt.previous_receipt),String(receipt.previous_receipt_sha256)): return false
	var original: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(receipt.previous_receipt))
	if not track(String(original.isolated_result),String(original.isolated_result_sha256)): return false
	var proof: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(original.isolated_result))
	if not check(proof.get("passed")==true and proof.get("failures",[]).is_empty() and proof.get("checks")==900 and proof.get("rows",[]).size()==28,"Reuse actual Root28 imported fullRGBA/23-parameter proof; no reimport"): return false
	for leaf: Dictionary in receipt.leaves:
		if not check(leaf.observed_mtime_ticks is String and String(leaf.observed_mtime_ticks).is_valid_int(),"Ticks retained as string; native key does not claim exactticks measurement"): return false
		if not track(String(leaf.path),String(leaf.sha256)) or not check(fact(String(leaf.path)).bytes==int(leaf.length),"Current published leaf length matches receipt"): return false
	for row: Dictionary in proof.rows:
		if not check(row.full_rgba_exact and row.source_import_native_full_rgba_exact and row.params23 and row.mipmap_count==0,"Actual unchanged complete RGBA import row "+String(row.id)): return false
		for pair: Array in [[row.texture,row.source_sha256],[row.import_path,row.import_sha256],[row.compiled_path,row.compiled_sha256]]:
			if not track(String(pair[0]),String(pair[1])): return false
	records.append({"kind":"IMPORT_PROOF_REUSE","path":original.isolated_result,"sha":original.isolated_result_sha256,"rows":28,"redecoded_in_this_key":false,"strict_zero_padding_claimed":false,"ticks_claim":"v2 current string observation; not measured exactticks by this native key"})
	return true
func _fixed_zones(geometry: Dictionary,scale: Vector2) -> bool:
	var declared: Array=geometry.get("foot_forbidden_regions_px",[])
	var fixed: Array=geometry.get("fixed_architecture",[])
	if not check(declared.size()==fixed.size(),"Every fixed baked pillar has an explicit foot-only actor exclusion"): return false
	var env: Array=geometry.actor_clearance_model.envelope_world_px
	if not check(env==[-90.0,-171.0,180.0,181.0] and geometry.actor_clearance_model.coordinate_domain=="actual_world_pixels" and geometry.actor_clearance_model.room_player_visual_scale==1.18,"Frozen full160-cell actor envelope includes LINEAR half texel, not just physical foot"): return false
	for index: int in fixed.size():
		var item: Dictionary=fixed[index]
		var projection: PackedVector2Array=_poly(item.full_visual_projection_px)
		var low:=projection[0];var high:=projection[0]
		for point: Vector2 in projection: low=low.min(point);high=high.max(point)
		if not check(projection.size()==4 and _poly(item.ground_base_polygon_px).size()>=3,"Current four shell pillar projection is a true source rectangle, actual ground separate"): return false
		for point: Vector2 in projection:
			if not check(point in [low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)],"All full-projection corners retained"): return false
		var minimum:=Vector2(maxf(0,low.x-float(env[0]+env[2])/scale.x),maxf(0,low.y-float(env[1]+env[3])/scale.y))
		var maximum:=Vector2(minf(SOURCE_SIZE.x,high.x-float(env[0])/scale.x),minf(float(item.depth_front_px),high.y-float(env[1])/scale.y))
		var expected:=PackedVector2Array([minimum,Vector2(maximum.x,minimum.y),maximum,Vector2(minimum.x,maximum.y)])
		if not check(_poly(declared[index])==expected,"Independent source Minkowski + canvas/depth clip exact; foot-only, never twice body-expanded"): return false
	return true
func _room(row: Dictionary) -> bool:
	if not track(String(row.author_path),String(row.author_sha256)): return false
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(row.author_path))
	if row.get("reuse_existing_accepted",false):
		if not check(row.type_id=="smithy" and row.author_sha256=="760e0169750c73579cd59679dddeaf89c7e2de349e83dd90c812cfaea37ae9b9","Only unchanged accepted smith reused, not four-station replay"): return false
		records.append({"kind":"UNCHANGED_SMITH_REUSED","author_sha":row.author_sha256});return true
	var geometry: Dictionary=data.geometry
	var scale: Vector2=ACTUAL_WORLD/SOURCE_SIZE
	if not check(_v(geometry.source_size_px)==SOURCE_SIZE and _v(geometry.actual_world_size_px)==ACTUAL_WORLD and data.type_id==row.type_id and data.room.scene_id==row.scene_id,"Explicit source/actual cover coordinate domains"): return false
	var designed: Dictionary={}
	var design_type: String="market_counter" if row.type_id=="general_stall" else String(row.type_id)
	var design_matches: int=0
	for item: Dictionary in layout_plan.rooms:
		if item.type_id==design_type: designed=item;design_matches+=1
	if not check(design_matches==1 and not designed.is_empty() and designed.scene_id==row.scene_id and designed.required_this_milestone and designed.distinctness_axes.size()>=3,"Actual functional design, only explicit general_stall→market_counter alias, exact same SceneID"): return false
	var prior_binding: Dictionary=designed.get("retained_external_binding",{})
	if not String(prior_binding.get("city_id","")).is_empty():
		if not check(data.room.city_id==prior_binding.city_id and data.room.building_id==prior_binding.building_id and _v(data.room.return_foot_px)==_v(prior_binding.configured_return_foot_px),"Retained original exterior building/city/return mapping"): return false
	var physical: Array=[]
	for base: Dictionary in geometry.furniture_bases:
		if not check(base.blocking==true,"Each declared furniture/column base remains blocking "+String(base.id)): return false
		physical.append({"id":base.id,"kind":base.kind,"points_px":base.ground_polygon_px})
	var shell_contract: Dictionary=asset_contracts.get(String(data.shell.asset_id),{})
	if not check(not shell_contract.is_empty() and data.shell.source_sha256==shell_contract.sha256 and _equal(geometry.floor_regions_px,shell_contract.source_geometry.floor_regions_px),"Actual floor is original image-guided shell floor, not guessed whole canvas"): return false
	var source_columns: Array=shell_contract.source_geometry.fixed_base_polygons_px
	var source_projections: Array=shell_contract.source_geometry.fixed_full_visual_projection_px
	if not check(source_columns.size()==geometry.fixed_architecture.size() and source_projections.size()==source_columns.size(),"Every baked fixed column accounted from original shell"): return false
	for i: int in source_columns.size():
		if not check(_equal(geometry.fixed_architecture[i].ground_base_polygon_px,source_columns[i]) and _equal(geometry.fixed_architecture[i].full_visual_projection_px,source_projections[i]),"Column ground and whole visual projection retain source geometry"): return false
	if not _fixed_zones(geometry,scale): return false
	var oracle:=RAW.new()
	if not check(oracle.configure(geometry.floor_regions_px,physical,SOURCE_SIZE,ACTUAL_WORLD,geometry.foot_forbidden_regions_px),"Independent real floor/ground/foot-only zones "+String(row.type_id),oracle.errors): return false
	var source_scene: SceneScript=ResourceLoader.load(row.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var layout: WalkableMapLayout=ResourceLoader.load(row.layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not check(source_scene!=null and layout!=null and source_scene.map_layout.resource_path==row.layout_path and source_scene.scene_id==StringName(row.scene_id) and source_scene.actor_positions_are_feet and source_scene.player_visual_scale==1.18 and source_scene.background_path==data.shell.texture and source_scene.player_spawn==_v(geometry.spawn_foot_px)/SOURCE_SIZE and source_scene.on_enter_dialog==null and source_scene.hotspots.is_empty() and source_scene.trigger_zones.is_empty(),"Actual source Scene identity/feet spawn/no unapproved story "+String(row.type_id)): return false
	if not check(layout.design_size==Vector2i(1536,1024) and layout.fill_viewport and layout.display_at_native_size and layout.blockers.size()==physical.size() and layout.visual_objects.size()==data.furniture.size(),"Actual design/cover and every independent object/base count"): return false
	if not check(layout.walkable_regions.size()==geometry.floor_regions_px.size(),"No invented whole-rectangle floor region"): return false
	for i: int in geometry.floor_regions_px.size():
		var expected_floor:=PackedVector2Array()
		for point: Array in geometry.floor_regions_px[i]: expected_floor.append(Vector2(float(point[0])/1536.0,float(point[1])/1024.0))
		if not check(layout.walkable_regions[i]==expected_floor,"Every actual floor/doorway point exactly reflects source floor"): return false
	for i: int in physical.size():
		var expected:=PackedVector2Array()
		for point: Array in physical[i].points_px: expected.append(Vector2(float(point[0])/1536.0,float(point[1])/1024.0))
		if not check(layout.blockers[i].id==physical[i].id and layout.blockers[i].ground_polygon==expected and layout.blockers[i].walkability_margin==0.0,"Every serialized ground point from source base "+String(physical[i].id)): return false
	for i: int in data.furniture.size():
		var furniture: Dictionary=data.furniture[i];var object: Dictionary=layout.visual_objects[i]
		var original: Dictionary=asset_contracts.get(String(furniture.asset_id),{})
		if not check(not original.is_empty() and furniture.source_sha256==original.sha256 and _equal(furniture.source_ground_anchor_px,original.source_geometry.source_ground_anchor_px) and _equal(furniture.source_ground_solid_polygons_px,original.source_geometry.ground_solid_polygons_px),"Geometry traces to frozen original ART batch, not a reduced guessed furniture base"): return false
		var base: Dictionary=physical[i]
		var anchor: Vector2=_v(furniture.source_ground_anchor_px);var foot: Vector2=_v(furniture.placement_foot_px);var ratio: float=furniture.render_scale
		var source_poly: Array=furniture.source_ground_solid_polygons_px[0]
		if not check(base.id==furniture.id and source_poly.size()==base.points_px.size() and object.id==furniture.id and object.texture==furniture.texture and object.get("centered")==false and object.sort_by_feet and object.assembled_furniture,"Independent furniture identity, not baked background duplicate"): return false
		var expected_pos:=Vector2((float(foot.x)-float(anchor.x)*ratio)/1536.0,(float(foot.y)-float(anchor.y)*ratio)/1024.0)
		var expected_size:=Vector2(float(furniture.source_size_px[0])*ratio,float(furniture.source_size_px[1])*ratio)
		if not check(object.pos==expected_pos and object.render_size_px==expected_size and object.depth_sort_foot_y==float(furniture.depth_foot_y)/1024.0,"Actual Sprite origin/size/sort line independently tied to the same source ground anchor"): return false
		for index: int in source_poly.size():
			var expected:=Vector2(float(foot.x)+(float(source_poly[index][0])-float(anchor.x))*ratio,float(foot.y)+(float(source_poly[index][1])-float(anchor.y))*ratio)
			if not check(_v(base.points_px[index])==expected,"Independent Float64 placement then native-point projection "+String(furniture.id)): return false
	var exit: Dictionary=layout.portals[0]
	if not check(layout.portals.size()==1 and exit.target_scene==data.room.city_id and exit.pos==_v(geometry.front_exit.approach_foot_px)/SOURCE_SIZE and exit.target_pos==_v(data.room.return_foot_px)/Vector2(3072,2048) and exit.auto_trigger==false,"Unique original city/return binding and actual source-foot exit"): return false
	var old_path: String=String(data.npc_policy.source_scene_anchor_record).trim_prefix("game/")
	var original_npcs: SceneScript=ResourceLoader.load("res://"+old_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not check(original_npcs!=null and data.npc_policy.new_npc_or_story_authorized==false and _equal(source_scene.npcs,original_npcs.npcs) and source_scene.npcs.size()==data.npc_policy.fixed_source_feet.size(),"Original NPC identities/dialog/flags/actions/positions retained, now explicit ground-feet actors"): return false
	for foot: Array in data.npc_policy.fixed_source_feet:
		if not check(oracle.clear(_v(foot)*scale),"NPC real source-foot floor/base safety; no self collider in CPU geometry",oracle.last): return false
	var route_samples:=0
	for route: Dictionary in geometry.required_routes:
		if not check(route.points_px.size()>=2,"Complete source-feet route"): return false
		for i: int in range(1,route.points_px.size()):
			var result: Dictionary=oracle.segment(_v(route.points_px[i-1])*scale,_v(route.points_px[i])*scale,deadline)
			if not check(result.clear,"Independent full87517 continuous34x24 <=4world route "+String(row.type_id)+"/"+String(route.id),result): return false
			route_samples+=int(result.samples)
	for point: Dictionary in geometry.validation_stations:
		if not check(oracle.clear(_v(point.foot_px)*scale),"Actual-cover source station "+String(point.id),oracle.last): return false
	for point: Vector2 in [Vector2(400,900),Vector2(1100,900),Vector2(768,1010)]:
		if not check(not oracle.clear(point*scale),"Baked low front walls/outer black are not floor"): return false
	for base: Dictionary in physical:
		var raw: PackedVector2Array=_poly(base.points_px);var center:=Vector2.ZERO
		for point: Vector2 in raw: center+=point
		center/=raw.size()
		var probe:=RAW.new()
		if not check(probe.configure([[[0,0],[1536,0],[1536,1024],[0,1024]]],[base],SOURCE_SIZE,ACTUAL_WORLD) and not probe.clear(center*scale) and String(probe.last.get("id",""))==String(base.id),"Isolated real furniture/column solid negative, not an unrelated floor reject "+String(base.id)): return false
	var roundtrip: String=output.path_join(String(row.type_id)+"_roundtrip.tres")
	if not check(ResourceSaver.save(source_scene,roundtrip)==OK,"Own-output full serialized Scene readback saved"): return false
	var loaded: Resource=ResourceLoader.load(roundtrip,"",ResourceLoader.CACHE_MODE_IGNORE)
	if not check(loaded!=null and _equal(source_scene,loaded),"Every serialized storage property including metadata survives native readback"): return false
	total_samples+=route_samples
	records.append({"kind":"INDEPENDENT_ROOM","type":row.type_id,"furniture":data.furniture.size(),"fixed":geometry.fixed_architecture.size(),"routes":geometry.required_routes.size(),"samples":route_samples,"physical_bases":physical.size(),"body_world":[34,24],"foot_zones_not_physical_expansion":true,"door_enabled":row.door_enabled,"runtime_or_Physics_credit":false})
	return true
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+60000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	output="res://build/luoyang_eleven_rooms_cpu_20261016g/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(output)
	var complete: bool=precheck()
	var seen: Dictionary={}
	if complete: complete=_oracle_units() and _imports()
	if complete:
		for row: Dictionary in catalogue.rooms.values():
			if not check(row.type_id in TYPES and not seen.has(row.type_id),"Exactly one real layout per required type, SW disabled not counted") or not _room(row): complete=false;break
			seen[row.type_id]=true
	if complete: complete=check(seen.size()==11,"All11 types data audited, not11 exterior doors/actual GPU")
	records.append({"kind":"SCOPE","limit_ms":60000,"route_samples":total_samples,"old_smith_stations_replayed":false,"new_types":10,"reused_types":1,"full_external_door_Physics_claimed":false})
	finish(output,began,complete,"ELEVEN_TYPES_SOURCE_GEOMETRY_NOT_RUNTIME_OR_ALL_DOORS")

