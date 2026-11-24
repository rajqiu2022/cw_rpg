extends RefCounted
## Remove one duplicate, doorless building. No old record, artwork or proof edits.
## The original Harbour pipeline is completed before this child is consumed.
const SELF="res://scripts/city/luoyang_building_spacing_20261017p.gd"
const FLAG="--luoyang-building-spacing-20261017p"
const FORMAL_ENABLED=false
const ID=&"ch4_s2_canal_docks"
const META="luoyang_building_spacing_author_20261017p"
const AUTHOR_PATH="res://data/maps/luoyang_building_spacing_20261017p/author.json"
const AUTHOR_SHA="a6eccd68c78947af74de4fed5e1d844f464d316e21d9524688cf5439f92571ad"
const BIND_PATH="res://data/maps/luoyang_building_spacing_20261017p/binding_cpu_import_candidate_20261018q.json"
const BIND_SHA="a52e4b51474c4b5232448004e7de85aaad6a8918140127f1ad3453764d22c06c"
const REMOVED="harbour_main_warehouse"
const SIZE=Vector2(3072,2048)
static func _c() -> Variant: return load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
static func _g() -> Variant: return load("res://scripts/city/luoyang_harbour_life_geometry_retry3_20261016.gd")
static func _serial() -> Variant: return load("res://scripts/city/luoyang_city_revision_candidate_retry2_20261015.gd")
static func enabled() -> bool: return FORMAL_ENABLED or FLAG in OS.get_cmdline_user_args()
static func requested(id: StringName) -> bool: return id==ID and enabled()
static func _wire(value: Variant) -> Variant: return JSON.parse_string(JSON.stringify(value,"\t",true,true))
static func equal(left: Variant,right: Variant) -> bool: return _c()._equal_value(_wire(left),_wire(right))
static func _v(value: Variant) -> Vector2: return _c()._vec(value)
static func _find(rows: Array,id: String) -> Dictionary:
	var found: Dictionary={}
	for row: Dictionary in rows:
		if String(row.get("id",""))!=id: continue
		if not found.is_empty(): return {}
		found=row
	return found
static func author() -> Dictionary:
	if AUTHOR_SHA.length()!=64 or FileAccess.get_sha256(AUTHOR_PATH)!=AUTHOR_SHA: return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(AUTHOR_PATH))
	if not value is Dictionary or value.get("change_id")!="luoyang-building-spacing-20261017p" or value.get("scene_id")!=String(ID) or value.get("remove_id")!=REMOVED: return {}
	return value
static func sources_match(paths: Dictionary,cancel: Callable=Callable()) -> bool:
	if paths.is_empty(): return false
	for path: String in paths:
		if cancel.is_valid() and cancel.call(): return false
		if not path.begins_with("res://") or ".." in path or not paths[path] is String or paths[path].length()!=64 or FileAccess.get_sha256(path)!=paths[path]: return false
	return true
static func parent_manifest() -> Dictionary:
	var data: Dictionary=author()
	if data.is_empty() or not sources_match(data.source_sha256): return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(data.parent_manifest_path))
	if not value is Dictionary or value.get("scene_id")!=String(ID) or value.get("status")!="HARBOUR_CPU_CANDIDATE_NOT_IMPORTED_NOT_RUNTIME_NOT_FORMAL": return {}
	return value
static func source_paths() -> Dictionary:
	# Inactive candidate does not demand a PENDING binding from ordinary Gate.
	if not enabled(): return {}
	var result: Dictionary={SELF:true,AUTHOR_PATH:true}
	result[BIND_PATH]=true
	var data: Dictionary=author()
	if not data.is_empty():
		for path: String in data.source_sha256: result[path]=true
	var config: Dictionary=binding()
	if not config.is_empty():
		for path: String in config.source_sha256: result[path]=true
	return result
static func binding() -> Dictionary:
	if BIND_SHA.length()!=64 or FileAccess.get_sha256(BIND_PATH)!=BIND_SHA: return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(BIND_PATH))
	if not value is Dictionary or value.get("status")!="SPACING_CPU_AND_IMPORT_READY_CANDIDATE" or value.get("author_sha256")!=AUTHOR_SHA or value.get("scene_id")!=String(ID) or value.get("source_sha256",{}).is_empty(): return {}
	var proof: Dictionary=value.get("walk_texture_proof",{})
	if proof.get("texture")!=value.get("walk_path") or proof.get("import_path")!=String(value.get("walk_path",""))+".import" or proof.get("full_rgba_exact")!=true or proof.get("params23")!=true or _v(proof.get("size_px"))!=SIZE: return {}
	for pair: Array in [[value.get("manifest_path"),value.get("manifest_sha256")],[proof.get("texture"),proof.get("source_sha256")],[proof.get("import_path"),proof.get("import_sha256")],[proof.get("compiled_path"),proof.get("compiled_sha256")],[value.get("import_report_path"),value.get("import_report_sha256")]]:
		if not pair[0] is String or not pair[1] is String or pair[1].length()!=64 or value.source_sha256.get(pair[0])!=pair[1]: return {}
	return value
static func compose(parent: Dictionary,walk_path: String) -> Dictionary:
	var data: Dictionary=author(); var published: Dictionary=parent_manifest()
	if data.is_empty() or published.is_empty() or not equal(parent,published.record) or walk_path.is_empty(): return {}
	var old: Dictionary=_find(parent.get("objects",[]),REMOVED)
	if old.is_empty() or parent.objects.size()!=int(data.expected_parent_count) or _v(old.get("world_foot_px"))!=_v(data.expected_removed_foot_px) or old.get("solid_polygons_px",[]).size()!=1 or old.solid_polygons_px[0].size()!=6: return {}
	var result: Dictionary=parent.duplicate(true)
	var index: int=result.objects.find(_find(result.objects,REMOVED))
	if index<0: return {}
	result.objects.remove_at(index)
	if result.objects.size()!=int(data.expected_child_count) or not _find(result.objects,REMOVED).is_empty(): return {}
	result.walk_path=walk_path
	result["spacing_author_sha256"]=AUTHOR_SHA
	result["spacing_removed_object_id"]=REMOVED
	return result
static func materialize(parent: SceneScript,record: Dictionary,walk_path: String) -> SceneScript:
	if parent==null or parent.scene_id!=ID or parent.map_layout==null or record.get("spacing_author_sha256")!=AUTHOR_SHA or record.get("walk_path")!=walk_path: return null
	var original: Array=parent.map_layout.visual_objects
	var old: Dictionary=_find(original,REMOVED)
	if original.size()!=28 or old.is_empty() or _v(old.get("world_foot_px"))!=Vector2(1450,650) or old.get("city_v3_solid_polygons_px",[]).size()!=1 or old.city_v3_solid_polygons_px[0].size()!=6: return null
	var result:=parent.duplicate(true) as SceneScript
	result.map_layout=parent.map_layout.duplicate(true) as WalkableMapLayout
	var entries: Array[Dictionary]=[]
	for entry: Dictionary in original:
		if String(entry.get("id",""))!=REMOVED: entries.append(entry.duplicate(true))
	if entries.size()!=27: return null
	result.map_layout.visual_objects=entries
	result.map_layout.walkable_mask_path=walk_path
	result.set_meta(META,AUTHOR_SHA)
	# Complete reversible storage check: no broad whitelist or dropped fields.
	var restored:=result.duplicate(true) as SceneScript
	restored.map_layout=result.map_layout.duplicate(true) as WalkableMapLayout
	var restore_entries: Array[Dictionary]=[]
	for entry: Dictionary in original: restore_entries.append(entry.duplicate(true))
	restored.map_layout.visual_objects=restore_entries
	restored.map_layout.walkable_mask_path=parent.map_layout.walkable_mask_path
	restored.remove_meta(META)
	if not _serial().serialized_equal(restored,parent): return null
	return result
static func mask_monotonic(old_mask: Image,new_mask: Image,cancel: Callable=Callable()) -> Dictionary:
	if old_mask==null or new_mask==null or old_mask.get_size()!=Vector2i(SIZE) or new_mask.get_size()!=Vector2i(SIZE): return {}
	old_mask.convert(Image.FORMAT_RGBA8); new_mask.convert(Image.FORMAT_RGBA8)
	var old_bytes: PackedByteArray=old_mask.get_data(); var new_bytes: PackedByteArray=new_mask.get_data()
	var restored: int=0
	for offset: int in range(0,old_bytes.size(),4):
		if offset%1048576==0 and cancel.is_valid() and cancel.call(): return {}
		if old_bytes[offset]==new_bytes[offset] and old_bytes[offset+1]==new_bytes[offset+1] and old_bytes[offset+2]==new_bytes[offset+2] and old_bytes[offset+3]==new_bytes[offset+3]: continue
		if old_bytes[offset]!=0 or old_bytes[offset+1]!=0 or old_bytes[offset+2]!=0 or old_bytes[offset+3]!=255 or new_bytes[offset]!=255 or new_bytes[offset+1]!=255 or new_bytes[offset+2]!=255 or new_bytes[offset+3]!=255: return {}
		restored+=1
	return {"passed":restored>0,"restored_pixels":restored,"no_previously_walkable_pixel_blocked":true}
static func geometry(record: Dictionary,mask: Image,old_record: Dictionary,old_mask: Image,cancel: Callable=Callable()) -> Dictionary:
	var audit: Dictionary=_g().audit(record,mask,cancel)
	if audit.get("passed")!=true: return {"passed":false,"error":"ORIGINAL_ROUTES_OR_CROWD","audit":audit}
	var c: Variant=_c(); var solids: Array[PackedVector2Array]=c.object_solids(record.objects)
	if not c._all_gameplay_safe_cpu(record,mask,solids,cancel): return {"passed":false,"error":"ORIGINAL_GAMEPLAY"}
	var mono: Dictionary=mask_monotonic(old_mask,mask,cancel)
	if mono.get("passed")!=true: return {"passed":false,"error":"MASK_NOT_REMOVE_ONLY"}
	var data: Dictionary=author(); var count: int=0
	var old_solids: Array[PackedVector2Array]=c.object_solids(old_record.objects)
	for raw: Variant in data.restored_stations_px:
		var foot: Vector2=_v(raw)
		if c._safe_body_cpu(foot,old_mask,old_solids) or not c._safe_body_cpu(foot,mask,solids) or not _g().seventeen(foot,mask): return {"passed":false,"error":"REMOVED_NATIVE_BASE_NOT_RESTORED","foot_px":raw}
	for route: Dictionary in data.new_routes:
		for segment: int in range(route.points_px.size()-1):
			var from: Vector2=_v(route.points_px[segment]); var to: Vector2=_v(route.points_px[segment+1]); var steps: int=maxi(1,ceili(from.distance_to(to)/4.0))
			for i: int in range(steps+1):
				if cancel.is_valid() and cancel.call(): return {"passed":false,"error":"CANCELLED"}
				var foot: Vector2=from.lerp(to,float(i)/steps)
				if not c._safe_body_cpu(foot,mask,solids) or not _g().seventeen(foot,mask): return {"passed":false,"error":"RESTORED_ROUTE","foot_px":[foot.x,foot.y]}
				count+=1
	return {"passed":true,"original_audit":audit,"monotonic":mono,"new_route_samples":count,"full87517":true,"max_step_px":4}
static func bound(scene: SceneScript) -> bool:
	var config: Dictionary=binding()
	return requested(ID) and not config.is_empty() and scene!=null and scene.scene_id==ID and scene.map_layout!=null and scene.get_meta(META,"")==AUTHOR_SHA and scene.map_layout.walkable_mask_path==config.get("walk_path") and _find(scene.map_layout.visual_objects,REMOVED).is_empty() and scene.map_layout.visual_objects.size()==27
static func combined_geometry(record: Dictionary,mask: Image,cancel: Callable=Callable()) -> Dictionary:
	# Reuse the unchanged District projection/math with this child's actual base.
	# Do not feed its frozen original-parent equality a different record silently.
	var district: Variant=load("res://scripts/city/luoyang_district_life_20261016f.gd")
	var dg: Variant=load("res://scripts/city/luoyang_district_life_geometry_20261016f.gd")
	var config: Dictionary=district.binding(); var data: Dictionary=district.author(config)
	if data.is_empty() or not district.cpu_proof_valid(config,data): return {"passed":false,"error":"DISTRICT_SOURCE_OR_PROOF"}
	var projection: Dictionary=dg.project(data,ID)
	if projection.is_empty(): return {"passed":false,"error":"DISTRICT_PROJECT"}
	var solids: Array[PackedVector2Array]=_c().object_solids(record.objects)
	var extra: Array[PackedVector2Array]=dg.delta_solids(projection)
	solids.append_array(extra)
	var paths: Array=record.routes.duplicate(true)
	paths.append_array(author().new_routes)
	paths.append_array(projection.spec.get("required_routes",[]))
	paths.append_array(projection.spec.get("protected_routes",[]))
	for slot: Dictionary in record.gameplay_slots.portals:
		paths.append({"id":"portal_"+String(slot.source_id),"points_px":slot.passage_path_px})
	var crowd: Variant=load("res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd")
	for lane: Dictionary in crowd.lanes(ID):
		var row: Dictionary=lane.duplicate(true); row["new_npc"]=true; paths.append(row)
	var samples: int=0
	for route: Dictionary in paths:
		for segment: int in range(route.points_px.size()-1):
			var from: Vector2=_v(route.points_px[segment]); var to: Vector2=_v(route.points_px[segment+1]); var steps: int=maxi(1,ceili(from.distance_to(to)/4.0))
			if route.get("new_npc",false) and not dg.safe_foot(solids,(from+to)*.5,(to-from).abs()*.5+Vector2(17,15)): return {"passed":false,"error":"COMBINED_NPC_SWEEP","route":route.id}
			for i: int in range(steps+1):
				if cancel.is_valid() and cancel.call(): return {"passed":false,"error":"CANCELLED"}
				var foot: Vector2=from.lerp(to,float(i)/steps)
				if not _c()._safe_body_cpu(foot,mask,solids) or not _g().seventeen(foot,mask) or (route.get("new_npc",false) and not dg._npc_clear(foot,mask,solids)): return {"passed":false,"error":"COMBINED_FULL_BODY","route":route.id,"foot_px":[foot.x,foot.y]}
				samples+=1
	for raw: Variant in projection.spec.get("protected_feet",[])+author().restored_stations_px+[[754,610]]:
		if not _c()._safe_body_cpu(_v(raw),mask,solids) or not _g().seventeen(_v(raw),mask): return {"passed":false,"error":"COMBINED_PROTECTED_OR_RESTORED","foot_px":raw}
	return {"passed":true,"samples":samples,"district_polygons":extra.size(),"full87517":true,"npc_continuous_body_px":[34,30],"max_step_px":4,"all_original_routes_and_six_moving_lanes":true}
static func prepare_packet(old_record: Dictionary,old_mask: Image,cancel: Callable=Callable()) -> Dictionary:
	var config: Dictionary=binding()
	if config.is_empty() or not sources_match(config.source_sha256,cancel): return {}
	var manifest: Variant=JSON.parse_string(FileAccess.get_file_as_string(config.manifest_path))
	if not manifest is Dictionary or manifest.get("status")!="SPACING_REMOVE_ONE_CPU_NOT_IMPORTED_NOT_RUNTIME" or manifest.get("author_sha256")!=AUTHOR_SHA or manifest.get("geometry",{}).get("passed")!=true or manifest.get("walk_path")!=config.walk_path or manifest.get("walk_sha256")!=config.walk_texture_proof.source_sha256 or manifest.get("walk_rgba_sha256")!=config.walk_texture_proof.get("rgba_sha256"): return {}
	if not equal(old_record,manifest.get("parent_record")): return {}
	var record: Dictionary=compose(old_record,config.walk_path)
	if record.is_empty() or not equal(record,manifest.record): return {}
	var raw: Image=Image.load_from_file(String(old_record.raw_walk_path))
	if raw==null: return {}
	var raster: Image=_c()._raster_walk_cpu(raw,record.objects,cancel)
	var saved: Image=Image.load_from_file(config.walk_path)
	if raster==null or saved==null: return {}
	raster.convert(Image.FORMAT_RGBA8); saved.convert(Image.FORMAT_RGBA8)
	if raster.get_data()!=saved.get_data(): return {}
	var audit: Dictionary=geometry(record,raster,old_record,old_mask,cancel)
	if audit.get("passed")!=true: return {}
	if manifest.get("combined_geometry",{}).get("passed")!=true: return {}
	return {"record":record,"walk_bytes":raster.get_data(),"bytes":raster.get_data(),"size":raster.get_size(),"path":config.walk_path,"solids":_c().object_solids(record.objects),"geometry":audit}
static func install_packet(scene: SceneScript,packet: Dictionary,spacing: Dictionary) -> SceneScript:
	if spacing.is_empty(): return null
	var texture:=ResourceLoader.load(String(spacing.path)) as Texture2D
	var image: Image=texture.get_image() if texture!=null else null
	if image==null: return null
	image.convert(Image.FORMAT_RGBA8)
	if image.get_size()!=spacing.size or image.get_data()!=spacing.bytes: return null
	var result: SceneScript=materialize(scene,spacing.record,String(spacing.path))
	if result==null: return null
	# Keep the existing runtime receipts precise; only the child record/nav replace.
	var record: Dictionary=spacing.record.duplicate(true)
	record["harbour_runtime_binding_sha"]=packet.record.harbour_runtime_binding_sha
	record["harbour_parent_task_semantics_preserved"]=true
	record["spacing_runtime_binding_sha"]=BIND_SHA
	for key: String in ["record","walk_bytes","bytes","size","path","solids"]: packet[key]=record if key=="record" else spacing[key]
	return result
static func restore_parent_record(current: Dictionary,expected: Dictionary,scene: SceneScript) -> Dictionary:
	if not bound(scene): return {}
	var config: Dictionary=binding(); var actual: Dictionary=current.duplicate(true)
	if actual.get("spacing_runtime_binding_sha")!=BIND_SHA: return {}
	actual.erase("spacing_runtime_binding_sha")
	var wanted: Dictionary=compose(expected,String(config.walk_path))
	return expected.duplicate(true) if not wanted.is_empty() and equal(actual,wanted) else {}
