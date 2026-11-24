extends "res://scripts/city/luoyang_city_assembled_fade_20261016b.gd"
## Preserve the selected parent's original exact whitelist/count guard first.
## Extra low items remain in native depth/alpha-mask but never fade themselves.
func configure_district(world: Node2D,scene: SceneScript,parent_objects: Array,projected: Dictionary) -> bool:
	release()
	var paths: Dictionary={"ch4_s3_luoyang_market":"res://scripts/city/luoyang_city_assembled_fade_20261016b.gd","ch4_s1_luoyang_yamen":"res://scripts/city/luoyang_yamen_annex_fade_20261016.gd","ch4_s0_luoyang_gate":"res://scripts/city/luoyang_harbour_life_fade_20261016.gd","ch4_s2_canal_docks":"res://scripts/city/luoyang_harbour_life_fade_20261016.gd"}
	if scene==null or not paths.has(String(scene.scene_id)): return false
	var original: RefCounted=load(paths[String(scene.scene_id)]).new()
	var harbour: bool=String(scene.scene_id) in ["ch4_s0_luoyang_gate","ch4_s2_canal_docks"]
	var oracle_scene: SceneScript=scene
	var oracle_objects: Array=parent_objects
	var t: Variant=load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
	if scene.has_meta("luoyang_layout_quest_20261018t"):
		oracle_scene=t.parent_scene(scene)
		if oracle_scene==null: original.release(); return false
		oracle_objects=oracle_scene.map_layout.visual_objects
	var ok: bool=original.configure_harbour_scene(world,oracle_scene,oracle_objects) if harbour else original.configure_assembled_scene(world,oracle_scene,oracle_objects)
	if not ok: original.release(); return false
	_ids=original.get("_ids").duplicate(); _fade_ids=original.get("_fade_ids").duplicate(); original.release()
	if scene.has_meta("luoyang_layout_quest_20261018t"):
		# Keep original whitelist admission, then remove only absent parent IDs.
		var actual: Array=[]
		for entry: Dictionary in parent_objects:
			if entry.get("sort_by_feet",false): actual.append(String(entry.id))
		for id: String in _ids.duplicate():
			if id not in actual:
				if id not in ["southwest_market_front","southeast_market_front","market_northwest_rear_frontage","market_northeast_rear_frontage","assembled_market_backlane_row","assembled_market_warehouse_edge"] and not t.ao_retired_visual_id(scene,id): return false
				_ids.erase(id); _fade_ids.erase(id)
		for id: String in actual:
			if id not in _ids: return false
	for entry: Dictionary in projected.additions+projected.replacements:
		var id: String=String(entry.id)
		if id not in _ids: _ids.append(id)
		_fade_ids.erase(id)
		if entry.district_life_fade: _fade_ids.append(id)
	configure(world); _fade_scene=String(scene.scene_id); _fade_opacity=.55; _fade_seconds=.18
	_fade_status="READY_PREVIEW_ONLY"; _runtime_bound=true; return true
