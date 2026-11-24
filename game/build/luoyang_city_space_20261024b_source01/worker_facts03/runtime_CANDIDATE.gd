extends RefCounted
## Exact Market-only successor. BUILD candidate: no native/artifact admission yet.
## Never calls C.prepare, a collector, image decode, or geometry raster replay.
const READY=true
const ID=&"ch4_s3_luoyang_market"
const SIZE=Vector2(3072,2048)
const SELF="res://build/luoyang_city_space_20261024b_source01/worker_facts03/runtime_CANDIDATE.gd"
const BINDING="res://build/luoyang_city_space_20261024b_source01/runtime_READY02/market_space_binding_READY.json"
const BINDING_SHA="003ec7f690ed9494f315132a4f3f6e16263ad3ca38ccb34392913ae07c5f4cdb"
const PURPOSE_AUTHOR="res://build/luoyang_city_space_20261024b_source01/author_space_delta_interaction_successor03_NOTREADY.json"
const PURPOSE_AUTHOR_SHA="cd1bf3be0cc7d6ddffb2bcbebd2ea51d3258fc5a4ed7ab603703fb020116a467"
const GEOMETRY_PATH="res://build/luoyang_city_space_20261024b_source01/market_replan_geometry_interaction_successor03_CANDIDATE.gd"
const GEOMETRY_SHA="25be67db002ceb1db1990cde55b5b237bcec0bbfbee70aea7e4d7c4b193744ec"
const TASK_ARTISAN="luoyang_paper_artisan_20261016"
static var _binding: Dictionary={}
static var _author: Dictionary={}
static var _geometry_handle: Variant=null
static var _projection_sessions: Dictionary={}
static var _raster_handle: Variant=null
static var _local_art_validated: bool=false
const RASTER_PATH="res://build/luoyang_city_full_rollout_20261022ap_system01/market_wall_retirement_epoch01/pure_wall_retirement_candidate.gd"
const RASTER_SHA="831b6a705990f74e1e98d5de38c26478326d4d11e41b2cd991da4db18a6ab0c7"

static func _b() -> Variant: return load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
static func _c() -> Variant: return load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
static func _dg() -> Variant: return load("res://scripts/city/luoyang_district_life_geometry_20261016f.gd")
static func _same(a: Variant,b: Variant) -> bool:
	if typeof(a)!=typeof(b): return false
	if a is Dictionary:
		if a.size()!=b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _same(a[key],b[key]): return false
		return true
	if a is Array:
		if a.size()!=b.size(): return false
		for index: int in a.size():
			if not _same(a[index],b[index]): return false
		return true
	return a==b
static func _json(path: String,sha: String) -> Dictionary:
	if not path.begins_with("res://") or ".." in path or sha.length()!=64 or FileAccess.get_sha256(path)!=sha: return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
static func binding() -> Dictionary:
	if not _binding.is_empty(): return _binding
	var value:=_json(BINDING,BINDING_SHA)
	if value.get("status")!="EXACT_MARKET_SPACE_SOURCE_BOUND_NOT_WHOLE_CITY" or value.get("scene_id")!=String(ID): return {}
	_binding=value;return _binding
static func _ready() -> bool:
	var data:=binding()
	if not READY or data.get("ready")!=true or data.get("native_spec_ready")!=true or data.get("source_closure_ready")!=true or data.get("local_ART_admitted")!=true: return false
	if not _local_art_validated:
		var art:=_json(String(data.get("local_ART_path","")),String(data.get("local_ART_sha256","")))
		if art.get("status")!="ROOT_TWO_COMPLETE_SHOP_ASSETS_LOCAL_ADMISSION_ONLY" or art.get("local_ART_admitted")!=true or art.get("whole_street_GPU_ART")!=false or art.get("whole_city_ART")!=false: return false
		for path: String in art.get("assets",{}):
			if data.source_sha256.get(path)!=art.assets[path]: return false
		if art.get("assets",{}).size()!=2: return false
		_local_art_validated=true
	return true
static func _geometry() -> Variant:
	if _geometry_handle!=null: return _geometry_handle
	if FileAccess.get_sha256(GEOMETRY_PATH)!=GEOMETRY_SHA: return null
	var value: Variant=load(GEOMETRY_PATH)
	if not value is GDScript or value.resource_path!=GEOMETRY_PATH: return null
	_geometry_handle=value;return value
static func author() -> Dictionary:
	if not _author.is_empty(): return _author
	var spec:=binding()
	var value:=_json(String(spec.get("author_path","")),String(spec.get("author_sha256","")))
	if value.is_empty() or _geometry()==null: return {}
	_author=value;return _author
static func requested(scene: SceneScript) -> bool:
	if scene==null or scene.scene_id!=ID or scene.map_layout==null: return false
	var spec:=binding();var path: String=String(spec.get("artifacts",{}).get("walk.png",{}).get("path",""))
	return not path.is_empty() and scene.map_layout.walkable_mask_path==path
static func source_paths() -> Dictionary:
	var spec:=binding()
	if spec.is_empty(): return {}
	var result: Dictionary={SELF:true,BINDING:true,GEOMETRY_PATH:true,PURPOSE_AUTHOR:true}
	for path: String in spec.get("source_sha256",{}):
		if not path.begins_with("res://") or ".." in path: return {}
		result[path]=true
	return result
static func _proof(scene: SceneScript) -> Dictionary:
	var c: Variant=_c()
	for value: Dictionary in [c._transition_validation,c._resident_ready]:
		if value.get("scene")==scene and value.get("id")==ID and value.get("record")==c._records.get(String(ID)) and int(value.get("token",0))>0: return value
	return {}
static func _sources_match(sources: Dictionary) -> bool:
	var spec:=binding()
	if not _ready() or sources.get(BINDING)!=BINDING_SHA or sources.get(GEOMETRY_PATH)!=GEOMETRY_SHA or sources.get(PURPOSE_AUTHOR)!=PURPOSE_AUTHOR_SHA: return false
	for path: String in spec.source_sha256:
		if sources.get(path)!=spec.source_sha256[path]: return false
	# SELF's exact successor is externally pinned by the canonical consumers,
	# avoiding binding -> helper -> binding SHA cycles. C FIRST hashes it fresh.
	return sources.get(SELF) is String and String(sources[SELF]).length()==64
static func bound(scene: SceneScript) -> bool:
	if not requested(scene) or not _ready() or not _b().whole_bound(scene): return false
	var proof:=_proof(scene)
	return not proof.is_empty() and _sources_match(proof.get("sources",{}))
static func purpose_binding(scene: SceneScript) -> Dictionary:
	if not bound(scene): return {}
	return {"ok":true,"ready":true,"native_spec_ready":true,"author_path":PURPOSE_AUTHOR,"author_sha256":PURPOSE_AUTHOR_SHA,"final_author_path":binding().author_path,"final_author_sha256":binding().author_sha256,"source_first_in_city_receipt":true,"token":_proof(scene).token}
static func _spec_matches(actual: Dictionary,expected: Dictionary) -> bool:
	# AP's three already-authored transformed feet are native Vector2. Restore
	# exactly that representation in the JSON declaration, not general wire/coercion.
	var plain:=expected.duplicate(true)
	if actual.get("placements",[]).size()!=plain.get("placements",[]).size(): return false
	for index: int in plain.placements.size():
		if actual.placements[index].get("id")!=plain.placements[index].get("id"): return false
		if actual.placements[index].get("foot_px") is Vector2: plain.placements[index].foot_px=_geometry().v(plain.placements[index].foot_px)
	return _same(actual,plain)
static func _entries(spec: Dictionary,assets: Dictionary) -> Dictionary:
	var additions: Array=[];var replacements: Array=[];var seen: Dictionary={}
	for placement: Dictionary in spec.get("placements",[]):
		var id: String=String(placement.get("id",""));var asset: Dictionary=assets.get(placement.get("asset_id"),{})
		if id.is_empty() or seen.has(id) or asset.is_empty(): return {}
		seen[id]=true
		var foot: Vector2=_geometry().v(placement.foot_px);var size: Vector2=_geometry().v(asset.size_px);var anchor: Vector2=_geometry().v(asset.source_ground_anchor_px);var scale_value: float=float(placement.scale)
		if not foot.is_finite() or not size.is_finite() or not anchor.is_finite() or not is_finite(scale_value) or scale_value<=0: return {}
		var solids: Array=[]
		for raw: Variant in asset.ground_solid_polygons_px:
			var points: Array=[]
			for point: Vector2 in _geometry().poly(raw):
				var transformed: Vector2=foot+(point-anchor)*scale_value
				points.append([float(transformed.x),float(transformed.y)])
			if points.size()<3: return {}
			solids.append(points)
		var row: Dictionary={"id":id,"texture":String(asset.texture),"pos":(foot+(size*.5-anchor)*scale_value)/SIZE,"render_size_px":size*scale_value,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":foot.y/SIZE.y,"world_foot_px":[float(foot.x),float(foot.y)],"physical_center_px":[float(foot.x),float(foot.y)],"collision_size_px":[0.0,0.0],"city_v3_solid_polygons_px":solids,"blocking":true,"district_life_asset_id":placement.asset_id,"district_life_fade":placement.get("fade",false)}
		if placement.get("replaces","")=="": additions.append(row)
		else:
			if placement.replaces!=id: return {}
			row.replaces=id;replacements.append(row)
	if additions.size()!=12 or replacements.size()!=1 or replacements[0].id!="medicine_stall": return {}
	return {"additions":additions,"replacements":replacements}
static func project_district(scene: SceneScript,original: Dictionary,sources: Dictionary,owner: Callable) -> Dictionary:
	if not owner.is_valid() or not owner.call() or not bound(scene) or not _sources_match(sources): return {}
	var data:=author()
	if data.is_empty() or not _spec_matches(original.get("spec",{}),data.district_current_frozen): return {}
	var next:=_entries(data.runtime_district,data.district_assets)
	if next.is_empty(): return {}
	# Preserve the complete old parent record for the unchanged B full inverse.
	var result:=original.duplicate(true)
	result.spec=data.runtime_district.duplicate(true);result.additions=next.additions;result.replacements=next.replacements
	if not _same(result.parent,original.parent) or not owner.call(): return {}
	var render: Array=_dg().apply_render(scene.map_layout.visual_objects,result)
	if render.size()!=37: return {}
	var proof:=_proof(scene)
	_projection_sessions[scene.get_instance_id()]={"scene":weakref(scene),"layout":weakref(scene.map_layout),"owner":owner,"token":proof.token,"render":render.duplicate(true)}
	return result
static func _projection_session(scene: SceneScript) -> Dictionary:
	if scene==null or scene.map_layout==null: return {}
	var session: Dictionary=_projection_sessions.get(scene.get_instance_id(),{})
	if session.is_empty() or session.scene.get_ref()!=scene or session.layout.get_ref()!=scene.map_layout or not session.owner.is_valid() or not session.owner.call(): return {}
	return session
static func ground_parent_matches(scene: SceneScript,base_render: Array) -> bool:
	var session:=_projection_session(scene)
	return bound(scene) and not session.is_empty() and base_render.size()==37 and _same(base_render,session.render) and int(_proof(scene).get("token",0))==session.token
static func project_task_rows(scene: SceneScript,original: Dictionary) -> Dictionary:
	# Also used by the existing owner-bound warm task refresh after C clears its
	# transition proof. This is NOT new source freshness credit or a token rebind.
	if not requested(scene) or not _ready() or not _b().whole_bound(scene): return {}
	if original.get("ok")!=true or not original.get("npcs") is Array: return {}
	var result:=original.duplicate(true);var count: int=0
	for npc: Dictionary in result.npcs:
		if npc.get("npc_id")!=TASK_ARTISAN: continue
		count+=1
		if npc.get("pos")!=Vector2(1320,1290)/SIZE: return {}
		npc.pos=Vector2(880,1340)/SIZE
	if count!=1: return {}
	# Exact output dictionary inverse: only one task actor position may change.
	var inverse:=result.duplicate(true)
	for npc: Dictionary in inverse.npcs:
		if npc.get("npc_id")==TASK_ARTISAN: npc.pos=Vector2(1320,1290)/SIZE
	return result if _same(inverse,original) else {}

static func prepare_worker_context(sources: Dictionary) -> Dictionary:
	# Main-thread preparation only; the existing C FIRST already hashes these
	# exact paths. No new job, per-frame stat, or cross-token freshness cache.
	if not _sources_match(sources) or sources.get(RASTER_PATH)!=RASTER_SHA: return {}
	if _raster_handle==null:
		if FileAccess.get_sha256(RASTER_PATH)!=RASTER_SHA: return {}
		_raster_handle=load(RASTER_PATH)
	if not _raster_handle is GDScript or _raster_handle.resource_path!=RASTER_PATH: return {}
	var data:=author()
	return {"spec":binding().duplicate(true),"author":data.duplicate(true)} if not data.is_empty() else {}
static func effective_domain(original: Dictionary) -> Dictionary:
	if not _ready(): return {}
	var result:=original.duplicate(true)
	for key: String in binding().domain_overrides: result[key]=binding().domain_overrides[key].duplicate(true) if binding().domain_overrides[key] is Dictionary else binding().domain_overrides[key]
	result.source_sha256=original.source_sha256.duplicate(true)
	result.source_sha256.merge(binding().source_sha256)
	# The worker's same-token facts must include all four exact published child
	# artifacts, not only their already-admitted FIRST/FINAL city source rows.
	if result.artifacts.size()!=4 or not _same(result.artifacts,binding().artifacts): return {}
	for suffix: String in ["scene.res","layout.res","packet.bin","walk.png"]:
		var artifact: Dictionary=result.artifacts.get(suffix,{})
		if artifact.size()!=2 or not artifact.get("path") is String or not artifact.get("sha256") is String: return {}
		if result.source_sha256.has(artifact.path) and result.source_sha256[artifact.path]!=artifact.sha256: return {}
		result.source_sha256[artifact.path]=artifact.sha256
	return result
static func _pointer(root: Dictionary,path: Array) -> Variant:
	var cursor: Variant=root
	for key: Variant in path:
		if not cursor is Dictionary or not cursor.has(key): return null
		cursor=cursor[key]
	return cursor
static func _assign(root: Dictionary,path: Array,value: Variant) -> bool:
	if path.is_empty(): return false
	var cursor: Dictionary=root
	for index: int in path.size()-1:
		if not cursor.get(path[index]) is Dictionary: return false
		cursor=cursor[path[index]]
	if not cursor.has(path[-1]): return false
	cursor[path[-1]]=value;return true
static func _expected_record(parent: Dictionary,data: Dictionary,walk_path: String) -> Dictionary:
	# The same pure source operations as the admitted publisher; no PNG/Scene.
	var g: Variant=_geometry_handle
	var replacements: Array=[]
	for placement: Dictionary in data.complete_buildings:
		var building: Dictionary=g.building(data.assets.get(placement.asset_id,{}),placement)
		if building.is_empty(): return {}
		replacements.append(building)
	if replacements.size()!=2: return {}
	var changed: Dictionary=g.replace_objects(parent.get("objects",[]),replacements,data.native_object_moves)
	if changed.is_empty(): return {}
	var pruned: Dictionary=g.retire_closed_stalls(changed.rows,data.retire_closed_stall_ids)
	if pruned.is_empty() or pruned.rows.size()!=21: return {}
	var output:=parent.duplicate(true);output.objects=pruned.rows
	for placement: Dictionary in data.low_wall_components:
		var wall: Dictionary=g.low_wall(data.low_wall_asset,placement)
		if wall.is_empty() or not g.exact_row(parent.objects,String(placement.id)).is_empty(): return {}
		output.objects.append(wall)
	if output.objects.size()!=25: return {}
	for migration: Dictionary in data.record_point_migrations:
		if migration.pointer not in [["npc_stations"],["interaction_anchors"],["gameplay_slots","npcs"],["gameplay_slots","interactions"],["gameplay_slots","portals"]]: return {}
		var old: Variant=_pointer(output,migration.pointer)
		if not old is Array: return {}
		var moved: Dictionary=g.exact_point_row_migration(old,migration.deltas,migration.id_key,migration.point_key)
		if moved.is_empty() or not _assign(output,migration.pointer,moved.rows): return {}
	var seen: Dictionary={}
	for route: Dictionary in data.route_replacements:
		if seen.has(route.id): return {}
		seen[route.id]=true
		var found: Dictionary=g.exact_row(output.routes,String(route.id))
		if found.is_empty() or g.poly(found.points_px)!=g.poly(route.old_points_px): return {}
		found.points_px=route.new_points_px.duplicate(true)
	output.walk_path=walk_path
	return output
static func validate_child_worker(child: Dictionary,parent: Dictionary,context: Dictionary,stream_sha: String) -> bool:
	# Exactly one admitted immutable child, with original complete parent chain
	# still verified by the adapter. This does not claim runtime pixel replay.
	var spec: Dictionary=context.get("spec",{});var data: Dictionary=context.get("author",{})
	if spec.is_empty() or data.is_empty() or _geometry_handle==null or _raster_handle==null: return false
	if stream_sha!=spec.artifacts["packet.bin"].sha256 or child.get("geometry_basis")!=spec.basis or child.get("space_replan_parent_packet_sha256")!=spec.old_finite_packet.sha256: return false
	var published_input_sha: String=String(spec.source_sha256.get("res://build/luoyang_city_revision_20261024b_root01/market_detours06_READY/input_READY.json",""))
	if published_input_sha.length()!=64 or child.get("space_replan_input_sha256")!=published_input_sha: return false
	if child.get("mask_sha")!=spec.mask_rgba_sha256 or not child.get("walk_bytes") is PackedByteArray or child.walk_bytes.size()!=3072*2048*4 or _sha(child.walk_bytes)!=spec.mask_rgba_sha256: return false
	var expected:=_expected_record(parent.record,data,spec.artifacts["walk.png"].path)
	if expected.is_empty() or not _same(child.get("record"),expected) or not _same(child.get("solids"),_raster_handle.native_solids(expected.objects)) or child.solids.size()!=33: return false
	# Full storage inverse, retaining wrappers, resources, types and every field
	# outside the producer-authorized Scene.npcs / four layout storage fields.
	var scene_inverse: Dictionary=child.scene_storage.duplicate(true)
	var layout_inverse: Dictionary=child.layout_storage.duplicate(true)
	if not scene_inverse.fields.get("npcs") is Dictionary or not scene_inverse.fields.npcs.get("array_values") is Array or scene_inverse.fields.npcs.array_values.size()!=8: return false
	for key: String in ["visual_objects","portals","interactions"]:
		if not layout_inverse.fields.get(key) is Dictionary or not layout_inverse.fields[key].get("array_values") is Array: return false
	if layout_inverse.fields.visual_objects.array_values.size()!=25 or layout_inverse.fields.portals.array_values.size()!=9 or layout_inverse.fields.interactions.array_values.size()!=4: return false
	if not _array_wrapper_type_equal(scene_inverse.fields.npcs,parent.scene_storage.fields.npcs): return false
	for key: String in ["visual_objects","portals","interactions"]:
		if not _array_wrapper_type_equal(layout_inverse.fields[key],parent.layout_storage.fields[key]): return false
	scene_inverse.fields.npcs=parent.scene_storage.fields.npcs.duplicate(true)
	for key: String in ["visual_objects","portals","interactions","walkable_mask_path"]: layout_inverse.fields[key]=parent.layout_storage.fields[key].duplicate(true) if parent.layout_storage.fields[key] is Dictionary else parent.layout_storage.fields[key]
	if not _same(scene_inverse,parent.scene_storage) or not _same(layout_inverse,parent.layout_storage): return false
	var inverse:=child.duplicate(true)
	for key: String in ["record","solids","walk_bytes","mask_sha","scene_storage","layout_storage","geometry_basis"]: inverse[key]=parent[key]
	for key: String in ["space_replan_parent_packet_sha256","space_replan_input_sha256"]: inverse.erase(key)
	return _same(inverse,parent)
static func _sha(bytes: PackedByteArray) -> String:
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes);return hash.finish().hex_encode()

static func room_source_paths() -> Dictionary:
	# Shared room source domain is deliberately small: it never pulls the new
	# Market Scene/packet/mask or all media into the other cities' G catalogue.
	var spec:=binding()
	if spec.is_empty(): return {}
	var output: Dictionary={SELF:true,BINDING:true,PURPOSE_AUTHOR:true,GEOMETRY_PATH:true}
	for path: String in [String(spec.author_path),String(spec.publication_path)]: output[path]=true
	output[String(spec.local_ART_path)]=true
	for row: Dictionary in spec.room_returns.values(): output[row.author_path]=true
	return output
static func owns_room(id: StringName) -> bool:
	return String(id) in ["luoyang_market_market_northeast_rear_frontage_interior_20261015","luoyang_market_market_east_ward_frontage_interior_20261015"]
static func room_return_binding(id: StringName,original: Dictionary) -> Dictionary:
	if not owns_room(id): return original.duplicate(true)
	if not _ready(): return {}
	var delta: Dictionary=binding().room_returns.get(String(id),{})
	if delta.is_empty() or original.get("scene_id")!=String(id) or original.get("city_id")!=String(ID) or _geometry().v(original.get("return_foot_px"))!=_geometry().v(delta.old_return_px): return {}
	# The fixed raw room author/native/storage stay unchanged. Only this new
	# declared return binding is projected, exactly these two room IDs.
	if FileAccess.get_sha256(delta.author_path)!=delta.author_sha256: return {}
	var output:=original.duplicate(true);output.return_foot_px=delta.new_return_px.duplicate(true)
	var inverse:=output.duplicate(true);inverse.return_foot_px=original.return_foot_px.duplicate(true)
	return output if _same(inverse,original) else {}
static func city_native_threshold(scene: SceneScript,id: StringName,projected_return: Vector2) -> Vector2:
	if not requested(scene) or not bound(scene) or not owns_room(id): return Vector2(INF,INF)
	var delta: Dictionary=binding().room_returns.get(String(id),{})
	if delta.is_empty() or projected_return!=_geometry().v(delta.new_return_px)/SIZE: return Vector2(INF,INF)
	return _geometry().v(delta.new_threshold_px)/SIZE
static func room_exit_portals(scene: SceneScript,original: Array) -> Dictionary:
	if scene==null or not owns_room(scene.scene_id) or not _ready(): return {"ok":false,"portals":[],"error":"MARKET_SPACE_ROOM_SOURCE_PENDING"}
	var delta: Dictionary=binding().room_returns.get(String(scene.scene_id),{})
	if delta.is_empty() or FileAccess.get_sha256(delta.author_path)!=delta.author_sha256: return {"ok":false,"portals":[],"error":"MARKET_SPACE_ROOM_AUTHOR_CHANGED"}
	var result:=original.duplicate(true);var count: int=0
	for portal: Dictionary in result:
		if String(portal.get("target_scene",""))!=String(ID): continue
		count+=1
		if portal.get("target_pos")!=_geometry().v(delta.old_return_px)/SIZE: return {"ok":false,"portals":[],"error":"MARKET_SPACE_ROOM_OLD_RETURN_CHANGED"}
		portal.target_pos=_geometry().v(delta.new_return_px)/SIZE
	if count!=1: return {"ok":false,"portals":[],"error":"MARKET_SPACE_ROOM_RETURN_COUNT"}
	var inverse:=result.duplicate(true)
	for portal: Dictionary in inverse:
		if String(portal.get("target_scene",""))==String(ID): portal.target_pos=_geometry().v(delta.old_return_px)/SIZE
	return {"ok":true,"portals":result} if _same(inverse,original) else {"ok":false,"portals":[],"error":"MARKET_SPACE_ROOM_RETURN_INVERSE"}

static func _array_wrapper_type_equal(left: Variant,right: Variant) -> bool:
	if not left is Dictionary or not right is Dictionary or not left.get("array_values") is Array or not right.get("array_values") is Array: return false
	var a: Dictionary=left.duplicate(true);var b: Dictionary=right.duplicate(true)
	a.erase("array_values");b.erase("array_values")
	return _same(a,b)

static func fade_native_admission(scene: SceneScript,parent_objects: Array) -> Dictionary:
	if not bound(scene) or not _same(parent_objects,scene.map_layout.visual_objects): return {}
	var data:=author()
	if data.is_empty() or data.low_wall_components.size()!=4 or parent_objects.size()!=25: return {}
	var ids: Array=[]
	for row: Dictionary in data.low_wall_components:
		if _geometry().exact_row(parent_objects,String(row.id)).is_empty(): return {}
		ids.append(String(row.id))
	return {"ok":true,"ids":ids,"retired_ids":data.retire_closed_stall_ids.duplicate()}
