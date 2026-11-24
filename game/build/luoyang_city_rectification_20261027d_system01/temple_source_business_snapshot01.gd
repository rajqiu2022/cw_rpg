extends RefCounted
## Frozen Temple source business extraction only; no legacy owner, prepare or source_paths.
const FLAG="--luoyang-temple-assembly-20261016"
const FORMAL_ENABLED=true
const ID=&"ch4_s4_ancient_temple"
const META="temple_assembled_ground_feet_20261016"
const BIND_PATH="res://build/luoyang_city_finish_20261025i_source01/garden_estate_exit_repair_20261027c01/closure_READY01/Temple_binding_READY.json"
const BIND_SHA="ca6d8cf4e42517ae92eb8ff0647fa93ba50d2c9ffcfb260469258b65f4279703"
const SCENE_PATH="res://data/scenes/luoyang_temple_layout_quest_20261018t/temple.tres"
const LAYOUT_PATH="res://data/maps/luoyang_temple_layout_quest_20261018t/layout.tres"
const ORIGINAL="res://data/scenes/ch4_s4_ancient_temple.tres"
const ORIGINAL_LAYOUT="res://data/maps/ch4_s4_ancient_temple_layout_v1.tres"
const ORIGINAL_SHA="1570a4d9cfcb0508a12bfa639052db8aec11ab25634a3f5c606d19cbe2223730"
const ORIGINAL_LAYOUT_SHA="c639287b0afff4c5e2e8ad667438a5b023102a1215549610189540c8e96a26f0"
const SOURCE_SIZE=Vector2(1536,1024)
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

static func is_scene(scene: SceneScript) -> bool:
	# Frame-path identity only. Complete sources/storage are proved per Field.
	return scene!=null and requested(scene.scene_id) and scene.resource_path==SCENE_PATH and scene.actor_positions_are_feet and scene.get_meta("temple_assembly_contract","")==META and scene.map_layout!=null and scene.map_layout.resource_path==LAYOUT_PATH

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
