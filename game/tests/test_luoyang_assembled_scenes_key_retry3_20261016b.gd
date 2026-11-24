extends SceneTree
## NEW thin key, not an extension of the 4300/1673 legacy proof chain.
## ROOT only: fixed120s two public near-door setups, one actual room trip.
const SOURCE_READY := true
const INPUT = preload("res://tests/helpers/v15_input_driver.gd")
const RAW = preload("res://tests/helpers/v15_field_raw_oracle.gd")
const ASSEMBLY = preload("res://scripts/city/luoyang_assembled_rooms_20261016b.gd")
const R = preload("res://scripts/city/luoyang_city_assembled_runtime_20261016b.gd")
const C = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const SOURCE_PINS := {
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"3b8c6e5276118ee82537055101e09b1001323a2a5956d145d6a4120d5ae51c72",
	"res://scripts/field/field_walkable_controller.gd":"7765a22e3a889c4bb3cb97e482fcc53ecf34205dfba11fb36ba67ad102ab1d79",
	"res://scripts/city/luoyang_functional_interiors_20261016.gd":"e600fe03b633f34ef6795ad3c7818cdf025780ee04963f6ee732c34016105122",
	"res://scripts/city/luoyang_assembled_rooms_20261016b.gd":"6e2d7d3c13c3e5b54da5905619f1db014beecb1f0293c161c09108dda6a5e094",
	"res://data/maps/luoyang_assembled_rooms_20261016b/smithy_author.json":"760e0169750c73579cd59679dddeaf89c7e2de349e83dd90c812cfaea37ae9b9",
	"res://scripts/city/luoyang_city_assembled_runtime_20261016b.gd":"e751a55c1f0cfc96b7c8e9fc693fcda2f64b2fe1e0baaf0be69122e110793fe0",
	"res://data/maps/luoyang_city_assembled_20261016b/runtime_bindings.json":"a144522d342e9da36a936d40961a074919e630206d49cce5db32c7edbc3648ac",
	"res://scripts/city/luoyang_city_assembled_fade_20261016b.gd":"806eea289f4075d3ee6cf3c8feb2944e44c425c98e14281e66f332019484d741",
	"res://scripts/city/luoyang_assembled_furniture_fade_20261016b.gd":"52c81b040d233315b40fdef17a5a149e8460e26fb871b8b0a4d53bdae2dd137d",
	"res://scripts/autoload/scene_router.gd":"1877df7c4544275e66241552cee63e00f69d84a4c38bf5166976a4e401b2c1e1",
	"res://scripts/autoload/loading_manager.gd":"d3dff3a613707774e38c1888cd8d9eae3611f6f35be1e7c96a7b4234e7578c17",
	"res://scripts/city/luoyang_resident_field_20261016.gd":"cd5d3485d7f639b447010df9e88cc6347242a2a2fe491a873fa2e46d6ff55b86",
	"res://data/scenes/luoyang_assembled_rooms_20261016b/smithy_room.tres":"fa9b86c0e39a3eaa7b248b3d3ea1a280813c5e22930cf045ae6574fb3b6ae823",
	"res://data/maps/luoyang_assembled_rooms_20261016b/smithy_layout.tres":"377bb2d0bdd5b8210aa83b51fe519c24fa6234cc0a73d4f4845ae06a3e718366",
	"res://build/luoyang_assembled_room_cpu_20261016b/15492_1819/result.json":"c535b6dd8db5c363a5fe5a721de792deeb1404e8e47e8772da44ad5b83b0f011",
	"res://build/luoyang_assembled_before_20261016b_system01/smithy_author_20986084.source":"20986084094a7f233e1d096e8ae466f865d938d48909f7b9e59dc7f4030500c1",
	"res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
	"res://tests/helpers/v15_field_raw_oracle.gd":"dc36f4144496477508f9ad8b346f846043db109415760ab87205fa814aad26fb"
}
## These fields must come from the final reviewed NEW author, not old room hints.
var PLAN := {
	"market":{"id":"ch4_s3_luoyang_market","size":Vector2(3072,2048),"setup_foot":Vector2(2320,920),"portal_foot":Vector2(2320,874),"approach":PackedVector2Array([Vector2(2320,920),Vector2(2320,898),Vector2(2320,874)]),"portal_id":"enter_shop_room"},
	"room":{"id":"luoyang_market_shop_interior_20261015","size":Vector2(INF,INF),"front":Vector2(INF,INF),"behind":Vector2(INF,INF),"side":Vector2(INF,INF),"routes":[],"impact_direction":Vector2.ZERO,"impact_target":Vector2(INF,INF),"return_approach":PackedVector2Array()},
	"yamen":{"id":"ch4_s1_luoyang_yamen","size":Vector2(3072,2048),"setup_foot":Vector2(300,1260),"portal_foot":Vector2(300,1220),"approach":PackedVector2Array([Vector2(300,1260),Vector2(300,1238),Vector2(300,1220)]),"portal_id":"to_south_market"}
}
const SHARED_MS := 120000
const ARRIVAL_MS := 60000
const RETURN_MS := 2000.0
var deadline := 0
var checks := 0
var failures := 0
var output := ""
var driver: RefCounted
var field: Node
var scene: SceneScript
var oracle: RefCounted
var exact_solids: Array[PackedVector2Array]=[]
var source_before: Dictionary={}
var players_before: Dictionary={}
var rows: Array[Dictionary]=[]
var captures: Array[Dictionary]=[]
var sources_observed: Dictionary={}
var initialized := false
var room_author: Dictionary={}
var floors: Array[PackedVector2Array]=[]
var current_size:=Vector2.ZERO
var manifest_records: Dictionary={}
var candidate_manifest_paths: Dictionary={}
var retained_city_id:=0
var room_scale:=Vector2.ONE

func _initialize() -> void: call_deferred("_run")
func _check(ok: bool,label: String,detail: Variant=null) -> bool:
	checks+=1
	if not ok: failures+=1; printerr("ASSEMBLED_KEY_FAIL ",label," ",detail)
	return ok
func _fact(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists":false,"sha256":"ABSENT","bytes":0,"mtime_seconds":0}
	var file:=FileAccess.open(path,FileAccess.READ)
	var length:=file.get_length(); file.close()
	return {"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":length,"mtime_seconds":FileAccess.get_modified_time(path)}
func _players() -> Dictionary:
	var result: Dictionary={}
	for index: int in range(5):
		for suffix: String in [".json",".json.bak",".json.tmp"]:
			var path:="user://save_"+str(index)+suffix
			result[path]=_fact(path)
	return result
func _track(path: String,expected: String="") -> bool:
	var fact:=_fact(path)
	if not _check(fact.exists and fact.sha256.length()==64 and (expected.is_empty() or fact.sha256==expected.to_lower()),"Exact new closure "+path): return false
	if source_before.has(path): return _check(source_before[path]==fact,"Stable duplicate source "+path)
	source_before[path]=fact
	return true
func _precheck() -> bool:
	if not _check(SOURCE_READY and ASSEMBLY.enabled() and R.enabled() and not ASSEMBLY.FORMAL_ENABLED and not R.FORMAL_ENABLED,"Exact candidate-only two exteriors plus assembled room"): return false
	for path: String in SOURCE_PINS:
		if not _track(path,SOURCE_PINS[path]): return false
	room_author=ASSEMBLY.author()
	var old_author: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://build/luoyang_assembled_before_20261016b_system01/smithy_author_20986084.source"))
	if not _check(not room_author.is_empty() and room_author.geometry==old_author.geometry and room_author.room==old_author.room and room_author.furniture==old_author.furniture and room_author.shell==old_author.shell,"CPU geometry/Scene/layout/7assets unchanged; only declared functional sourcepin linkage"): return false
	for path: String in room_author.source_sha256:
		if not _track(path,room_author.source_sha256[path]): return false
	var config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(R.BIND_PATH))
	for path: String in config.source_sha256:
		if not _track(path,config.source_sha256[path]): return false
	for id: String in ["ch4_s3_luoyang_market","ch4_s1_luoyang_yamen"]:
		var item: Dictionary=config.cities[id]
		if not _track(item.manifest_path,R.PINS[id]): return false
		var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(item.manifest_path))
		manifest_records[id]=manifest.record
		candidate_manifest_paths[id]=item
		var canonical:=ResourceLoader.load("res://data/scenes/"+id+".tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		# Read-only path discovery only. Never calls prepare/resolve/getter.
		var closure: Dictionary=C._transition_sources(canonical,false)
		if not _check(not closure.is_empty(),"Full production-declared path closure before public request "+id): return false
		for path: String in closure:
			if not source_before.has(path) and not _track(path): return false
	return _track(get_script().resource_path)

func _busy() -> bool:
	var router: Node=root.get_node("SceneRouter")
	var loading: Node=root.get_node("LoadingManager")
	var public_state: Dictionary=router.call("get_public_city_preparation_state")
	var resident: Dictionary=router.call("get_resident_city_state")
	if bool(loading.get("_transition_active")) or public_state.get("active",false) or (resident.get("return",{}) as Dictionary).get("active",false): return true
	var validation: Dictionary=C.transition_validation_state()
	for key: String in ["source_worker_active","base_cpu_worker_active","navigation_worker_active","revision_worker_active","module_worker_active"]:
		if validation.get(key,false): return true
	return C._live_module_task>=0 or C._live_module_job!=null or C._live_revision_task>=0 or C._live_revision_job!=null
func _operable() -> bool:
	if not is_instance_valid(field) or field!=current_scene or _busy(): return false
	var loading: Node=root.get_node("LoadingManager")
	var screen: Node=loading.get("_screen") as Node
	var panel: Control=screen.get("root") as Control if is_instance_valid(screen) else null
	var player: Node=field.get("_player") as Node
	return (panel==null or not panel.is_visible_in_tree()) and is_instance_valid(player) and player.is_inside_tree() and bool(player.get("can_move")) and not bool(field.get("_scene_rebuilding"))
func _wait(id: String) -> bool:
	var end:=mini(deadline,Time.get_ticks_msec()+ARRIVAL_MS)
	while Time.get_ticks_msec()<end:
		await process_frame
		if _busy() or not is_instance_valid(current_scene): continue
		var definition:=current_scene.get("_current_scene") as SceneScript
		if definition==null or String(definition.scene_id)!=id: continue
		field=current_scene; scene=definition
		if not _operable(): continue
		await driver.call("completed_actor_stage")
		if _operable() and field.get("_current_scene")==scene: return _bind_geometry()
	return _check(false,"Bounded arrival/hidden Loading/operable "+id,{"public":root.get_node("SceneRouter").call("get_public_city_preparation_state"),"C":C.transition_validation_state(),"current_scene":String(current_scene.name) if is_instance_valid(current_scene) else "NONE","errors":C.errors()})

func _writer_domain_record(native: Dictionary) -> Dictionary:
	# Exact original publisher writer + Godot JSON parser wire domain.
	# The actual file can preserve digits that native JSON parse rounds; this
	# is NOT an epsilon, a field exception or a geometry rewrite.
	var value: Variant=JSON.parse_string(JSON.stringify(native,"\t",true,true))
	return value if value is Dictionary else {}
func _complete_publication_record(native: Dictionary,published: Dictionary,id: String) -> bool:
	var raw_equal:=C._equal_value(native,published)
	var domain:=_writer_domain_record(native)
	var twice:=_writer_domain_record(domain)
	if not _check(not domain.is_empty() and C._equal_value(domain,twice),"Original writer/parser wire-domain exact complete roundtrip "+id): return false
	if id=="ch4_s3_luoyang_market":
		if not _check(not raw_equal,"Known raw native-record comparison still refuses JSON parser-domain difference"): return false
	var moved: Dictionary=native.duplicate(true)
	var before: float=float(moved.objects[0].world_foot_px[0])
	moved.objects[0].world_foot_px[0]=before+1.0
	var extra: Dictionary=native.duplicate(true)
	extra["QA_NEGATIVE_UNDECLARED_FIELD"]=true
	var unchanged:=C._equal_value(domain,published)
	var move_rejected:=not C._equal_value(_writer_domain_record(moved),published)
	var extra_rejected:=not C._equal_value(_writer_domain_record(extra),published)
	rows.append({"kind":"FULL_ORIGINAL_WRITER_PARSE_DOMAIN","scene_id":id,"raw_native_equal":raw_equal,"complete_wire_equal":unchanged,"exact_wire_roundtrip":C._equal_value(domain,twice),"one_world_px_real_position_change_rejected":move_rejected,"undeclared_extra_field_rejected":extra_rejected,"native_record_not_replaced_or_mutated":native.objects[0].world_foot_px[0]==before})
	return _check(unchanged and move_rejected and extra_rejected and native.objects[0].world_foot_px[0]==before,"Complete exact writer/parser wire-domain equality plus real-position/extra-field refusal "+id)
func _bind_geometry() -> bool:
	if oracle!=null: oracle.call("release")
	oracle=RAW.new()
	floors.clear(); exact_solids.clear()
	current_size=field.get("_world_size")
	var layout: Resource=scene.map_layout
	var clone: Resource=layout.duplicate(true)
	clone.set("design_size",Vector2i(current_size))
	var is_room: bool=String(scene.scene_id)==String(ASSEMBLY.ROOM)
	if is_room:
		room_scale=current_size/Vector2(1536,1024)
		if not _check(current_size==Vector2(1920,1280) and scene.actor_positions_are_feet and scene.background_path==room_author.shell.texture and scene.resource_path==room_author.room.scene_path and scene.get_meta("assembled_room_contract","")==ASSEMBLY.META and scene.map_layout.resource_path==room_author.room.layout_path,"Actual new room identity/feettrue/1920cover; no minus42"): return false
		var declarations: Array[Dictionary]=[]
		var empty_blockers: Array[Dictionary]=[]
		for base: Dictionary in room_author.geometry.furniture_bases:
			var poly:=PackedVector2Array()
			for pair: Array in base.ground_polygon_px: poly.append(Vector2(pair[0],pair[1])*room_scale)
			declarations.append({"id":base.id,"solid_polygons_px":[poly]})
		clone.set("blockers",empty_blockers)
		clone.set("visual_objects",declarations)
		if not _check(clone.get("blockers").is_empty() and layout.get("blockers").size()==6,"Only typed duplicate blocker clone cleared, source6 remain"): return false
	else:
		var id:=String(scene.scene_id)
		if not _check(C.assembled_bound(scene) and current_size==Vector2(3072,2048) and C._records.has(id),"Actual new city adapter and already-prepared record"): return false
		var record: Dictionary=C._records[id].duplicate(true)
		var runtime_sha: String=record.get("assembled_runtime_binding_sha","")
		var task_receipt: bool=record.get("assembled_parent_task_semantics_preserved",false)
		record.erase("assembled_runtime_binding_sha"); record.erase("assembled_parent_task_semantics_preserved")
		if not _check(runtime_sha==R.BIND_SHA and task_receipt and _complete_publication_record(record,manifest_records[id],id),"Whole published record equals already-prepared actual, excluding two declared receipts; no getter prepare"): return false
		var item: Dictionary=candidate_manifest_paths[id]
		if not _check(scene.get_meta("city_assembled_published_scene_path","")==item.scene_path and scene.map_layout.walkable_mask_path==item.walk_path and scene.map_layout.visual_objects.size()==(30 if id=="ch4_s3_luoyang_market" else 24),"Actual new published layout/native mask/object count"): return false
		var declarations: Array[Dictionary]=[]
		for object: Dictionary in record.objects:
			var shapes: Array[PackedVector2Array]=[]
			var extent:=Vector2(object.collision_size_px[0],object.collision_size_px[1])
			if extent.x>0 and extent.y>0:
				var center:=Vector2(object.physical_center_px[0],object.physical_center_px[1])
				var rect:=Rect2(center-extent*.5,extent)
				shapes.append(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))
			for raw: Array in object.solid_polygons_px:
				var polygon:=PackedVector2Array()
				for pair: Array in raw: polygon.append(Vector2(pair[0],pair[1]))
				shapes.append(polygon)
			if not shapes.is_empty(): declarations.append({"id":object.id,"solid_polygons_px":shapes})
		clone.set("visual_objects",declarations)
	var accepted: bool=bool(oracle.call("configure",clone,"normalized_image_round" if is_room else "round_world_pixel",0.0))
	if not _check(accepted,"Independent new source mask/polygon oracle",oracle.get("errors")): return false
	for poly: PackedVector2Array in oracle.get("regions"):
		var projected:=PackedVector2Array()
		for point: Vector2 in poly: projected.append(point*current_size)
		floors.append(projected)
	for solid: Dictionary in oracle.get("solids"):
		if solid.kind=="exact_world_polygon": exact_solids.append(solid.polygon)
		else:
			var rect: Rect2=solid.rect
			exact_solids.append(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))
	if is_room:
		var actual: Dictionary={}
		for node: Sprite2D in field.get("_scene_object_nodes"): actual[String(node.name)]=node
		for prop: Dictionary in room_author.furniture:
			var name:="SceneObject_"+String(prop.id)
			if not _check(actual.has(name),"Independent furniture exists "+name): return false
			var node: Sprite2D=actual[name]
			var foot:=Vector2(prop.placement_foot_px[0],prop.placement_foot_px[1])
			var anchor:=Vector2(prop.source_ground_anchor_px[0],prop.source_ground_anchor_px[1])
			var ratio: float=prop.render_scale
			if not _check(node.texture.resource_path==prop.texture and not node.centered and node.position.is_equal_approx((foot-anchor*ratio)*room_scale) and node.scale.is_equal_approx(Vector2.ONE*ratio*room_scale),"Actual sprite source/ground anchor/render transform "+name): return false
		if not _check(exact_solids.size()==6,"Exactly6 new real ground solids"): return false
	var player:=field.get("_player") as CharacterBody2D
	var shape:=player.get_node("CollisionShape2D") as CollisionShape2D
	rows.append({"kind":"ACTUAL_SOURCE_BIND","scene_id":String(scene.scene_id),"world_size":current_size,"layout_path":layout.resource_path,"floor_regions":floors.size(),"independent_solids":exact_solids.size(),"native_body":(shape.shape as RectangleShape2D).size,"collision_offset":shape.position,"C_state":C.transition_validation_state()})
	return _check(scene.actor_positions_are_feet and shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size==Vector2(34,24) and shape.position==Vector2.ZERO and _clear(player.position),"Actual bound spawn full875+17/nativePhysics/native34x24 feet")
func _physical(point: Vector2) -> bool:
	var player:=field.get("_player") as CharacterBody2D
	var world:=field.get("world_container") as Node2D
	var shape:=player.get_node("CollisionShape2D") as CollisionShape2D
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=shape.shape; query.transform=shape.global_transform
	query.transform.origin+=world.to_global(point)-player.global_position
	query.exclude=[player.get_rid()]; query.collision_mask=player.collision_mask; query.collide_with_areas=false
	return player.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()
func _clear(point: Vector2) -> bool:
	if Time.get_ticks_msec()>=deadline or oracle==null or not bool(oracle.call("clear",point)): return false
	var rect:=Rect2(point-Vector2(17,12),Vector2(34,24))
	var body:=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	if not floors.is_empty():
		var fits:=false
		for poly: PackedVector2Array in floors:
			if Geometry2D.clip_polygons(body,poly).is_empty(): fits=true; break
		if not fits: return false
	for poly: PackedVector2Array in exact_solids:
		if not Geometry2D.intersect_polygons(body,poly).is_empty(): return false
	for y: int in range(roundi(point.y)-12,roundi(point.y)+13):
		for x: int in range(roundi(point.x)-17,roundi(point.x)+18):
			var sample:=Vector2(x,y)
			if not bool((oracle.call("pixel_evidence",sample) as Dictionary).get("clear",false)): return false
			for poly: PackedVector2Array in exact_solids:
				if Geometry2D.is_point_in_polygon(sample,poly): return false
	return _physical(point)
func _segment(a: Vector2,b: Vector2) -> Dictionary:
	var count:=maxi(1,ceili(a.distance_to(b)/4.0))
	for index: int in range(count+1):
		if not _clear(a.lerp(b,float(index)/count)): return {"clear":false,"index":index}
	return {"clear":true,"centers":count+1,"max_world_step_px":a.distance_to(b)/count}
func _way(points: PackedVector2Array,label: String) -> bool:
	var receipt: Dictionary=await driver.call("follow",field,points,_clear,_segment)
	rows.append({"kind":"NORMAL_INPUT","label":label,"receipt":receipt})
	return _check(receipt.get("ok")==true,label,receipt)
func _foot_frame(label: String) -> Dictionary:
	var player:=field.get("_player") as CharacterBody2D
	var sprite:=player.get("sprite") as Sprite2D
	var world:=field.get("world_container") as Node2D
	var shape:=player.get_node("CollisionShape2D") as CollisionShape2D
	var texture: Texture2D=sprite.texture
	# AtlasTexture.get_image() is the texture-local image, not the full atlas.
	var image: Image=texture.get_image()
	var size: Vector2i=Vector2i(texture.get_size())
	if not _check(image!=null and image.get_size()==size and not sprite.region_enabled and sprite.hframes>0 and sprite.vframes>0,"Exact actual texture-local frame domain"): return {}
	var cell:=Vector2i(size.x/sprite.hframes,size.y/sprite.vframes)
	var frame_rect:=Rect2i(sprite.frame_coords*cell,cell)
	var frame_image:=image.get_region(frame_rect)
	var bounds:=frame_image.get_used_rect()
	var last:=bounds.end.y-1
	var last_x: int=-1
	if last>=0:
		for x: int in range(bounds.position.x,bounds.end.x):
			if frame_image.get_pixel(x,last).a>0.0: last_x=x; break
	if not _check(last_x>=0,"Actual alpha-lowest visible pixel exists"): return {}
	var rect:=sprite.get_rect()
	var alpha_local:=rect.position+Vector2((last_x+.5)/cell.x*rect.size.x,(last+.5)/cell.y*rect.size.y)
	var alpha_foot:=world.to_local(sprite.to_global(alpha_local))
	var collider:=world.to_local(shape.global_position)
	var nominal:=world.to_local(Vector2(player.global_position.x,float(player.call("get_depth_sort_y"))))
	var row: Dictionary={"kind":"SAME_FRAME_PLAYER_FEET","label":label,"frame":Engine.get_process_frames(),"animation_frame":sprite.frame,"texture_class":texture.get_class(),"texture_path":texture.resource_path,"frame_rect":frame_rect,"actor_world":player.position,"collider_world":collider,"nominal_depth_world_y":nominal.y,"alpha_lowest_pixel_center_world":alpha_foot,"alpha_delta_y":alpha_foot.y-player.position.y,"alpha_bounds":bounds,"sprite_position":sprite.position,"sprite_scale":sprite.scale,"body_size":(shape.shape as RectangleShape2D).size,"collision_offset":shape.position}
	rows.append(row)
	_check(scene.actor_positions_are_feet and shape.position==Vector2.ZERO and (shape.shape as RectangleShape2D).size==Vector2(34,24) and collider.distance_to(player.position)<.03 and absf(nominal.y-player.position.y)<.03 and absf(alpha_foot.y-player.position.y)<=12.0,"True feet plus pre-frozen visible-alpha <=12worldpx; reject legacy38px mismatch "+label,row)
	return row
func _four_natural_frames() -> bool:
	var seen: Dictionary={}
	var until:=mini(deadline,Time.get_ticks_msec()+3000)
	while Time.get_ticks_msec()<until and seen.size()<4:
		await RenderingServer.frame_post_draw
		if not _operable(): return false
		var player:=field.get("_player") as CharacterBody2D
		var sprite:=player.get("sprite") as Sprite2D
		var key:=str(sprite.texture.get_instance_id())+":"+str(sprite.frame)
		if not seen.has(key):
			seen[key]=true
			if _foot_frame("natural_"+str(seen.size())).is_empty(): return false
	return _check(seen.size()==4,"Four naturally displayed animation frames; no forced sprite frame")
func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	var path:=output.path_join(label+".png")
	if _check(image.save_png(path)==OK,"Actual new-scene GPU capture "+label): captures.append({"path":path,"sha256":FileAccess.get_sha256(path),"size":image.get_size()})
func _overview(label: String) -> bool:
	var original:=field.get("_world_camera") as Camera2D
	var world:=field.get("world_container") as Node2D
	if not _check(original!=null and original.is_current(),"Original ordinary city camera available for exact restore"): return false
	var old_position:=original.position
	var old_zoom:=original.zoom
	var player:=field.get("_player") as CharacterBody2D
	var old_foot:=player.position
	var camera:=Camera2D.new()
	camera.name="QAOnlyWholeLayoutCamera"
	camera.position=Vector2(1536,1024)
	camera.zoom=Vector2(.5,.5)
	world.add_child(camera)
	camera.make_current()
	await process_frame
	await _capture(label)
	rows.append({"kind":"QA_ONLY_WHOLE_CITY_CAMERA","label":label,"world_center":camera.position,"zoom":camera.zoom,"logical_city_size":current_size,"viewport":root.get_visible_rect().size,"ordinary_player_foot":old_foot,"not_ordinary_camera_travel":true})
	original.make_current()
	camera.queue_free()
	await process_frame
	return _check(original.is_current() and original.position==old_position and original.zoom==old_zoom and player.position==old_foot,"Whole-layout QA camera removed; ordinary camera/follow/player exactly restored")
func _setup(item: Dictionary) -> bool:
	var started:=Time.get_ticks_usec()
	var accepted: bool=bool(root.get_node("SceneRouter").call("go_field_smart",StringName(item.id),item.setup_foot/item.size,"",-1,3))
	var call_ms: float=(Time.get_ticks_usec()-started)/1000.0
	if not _check(accepted,"Public current-v3 near-door setup, not travel") or not await _wait(item.id): return false
	rows.append({"kind":"PUBLIC_SETUP_NOT_TRAVEL","id":item.id,"call_ms":call_ms,"ready_ms":(Time.get_ticks_usec()-started)/1000.0})
	return _clear(item.setup_foot)
func _portal(item: Dictionary) -> bool:
	var definition: Dictionary={}
	for entry: Dictionary in scene.map_layout.portals:
		if entry.id==item.portal_id: definition=entry; break
	var player:=field.get("_player") as CharacterBody2D
	if not _check(not definition.is_empty() and (definition.pos*current_size).distance_to(item.portal_foot)<.02 and player.position.distance_to(item.portal_foot)<.3 and _clear(player.position),"Exact new authored portal foot plus native body "+String(item.portal_id)): return false
	var found: Array[Node]=[]
	var layer:=field.get("_portal_layer") as Node
	for zone: Node in layer.get_children():
		if String(zone.get("target_scene_id"))==String(definition.target_scene) and (zone as Node2D).position.distance_to(item.portal_foot)<.02: found.append(zone)
	if not _check(found.size()==1,"Exactly one matching live native portal "+String(item.portal_id)): return false
	var zone: Node=found[0]
	var available: bool=bool(zone.call("can_enter"))
	rows.append({"kind":"ACTUAL_PORTAL","id":item.portal_id,"scene_id":String(scene.scene_id),"player_foot":player.position,"portal_foot":(zone as Node2D).position,"target":zone.get("target_scene_id"),"label":zone.get("exit_label"),"can_enter":available,"marker_material":zone.get("marker_visual")!=null})
	return _check(available and not bool(zone.get("is_locked")),"Actual live native portal available; no signal/activate injection")
func _room_points(source: Array) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for pair: Array in source: result.append(Vector2(pair[0],pair[1])*room_scale)
	return result
func _route(id: String) -> PackedVector2Array:
	for entry: Dictionary in room_author.geometry.required_routes:
		if entry.id==id: return _room_points(entry.feet_points_px)
	return PackedVector2Array()
func _anvil() -> Sprite2D:
	var nodes: Array=field.get("_scene_object_nodes")
	for node: Sprite2D in nodes:
		if String(node.name)=="SceneObject_anvil_stump": return node
	return null
func _station(id: String,behind: bool,equal: bool=false) -> bool:
	var until:=mini(deadline,Time.get_ticks_msec()+450)
	while Time.get_ticks_msec()<until: await process_frame
	await driver.call("completed_actor_stage")
	var player:=field.get("_player") as CharacterBody2D
	var prop:=_anvil()
	if not _check(prop!=null,"Live independent anvil sprite "+id): return false
	var prop_first:=prop.z_index<player.z_index or (prop.z_index==player.z_index and prop.get_parent()==player.get_parent() and prop.get_index()<player.get_index())
	var state: Dictionary=field.call("get_city_building_fade_debug")
	var depth: Array=field.call("get_v14_depth_order_debug")
	var factor: float=prop.self_modulate.a
	var native_clear:=_physical(player.position)
	rows.append({"kind":"ACTUAL_STATION","id":id,"frame":Engine.get_process_frames(),"player_foot":player.position,"native_shape_clear":native_clear,"prop_alpha":factor,"prop_first":prop_first,"prop_z":prop.z_index,"actor_z":player.z_index,"fade":state,"depth":depth})
	_foot_frame(id)
	var valid:=_check(native_clear and _clear(player.position) and state.get("runtime_hooked",false) and state.get("scope")=="EXACT_ASSEMBLED_FURNITURE_ONLY" and depth.size()>=7,"Actual875+17/nativePhysics and new fade/depth runtime station "+id) and _check(prop_first==not behind,"Native prop/actor front-behind-tie order "+id)
	# No forced fade refresh or artificial delta. Actual runtime settles naturally.
	valid=_check(absf(factor-(.55 if behind else 1.0))<.015,"Current-source-alpha overlap fade "+id,factor) and valid
	if equal: valid=_check(absf(player.position.y-640.0*room_scale.y)<.3,"Real equal-foot side not legacyoffset") and valid
	await _capture("room_"+id)
	return valid
func _impact() -> bool:
	var player:=field.get("_player") as CharacterBody2D
	var start:=player.position
	var samples:=PackedVector2Array()
	Input.action_press("move_up")
	for tick: int in range(22):
		await physics_frame
		samples.append(player.position)
	driver.call("release_movement")
	await driver.call("completed_actor_stage")
	var safe:=true
	for foot: Vector2 in samples:
		if not _clear(foot): safe=false
	var stopped:=samples.size()==22
	for index: int in range(maxi(0,samples.size()-5),samples.size()):
		if samples[index].distance_to(player.position)>.2: stopped=false
	var blocked:=not _physical(Vector2(425,633)*room_scale)
	rows.append({"kind":"REAL_INPUT_GROUND_CONTACT","start":start,"end":player.position,"positions":samples,"safe":safe,"stopped":stopped,"negative_native_shape_blocked":blocked})
	return _check(safe and stopped and blocked and player.position.distance_to(start)>4.0,"Actual held-input base impact stops, no invalid-plan-only credit")
func _assembled_trip() -> bool:
	var city: Node=field
	retained_city_id=city.get_instance_id()
	var entry_player:=field.get("_player") as CharacterBody2D
	var remembered:=entry_player.position
	await driver.call("key",KEY_SPACE)
	if not await _wait("luoyang_market_shop_interior_20261015"): return false
	if not _check(city.get_instance_id()==retained_city_id and not city.is_inside_tree(),"Original city resident retained off-tree during real room entry"): return false
	if not await _four_natural_frames() or not await _way(_route("spawn_front"),"room_spawn_to_front") or not await _station("front",false): return false
	if not await _impact(): return false
	var player:=field.get("_player") as CharacterBody2D
	if not await _way(PackedVector2Array([player.position,Vector2(425,672)*room_scale]),"contact_back_to_front"): return false
	if not await _way(_route("front_to_behind"),"room_behind_绕行") or not await _station("behind",true): return false
	if not await _way(_route("behind_to_tie"),"room_side_绕行") or not await _station("side_equal",false,true): return false
	if not await _way(_room_points([[482,640],[500,640],[500,672],[425,672]]),"room_return_front") or not await _station("front_restored",false): return false
	if not await _way(_room_points([[425,672],[490,690],[550,717],[768,717],[768,885]]),"room_exit_normal_input"): return false
	var started:=Time.get_ticks_usec()
	await driver.call("key",KEY_SPACE)
	if not await _wait("ch4_s3_luoyang_market"): return false
	var elapsed: float=(Time.get_ticks_usec()-started)/1000.0
	player=field.get("_player") as CharacterBody2D
	rows.append({"kind":"ACTUAL_RESIDENT_RETURN","elapsed_ms_hidden_operable":elapsed,"same_city_instance":field.get_instance_id()==retained_city_id,"remembered":remembered,"actual_foot":player.position,"public":root.get_node("SceneRouter").call("get_public_city_preparation_state")})
	return _check(elapsed<RETURN_MS and field.get_instance_id()==retained_city_id and player.position.distance_to(remembered)<.3 and _clear(player.position),"Exact original-door resident return <2000ms hidden+operable")

func _exercise() -> bool:
	if not await _setup(PLAN.market): return false
	if not await _overview("new_market_overview"): return false
	if not await _way(PLAN.market.approach,"market_final_short_INPUT") or not _portal(PLAN.market) or not await _assembled_trip(): return false
	if not await _setup(PLAN.yamen): return false
	if not await _overview("new_yamen_overview"): return false
	if not await _way(PLAN.yamen.approach,"yamen_final_short_INPUT") or not _portal(PLAN.yamen): return false
	return await _way(PackedVector2Array([PLAN.yamen.portal_foot,PLAN.yamen.portal_foot+Vector2(16,0)]),"yamen_final_normal16px")
func _run() -> void:
	var began:=Time.get_ticks_msec(); deadline=began+SHARED_MS
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	players_before=_players()
	output="res://build/luoyang_assembled_scenes_key_20261016b/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(output)
	var complete:=false
	if _precheck():
		_check(DisplayServer.get_name()!="headless" and Engine.time_scale==1,"Actual normal-clock GPU engine")
		driver=INPUT.new(); driver.call("configure",self)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		initialized=true
		complete=await _exercise()
	if initialized: root.get_node("SceneRouter").call("reset_for_new_game")
	if driver!=null: driver.call("release"); driver=null
	if oracle!=null: oracle.call("release"); oracle=null
	if is_instance_valid(field): field=null
	if initialized and is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	if initialized: await process_frame; await process_frame
	var source_after: Dictionary={}
	for path: String in source_before: source_after[path]=_fact(path)
	var players_after:=_players()
	_check(source_after==source_before and players_after==players_before and bridge.call("is_checkpoint_saves_suspended")==true,"Exact new closure/15 saves held; no player restoration or source mutation")
	_check(complete and Time.get_ticks_msec()<deadline,"Fixed120s/two-public-setups/one-room scope complete")
	var file:=FileAccess.open(output.path_join("result.json"),FileAccess.WRITE)
	if file!=null:
		file.store_string(JSON.stringify({"scope":"NEW_ASSEMBLY_TWO_EXTERIORS_ONE_ROOM_THIN_KEY","complete":complete and failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"shared_ms":SHARED_MS,"arrival_ms":ARRIVAL_MS,"return_limit_ms":RETURN_MS,"records":rows,"captures":captures,"source_before":source_before,"source_after":source_after,"players_before":players_before,"players_after":players_after,"source_ready":SOURCE_READY,"no_old_inn_cloth_quest_or_all_city_replay":true},"\t")); file.close()
	print("ASSEMBLED_THIN_KEY=",output,"/result.json")
	quit(0 if complete and failures==0 else 1)
