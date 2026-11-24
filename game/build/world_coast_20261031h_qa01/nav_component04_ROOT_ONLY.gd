extends SceneTree
## Candidate-only, bounded pixel1 proof. No Field/input/user-save APIs.
const QA_ROOT: String="res://build/world_coast_20261031h_qa01/"
const WORLD_SIZE:=Vector2i(12288,8192)
const TILE:=Vector2i(1536,1024)
const ROI:=Rect2i(10400,2100,1888,2160)
var errors: Array[String]=[]
var checks:=0
var suspended:=false
var manifest: Dictionary={}
var images: Dictionary={}
var lru: Array[int]=[]
var output_dir: String
func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children():_early(node)
	_run.call_deferred()
func _early(node: Node) -> void:
	if node.name==&"PlatformBridge":node.call("set_checkpoint_saves_suspended",true);suspended=bool(node.call("is_checkpoint_saves_suspended"))
func _arg(name: String) -> String:
	var args: PackedStringArray=OS.get_cmdline_user_args();var index: int=args.find(name)
	return args[index+1] if index>=0 and index+1<args.size() else ""
func _need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("COAST31H_QA_FAIL ",label)
	return ok
func _image(path: String) -> Image:
	var image:=Image.load_from_file(path)
	if image==null or image.get_size()!=TILE:_need(false,"NATIVE1536x1024_IMAGE:"+path);return null
	image.convert(Image.FORMAT_RGBA8);return image
func _data(index: int) -> PackedByteArray:
	if images.has(index):lru.erase(index);lru.append(index);return images[index]
	var image: Image=_image(String(manifest.navigation_tiles[index].path))
	if image==null:return PackedByteArray()
	var data: PackedByteArray=image.get_data();images[index]=data;lru.append(index)
	while lru.size()>6:images.erase(lru.pop_front())
	return data
func _white(data: PackedByteArray,index: int) -> bool:
	return data[index+3]>=128 and maxi(data[index],maxi(data[index+1],data[index+2]))>=128
func _pixel(p: Vector2i) -> bool:
	if p.x<0 or p.y<0 or p.x>=WORLD_SIZE.x or p.y>=WORLD_SIZE.y:return false
	var col: int=p.x/TILE.x;var row: int=p.y/TILE.y;var data: PackedByteArray=_data(row*8+col)
	return not data.is_empty() and _white(data,((p.y-row*TILE.y)*TILE.x+p.x-col*TILE.x)*4)
func _expected_ports() -> Dictionary:
	var layout: Resource=load(String(manifest.baseline_reference_layout)) as Resource
	var expected: Dictionary={}
	for row: Dictionary in layout.get("portals"):
		var pos: Vector2=row.pos
		expected[String(row.id)]={"target_scene":String(row.get("target_scene","")),"world_foot":[pos.x*12288,pos.y*8192]}
	for path: String in ["res://build/three_towns_world_20261029j_system01/town_registry.gd","res://build/adventure_world_20261031f_system01/world_links.gd"]:
		var helper: Script=load(path) as Script
		for row: Dictionary in helper.call("portal_rows"):
			var p: Vector2=row.world_foot
			expected[String(row.id)]={"target_scene":String(row.target_scene),"world_foot":[p.x,p.y]}
	return expected
func _pair(value: Variant) -> Vector2:
	if not value is Array or value.size()!=2:return Vector2(INF,INF)
	return Vector2(float(value[0]),float(value[1]))
func _same_numbers(value: Variant,expected: Array) -> bool:
	if not value is Array or value.size()!=expected.size():return false
	for index: int in expected.size():
		if typeof(value[index]) not in [TYPE_INT,TYPE_FLOAT] or float(value[index])!=float(expected[index]):return false
	return true
func _body_clear(layout: Resource,p: Vector2) -> bool:
	var corners:=PackedVector2Array([p+Vector2(-17,-12),p+Vector2(17,-12),p+Vector2(17,12),p+Vector2(-17,12)])
	var foot_box:=Rect2(p-Vector2(17,12),Vector2(34,24))
	for row: Dictionary in layout.get("visual_objects"):
		if row.has("solid_polygons_px"):
			for polygon: PackedVector2Array in row.solid_polygons_px:
				if not Geometry2D.intersect_polygons(corners,polygon).is_empty():return false
		elif row.get("collision_size") is Vector2:
			var center: Vector2=(row.get("pos",Vector2.ZERO)+row.get("collision_offset",Vector2.ZERO))*Vector2(WORLD_SIZE)
			var extent: Vector2=row.collision_size*Vector2(WORLD_SIZE)
			if foot_box.intersects(Rect2(center-extent*.5,extent),true):return false
	for row: Dictionary in layout.get("blockers"):
		var center: Vector2=row.get("pos",Vector2.ZERO)*Vector2(WORLD_SIZE);var extent: Vector2=row.get("size",Vector2.ZERO)*Vector2(WORLD_SIZE)
		if foot_box.intersects(Rect2(center-extent*.5,extent),true):return false
	return true
func _foot_white(p: Vector2) -> bool:
	for y: int in range(-12,13):
		for x: int in range(-17,18):
			if not _pixel(Vector2i(floori(p.x+x),floori(p.y+y))):return false
	return true
func _bianzhou_approach() -> bool:
	var move: Dictionary=manifest.bianzhou
	var before: Array=move.get("old_compound_solid_polygons_px",[]);var after: Array=move.get("new_compound_solid_polygons_px",[])
	if not _need(not before.is_empty() and before.size()==after.size(),"BIANZHOU_EXPLICIT_COMPLETE_OLD_NEW_POLYGONS"):return false
	for index: int in before.size():
		if not _need(before[index].size()==after[index].size(),"BIANZHOU_POLYGON_VERTEX_COUNT"):return false
		for vertex: int in before[index].size():
			if not _need(_pair(after[index][vertex])==_pair(before[index][vertex])+Vector2(0,-640),"BIANZHOU_COMPLETE_BODY_EXACT_TRANSLATION"):return false
	var layout: Resource=load(String(manifest.layout_path)) as Resource
	var points: Array=move.get("approach_points_px",[])
	if not _need(points.size()>=3 and points.size()<=12,"EXPLICIT_BOUNDED_BIANZHOU_APPROACH"):return false
	var samples:=0
	for index: int in range(points.size()-1):
		var a:=_pair(points[index]);var b:=_pair(points[index+1]);var steps: int=maxi(1,ceili(a.distance_to(b)/24.0))
		if not _need(a.is_finite() and b.is_finite() and steps<=64,"BOUNDED_APPROACH_LEG"):return false
		for step: int in range(steps+1):
			var p: Vector2=a.lerp(b,float(step)/steps);samples+=1
			if not _need(_foot_white(p) and _body_clear(layout,p),"BIANZHOU_APPROACH_35x25_NAV_AND_SOURCE_BODY"):return false
	var plaza: Dictionary=move.get("plaza",{});var probes: Array=plaza.get("probe_feet_px",[])
	if not _need(probes.size()==5,"EXPLICIT_FIVE_BIANZHOU_PLAZA_PROBES"):return false
	for raw: Variant in probes:
		var p: Vector2=_pair(raw)
		if not _need(p.is_finite() and _foot_white(p) and _body_clear(layout,p),"BIANZHOU_DECLARED_PLAZA_SOURCE_BODY_AND_NAV"):return false
	return _need(_body_clear(layout,_pair(move.new_door_foot_px)),"NEW_BIANZHOU_GATE_SOURCE_BODY_CLEAR")
func _ports() -> bool:
	var expected: Dictionary=_expected_ports();var seen: Dictionary={}
	if not _need(manifest.get("moved_portals")==["bianzhou"] and manifest.get("bianzhou") is Dictionary,"ONLY_ROOT_APPROVED_BIANZHOU_MOVE_DECLARED"):return false
	if not _need(expected.size()==22 and manifest.portals.size()==22,"EXACT22_CURRENT_IDENTITIES"):return false
	for row: Dictionary in manifest.portals:
		var id: String=String(row.id)
		if not _need(expected.has(id) and not seen.has(id),"PRESERVED_UNIQUE_PORTAL:"+id):return false
		seen[id]=true;var original: Dictionary=expected[id]
		var old_foot: Vector2=_pair(original.world_foot);var new_foot: Vector2=_pair(row.world_foot)
		var foot_ok: bool=new_foot==old_foot
		if id=="bianzhou":
			var move: Dictionary=manifest.bianzhou
			foot_ok=move.get("portal_id")=="bianzhou" and _pair(move.get("old_door_foot_px"))==old_foot and _pair(move.get("compound_translation_px"))==Vector2(0,-640) and _pair(move.get("new_door_foot_px"))==new_foot and new_foot==old_foot+Vector2(0,-640)
		if not _need(row.target_scene==original.target_scene and foot_ok,"SAME22_ID_TARGET_21EXACT_FEET_ONLY_BIANZHOU_NORTH640:"+id):return false
		var foot:=Vector2(float(row.world_foot[0]),float(row.world_foot[1]));var clear:=true
		for y: int in range(-12,13):
			for x: int in range(-17,18):
				if not _pixel(Vector2i(floori(foot.x+x),floori(foot.y+y))):clear=false;break
			if not clear:break
		if not _need(clear,"FULL35x25_DOOR_NAV:"+id):return false
	return true
func _run() -> void:
	await process_frame
	output_dir=QA_ROOT+"nav_component02_actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(output_dir)
	var path: String=_arg("--manifest");var sha: String=_arg("--manifest-sha").to_lower()
	if not _need(suspended,"CHECKPOINTS_SUSPENDED") or not _need(path.begins_with("res://art/maps/world_coast_20261031h/") and sha.length()==64 and FileAccess.get_sha256(path)==sha,"EXPLICIT_NEW_ONLY_MANIFEST_SHA"):_finish({});return
	manifest=JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary
	if not _need(manifest.get("schema")=="WORLD_COAST_V16_CANDIDATE_2" and int(manifest.get("coordinate_space_version",-1))==16 and _same_numbers(manifest.world_size,[12288,8192]) and manifest.navigation_tiles.size()==64 and manifest.get("production_approved")==false,"EXACT_CANDIDATE16_NOT_FORMAL"):_finish({});return
	for index: int in range(64):
		var row: Dictionary=manifest.navigation_tiles[index]
		if not _need(_same_numbers(row.logical_rect,[(index%8)*1536,(index/8)*1024,1536,1024]) and FileAccess.get_sha256(String(row.path))==row.sha256,"EXACT_NAV_ROW_AND_SHA:"+str(index)):_finish({});return
	if not _ports() or not _bianzhou_approach():_finish({});return
	var size: int=ROI.size.x*ROI.size.y;var nav:=PackedByteArray();nav.resize(size)
	## Read only six overlapping tiles, not64 full images or a100M-pixel queue.
	for row: int in range(2,5):
		for col: int in range(6,8):
			var overlap: Rect2i=ROI.intersection(Rect2i(Vector2i(col,row)*TILE,TILE));var data: PackedByteArray=_data(row*8+col)
			if data.is_empty():_finish({});return
			for y: int in range(overlap.position.y,overlap.end.y):
				var dest: int=(y-ROI.position.y)*ROI.size.x+overlap.position.x-ROI.position.x
				var source: int=((y-row*TILE.y)*TILE.x+overlap.position.x-col*TILE.x)*4
				for x: int in overlap.size.x:nav[dest+x]=1 if _white(data,source+x*4) else 0
	images.clear();lru.clear()
	var island: Array=manifest.seeds.island;var start:=Vector2i(roundi(float(island[0])),roundi(float(island[1])))-ROI.position
	if not _need(ROI.has_point(start+ROI.position),"ISLAND_SEED_INSIDE_BOUNDED_ROI"):_finish({});return
	var start_index: int=start.y*ROI.size.x+start.x
	if not _need(nav[start_index]==1,"ISLAND_SEED_WALKABLE"):_finish({});return
	var visited:=PackedByteArray();visited.resize(size);var queue:=PackedInt32Array();queue.resize(size)
	queue[0]=start_index;visited[start_index]=1;var head:=0;var tail:=1;var boundary:=false
	var deltas: Array[int]=[-ROI.size.x-1,-ROI.size.x,-ROI.size.x+1,-1,1,ROI.size.x-1,ROI.size.x,ROI.size.x+1]
	while head<tail:
		var current: int=queue[head];head+=1;var x: int=current%ROI.size.x;var y: int=current/ROI.size.x
		if x==0 or y==0 or x==ROI.size.x-1 or y==ROI.size.y-1:boundary=true;break
		for delta: int in deltas:
			var next: int=current+delta
			if nav[next]==1 and visited[next]==0:visited[next]=1;queue[tail]=next;tail+=1
	_need(not boundary,"ISLAND_8_CONNECTED_COMPONENT_TOUCHES_NO_ROI_BORDER_NO_EDGE_WRAP")
	var seed_results: Dictionary={}
	for id: String in ["mainland","bailu"]:
		var pair: Array=manifest.seeds[id];var p:=Vector2i(roundi(float(pair[0])),roundi(float(pair[1])));var local: Vector2i=p-ROI.position
		var inside: bool=ROI.has_point(p);var reached: bool=inside and visited[local.y*ROI.size.x+local.x]==1
		_need(_pixel(p) and not reached,"MAINLAND_SEED_WHITE_AND_SEPARATE:"+id);seed_results[id]={"foot":p,"inside_roi":inside,"island_reached":reached}
	_finish({"roi":[10400,2100,1888,2160],"pixel_step":1,"connectivity":8,"visited_island_pixels":head,"queued_pixels":tail,"boundary_contact":boundary,"seed_results":seed_results,"max_queue_bytes":size*4,"nav_plus_visited_bytes":size*2,"image_cache_max_tiles":6,"proof":"Complete8-neighbor island component is trapped strictly insideROI; cannot reach mainland or worldedge. NAV-alone is stronger than adding blocking solids.","not_a_global_mainland_connectivity_or_ART_claim":true})
func _finish(detail: Dictionary) -> void:
	var file:=FileAccess.open(output_dir+"/result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"detail":detail,"scene_instances":0,"input_events":0,"real_save_API_calls":0,"production_writes":0},"\t"));file.close()
	quit(0 if errors.is_empty() else 1)
