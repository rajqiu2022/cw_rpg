extends RefCounted
## Exact Market-only successor. BUILD candidate: no native/artifact admission yet.
## Never calls C.prepare, a collector, image decode, or geometry raster replay.
const READY=false
const ID=&"ch4_s3_luoyang_market"
const SIZE=Vector2(3072,2048)
const SELF="res://build/luoyang_city_space_20261024b_source01/market_space_runtime_CANDIDATE.gd"
const BINDING="PENDING_ROOT_NATIVE_PUBLICATION_AND_LOCAL_ART_BINDING"
const BINDING_SHA=""
const PURPOSE_AUTHOR="res://build/luoyang_city_space_20261024b_source01/author_space_delta_interaction_successor03_NOTREADY.json"
const PURPOSE_AUTHOR_SHA="cd1bf3be0cc7d6ddffb2bcbebd2ea51d3258fc5a4ed7ab603703fb020116a467"
const GEOMETRY_PATH="res://build/luoyang_city_space_20261024b_source01/market_replan_geometry_interaction_successor03_CANDIDATE.gd"
const GEOMETRY_SHA="25be67db002ceb1db1990cde55b5b237bcec0bbfbee70aea7e4d7c4b193744ec"
const TASK_ARTISAN="luoyang_paper_artisan_20261016"
static var _binding: Dictionary={}
static var _author: Dictionary={}
static var _geometry_handle: Variant=null
static var _projection_sessions: Dictionary={}

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
	return READY and data.get("ready")==true and data.get("native_spec_ready")==true and data.get("source_closure_ready")==true and data.get("local_ART_admitted")==true
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
