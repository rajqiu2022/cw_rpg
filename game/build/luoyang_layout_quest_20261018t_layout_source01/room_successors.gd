extends RefCounted
## Data/resource successor compiler. Historical eleven-room registry and proof
## stay immutable. Only new returns/labels/bench and independent hall are new.
const T=preload("res://build/luoyang_layout_quest_20261018t_layout_source01/layout_transform.gd")
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const G=preload("res://build/luoyang_layout_quest_20261018t_layout_source01/g_geometry_original.gd")
const ROOT="res://data/maps/luoyang_layout_rooms_20261018t/"
const PRIOR="res://data/maps/luoyang_assembled_interiors_20261016g/registry_spacing_dependency_v3.json"
const PRIOR_SHA="959bc6f5408261586a6165bf731347959e6287bea9afa8bfb40f6e4035302ad5"
const META="source_feet_assembled_interiors_20261016g"
const ROOM_META="luoyang_room_successor_20261018t"
const SIZE=Vector2(1536,1024)
static func _json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
static func _write(path: String,value: Dictionary) -> bool:
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(value,"\t",true,true)); file.close(); return true
static func _native(path: String,value: Dictionary) -> bool:
	if not B._plain(value) or FileAccess.file_exists(path): return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_buffer(var_to_bytes(value)); file.close()
	return B.equal(value,bytes_to_var(FileAccess.get_file_as_bytes(path)))
static func _bases(items: Array) -> Array:
	var rows: Array=[]
	for item: Dictionary in items:
		for raw: Variant in item.source_ground_solid_polygons_px:
			var points: Array=[]
			for p: Variant in raw: points.append(T.xy(T.v(item.placement_foot_px)+(T.v(p)-T.v(item.source_ground_anchor_px))*float(item.render_scale)))
			rows.append({"id":item.id,"kind":"independent_furniture","blocking":true,"ground_polygon_px":points})
	return rows
static func _entry(item: Dictionary) -> Dictionary:
	var ratio: float=float(item.render_scale)
	return {"id":item.id,"texture":item.texture,"pos":(T.v(item.placement_foot_px)-T.v(item.source_ground_anchor_px)*ratio)/SIZE,"render_size_px":T.v(item.source_size_px)*ratio,"centered":false,"sort_by_feet":true,"depth_sort_foot_y":float(item.depth_foot_y)/1024.0,"assembled_furniture":true}
static func _layout_geometry(layout: WalkableMapLayout,author: Dictionary) -> void:
	var objects: Array[Dictionary]=[]; var blockers: Array[Dictionary]=[]
	for item: Dictionary in author.furniture: objects.append(_entry(item))
	for base: Dictionary in author.geometry.furniture_bases:
		var poly:=PackedVector2Array()
		for point: Variant in base.ground_polygon_px: poly.append(T.v(point)/SIZE)
		blockers.append({"id":base.id,"ground_polygon":poly,"walkability_margin":0.0})
	# Fixed architecture native bases remain separate from point-only visual
	# forbidden regions. They are not expanded twice or silently discarded.
	for fixed: Dictionary in author.geometry.get("fixed_architecture",[]):
		var poly:=PackedVector2Array()
		for point: Variant in fixed.ground_base_polygon_px: poly.append(T.v(point)/SIZE)
		blockers.append({"id":fixed.id,"ground_polygon":poly,"walkability_margin":0.0})
	layout.visual_objects=objects; layout.blockers=blockers
static func _bench(author: Dictionary,proposal: Dictionary) -> bool:
	var count: int=0
	for index: int in author.furniture.size():
		if author.furniture[index].id!=proposal.replace_id: continue
		var next: Dictionary=author.furniture[index].duplicate(true)
		for key: String in ["asset_id","texture","source_sha256","source_size_px","source_ground_anchor_px","source_ground_solid_polygons_px","placement_foot_px","render_scale","depth_foot_y","height_behavior"]: next[key]=proposal[key]
		next.id=proposal.proposed_id; next.source_sha256=String(next.source_sha256).to_lower()
		author.furniture[index]=next; count+=1
	if count!=1: return false
	var replacement_base: Dictionary=T.find(_bases(author.furniture),String(proposal.proposed_id))
	if replacement_base.is_empty(): return false
	for index: int in author.geometry.furniture_bases.size():
		if author.geometry.furniture_bases[index].id==proposal.replace_id: author.geometry.furniture_bases[index]=replacement_base
	for route: Dictionary in author.geometry.required_routes:
		if String(route.id)=="approach_"+String(proposal.replace_id): route.id="approach_"+String(proposal.proposed_id)
	author["furniture_successor"]={"proposal_path":"res://build/luoyang_layout_quest_20261018t_art_source01/placement_proposal.json","old_id":proposal.replace_id,"new_id":proposal.proposed_id,"original_geometry_proof_does_not_cover_this_change":true}
	return true
static func _hall(template: Dictionary,design: Dictionary) -> Dictionary:
	var a: Dictionary=template.duplicate(true)
	a.type_id="official_hall"; a.display_name=design.display_name
	a.room={"scene_id":design.scene_id,"city_id":design.city_id,"building_id":design.building_id,"return_foot_px":design.return_foot_px.duplicate()}
	# Actual working hall: one central document desk, one back screen and two
	# waiting benches. Not the mansion's furniture arrangement with a new label.
	var desk: Dictionary=T.find(template.furniture,"mansion_reception_writing_desk_4").duplicate(true)
	var screen: Dictionary=T.find(template.furniture,"mansion_reception_folding_screen_6").duplicate(true)
	var bench_template: Dictionary=_json("res://data/maps/luoyang_assembled_interiors_20261016g/herbal_shop_author.json")
	var bench: Dictionary=T.find(bench_template.get("furniture",[]),"herbal_shop_long_bench_5").duplicate(true)
	if desk.is_empty() or screen.is_empty() or bench.is_empty(): return {}
	desk.id="official_hall_document_desk"; desk.placement_foot_px=[768,500]; desk.depth_foot_y=500; desk.render_scale=.18
	screen.id="official_hall_rear_screen"; screen.placement_foot_px=[768,425]; screen.depth_foot_y=425; screen.render_scale=.20
	var left: Dictionary=bench.duplicate(true); left.id="official_hall_west_waiting_bench"; left.placement_foot_px=[350,740]; left.depth_foot_y=740
	var right: Dictionary=bench.duplicate(true); right.id="official_hall_east_waiting_bench"; right.placement_foot_px=[1180,740]; right.depth_foot_y=740
	a.furniture=[desk,screen,left,right]
	a.geometry.furniture_bases=_bases(a.furniture)
	a.geometry.spawn_foot_px=[768,840]
	a.geometry.required_routes=[{"id":"spawn_to_exit","points_px":[[768,840],[768,914]]},{"id":"central_document_desk","points_px":[[768,840],[768,740],[768,540]]},{"id":"west_waiting","points_px":[[768,840],[768,770],[350,770]]},{"id":"east_waiting","points_px":[[768,840],[768,770],[1180,770]]}]
	a.geometry.validation_stations=[{"id":"desk_front","foot_px":[768,540]},{"id":"west_waiting","foot_px":[350,770]},{"id":"east_waiting","foot_px":[1180,770]}]
	a.geometry.negative_points=[]
	a.npc_policy={"new_npcs":0,"new_story_or_rewards":false}
	a["independent_twelfth_type"]=true
	return a
static func _audit(author: Dictionary) -> Dictionary:
	var geometry: Dictionary=G.compile_geometry(author.geometry,Vector2(1920,1280))
	if geometry.is_empty(): return {"passed":false,"error":"GEOMETRY_COMPILE"}
	var samples: int=0
	for route: Dictionary in author.geometry.required_routes:
		for i: int in range(route.points_px.size()-1):
			var first: Vector2=T.v(route.points_px[i])*1.25; var last: Vector2=T.v(route.points_px[i+1])*1.25
			var count: int=maxi(1,ceili(first.distance_to(last)/4.0))
			for step: int in range(count+1):
				var foot: Vector2=first.lerp(last,float(step)/count)
				if not G.safe_foot(geometry,foot,Vector2(1920,1280),true): return {"passed":false,"route":route.id,"world_foot_px":T.xy(foot),"sample":step}
				samples+=1
	return {"passed":true,"samples":samples,"routes":author.geometry.required_routes.size(),"native_body_px":[34,24],"cover":1.25,"full875":true,"point_only_column_zones":true,"physics_not_run":true}
static func publish(design: Dictionary,migrate: Callable,track: Callable) -> Dictionary:
	if not track.call(PRIOR,PRIOR_SHA): return {"error":"Immutable eleven registry changed"}
	var prior: Dictionary=_json(PRIOR); var rows: Dictionary={}; var proposals: Dictionary={}
	for move: Dictionary in design.room_moves: proposals[String(move.scene_id)]=move
	var proof: Dictionary={"prior_path":PRIOR,"prior_sha256":PRIOR_SHA,"prior_geometry_cpu":prior.geometry_cpu_proof.duplicate(true),"prior_exterior_cpu":prior.exterior_cpu_proof.duplicate(true),"rows":{}}
	var expanded: Dictionary=prior.rooms.duplicate(true)
	var hall_id: String=String(design.official_hall.scene_id)
	expanded[hall_id]=prior.rooms["luoyang_functional_mansion_candidate_20261016"].duplicate(true)
	for id: String in expanded:
		var old: Dictionary=expanded[id]
		for key: String in ["author_path","scene_path","layout_path"]:
			if not track.call(old[key],old.get("source_sha256",{}).get(old[key],"")): return {"error":"Room parent source changed "+id+":"+key}
		var a: Dictionary=_json(old.author_path)
		var scene:=ResourceLoader.load(old.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		var layout:=ResourceLoader.load(old.layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
		if a.is_empty() or scene==null or layout==null: return {"error":"Room parent data missing "+id}
		if old.get("reuse_existing_accepted")==true:
			a["type_id"]="smithy"; a["display_name"]="铁匠铺"
		if id==hall_id:
			a=_hall(a,design.official_hall); scene.npcs=[]; scene.hotspots=[]; scene.trigger_zones=[]; scene.on_enter_dialog=null; scene.scene_id=StringName(id)
			if a.is_empty(): return {"error":"Hall actual furniture templates absent"}
		elif proposals.has(id):
			var move: Dictionary=proposals[id]
			if T.v(a.room.return_foot_px)!=T.v(move.old_return_foot_px): return {"error":"Room exact prior return differs "+id}
			a.room.return_foot_px=move.return_foot_px.duplicate(); a.room.building_id=move.building_id
		for label: Dictionary in design.label_revisions:
			if a.type_id==label.type_id:
				if a.display_name!=label.old: return {"error":"Label prior differs "+id}
				a.display_name=label.new
		if a.type_id=="herbal_shop":
			if not track.call(design.bench_proposal.path,design.bench_proposal.sha256) or not _bench(a,_json(design.bench_proposal.path)): return {"error":"Bench explicit successor refused"}
		var dir: String=ROOT+id+"/"
		if DirAccess.dir_exists_absolute(dir) or DirAccess.make_dir_recursive_absolute(dir)!=OK: return {"error":"Room fresh output required "+id}
		a["successor_basis"]="IMMUTABLE_ELEVEN_PARENT_PLUS_T_EXPLICIT_RETURN_LABEL_BENCH_OR_TWELFTH_HALL"
		a["prior_author_path"]=old.author_path; a["prior_author_sha256"]=FileAccess.get_sha256(old.author_path)
		if not _write(dir+"author.json",a): return {"error":"Room author write "+id}
		var author_sha: String=FileAccess.get_sha256(dir+"author.json")
		scene.display_name="洛阳 · "+String(a.display_name); scene.map_layout=layout
		if id==hall_id or a.type_id=="herbal_shop": _layout_geometry(layout,a)
		for portal: Dictionary in layout.portals:
			if String(portal.get("target_scene",""))==String(a.room.city_id): portal.target_pos=T.uv(a.room.return_foot_px)
		scene.set_meta(ROOM_META,author_sha); layout.set_meta(ROOM_META,author_sha)
		if id==hall_id:
			layout.portals[0].id="return_official_hall"; scene.player_spawn=T.v(a.geometry.spawn_foot_px)/SIZE
		var audit: Dictionary={"passed":true,"basis":"UNCHANGED_INTERNAL_NATIVE_GEOMETRY_EXPLICIT_RETURN_ONLY"}
		if id==hall_id or a.type_id=="herbal_shop": audit=_audit(a)
		if not audit.get("passed",false): return {"error":"Room changed geometry refused "+id,"audit":audit}
		var snapshot: Dictionary={"scene":B.storage(scene),"layout":B.storage(layout)}
		if ResourceSaver.save(layout,dir+"layout.res")!=OK: return {"error":"Room layout save "+id}
		scene.map_layout=ResourceLoader.load(dir+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
		if ResourceSaver.save(scene,dir+"scene.res")!=OK: return {"error":"Room Scene save "+id}
		var loaded:=ResourceLoader.load(dir+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		if loaded==null or not B.equal(snapshot.scene,B.storage(loaded)) or not B.equal(snapshot.layout,B.storage(loaded.map_layout)): return {"error":"Room all-storage native readback differs "+id}
		var parent_pins: Dictionary=old.get("source_sha256",a.get("source_sha256",{}))
		var pins: Dictionary=migrate.call(parent_pins)
		if pins.is_empty(): return {"error":"Room exact per-row current-source succession "+id}
		var used: Dictionary={String(a.shell.texture):true}; var texture_proofs: Array=[]
		for item: Dictionary in a.furniture: used[String(item.texture)]=true
		for texture: String in used:
			var found: Dictionary={}
			for historical_row: Dictionary in prior.rooms.values():
				for texture_proof: Dictionary in historical_row.get("texture_proofs",[]):
					if texture_proof.get("texture")==texture: found=texture_proof
			if a.type_id!="smithy":
				if found.is_empty() or found.get("full_rgba_exact")!=true or found.get("params23")!=true: return {"error":"Existing actual full-RGBA texture proof missing "+texture}
				for key: String in ["texture","import_path","compiled_path"]:
					var path: String=String(found[key]); var pin: String=String(prior.source_sha256.get(path,""))
					if pin.is_empty() or not track.call(path,pin): return {"error":"Existing texture proof exact source missing "+path}
					pins[path]=pin
				texture_proofs.append(found.duplicate(true))
		if not _native(dir+"storage.bin",snapshot): return {"error":"Room safe native storage packet "+id}
		for suffix: String in ["author.json","layout.res","scene.res"]: pins[dir+suffix]=FileAccess.get_sha256(dir+suffix)
		pins[dir+"storage.bin"]=FileAccess.get_sha256(dir+"storage.bin")
		rows[id]={"scene_id":id,"type_id":a.type_id,"author_path":dir+"author.json","author_sha256":author_sha,"scene_path":dir+"scene.res","layout_path":dir+"layout.res","storage_path":dir+"storage.bin","storage_sha256":pins[dir+"storage.bin"],"source_sha256":pins,"texture_proofs":texture_proofs,"smith_exact_parent_reuse":a.type_id=="smithy","runtime_ready":true,"door_enabled":true,"candidate_admission_only":true,"parent_row":old.duplicate(true),"geometry":audit,"new_hall":id==hall_id}
		proof.rows[id]=audit
	return {"status":"CPU_PUBLISHED_ROOM_SUCCESSORS_CANDIDATE","rooms":rows,"history":proof,"coordinate_contract":META,"formal_enabled":false}
