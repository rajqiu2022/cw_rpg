extends RefCounted
## One independently bound temple, not a C four-city scene or cached C proof.
## Assets/geometry/import receipts remain fail-closed until ROOT freezes binding.
const FLAG="--luoyang-temple-assembly-20261016"
const FORMAL_ENABLED=true
const ID=&"ch4_s4_ancient_temple"
const META="temple_assembled_ground_feet_20261016"
const SELF="res://scripts/city/luoyang_temple_assembly_20261016.gd"
const BIND_PATH="res://build/luoyang_layout_quest_20261018t_layout_source01/runtime_v2/temple_successor_binding_v2.json"
const BIND_SHA="83578bbe72adf19ea1b7139952d3b3675ae27087fe0bb433db0439c1e60d93ae"
const SCENE_PATH="res://data/scenes/luoyang_temple_layout_quest_20261018t/temple.tres"
const LAYOUT_PATH="res://data/maps/luoyang_temple_layout_quest_20261018t/layout.tres"
const ORIGINAL="res://data/scenes/ch4_s4_ancient_temple.tres"
const ORIGINAL_LAYOUT="res://data/maps/ch4_s4_ancient_temple_layout_v1.tres"
const ORIGINAL_SHA="1570a4d9cfcb0508a12bfa639052db8aec11ab25634a3f5c606d19cbe2223730"
const ORIGINAL_LAYOUT_SHA="c639287b0afff4c5e2e8ad667438a5b023102a1215549610189540c8e96a26f0"
const SOURCE_SIZE=Vector2(1536,1024)
const GEOMETRY=preload("res://scripts/city/luoyang_functional_interiors_20261016.gd")
var data: Dictionary={}
var _scene: SceneScript
var _source_first: Dictionary={}
var _source_final: Dictionary={}
var _scene_storage: Dictionary={}
var _layout_storage: Dictionary={}
var _textures: Dictionary={}
var _job: RefCounted
var _task: int=-1
var _released: bool=false
var _finalized: bool=false
var error: String=""
static func _city() -> Variant: return load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
static func enabled() -> bool: return FORMAL_ENABLED or FLAG in OS.get_cmdline_user_args()
static func requested(id: StringName) -> bool: return enabled() and id==ID
static func _v(a: Variant) -> Vector2: return Vector2(a[0],a[1]) if a is Array and a.size()==2 else Vector2(INF,INF)
static func binding() -> Dictionary:
	if BIND_SHA.length()!=64 or FileAccess.get_sha256(BIND_PATH)!=BIND_SHA: return {}
	var successor: Variant=JSON.parse_string(FileAccess.get_file_as_string(BIND_PATH))
	if not successor is Dictionary or successor.get("status")!="SOURCE_READY_NOT_DEPLOYED" or successor.get("assets_ready")!=true or successor.get("source_delta",{}).is_empty(): return {}
	var parent_path: String=String(successor.get("parent_binding_path",""))
	if parent_path.is_empty() or FileAccess.get_sha256(parent_path)!=successor.get("parent_binding_sha256",""): return {}
	var parent: Variant=JSON.parse_string(FileAccess.get_file_as_string(parent_path))
	if not parent is Dictionary or parent.get("status")!="READY_IMPORTED_TEMPLE_CANDIDATE" or parent.get("assets_ready")!=true or parent.get("source_sha256",{}).is_empty(): return {}
	var merged: Dictionary=parent.duplicate(true)
	var sources: Dictionary=merged.source_sha256.duplicate(true)
	for path: String in successor.source_delta:
		if not path.begins_with("res://") or ".." in path or String(successor.source_delta[path]).length()!=64: return {}
		sources[path]=successor.source_delta[path]
	merged.source_sha256=sources
	merged["successor_binding_path"]=BIND_PATH
	merged["successor_binding_sha256"]=BIND_SHA
	merged["parent_binding_path"]=parent_path
	merged["parent_binding_sha256"]=successor.parent_binding_sha256
	merged["not_formal_layout_quest_successor"]=true
	return merged
static func author(config: Dictionary) -> Dictionary:
	var path: String=String(config.get("author_path",""))
	if path.is_empty() or FileAccess.get_sha256(path)!=config.get("author_sha256",""): return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary and value.get("status")=="READY_SOURCE_FEET_TEMPLE" and value.get("scene_id")==String(ID) and value.get("assets",[]).size()==int(value.get("texture_count",-1)) and not value.get("placements",[]).is_empty() else {}
static func structure_valid(config: Dictionary,authored: Dictionary) -> bool:
	if config.is_empty() or authored.is_empty() or int(authored.texture_count)<=0 or config.get("texture_proofs",[]).size()!=int(authored.texture_count): return false
	var assets: Dictionary={}; var textures: Dictionary={}; var proofs: Dictionary={}; var instances: Dictionary={}
	for row: Dictionary in authored.assets:
		var id: String=String(row.get("id","")); var path: String=String(row.get("texture",""))
		if id.is_empty() or assets.has(id) or textures.has(path) or not path.begins_with("res://") or ".." in path or not _v(row.get("size_px")).is_finite() or _v(row.size_px).x<=0 or _v(row.size_px).y<=0: return false
		assets[id]=row; textures[path]=row
	if not textures.has(String(authored.get("ground",{}).get("texture",""))): return false
	for row: Dictionary in config.texture_proofs:
		var path: String=String(row.get("texture","")); var imported: String=String(row.get("import_path","")); var compiled: String=String(row.get("compiled_path",""))
		if proofs.has(path) or not textures.has(path) or imported!=path+".import" or not compiled.begins_with("res://.godot/imported/") or not compiled.ends_with(".ctex") or ".." in compiled or String(row.get("rgba_sha256","")).length()!=64: return false
		if _v(row.get("size_px"))!=_v(textures[path].size_px): return false
		for required: String in [path,imported,compiled]:
			if String(config.source_sha256.get(required,"")).length()!=64: return false
		var file:=ConfigFile.new()
		if file.load(imported)!=OK or file.get_value("remap","path","")!=compiled or file.get_value("deps","source_file","")!=path: return false
		proofs[path]=true
	if proofs.size()!=textures.size(): return false
	for row: Dictionary in authored.placements:
		var id: String=String(row.get("id","")); var asset_id: String=String(row.get("asset_id",""))
		if id.is_empty() or instances.has(id) or not assets.has(asset_id) or assets[asset_id].texture==authored.ground.texture or not _v(row.get("foot_px")).is_finite() or not is_finite(float(row.get("scale",0))) or float(row.get("scale",0))<=0: return false
		instances[id]=true
	for required: String in [SCENE_PATH,LAYOUT_PATH,String(config.get("author_path","")),ORIGINAL,ORIGINAL_LAYOUT]:
		if String(config.source_sha256.get(required,"")).length()!=64: return false
	return config.source_sha256.get(ORIGINAL)==ORIGINAL_SHA and config.source_sha256.get(ORIGINAL_LAYOUT)==ORIGINAL_LAYOUT_SHA
static func scene_path() -> String: return SCENE_PATH if not binding().is_empty() else ""
static func is_scene(scene: SceneScript) -> bool:
	# Frame-path identity only. Complete sources/storage are proved per Field.
	return scene!=null and requested(scene.scene_id) and scene.resource_path==SCENE_PATH and scene.actor_positions_are_feet and scene.get_meta("temple_assembly_contract","")==META and scene.map_layout!=null and scene.map_layout.resource_path==LAYOUT_PATH
static func source_paths() -> Dictionary:
	var config:=binding()
	if config.is_empty(): return {}
	var parent_binding_path: String=String(config.get("parent_binding_path",""))
	if parent_binding_path.is_empty() or FileAccess.get_sha256(parent_binding_path)!=config.get("parent_binding_sha256",""): return {}
	var result: Dictionary={SELF:true,BIND_PATH:true,parent_binding_path:true,SCENE_PATH:true,LAYOUT_PATH:true,ORIGINAL:true,ORIGINAL_LAYOUT:true,"res://scripts/city/luoyang_temple_task_adapter_20261016.gd":true,"res://scripts/city/luoyang_temple_fade_20261016.gd":true,"res://scripts/autoload/scene_router.gd":true,"res://scripts/field/field_walkable_controller.gd":true,"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":true}
	for path: String in config.source_sha256:
		if not path.begins_with("res://") or ".." in path: return {}
		result[path]=true
	var task_paths: Dictionary=load("res://scripts/city/luoyang_city_tasks_20261016.gd").source_paths()
	if task_paths.is_empty(): return {}
	result.merge(task_paths); return result
static func original_scene() -> SceneScript:
	if FileAccess.get_sha256(ORIGINAL)!=ORIGINAL_SHA or FileAccess.get_sha256(ORIGINAL_LAYOUT)!=ORIGINAL_LAYOUT_SHA: return null
	var scene:=ResourceLoader.load(ORIGINAL,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	return scene if scene!=null and scene.resource_path==ORIGINAL and scene.scene_id==ID and not scene.actor_positions_are_feet and scene.hotspots.size()==8 and scene.map_layout!=null and scene.map_layout.resource_path==ORIGINAL_LAYOUT else null
static func legacy_interactions(scene: SceneScript) -> Array:
	var result: Array=[]
	if scene==null: return result
	for i: int in scene.hotspots.size():
		var item: Dictionary=scene.hotspots[i]; var action: String=String(item.get("action",""))
		if action.is_empty() or action.begins_with("scene:") or action=="world_map": continue
		result.append({"id":"legacy_hotspot_%d"%i,"pos":Vector2(float(item.get("pos_x",.5)),float(item.get("pos_y",.5))),"size":Vector2(.11,.12),"action":action,"activation":"interact","require_flag":String(item.get("require_flag","")),"hide_flag":String(item.get("hide_flag",""))})
	return result
static func legacy_portals(scene: SceneScript) -> Array:
	var result: Array=[]
	if scene==null: return result
	for i: int in scene.hotspots.size():
		var item: Dictionary=scene.hotspots[i]; var action: String=String(item.get("action",""))
		if not action.begins_with("scene:"): continue
		result.append({"id":"legacy_portal_%d"%i,"pos":Vector2(float(item.pos_x),float(item.pos_y)),"size":Vector2(.13,.14),"label":String(item.get("label","前往下一处")),"require_flag":String(item.get("require_flag","")),"hide_flag":String(item.get("hide_flag","")),"target_scene":action.trim_prefix("scene:"),"target_pos":Vector2(.12,.75)})
	return result
static func successor_npcs() -> Array:
	const SPRITE="res://art/characters/luoyang_layout_quest_20261018t/npc_temple_gate_monk_idle_down_1f_v1.png"
	return [
		{"conversation_base_facing":"front","dialog_id":"luoyang_layout_quest_20261018t/longmen_offer","dialog_variants":[],"interaction_action":"","movement_mode":"idle","npc_id":"temple_cave_keeper_20261018t","npc_name":"守窟僧","portrait_path":SPRITE,"pos":Vector2(936.0,900.0)/SOURCE_SIZE,"scale":0.9459459459459459,"sprite_path":SPRITE},
		{"conversation_base_facing":"front","dialog_id":"luoyang_layout_quest_20261018t/baima_offer","dialog_variants":[],"interaction_action":"","movement_mode":"idle","npc_id":"temple_bell_keeper_20261018t","npc_name":"守钟僧","portrait_path":SPRITE,"pos":Vector2(600.0,900.0)/SOURCE_SIZE,"scale":0.9459459459459459,"sprite_path":SPRITE},
	]
static func successor_interactions(original: Array,authored: Dictionary) -> Array:
	var relocated: Array=relocated_interactions(original,authored)
	if relocated.is_empty(): return []
	var result: Array=[]; var removed: Dictionary={}
	for item: Dictionary in relocated:
		var id: String=String(item.get("id",""))
		if id in ["legacy_hotspot_4","legacy_hotspot_5"]:
			var expected_action: String="dialog:ch4_longmen_mystery" if id=="legacy_hotspot_4" else "dialog:ch4_baima_bell"
			if removed.has(id) or String(item.get("action",""))!=expected_action: return []
			removed[id]=true
			continue
		result.append(item.duplicate(true))
	return result if removed.size()==2 and result.size()==relocated.size()-2 else []
static func successor_portals(scene: SceneScript) -> Array:
	var result: Array=legacy_portals(scene)
	if result.size()!=2: return []
	var feet: Dictionary={"legacy_portal_6":Vector2(240.0,850.0),"legacy_portal_7":Vector2(1296.0,850.0)}
	for portal: Dictionary in result:
		var id: String=String(portal.get("id",""))
		if not feet.has(id) or portal.has("source_spawn_pos") or portal.has("source_foot_pos"): return []
		portal.pos=feet[id]/SOURCE_SIZE
	return result
static func successor_hotspots(scene: SceneScript) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]; var removed: Dictionary={}; var moved: Dictionary={}
	for source: Dictionary in scene.hotspots:
		var item: Dictionary=source.duplicate(true); var action: String=String(item.get("action",""))
		if action in ["dialog:ch4_longmen_mystery","dialog:ch4_baima_bell"]:
			if removed.has(action): return []
			removed[action]=true
			continue
		if action=="scene:ch4_s3_luoyang_market": item.pos_x=240.0/SOURCE_SIZE.x; item.pos_y=850.0/SOURCE_SIZE.y; moved[action]=true
		elif action=="scene:ch4_s2_canal_docks": item.pos_x=1296.0/SOURCE_SIZE.x; item.pos_y=850.0/SOURCE_SIZE.y; moved[action]=true
		result.append(item)
	return result if removed.size()==2 and moved.size()==2 and result.size()==scene.hotspots.size()-2 else []
static func relocated_interactions(original: Array,authored: Dictionary) -> Array:
	var moves: Array=authored.get("interaction_relocations",[])
	if moves.size()!=6: return []
	var expected: Array=legacy_interactions(original_scene())
	if expected.size()!=6: return []
	var by_id: Dictionary={}
	for move: Dictionary in moves:
		var id: String=String(move.get("id",""))
		if by_id.has(id) or not _v(move.get("new_pos_uv")).is_finite(): return []
		var found: bool=false
		for item: Dictionary in expected:
			if item.id==id:
				if _v(move.get("old_pos_uv"))!=item.pos: return []
				found=true; break
		if not found: return []
		by_id[id]=_v(move.new_pos_uv)
	var result: Array=original.duplicate(true)
	for item: Dictionary in result:
		if not by_id.has(String(item.get("id",""))): return []
		item.pos=by_id[String(item.id)]
	return result
static func _poly(points: Array,scale: Vector2=Vector2.ONE) -> PackedVector2Array:
	var out:=PackedVector2Array()
	for point: Array in points: out.append(_v(point)*scale)
	return out
static func build_scene(original: SceneScript,authored: Dictionary) -> SceneScript:
	if original==null or original.scene_id!=ID or authored.is_empty(): return null
	var scene:=original.duplicate(true) as SceneScript
	var layout:=WalkableMapLayout.new()
	layout.design_size=Vector2i(SOURCE_SIZE); layout.display_at_native_size=true; layout.fill_viewport=true
	for region: Array in authored.geometry.floor_regions_px: layout.walkable_regions.append(_poly(region,Vector2.ONE/SOURCE_SIZE))
	for base: Dictionary in authored.geometry.furniture_bases:
		if base.get("blocking")==true: layout.blockers.append({"id":base.id,"ground_polygon":_poly(base.ground_polygon_px,Vector2.ONE/SOURCE_SIZE),"walkability_margin":0.0})
	for placement: Dictionary in authored.placements:
		var asset: Dictionary={}
		for row: Dictionary in authored.assets:
			if row.id==placement.asset_id: asset=row; break
		if asset.is_empty(): return null
		layout.visual_objects.append({"id":placement.id,"texture":asset.texture,"source_ground_anchor_px":_v(asset.source_ground_anchor_px),"placement_foot_px":_v(placement.foot_px),"native_scale":Vector2.ONE*float(placement.scale)})
	var interactions: Array=successor_interactions(legacy_interactions(original),authored)
	var portals: Array=successor_portals(original)
	if interactions.size()!=4 or portals.size()!=2: return null
	layout.interactions.assign(interactions); layout.portals.assign(portals)
	scene.background_path=String(authored.ground.texture); scene.actor_positions_are_feet=true
	scene.npcs.assign(successor_npcs())
	scene.hotspots.assign(successor_hotspots(original))
	# Old baked door light / incense smoke must not hover over relocated props.
	# This explicit non-story delta disables only these two effects; mist stays.
	if authored.get("disabled_original_animated_prop_ids",[])!=["ch4_temple_door_glow","ch4_temple_incense_smoke"]: return null
	var effects: Array[Dictionary]=[]
	for effect: Dictionary in original.animated_props:
		if String(effect.id) not in authored.disabled_original_animated_prop_ids: effects.append(effect.duplicate(true))
	scene.animated_props=effects
	scene.map_layout=layout; scene.set_meta("temple_assembly_contract",META)
	return scene
static func project_objects(authored: Dictionary,world_size: Vector2) -> Array:
	var result: Array=[]
	for placement: Dictionary in authored.placements:
		var asset: Dictionary={}
		for row: Dictionary in authored.assets:
			if row.id==placement.asset_id: asset=row; break
		if asset.is_empty(): return []
		var ratio: float=float(placement.scale); var foot:=_v(placement.foot_px)
		result.append({"id":String(placement.id),"texture":String(asset.texture),"centered":false,"pos":(foot-_v(asset.source_ground_anchor_px)*ratio)/SOURCE_SIZE,"render_size_px":_v(asset.size_px)*ratio*(world_size/SOURCE_SIZE),"sort_by_feet":true,"depth_sort_foot_y":foot.y/SOURCE_SIZE.y})
	return result
static func safe_foot(geometry: Dictionary,foot: Vector2,size: Vector2,full: bool=false) -> bool:
	return GEOMETRY.safe_origin(geometry,foot-Vector2(0,42),size,full)
static func safe_motion(geometry: Dictionary,from: Vector2,to: Vector2,size: Vector2) -> bool:
	if not from.is_finite() or not to.is_finite(): return false
	var n: int=maxi(1,ceili(from.distance_to(to)/4.0))
	for i: int in range(n+1):
		if not safe_foot(geometry,from.lerp(to,float(i)/n),size): return false
	return true
static func anchors_clear(geometry: Dictionary,authored: Dictionary,size: Vector2) -> bool:
	var original:=original_scene()
	if original==null: return false
	var interactions: Array=successor_interactions(legacy_interactions(original),authored)
	if interactions.size()!=4: return false
	for interaction: Dictionary in interactions:
		if not safe_foot(geometry,interaction.pos*size,size,true): return false
	for portal: Dictionary in successor_portals(original):
		if not safe_foot(geometry,portal.pos*size,size,true): return false
	for npc: Dictionary in successor_npcs():
		if not safe_foot(geometry,npc.pos*size,size,true): return false
	for investigation_foot: Vector2 in [Vector2(380.0,600.0),Vector2(1320.0,670.0)]:
		if not safe_foot(geometry,investigation_foot,size,true): return false
	if not safe_foot(geometry,original.player_spawn*size,size,true): return false
	return true
func _owned(owner: Callable) -> bool: return not _released and owner.is_valid() and owner.call()
func _hash_sources(paths: Dictionary,owner: Callable) -> Dictionary:
	if paths.is_empty() or not _owned(owner) or _task>=0: return {}
	_job=_city().TransitionSourceJob.new(); _job.paths=paths.keys(); _job.paths.sort()
	var job: RefCounted=_job
	var task: int=WorkerThreadPool.add_task(job.run,false,"Temple owned complete source SHA")
	if task<0: _job=null; return {}
	_task=task
	while _owned(owner) and _job==job and not WorkerThreadPool.is_task_completed(task): await (Engine.get_main_loop() as SceneTree).process_frame
	if not _owned(owner) or _job!=job:
		if _job==job:
			job.request_cancel(); WorkerThreadPool.wait_for_task_completion(task)
			_task=-1; _job=null
		return {}
	WorkerThreadPool.wait_for_task_completion(task); _task=-1
	var result: Dictionary=job.hashes.duplicate(true)
	_job=null
	return result if result.size()==paths.size() else {}
func prepare(scene: SceneScript,owner: Callable) -> bool:
	var config:=binding(); data=author(config)
	if not is_scene(scene) or not structure_valid(config,data) or not _owned(owner): return _reject("TEMPLE_NOT_READY_UNBOUND_OR_STRUCTURE")
	var paths:=source_paths()
	_source_first=await _hash_sources(paths,owner)
	if not _owned(owner) or _source_first.is_empty(): return _reject("TEMPLE_FIRST_SOURCE_CANCELLED_OR_EMPTY")
	for path: String in config.source_sha256:
		if _source_first.get(path,"")!=config.source_sha256[path]: return _reject("TEMPLE_FIRST_SOURCE_CHANGED:"+path)
	var original:=original_scene(); var expected:=build_scene(original,data)
	if expected==null or not load("res://scripts/city/luoyang_city_revision_candidate_retry2_20261015.gd").serialized_equal(scene,expected): return _reject("TEMPLE_FULL_CHILD_STORAGE_CHANGED")
	if not _city()._equal_value(scene.npcs,successor_npcs()) or not _city()._equal_value(scene.hotspots,successor_hotspots(original)) or scene.bgm_path!=original.bgm_path: return _reject("TEMPLE_GAMEPLAY_OR_MUSIC_CHANGED")
	_scene=scene; _scene_storage=_city()._transition_storage(scene); _layout_storage=_city()._transition_storage(scene.map_layout)
	# Verify ACTUAL imported texture bytes used by Field, one image/frame. No
	# raw decode on the UI thread and no Image or GPU data crosses the SHA job.
	if config.get("texture_proofs",[]).size()!=int(data.texture_count): return _reject("TEMPLE_TEXTURE_PROOF_COUNT")
	for row: Dictionary in config.texture_proofs:
		if not _owned(owner): return _reject("TEMPLE_TEXTURE_OWNER_CHANGED")
		var texture:=ResourceLoader.load(row.texture) as Texture2D
		var image: Image=texture.get_image() if texture!=null else null
		if image==null or image.get_size()!=Vector2i(row.size_px[0],row.size_px[1]): return _reject("TEMPLE_TEXTURE_DIMENSION")
		image.convert(Image.FORMAT_RGBA8)
		if _city()._transition_bytes_sha(image.get_data())!=row.rgba_sha256: return _reject("TEMPLE_IMPORTED_FULL_RGBA")
		_textures[row.texture]=texture; image=null
		await (Engine.get_main_loop() as SceneTree).process_frame
	return true if _owned(owner) else _reject("TEMPLE_PREPARE_OWNER_CHANGED")
func finalize(scene: SceneScript,owner: Callable) -> bool:
	if _scene!=scene or _source_first.is_empty() or not _owned(owner): return _reject("TEMPLE_FINAL_OWNER_OR_SCENE_CHANGED")
	_source_final=await _hash_sources(_source_first,owner)
	if not _owned(owner): return _reject("TEMPLE_FINAL_SOURCE_OWNER_CHANGED")
	_finalized=not _source_final.is_empty() and _city()._equal_value(_source_first,_source_final) and _city()._equal_value(_scene_storage,_city()._transition_storage(scene)) and _city()._equal_value(_layout_storage,_city()._transition_storage(scene.map_layout))
	return true if _finalized else _reject("TEMPLE_FINAL_SOURCE_OR_STORAGE_CHANGED")
func texture_matches(path: String,texture: Texture2D) -> bool: return _textures.get(path)==texture and texture!=null
func _reject(message: String) -> bool:
	error=message; release(); return false
func state() -> Dictionary:
	return {"scope":"TEMPLE_OWN_FIELD_NOT_C_CITY_RECEIPT","source_first":_source_first.duplicate(true),"source_final":_source_final.duplicate(true),"source_count":_source_first.size(),"finalized":_finalized,"worker_active":_task>=0,"released":_released,"scene_instance":_scene.get_instance_id() if _scene!=null else 0,"error":error}
func release() -> void:
	_released=true
	if _job!=null: _job.request_cancel()
	if _task>=0: WorkerThreadPool.wait_for_task_completion(_task)
	_task=-1; _job=null; _scene=null; _textures.clear(); _scene_storage.clear(); _layout_storage.clear()
