extends "res://scripts/city/luoyang_city_assembled_fade_20261016b.gd"
## Exact same exterior fade/native-depth policy, bound to this new geometry.
func configure_assembled_scene(world: Node2D,scene: SceneScript,objects: Array) -> bool:
	release()
	var runtime: Variant=load("res://scripts/city/luoyang_yamen_annex_runtime_20261016.gd")
	if not runtime.bound(scene) or not is_instance_valid(world): return false
	for entry: Dictionary in objects:
		if entry.get("sort_by_feet",false)!=true: continue
		var id: String=String(entry.id)
		if id in _ids: return false
		_ids.append(id)
		if id in ["magistrate_hall","notice_pavilion","south_court_gate"] or "wall" in id or id.begins_with("assembled_") and not "tree" in id: _fade_ids.append(id)
	if _ids.size()!=24: return false
	configure(world); _fade_scene=String(scene.scene_id); _fade_opacity=.55; _fade_seconds=.18
	_fade_status="READY_PREVIEW_ONLY"; _runtime_bound=true; return true
