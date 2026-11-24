extends "res://scripts/city/luoyang_enclosure_building_fade_runtime_20261010.gd"
## Source-bound variable furniture count. Low tables/beds/benches remain solid
## and opaque; inherited actual-frame alpha masks draw the .46 actor ghost.
var _room_ids: Array=[]
var _high_ids: Array=[]

func configure_rooms(world: Node2D,scene: SceneScript,data: Dictionary) -> bool:
	release()
	if not is_instance_valid(world) or scene==null or not scene.actor_positions_are_feet or data.get("room",{}).get("scene_id")!=String(scene.scene_id) or data.get("furniture",[]).is_empty(): return false
	var seen: Dictionary={}
	for item: Dictionary in data.furniture:
		var id: String=String(item.get("id",""))
		if id.is_empty() or seen.has(id): return false
		seen[id]=true; _room_ids.append(id)
		if item.get("height_behavior")=="HIGH_FURNITURE_FADE": _high_ids.append(id)
	configure(world)
	_fade_scene=String(scene.scene_id); _fade_opacity=.55; _fade_seconds=.18
	_fade_status="READY_PREVIEW_ONLY"; _runtime_bound=true
	return true

func add_prop(sprite: Sprite2D,id: String,foot_y: float) -> void:
	if id not in _room_ids: return
	super.add_prop(sprite,id,foot_y)
	# Keep all native order + source alpha records, but only author-declared
	# high furniture participates in fading. No shared NPC/Player edits.
	if id not in _high_ids:
		for index: int in range(_fade_records.size()-1,-1,-1):
			var record: Dictionary=_fade_records[index]
			if record.id==id and record.sprite.get_ref()==sprite:
				_restore_record(record,sprite); _fade_records.remove_at(index)
		return
	for record: Dictionary in _fade_records:
		if record.sprite.get_ref()==sprite: return
	if not is_instance_valid(sprite) or not _finite_color(sprite.self_modulate): return
	for prop: Dictionary in _props:
		if prop.sprite==sprite:
			_fade_records.append({"sprite":weakref(sprite),"id":id,"base_color":sprite.self_modulate,"factor":1.0,"target":1.0,"hit":false,"eligible":false}); return

func release() -> void:
	super.release(); _room_ids.clear(); _high_ids.clear()
