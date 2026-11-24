extends RefCounted

## Two NEW street-block candidates. No SceneTree entry/engine/publisher writes.
## Existing source bytes, routes, NPCs, interaction identities and portals kept.
## Original fortification walls and ground are retained, not claimed rebuilt.
const BASE_ROOT := "res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/"
const SOURCE_ROOT := "res://art/maps/luoyang_modular_v3/source/"
const GATE := "ch4_s0_luoyang_gate"
const MARKET := "ch4_s3_luoyang_market"
const BASE_SHA := {GATE:"2818f9fca10d30abbbbd386ff2b26a3d4ed87f300a9b8ef47f882bcb83f7640d",MARKET:"bc100b541f74ddaa49391ccb7e8a5161905f3586c243dc74eded840284f8dc5f"}
const MODULE_SEM := SOURCE_ROOT+"module_semantics.json"
const MODULE_SEM_SHA := "9a2f68fd3c6c243dd690a04dbdeec8bd8627931aa498337b2fa01957a9c449c2"
const SOURCE_SIZES := {SOURCE_ROOT+"canal_warehouse_v3.png":Vector2i(1774,887),SOURCE_ROOT+"street_row_v3.png":Vector2i(1536,1024),SOURCE_ROOT+"shop_v1.png":Vector2i(1536,1024),SOURCE_ROOT+"goods_stall_v2.png":Vector2i(1536,1024)}
const SOURCE_PINS := {SOURCE_ROOT+"canal_warehouse_v3.png":"3bfa2bd8a906ffe8ef069f7933e45255fe569606781c46886dd0dea519e9580b",SOURCE_ROOT+"street_row_v3.png":"c012d6d3698a8ce00d3f3f32202614a1d2743dc5773c53e5521fd99821da0303",SOURCE_ROOT+"shop_v1.png":"02d474a76c6deaf995eff97be9cb343bf1b0f6ae26a42a72e716308f38d23883",SOURCE_ROOT+"goods_stall_v2.png":"85cfbe6b14d6aef518d33acb3c3034e07a7b26e0d3e57dc3e9c1047452d416d0"}
const WALL_WORKSPACE := "assets/raw/scene_module/luoyang_yamen_front_v9/front_wall_v9_candidate.png"
const WALL_RESOURCE := "res://art/maps/luoyang_enclosure_v11/source/front_wall_v9_candidate.png"
const WALL_SHA := "b903c3aef333e0c3880ad0fb2fc83e131336cc381fde8d4f0fa88b59585149fb"
const LOW_WALL_SCALE := .33
const LOW_WALL_GROUND_DEPTH := 12.
var region: String=GATE
var error := ""
var bases: Dictionary={}
var module_semantics: Dictionary={}
var textures: Dictionary={}

static func _repo(relative: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("../"+relative).simplify_path()

static func _vec(a: Array) -> Vector2:
	return Vector2(float(a[0]),float(a[1]))

static func _rect(x0: float,y0: float,x1: float,y1: float) -> Array:
	return [[x0,y0],[x1,y0],[x1,y1],[x0,y1]]

func prepare(chosen: String=GATE) -> bool:
	error=""
	release()
	if not chosen in [GATE,MARKET]: error="Unsupported street-block region.";return false
	region=chosen
	for scene: String in [GATE,MARKET]:
		var path: String=BASE_ROOT+scene+"/art_contract.json"
		if FileAccess.get_sha256(path).to_lower()!=BASE_SHA[scene]: error="Frozen base SHA changed: "+scene;return false
		var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
		if not raw is Dictionary or not raw.get("objects") is Array: error="Frozen street base malformed.";return false
		bases[scene]=raw
	if FileAccess.get_sha256(MODULE_SEM).to_lower()!=MODULE_SEM_SHA: error="Registered foot/solid semantic source SHA changed.";return false
	var sem: Variant=JSON.parse_string(FileAccess.get_file_as_string(MODULE_SEM))
	if not sem is Dictionary or not sem.get("modules") is Dictionary: error="Actual registered module semantics unavailable.";return false
	module_semantics=sem.modules
	for path: String in SOURCE_PINS:
		if FileAccess.get_sha256(path).to_lower()!=SOURCE_PINS[path]: error="Registered original source SHA changed: "+path;return false
		var image:=Image.load_from_file(path)
		if image==null or image.get_format()!=Image.FORMAT_RGBA8 or image.get_size()!=SOURCE_SIZES[path]: error="Actual registered size/native originalRGBA8 required: "+path;return false
		textures[path]=ImageTexture.create_from_image(image)
	if FileAccess.get_sha256(_repo(WALL_WORKSPACE)).to_lower()!=WALL_SHA: error="Approved originalV9 low-wall source changed.";return false
	var wall:=Image.load_from_file(_repo(WALL_WORKSPACE))
	if wall==null or wall.get_size()!=Vector2i(2172,724) or wall.get_format()!=Image.FORMAT_RGBA8: error="Actual V9 wall2172x724RGBA8 required.";return false
	textures[WALL_RESOURCE]=ImageTexture.create_from_image(wall)
	return true

func _existing(scene: String,id: String) -> Dictionary:
	for object: Dictionary in bases.get(scene,{}).get("objects",[]):
		if String(object.id)==id: return object
	error="Required frozen semantic object missing: "+id
	return {}

func _new_record(id: String,source: String,size: Vector2,foot_source: Vector2,scale_value: float,foot: Vector2,source_solids: Array) -> Dictionary:
	var origin:=foot-foot_source*scale_value
	var solids: Array=[]
	for polygon: Array in source_solids:
		var transformed: Array=[]
		for p: Array in polygon:
			var q: Vector2=origin+_vec(p)*scale_value
			transformed.append([q.x,q.y])
		solids.append(transformed)
	return {"id":id,"world_foot_px":[foot.x,foot.y],"physical_center_px":[foot.x,foot.y],"collision_size_px":[0,0],"solid_polygons_px":solids,"blocking":true,"pieces":[{"source":source,"uv_polygon_px":_rect(0,0,size.x,size.y),"origin_px":[origin.x,origin.y],"scale":scale_value}],"foot_authority":"Registered original source semantic ground point, not alpha bottom/bbox; independently transform original ground solids at same uniform scale"}

func _module(id: String,filename: String,foot: Vector2,scale_value: float) -> Dictionary:
	var sem: Dictionary=module_semantics.get(filename,{})
	if sem.is_empty(): error="Module semantic missing: "+filename;return {}
	var size:=_vec(sem.source_size_px)
	var source_solids: Array=[]
	for polygon: Array in sem.solid_polygons_uv:
		var actual: Array=[]
		for p: Array in polygon: actual.append([float(p[0])*size.x,float(p[1])*size.y])
		source_solids.append(actual)
	return _new_record(id,SOURCE_ROOT+filename,size,_vec(sem.measured_source_foot_px),scale_value,foot,source_solids)

func _reuse_market(id: String,old_id: String,foot: Vector2,scale_value: float) -> Dictionary:
	var old:=_existing(MARKET,old_id)
	if old.is_empty(): return {}
	var size:=_vec(old.source_size_px)
	var source_foot:=_vec(old.foot_uv)*size
	var old_scale: float=float(old.render_size_px[0])/size.x
	if absf(old_scale-float(old.render_size_px[1])/size.y)>.000001: error="Original architecture was not uniformly scaled.";return {}
	var old_origin: Vector2=_vec(old.world_foot_px)-source_foot*old_scale
	var source_solids: Array=[]
	for polygon: Array in old.solid_polygons_px:
		var source_polygon: Array=[]
		for p: Array in polygon:
			var q: Vector2=(_vec(p)-old_origin)/old_scale
			source_polygon.append([q.x,q.y])
		source_solids.append(source_polygon)
	return _new_record(id,String(old.source),size,source_foot,scale_value,foot,source_solids)

func _low_wall(id: String,x0: float,x1: float,ground_y: float) -> Dictionary:
	# All pieces fit ONE actual clean source interior x100..2080, no repeats.
	# Lower height is genuine equalXYscale, never compressed wall height alone.
	var source_end: float=100.+(x1-x0)/LOW_WALL_SCALE
	if x1<=x0 or source_end>2080.: error="Low-wall span exceeds actual unchanged source.";return {}
	var origin:=Vector2(x0-100.*LOW_WALL_SCALE,ground_y-563.*LOW_WALL_SCALE)
	return {"id":id,"world_foot_px":[(x0+x1)*.5,ground_y],"physical_center_px":[(x0+x1)*.5,ground_y-LOW_WALL_GROUND_DEPTH*.5],"collision_size_px":[0,0],"solid_polygons_px":[_rect(x0,ground_y-LOW_WALL_GROUND_DEPTH,x1,ground_y)],"blocking":true,"pieces":[{"source":WALL_RESOURCE,"uv_polygon_px":_rect(100,200,source_end,572),"origin_px":[origin.x,origin.y],"scale":LOW_WALL_SCALE}],"foot_authority":"Explicit NEW low-wall ground at selected source brickfoot563; ground depth12logical authoring, not alpha roof bbox or imported old collision credit","source_uv_exclusion":"Exclude original generated terminal pillars and A1 canvas edges; no alpha threshold or bitmap edit","known_risk":"Selected panel flat terminal cuts require current GPU review, not a finished endcap/native wall claim"}

func remove_object_ids(chosen: String="") -> Array[String]:
	var scene: String=region if chosen.is_empty() else chosen
	if scene==GATE: return ["east_street_front"]
	if scene==MARKET: return ["north_market_front","southwest_market_front","southeast_market_front"]
	return []

func author_records(chosen: String="") -> Array:
	var scene: String=region if chosen.is_empty() else chosen
	if bases.is_empty() or module_semantics.is_empty(): error="prepare() before registered semantic transforms required.";return []
	if scene==GATE:
		return [
			_module("east_street_front","canal_warehouse_v3.png",Vector2(2370,1040),.62),
			_low_wall("v13_gate_west_plot_wall_0",280.,920.,1160.),
			_low_wall("v13_gate_west_plot_wall_1",1040.,1160.,1160.),
			_low_wall("v13_gate_east_plot_wall_0",1940.,2350.,1160.),
			_low_wall("v13_gate_east_plot_wall_1",2490.,2850.,1160.),
			_reuse_market("v13_gate_provision_stall","goods_stall",Vector2(2200,1410),.18)
		]
	if scene==MARKET:
		return [
			_module("north_market_front","street_row_v3.png",Vector2(1536,630),.67),
			_module("southwest_market_front","canal_warehouse_v3.png",Vector2(600,1810),.50),
			_reuse_market("southeast_market_front","shop",Vector2(2520,1810),.56),
			_low_wall("v13_market_west_plot_wall",220.,850.,1510.),
			_low_wall("v13_market_east_plot_wall",2190.,2790.,1320.)
		]
	error="Unsupported street region author_records."
	return []

func source_catalog() -> Dictionary:
	var sources: Dictionary=SOURCE_PINS.duplicate()
	sources[WALL_RESOURCE]=WALL_SHA
	return sources

func source_copy_requests() -> Dictionary:
	# Runtime owner performs exact-byte copy/import, art never modifies sourcePNG.
	return {_repo(WALL_WORKSPACE):WALL_RESOURCE}

func base_manifest_path() -> String:
	return BASE_ROOT+region+"/art_contract.json"

func protected_context() -> Dictionary:
	var base: Dictionary=bases.get(region,{})
	return {"routes":base.get("routes",[]).duplicate(true),"gameplay_slots":base.get("gameplay_slots",{}).duplicate(true),"entry_foot_px":base.get("entry_foot_px",[]).duplicate(true),"authority_camera":base.get("authority_camera",{}).duplicate(true)}

func authoring_observations() -> Dictionary:
	return {"scope":"TWO_REGION_STREET_BLOCK_CANDIDATE_NOT_ADOPTED","region":region,"generated_images":0,"new_story_or_interaction":false,"physical_routes_npc_slots_portals_unchanged":true,"fortification_and_ground":"Unchanged; not declared newly finished by this helper","west_gate_entrance_ground_width":120.,"east_gate_entrance_ground_width":140.,"low_wall_visible_ridge_foot_height":344.*LOW_WALL_SCALE,"north_market_front_alpha_gt30_top_expected":630.-(911.-53.)*.67,"north_market_front_weak_alpha0_source_row_expected":630.-911.*.67,"actual_gpu_alpha_crop_visual_Field":"PENDING; no prior credit inherited","known_risks":["Low-wall end cuts and original source light need actual GPU review","North roof/weak alpha margins must be reviewed current render","All transformed source solids need realField player17point/currentY checks","No claim town fully approved or formally integrated"]}

func draw(parent: Node2D,rect: Rect2i,zoom: float=1.) -> Array[Polygon2D]:
	var nodes: Array[Polygon2D]=[]
	var records: Array=author_records()
	records.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return float(a.world_foot_px[1])<float(b.world_foot_px[1]))
	for record: Dictionary in records:
		for piece: Dictionary in record.pieces:
			var node:=Polygon2D.new()
			var uv:=PackedVector2Array()
			for p: Array in piece.uv_polygon_px: uv.append(_vec(p))
			node.name=String(record.id)
			node.polygon=uv.duplicate();node.uv=uv.duplicate()
			node.texture=textures[piece.source]
			node.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
			node.texture_repeat=CanvasItem.TEXTURE_REPEAT_DISABLED
			node.position=(_vec(piece.origin_px)-Vector2(rect.position))*zoom
			node.scale=Vector2.ONE*float(piece.scale)*zoom
			parent.add_child(node);nodes.append(node)
	return nodes

func release() -> void:
	textures.clear()
	bases.clear()
	module_semantics.clear()
